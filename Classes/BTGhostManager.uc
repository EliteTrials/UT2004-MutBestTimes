//=============================================================================
// Copyright 2005-2016 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGhostManager extends Info;

var const int MaxGhosts;
var const string GhostTag;

var const noexport string GhostDataPackagePrefix;
var const class<BTGhostData> GhostDataClass;
var const class<BTGhostPlayback> GhostPlaybackClass;

// The ghosts that we are currently playing, if a ghost is missing from this array, then it will be deleted from the package on the next save.
var array<BTGhostPlayback> Ghosts, CustomGhosts;
var BTGhostSaver Saver;
// Pending packages that have became dirty and need to be saved.
var private array<string> DirtyPackageNames;
var private MutBestTimes BT;

event PreBeginPlay()
{
    BT = MutBestTimes(Owner);
    Saver = Spawn( class'BTGhostSaver', Owner );
    Saver.Manager = self;
}

// Remove obsolete ghosts from the loaded ghost packages.
final function SqueezeGhosts( optional bool byRank )
{
    local int i, ghostRank;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        // Only erase low ranked ghosts!
        if( byRank )
        {
            ghostRank = GetGhostRank( Ghosts[i] );
            if( ghostRank != 0 && ghostRank <= 3 )
            {
                continue;
            }

        }

        BT.FullLog( "Removed old ghost data from map" @ Ghosts[i].GhostMapName @ "belonging to" @ Ghosts[i].GhostData.PLID );
        Ghosts[i].Destroy();
        Ghosts.Remove( i --, 1 ); // This ghost's data will be deleted on the next saving event.
    }
}

// Saves all relevant ghosts and their packages, if a ghost does no longer exist, all its data will be erased before saving.
final function bool SaveRelevantGhosts( string mapName )
{
    local int i;
    local array<string> dataNames;
    local object data;
    local BTGhostData ghostData;
    local string ghostPackageName;
    local bool skipNext;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    Log("Saving relevant ghosts for map" @ mapName);
    for( i = 0; i < DirtyPackageNames.Length; ++ i )
    {
        if( DirtyPackageNames[i] == ghostPackageName )
        {
            DirtyPackageNames.Remove( i, 1 );
            skipNext = true;
            break;
        }
    }

    // This package doesn't need saving!
    if( !skipNext )
    {
        Log("Map has no dirty ghosts" @ mapName);
        return false;
    }

    foreach Level.Game.AllDataObjects( GhostDataClass, data, ghostPackageName )
    {
        ghostData = BTGhostData(data);
        if( ghostData == none )
            continue;

        skipNext = false;
        for( i = 0; i < Ghosts.Length; ++ i )
        {
            if( Ghosts[i].GhostData == ghostData )
            {
                // Don't delete this ghost's data.
                skipNext = true;
                break;
            }
        }

        if( skipNext )
            continue;

        dataNames[dataNames.Length] = ghostData.PLID;
    }
    for( i = 0; i < dataNames.Length; ++ i )
    {
        Log("Deleting ghost data" @ ghostPackageName @ "object" @ dataNames[i]);
        DeleteGhostData( mapName, dataNames[i] );
    }
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        Log( Ghosts[i].GhostData.PLID @ Ghosts[i].GhostPackageName );
    }
    Log("Saving ghosts package" @ ghostPackageName);
    return SaveGhostsPackage( mapName );
}

// 0 = no rank
final function int GetGhostRank( BTGhostPlayback playback )
{
    local int ghostRank, mapIndex;

    mapIndex = BT.RDat.FindRecord( playback.GhostMapName );
    if( mapIndex == -1 ) // To delete or keep for nostalgie?
        return 0;

    ghostRank = BT.RDat.GetPlayerRank( mapIndex, playback.GhostSlot );
    return ghostRank;
}

/**
 *  Loads and spawns all ghosts for the specified map.
 *  Can load multiple map instances.
 */
final function LoadGhosts( string mapName )
{
    local object data;
    local BTGhostData ghostData;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    foreach Level.Game.AllDataObjects( GhostDataClass, data, ghostPackageName )
    {
        ghostData = BTGhostData(data);
        if( ghostData == none )
            continue;

        Ghosts[Ghosts.Length] = CreateGhostPlayback( ghostData, mapName );
    }
}

final function BTGhostPlayback CreateGhostPlayback( BTGhostData data, string mapName, optional bool instantPlay, optional bool isCustom )
{
    local int playerSlot;
    local string ghostPackageName;
    local int ghostRank;
    local BTGhostPlayback playback;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    playerSlot = BT.FindPlayerSlot( data.PLID );
    playback = Spawn( GhostPlaybackClass, Owner );
    playback.GhostMapName = mapName;
    playback.GhostPackageName = ghostPackageName;
    playback.GhostData = data;
    playback.GhostSlot = playerSlot;
    if( playback.GhostSlot != -1 )
    {
        playback.GhostName = BT.PDat.Player[playerSlot-1].PLName $ GhostTag @ "in" @ mapName;
        playback.GhostChar = BT.PDat.Player[playerSlot-1].PLChar;
    }
    else
    {
        playback.GhostName = "Unknown" $ GhostTag;
    }

    if( isCustom )
    {
        return playback;
    }

    BT.FullLog( "Loaded ghost" @ playback.GhostData.PLID @ "for" @ mapName @ "with" @ data.MO.Length @ "frames" );
    ghostRank = GetGhostRank( playback );
    if( ghostRank == 1 )
    {
        playback.InstallMarkers( instantPlay/**replace old*/ );
    }
    playback.OnGhostEndPlay = InternalOnGhostEndPlay;
    if( instantPlay )
    {
        playback.StartPlay();
    }
    return playback;
}

private function AddDirtyPackage( string packageName )
{
    local int i;

    for( i = 0; i < DirtyPackageNames.Length; ++ i )
    {
        if( DirtyPackageNames[i] == packageName )
            return;
    }
    DirtyPackageNames[DirtyPackageNames.Length] = packageName;
}

final function BTGhostData GetGhostData( string mapName, string ghostId )
{
    local int i;
    local BTGhostData data;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    data = Level.Game.LoadDataObject( GhostDataClass, "BTGhost_"$ghostId, ghostPackageName );
    if( data != none )
    {
        for( i = 0; i < Ghosts.Length; ++ i )
        {
            if( Ghosts[i].GhostPackageName == ghostPackageName
                && Ghosts[i].GhostData != none
                && Ghosts[i].GhostData.PLID == ghostId )
            {
                return Ghosts[i].GhostData;
            }
        }
    }
    return data;
}

final function BTGhostData CreateGhostData( string mapName, string ghostId )
{
    local BTGhostData data;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    data = Level.Game.CreateDataObject( GhostDataClass, "BTGhost_"$ghostId, ghostPackageName );
    if( data != none )
    {
        data.Init();
        AddDirtyPackage( ghostPackageName );
    }
    return data;
}

final function DirtyGhostPackage( string mapName )
{
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    AddDirtyPackage( ghostPackageName );
}

final function bool DeleteGhostData( string mapName, string ghostId )
{
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    AddDirtyPackage( ghostPackageName );
    return Level.Game.DeleteDataObject( GhostDataClass, "BTGhost_"$ghostId, ghostPackageName );
}

final function bool SaveGhostsPackage( string mapName )
{
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    return Level.Game.SavePackage( ghostPackageName );
}

final function bool DeleteGhostsPackage( string mapName )
{
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    return Level.Game.DeletePackage( ghostPackageName );
}

final function bool RemoveGhost( string mapName, string ghostId )
{
    local int i;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostPackageName == ghostPackageName
            && (Ghosts[i].GhostData != none && Ghosts[i].GhostData.PLID == ghostId) )
        {
            AddDirtyPackage( ghostPackageName );
            Ghosts[i].Destroy();
            Ghosts.Remove( i, 1 );
            return true;
        }
    }
    return false;
}

// Note: CustomGhosts array doesn't require updates because such ghosts are not spectable!
final function UpdateGhostsName( int playerSlot, string newName )
{
    local int i;

    // BT.FullLog( "Ghost::UpdateGhostsName" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        // Ghost owner??
        if( Ghosts[i].GhostSlot-1 != playerSlot )
        {
            continue;
        }

        Ghosts[i].GhostName = newName $ GhostTag @ "in" @ Ghosts[i].GhostMapName;
        if( Ghosts[i].Controller != none )
        {
            Ghosts[i].Controller.PlayerReplicationInfo.PlayerName = Ghosts[i].GhostName;
        }
    }
}

final function ClearGhostsData( string mapName, optional bool bCurrentMap )
{
    local int i;
    local object data;
    local array<name> dataNames;
    local string ghostPackageName;

    // BT.FullLog( "Ghost::ClearGhostsData" );
    ghostPackageName = GhostDataPackagePrefix $ mapName;
    if( bCurrentMap )
    {
        for( i = 0; i < Ghosts.Length; ++ i )
        {
            if( Ghosts[i].GhostPackageName != ghostPackageName )
            {
                continue;
            }
            Ghosts[i].Destroy();
            Ghosts.Remove( i --, 1 );
        }
    }

    BT.FullLog( "Deleted all ghost data files for" @ mapName );
    // Ensure that all objects are deleted from the package and memory, otherwise the next SavePackage may re-save the ghosts.
    foreach Level.Game.AllDataObjects( GhostDataClass, data, ghostPackageName )
    {
        dataNames[dataNames.Length] = data.Name;
    }
    for( i = 0; i < dataNames.Length; ++ i )
    {
        Level.Game.DeleteDataObject( GhostDataClass, string(dataNames[i]), ghostPackageName );
    }
    Level.Game.DeletePackage( ghostPackageName );
}

final function GhostsPlay()
{
    local int i;

    BT.FullLog( "Ghost::GhostsPlay" );
    if( Ghosts.Length == 0 )
    {
        BT.FullLog( "Ghost::No ghosts to start!" );
        return;
    }

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostData == none )
        {
            BT.FullLog( "Ghost::" $ i @ "tried to play ghost with no data!" );
            continue;
        }
        Ghosts[i].StartPlay();
    }
}

final function GhostsPause()
{
    local int i;

    // BT.FullLog( "Ghost::GhostsPause" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        Ghosts[i].PausePlay();
    }
}

final function GhostsRespawn()
{
    local int i;

    // BT.FullLog( "Ghost::GhostsRespawn" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        Ghosts[i].RestartPlay();
    }
}

final function int FindGhostByRank( string mapName, int ghostRank )
{
    local int i;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostMapName == mapName
            && GetGhostRank( Ghosts[i] ) == ghostRank )
        {
            return i;
        }
    }
    return -1;
}

final function bool SpawnGhostFor( int ghostIndex, Controller c )
{
    local int i;
    local BTGhostData data;
    local string mapName;
    local BTGhostPlayback playback;

    for( i = 0; i < CustomGhosts.Length; ++ i )
    {
        if( CustomGhosts[i].CustomController == c )
        {
            return false;
        }
    }

    data = Ghosts[ghostIndex].GhostData;
    mapName = Ghosts[ghostIndex].GhostMapName;
    playback = CreateGhostPlayback( data, mapName, false, true );
    if( playback == none )
        return false;

    playback.CustomController = c;
    playback.RestartPlay();
    CustomGhosts[CustomGhosts.Length] = playback;
    return true;
}

final function RestartGhostFor( Controller c )
{
    local int i;

    for( i = 0; i < CustomGhosts.Length; ++ i )
    {
        if( CustomGhosts[i].CustomController == c )
        {
            CustomGhosts[i].RestartPlay();
            break;
        }
    }
}

final function bool KillGhostFor( Controller c )
{
    local int i;

    for( i = 0; i < CustomGhosts.Length; ++ i )
    {
        if( CustomGhosts[i].CustomController == c )
        {
            CustomGhosts[i].Destroy();
            CustomGhosts.Remove( i, 1 );
            return true;
        }
    }
    return false;
}

final function GhostsSpawn()
{
    // BT.FullLog( "Ghost::GhostsSpawn" );
    GhostsPlay();
}

final function GhostsKill()
{
    local int i;

    BT.FullLog( "Ghost::GhostsKill" );
    GhostsPause();
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].Controller != none && Ghosts[i].Controller.Pawn != none )
        {
            Ghosts[i].Controller.Pawn.Destroy();
        }
    }
}

// Respawn all ghosts once the ghosts have reached the end of their playback.
final function InternalOnGhostEndPlay( BTGhostPlayback playback )
{
    local int i;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostMapName == playback.GhostMapName && !Ghosts[i].GhostDisabled )
            return;
    }

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostMapName != playback.GhostMapName )
            continue;

        Ghosts[i].RestartPlay();
    }
}

final function Pawn GetGhostPawn( int ghostIndex )
{
    if( Ghosts[ghostIndex].Controller == none )
        return none;

    return Ghosts[ghostIndex].Controller.Pawn;
}

final function ForceViewGhost()
{
    local Controller C;
    local Pawn p;

    if( Ghosts.Length == 0 )
        return;

    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) != none && C.bIsPlayer )
        {
            p = GetGhostPawn( 0 );
            if( p != none )
            {
                PlayerController(C).SetViewTarget( p );
                PlayerController(C).ClientSetViewTarget( p );
            }
        }
    }
}

function Reset()
{
    super.Reset();
    GhostsRespawn();
}

event Destroyed()
{
    super.Destroyed();
    GhostsKill();
}

defaultproperties
{
    MaxGhosts=8
    GhostTag="' ghost"
    GhostDataPackagePrefix="BTGhost_"
    GhostDataClass=class'BTGhostData'
    GhostPlaybackClass=class'BTGhostPlayback'
}
