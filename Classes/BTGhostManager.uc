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
var array<BTGhostPlayback> Ghosts;
var BTGhostSaver Saver;
// Pending packages that have became dirty and need to be saved.
var private array<string> PendingPackageNames;
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

        BT.FullLog( "Deleted old ghost data from map" @ Ghosts[i].GhostMapName @ "belonging to" @ Ghosts[i].GhostData.PLID );
        Ghosts[i].Destroy();
        Ghosts.Remove( i --, 1 );
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

    for( i = 0; i < PendingPackageNames.Length; ++ i )
    {
        if( PendingPackageNames[i] == mapName )
        {
            PendingPackageNames.Remove( i, 1 );
            skipNext = true;
            break;
        }
    }

    // This package doesn't need saving!
    if( !skipNext )
        return false;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
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
        DeleteGhostData( mapName, dataNames[i] );
    }
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

        CreateGhostPlayback( ghostData, mapName );
    }
}

final function BTGhostPlayback CreateGhostPlayback( BTGhostData data, string mapName, optional bool instantPlay )
{
    local int j;
    local string ghostPackageName;
    local int ghostRank;
    local BTGhostPlayback playback;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    playback = Spawn( GhostPlaybackClass, Owner );
    j = Ghosts.Length;
    Ghosts.Length = j + 1;
    Ghosts[j] = playback;
    playback.GhostMapName = mapName;
    playback.GhostPackageName = ghostPackageName;
    playback.GhostData = data;
    playback.GhostSlot = BT.FindPlayerSlot( playback.GhostData.PLID );
    if( playback.GhostSlot != -1 )
    {
        playback.GhostName = BT.PDat.Player[playback.GhostSlot-1].PLName $ GhostTag @ "in" @ mapName;
        playback.GhostChar = BT.PDat.Player[playback.GhostSlot-1].PLChar;
    }
    else
    {
        playback.GhostName = "Unknown" $ GhostTag;
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

private function AddPendingPackage( string packageName )
{
    local int i;

    for( i = 0; i < PendingPackageNames.Length; ++ i )
    {
        if( PendingPackageNames[i] == packageName )
            return;
    }
    PendingPackageNames[PendingPackageNames.Length] = packageName;
}

final function BTGhostData GetGhostData( string mapName, string ghostId )
{
    local BTGhostData data;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    data = Level.Game.LoadDataObject( GhostDataClass, "BTGhost_"$ghostId, ghostPackageName );
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
        AddPendingPackage( ghostPackageName );
    }
    return data;
}

final function bool DeleteGhostData( string mapName, string ghostId )
{
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    AddPendingPackage( ghostPackageName );
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
            && (Ghosts[i].GhostData != none Ghosts[i].GhostData.PLID == ghostId) )
        {
            Ghosts[i].Destroy();
            Ghosts.Remove( i, 1 );
            return true;
        }
    }
    return false;
}

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
