//=============================================================================
// TODO:
//  Previous record ghost
//  Personal ghosts
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGhostManager extends Info;

var const int MaxGhosts;
var const string GhostTag;

var const noexport string GhostDataPackagePrefix;
var const class<BTGhostData> GhostDataClass;
var const class<BTGhostPlayback> GhostPlaybackClass;

var array<BTGhostPlayback> Ghosts;
var private MutBestTimes BT;

event PreBeginPlay()
{
    BT = MutBestTimes(Owner);
}

/**
 *  Loads and spawns all ghosts for the specified map.
 *  Can load multiple map instances.
 */
final function LoadGhosts( string mapName )
{
    local int i, j;
    local object data;
    local BTGhostData ghostData;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    foreach Level.Game.AllDataObjects( GhostDataClass, data, ghostPackageName )
    {
        ghostData = BTGhostData(data);
        if( ghostData == none )
            continue;

        j = Ghosts.Length;
        Ghosts.Length = j + 1;
        Ghosts[j] = Spawn( GhostPlaybackClass, Owner );
        Ghosts[j].GhostMapName = mapName;
        Ghosts[j].GhostPackageName = ghostPackageName;
        Ghosts[j].GhostData = ghostData;
        Ghosts[j].GhostSlot = BT.FindPlayerSlot( Ghosts[j].GhostData.PLID );
        if( Ghosts[j].GhostSlot != -1 )
        {
            Ghosts[j].GhostName = BT.PDat.Player[Ghosts[j].GhostSlot-1].PLName $ GhostTag @ "in" @ mapName;
            Ghosts[j].GhostChar = BT.PDat.Player[Ghosts[j].GhostSlot-1].PLChar;
        }
        else
        {
            Ghosts[i].GhostName = "Unknown" $ GhostTag;
        }
        BT.FullLog( "Loaded ghost" @ Ghosts[j].GhostData.PLID @ "for" @ mapName @ "with" @ ghostData.MO.Length @ "frames" );
        Ghosts[j].OnGhostEndPlay = InternalOnGhostEndPlay;
    }
}

final function CreateGhostsData( string mapName, array<string> playerGUIDS, out array<BTGhostData> dataObjects )
{
    local int i;
    local string ghostPackageName;

    // BT.FullLog( "Ghost::CreateGhostsData" );
    ghostPackageName = GhostDataPackagePrefix $ mapName;
    dataObjects.Length = playerGUIDS.Length;
    for( i = 0; i < playerGUIDS.Length; ++ i )
    {
        dataObjects[i] = Level.Game.CreateDataObject( GhostDataClass, "BTGhost_"$playerGUIDS[i], ghostPackageName );
        dataObjects[i].Presave( BT, playerGUIDS[i] );
    }
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

final function SaveGhosts( string mapName )
{
    BT.FullLog( "Ghost::SaveGhosts" );
    Level.Game.SavePackage( GhostDataPackagePrefix $ mapName );
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

    BT.FullLog( "Ghost::GhostsPause" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        Ghosts[i].PausePlay();
    }
}

final function GhostsRespawn()
{
    local int i;

    BT.FullLog( "Ghost::GhostsRespawn" );
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
final function InternalOnGhostEndPlay()
{
    local int i;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( !Ghosts[i].GhostDisabled )
            return;
    }
    GhostsRespawn();
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
