class BTGhostPlayback extends Info;

var const class<BTClient_GhostMarker> GhostMarkerClass;
var const class<BTServer_GhostController> GhostControllerClass;

var BTServer_GhostController    Controller;
var string                      GhostName;
var string                      GhostChar;
var UnrealTeamInfo              GhostTeam;
var int                         GhostSlot;
var BTServer_GhostData          GhostData;
var float                       GhostMoved;
var bool                        GhostDisabled;
var string                      GhostPackageName, GhostMapName;

var private MutBestTimes BT;

delegate OnGhostEndPlay();

event PreBeginPlay()
{
	BT = MutBestTimes(Owner);
    if( BT.bAddGhostTimerPaths && BT.bSoloMap )
    {
        AddGhostMarkers();
    }
}

final function AddGhostMarkers()
{
    local int i;
    local BTClient_GhostMarker Marking;

    // Already have added markers for a ghost.
    if( BT.MRI.MaxMoves != 0 )
    	return;

    if( GhostData.MO.Length < 2000 )
    {
        for( i = 0; i < GhostData.MO.Length; ++ i )
        {
            if( Marking == none || VSize( Marking.Location - GhostData.MO[i].P ) > 512 )
            {
                Marking = Spawn( GhostMarkerClass, self,, GhostData.MO[i].P );
                Marking.MoveIndex = i;
            }
        }
        // FIXME: Multiple level maps
        BT.MRI.MaxMoves = GhostData.MO.Length;
    }
}

final function CreateGhostController()
{
    local PlayerReplicationInfo PRI;

    Controller = Spawn( GhostControllerClass );
    PRI = Controller.PlayerReplicationInfo;
    PRI.PlayerName = GhostName;
    if( ASGameInfo(Level.Game) != none )
    {
        PRI.Team = TeamGame(Level.Game).Teams[ASGameInfo(Level.Game).CurrentAttackingTeam];
    }
    else if( TeamGame(Level.Game) != none )
    {
        PRI.Team = TeamGame(Level.Game).Teams[0];
    }
    PRI.CharacterName = GhostChar;
}

final function float PlayFPS()
{
    return 1f/GhostData.UsedGhostFPS;
}

final function StartPlay()
{
	if( Controller == none )
		CreateGhostController();

    SetTimer( PlayFPS(), true );
    Timer();
}

final function PausePlay()
{
    SetTimer( 0f, false );
}

final function RestartPlay()
{
	if( GhostData != none )
		GhostData.CurrentMove = 0;

    GhostDisabled = false;
    GhostMoved = 0f;
    StartPlay();
}

final function PlayNextFrame()
{
    local Pawn p;

    if( GhostData == none || GhostDisabled )
    	return;

    // Don't play until we have elapsed the same time as when the ghost' began recording.
    if( Level.TimeSeconds - BT.MRI.MatchStartTime < GhostData.RelativeStartTime )
    	return;

    p = Controller.Pawn;
    if( p == none )
    {
        if( Controller == none )
        {
            Warn( "Creating unexpectedly new ghost controller!!" );
            CreateGhostController();
            if( Controller.bDeleteMe )
                return;
        }

        p = Controller.CreateGhostPawn( GhostData );
        if( p == none )
        {
            // Perhaps we tried to spawn the ghost in an invalid location.
            ++ GhostData.CurrentMove;
            return;
        }
    }

    if( !GhostData.PerformNextMove( p ) )
    {
        if( BT.bSoloMap )
        {
            GhostData.CurrentMove = 0;
        }
        else
        {
            p.Velocity = vect( 0, 0, 0 );
            GhostDisabled = true;
            OnGhostEndPlay();
        }
    }
}

event Timer()
{
	PlayNextFrame();
}

event Destroyed()
{
    local BTClient_GhostMarker marker;

	super.Destroyed();
    if( Controller != none )
    {
        Controller.Destroy();
    }

    // FIXME: only destroy those which are related to the current map (& instance)
    foreach DynamicActors( class'BTClient_GhostMarker', marker )
    {
        marker.Destroy();
    }
    BT.MRI.MaxMoves = 0;
}

defaultproperties
{
    GhostControllerClass=class'BTServer_GhostController'
    GhostMarkerClass=class'BTClient_GhostMarker'
}