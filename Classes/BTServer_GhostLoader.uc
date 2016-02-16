//=============================================================================
// TODO:
//  Previous record ghost
//  Personal ghosts
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GhostLoader extends Info;

struct sGhostInfo
{
    var BTClient_Ghost      GhostPawn;
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

        if( data.MO.Length > 0 )
        {
            Log( "GhostData" @ data.PackageName @ "with" @ data.MO.Length @ "frames loaded", Name );
        }
        else
        {
            Log( "GhostData" @ data.PackageName @ "is empty!", Name );
        }
    }

    UpdateGhostsInfo();
    Log( "Loaded" @ Ghosts.Length @ "ghosts", Name );
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

final function UpdateGhostsInfo()
{
    local int i;
    local BTClient_GhostMarker Marking;

    // BT.FullLog( "Ghost::UpdateGhostsInfo" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        Ghosts[i].GhostSlot = BT.FindPlayerSlot( Ghosts[i].GhostData.PLID );
        if( Ghosts[i].GhostSlot != -1 )
        {
            Ghosts[i].GhostName = BT.PDat.Player[Ghosts[i].GhostSlot-1].PLName $ GhostTag;
            Ghosts[i].GhostChar = BT.PDat.Player[Ghosts[i].GhostSlot-1].PLChar;
            Ghosts[i].GhostTeam = ASGameInfo(Level.Game).Teams[ASGameInfo(Level.Game).CurrentAttackingTeam];
        }
        else
        {
            Ghosts[i].GhostName = "Unknown" $ GhostTag;
        }
    }

    if( BT.bAddGhostTimerPaths && BT.bSoloMap && Ghosts.Length > 0 && Ghosts[0].GhostData.MO.Length < 2000 )
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
        if( Ghosts[i].GhostPawn != none )
        {
            Ghosts[i].GhostPawn.PlayerReplicationInfo.PlayerName = Ghosts[i].GhostName;
        }
    }
}

final function ClearGhostsData( string mapName, string ghostDataName, optional bool bCurrentMap )
{
    local int i;
    local BTServer_GhostData data;
    local BTClient_GhostMarker marker;

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

    data = Level.Game.LoadDataObject( GhostDataClass, ghostDataName $ mapName $ Eval( i > 0, "("$i$")", "" ), ghostDataName $ mapName );
    if( data == none )
        return;

    Level.Game.DeletePackage( data.PackageName );
    Log( "Deleted all ghost data files for" @ mapName, Name );
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

        Ghosts[i].GhostData.TZERO = 0f;
        Ghosts[i].GhostData.TONE = 0f;
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
    GhostsPause();
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

    // BT.FullLog( "Ghost::GhostsKill" );
    GhostsPause();
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostPawn == none )
            continue;

        if( Ghosts[i].GhostPawn.PlayerReplicationInfo != none )
        {
            Ghosts[i].GhostPawn.PlayerReplicationInfo.Destroy();
        }

        if( Ghosts[i].GhostPawn.Controller != none )
        {
            Ghosts[i].GhostPawn.Controller.Destroy();
        }

        if( Ghosts[i].GhostPawn != none )
        {
            Ghosts[i].GhostPawn.Destroy();
        }

        Ghosts[i].GhostData.Ghost = none;
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

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostDisabled || Ghosts[i].GhostData == none )
        {
            continue;
        }

        if( Ghosts[i].GhostPawn == none )
        {
            if( Level.TimeSeconds - BT.MRI.MatchStartTime >= Ghosts[i].GhostData.RelativeStartTime )
            {
                BT.FullLog( "Spawning ghost for" @ Ghosts[i].GhostName );
                Ghosts[i].GhostPawn = Ghosts[i].GhostData.InitializeGhost( self, i );
            }
        }

        // BT.FullLog( "Moving ghost[" $ i $ "]" @ Ghosts[i].GhostData.CurrentMove $ "/" $ Ghosts[i].GhostData.MO.Length );
        if( !Ghosts[i].GhostData.LoadNextMoveData() )
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

/**event Tick( float deltaTime )
{
    local int i;
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostDisabled || Ghosts[i].GhostData == none || Ghosts[i].GhostPawn == none )
        {
            continue;
        }
        // Smooth the movement
        Ghosts[i].GhostData.InterpolateMove();
    }
}*/

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
    GhostMarkerClass=class'BTClient_GhostMarker'
}
