//=============================================================================
// TODO:
//  Previous record ghost
//  Personal ghosts
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GhostLoader extends Info;

struct sGhostInfo
{
    var BTServer_GhostController
                            Controller;
    var string              GhostName;
    var string              GhostChar;
    var UnrealTeamInfo      GhostTeam;
    var int                 GhostSlot;
    var BTServer_GhostData  GhostData;
    var float               GhostMoved;
    var bool                GhostDisabled;
};

var array<sGhostInfo> Ghosts;

var const int MaxGhosts;
var const string GhostTag;

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
 *  Load all the ghosts from data objects and assign them to the Ghosts array.
 */
final function LoadGhosts( string mapName, string ghostDataName )
{
    local int i, j;
    local BTServer_GhostData data;

    // BT.FullLog( "Ghost::LoadGhosts" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].Controller != none )
        {
            Ghosts[i].Controller.Destroy();
        }
    }
    Ghosts.Length = 0;
    for( i = 0; i < MaxGhosts; ++ i )
    {
        data = Level.Game.LoadDataObject( GhostDataClass, ghostDataName $ mapName $ Eval( i > 0, "("$i$")", "" ), ghostDataName $ mapName );
        if( data == none )
            break;

        data.PackageName = ghostDataName $ mapName;

        j = Ghosts.Length;
        Ghosts.Length = j + 1;
        Ghosts[j].GhostData = data;

        Ghosts[j].GhostSlot = BT.FindPlayerSlot( Ghosts[j].GhostData.PLID );
        if( Ghosts[j].GhostSlot != -1 )
        {
            Ghosts[j].GhostName = BT.PDat.Player[Ghosts[j].GhostSlot-1].PLName $ GhostTag;
            Ghosts[j].GhostChar = BT.PDat.Player[Ghosts[j].GhostSlot-1].PLChar;
            Ghosts[j].GhostTeam = ASGameInfo(Level.Game).Teams[ASGameInfo(Level.Game).CurrentAttackingTeam];
        }
        else
        {
            Ghosts[i].GhostName = "Unknown" $ GhostTag;
        }
        Ghosts[j].Controller = CreateGhostController( j );

        if( data.MO.Length > 0 )
        {
            Log( "GhostData" @ data.PackageName @ "with" @ data.MO.Length @ "frames loaded", Name );
        }
        else
        {
            Log( "GhostData" @ data.PackageName @ "is empty!", Name );
        }
    }

    if( BT.bAddGhostTimerPaths && BT.bSoloMap )
    {
        AddGhostMarkers();
    }
    Log( "Loaded" @ Ghosts.Length @ "ghosts", Name );
}

final function BTServer_GhostController CreateGhostController( int ghostIndex )
{
    local BTServer_GhostController controller;
    local PlayerReplicationInfo PRI;

    controller = Spawn( GhostControllerClass );
    PRI = controller.PlayerReplicationInfo;
    PRI.PlayerName = Ghosts[ghostIndex].GhostName;
    PRI.Team = Ghosts[ghostIndex].GhostTeam;
    PRI.CharacterName = Ghosts[ghostIndex].GhostChar;
    return controller;
}

final function CreateGhostsData( string mapName, string ghostDataName, array<string> IDs, out array<BTServer_GhostData> dataObjects )
{
    local int i;

    // BT.FullLog( "Ghost::CreateGhostsData" );
    dataObjects.Length = IDs.Length;
    for( i = 0; i < IDs.Length; ++ i )
    {
        dataObjects[i] = Level.Game.CreateDataObject( GhostDataClass, ghostDataName $ mapName $ Eval( i > 0, "("$i$")", "" ), ghostDataName $ mapName );
        dataObjects[i].PackageName = ghostDataName $ mapName;
        dataObjects[i].Presave( BT, IDs[i] );
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

        Ghosts[i].GhostName = newName $ GhostTag;
        if( Ghosts[i].Controller != none )
        {
            Ghosts[i].Controller.PlayerReplicationInfo.PlayerName = Ghosts[i].GhostName;
        }
    }
}

final function ClearGhostsData( string mapName, string ghostDataName, optional bool bCurrentMap )
{
    local int i;
    local BTServer_GhostData data;
    local BTClient_GhostMarker marker;
    local array<name> dataNames;

    // BT.FullLog( "Ghost::ClearGhostsData" );
    if( bCurrentMap )
    {
        GhostsKill();
        Ghosts.Length = 0;

        foreach DynamicActors( class'BTClient_GhostMarker', marker )
        {
            marker.Destroy();
        }

        BT.MRI.MaxMoves = 0;
    }

    Log( "Deleted all ghost data files for" @ mapName, Name );
    // Ensure that all objects are deleted from the package and memory, otherwise the next SavePackage may re-save the ghosts.
    foreach Level.Game.AllDataObjects( GhostDataClass, data, ghostDataName $ mapName )
    {
        dataNames[dataNames.Length] = data.Name;
    }
    for( i = 0; i < dataNames.Length; ++ i )
    {
        Level.Game.DeleteDataObject( GhostDataClass, string(dataNames[i]), ghostDataName $ mapName );
    }
    Level.Game.DeletePackage( data.PackageName );
}

final function SaveGhosts( string mapName, string ghostDataName )
{
    BT.FullLog( "Ghost::SaveGhosts" );
    Level.Game.SavePackage( ghostDataName $ mapName );
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
                Log( "Creating unexpectedly new ghost controller!!" );
                Ghosts[i].Controller = CreateGhostController( i );
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
    // Kill to undo NewRound modifications
    GhostsKill();
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

    GhostDataClass=class'BTServer_GhostData'
    GhostControllerClass=class'BTServer_GhostController'
    GhostMarkerClass=class'BTClient_GhostMarker'
}
