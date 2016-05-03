//=============================================================================
// TODO:
//  Previous record ghost
//  Personal ghosts
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GhostLoader extends Info;

struct sGhostInfo
{
    var BTServer_GhostController    Controller;
    var string                      GhostName;
    var string                      GhostChar;
    var UnrealTeamInfo              GhostTeam;
    var int                         GhostSlot;
    var BTServer_GhostData          GhostData;
    var float                       GhostMoved;
    var bool                        GhostDisabled;
    var string                      GhostPackageName, GhostMapName;
};

var array<sGhostInfo> Ghosts;

var const int MaxGhosts;
var const string GhostTag;

var const noexport string GhostDataPackagePrefix;
var const class<BTServer_GhostData> GhostDataClass;
var const class<BTServer_GhostController> GhostControllerClass;
var const class<BTClient_GhostMarker> GhostMarkerClass;
var MutBestTimes BT;

event PreBeginPlay()
{
    super.PreBeginPlay();
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
    local BTServer_GhostData ghostData;
    local string ghostPackageName;

    ghostPackageName = GhostDataPackagePrefix $ mapName;
    foreach Level.Game.AllDataObjects( GhostDataClass, data, ghostPackageName )
    {
        ghostData = BTServer_GhostData(data);
        if( ghostData == none )
            continue;

        j = Ghosts.Length;
        Ghosts.Length = j + 1;
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
        Ghosts[j].Controller = CreateGhostController( j );
    }

    if( BT.bAddGhostTimerPaths && BT.bSoloMap )
    {
        AddGhostMarkers();
    }
}

final function BTServer_GhostController CreateGhostController( int ghostIndex )
{
    local BTServer_GhostController controller;
    local PlayerReplicationInfo PRI;

    controller = Spawn( GhostControllerClass );
    PRI = controller.PlayerReplicationInfo;
    PRI.PlayerName = Ghosts[ghostIndex].GhostName;
    if( ASGameInfo(Level.Game) != none )
    {
        PRI.Team = TeamGame(Level.Game).Teams[ASGameInfo(Level.Game).CurrentAttackingTeam];
    }
    else if( TeamGame(Level.Game) != none )
    {
        PRI.Team = TeamGame(Level.Game).Teams[0];
    }
    PRI.CharacterName = Ghosts[ghostIndex].GhostChar;
    return controller;
}

final function CreateGhostsData( string mapName, array<string> playerGUIDS, out array<BTServer_GhostData> dataObjects )
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

final function AddGhostMarkers()
{
    local int i;
    local BTClient_GhostMarker Marking;

    if( Ghosts.Length > 0 && Ghosts[0].GhostData.MO.Length < 2000 )
    {
        for( i = 0; i < Ghosts[0].GhostData.MO.Length; ++ i )
        {
            if( Marking == none || VSize( Marking.Location - Ghosts[0].GhostData.MO[i].P ) > 512 )
            {
                Marking = Spawn( GhostMarkerClass, self,, Ghosts[0].GhostData.MO[i].P );
                Marking.MoveIndex = i;
            }
        }
        BT.MRI.MaxMoves = Ghosts[0].GhostData.MO.Length;
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
    local BTClient_GhostMarker marker;
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

            if( Ghosts[i].Controller != none )
            {
                Ghosts[i].Controller.Destroy();
            }

            Ghosts.Remove( i --, 1 );
        }

        // FIXME: only destroy those which are related to the current map (& instance)
        foreach DynamicActors( class'BTClient_GhostMarker', marker )
        {
            marker.Destroy();
        }
        BT.MRI.MaxMoves = 0;
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
    }

    SetTimer( GhostFramesPerSecond( 0 ), true );
    Timer();
}

final function GhostsPause()
{
    BT.FullLog( "Ghost::GhostsPause" );
    SetTimer( 0f, false );
}

final function GhostsRespawn()
{
    local int i;

    BT.FullLog( "Ghost::GhostsRespawn" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostData == none )
        {
            continue;
        }

        Ghosts[i].GhostData.CurrentMove = 0;
        Ghosts[i].GhostDisabled = false;
        Ghosts[i].GhostMoved = 0f;
    }
    GhostsPlay();
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

final function float GhostFramesPerSecond( int ghostSlot )
{
    return 1f / Ghosts[ghostSlot].GhostData.UsedGhostFPS;
}

event Timer()
{
    local int i;
    local bool primairGhostDone, allGhostsDone;
    local Pawn p;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostDisabled
            || Ghosts[i].GhostData == none
            || Level.TimeSeconds - BT.MRI.MatchStartTime < Ghosts[i].GhostData.RelativeStartTime )
        {
            continue;
        }

        p = GetGhostPawn( i );
        if( p == none )
        {
            if( Ghosts[i].Controller == none )
            {
                Warn( "Creating unexpectedly new ghost controller!!" );
                Ghosts[i].Controller = CreateGhostController( i );
                if( Ghosts[i].Controller.bDeleteMe )
                    continue;
            }
            p = Ghosts[i].Controller.CreateGhostPawn( Ghosts[i].GhostData );
            if( p == none )
            {
                // Perhaps we tried to spawn the ghost in an invalid location.
                ++ Ghosts[i].GhostData.CurrentMove;
                continue;
            }
        }

        if( !Ghosts[i].GhostData.PerformNextMove( p ) )
        {
            if( BT.bSoloMap )
            {
                Ghosts[i].GhostData.CurrentMove = 0;
            }
            else
            {
                p.Velocity = vect( 0, 0, 0 );
                Ghosts[i].GhostDisabled = true;
                if( i == 0 )
                {
                    primairGhostDone = true;
                }
            }
        }
    }

    if( primairGhostDone )
    {
        for( i = 0; i < Ghosts.Length; ++ i )
        {
            if( !Ghosts[i].GhostDisabled )
            {
                allGhostsDone = false;
            }
        }

        if( !allGhostsDone )
        {
            return;
        }

        for( i = 0; i < Ghosts.Length; ++ i )
        {
            Ghosts[i].GhostData.CurrentMove = 0;
            Ghosts[i].GhostDisabled = false;
        }
        primairGhostDone = false;
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
    GhostDataClass=class'BTServer_GhostData'
    GhostControllerClass=class'BTServer_GhostController'
    GhostMarkerClass=class'BTClient_GhostMarker'
}
