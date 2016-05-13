class BTGhostPlayback extends Info;

var const class<BTClient_GhostMarker> GhostMarkerClass;
var const class<BTGhostController> GhostControllerClass;

var BTGhostController   Controller;
var string              GhostName;
var string              GhostChar;
var int                 GhostSlot;
var BTGhostData         GhostData;
var bool                GhostDisabled;
var string              GhostPackageName, GhostMapName;

var private MutBestTimes BT;
var private BTClient_LevelReplication MyLevel;

delegate OnGhostEndPlay( BTGhostPlayback playback );

event PreBeginPlay()
{
	BT = MutBestTimes(Owner);
}

final function InstallMarkers( optional bool replaceOld )
{
    local BTGhostPlayback playback;
    local BTClient_LevelReplication ghostLevel;
    local BTClient_GhostMarker marker;

    if( !BT.bAddGhostTimerPaths || !BT.bSoloMap )
        return;

    ghostLevel = BT.GetObjectiveLevelByFullName( GhostMapName );
    ghostLevel.PrimaryGhostNumMoves = GhostData.MO.Length;

    if( replaceOld )
    {
        // Cleanup any marker of this ghost's level, even if they belong to another ghost.
        foreach DynamicActors( class'BTClient_GhostMarker', marker )
        {
            playback = BTGhostPlayback(marker.Owner);
            if( playback.GhostMapName == GhostMapName )
            {
                marker.Destroy();
            }
        }
    }
    AddMarkers();
}

private function AddMarkers()
{
    local int i;
    local BTClient_GhostMarker marker;

    // Log( "Adding frame markers for ghost" @ GhostName @ GhostMapName );
    if( GhostData.MO.Length > 10 && GhostData.MO.Length < 2000 )
    {
        for( i = 0; i < GhostData.MO.Length; ++ i )
        {
            if( (marker == none && VSize( GhostData.MO[0].P - GhostData.MO[i].P ) > 512)
                || (marker != none && VSize( marker.Location - GhostData.MO[i].P ) > 512) )
            {
                marker = Spawn( GhostMarkerClass, self,, GhostData.MO[i].P );
                marker.MoveIndex = i;
            }
        }
    }
}

private function ClearMarkers()
{
    local BTClient_GhostMarker marker;

    if( MyLevel != none )
    {
        MyLevel.PrimaryGhostNumMoves = 0;
    }

    foreach DynamicActors( class'BTClient_GhostMarker', marker )
    {
        if( marker.Owner != self )
            continue;

        marker.Destroy();
    }
}

private function CreateGhostController()
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

    if( MyLevel == none )
    {
	    // TODO: add client LRI and replicate @PlayingLevel
	    MyLevel = BT.GetObjectiveLevelByFullName( GhostMapName );
        if( MyLevel != none && BT.MRI.MapLevel == none ) // Only necessary on multiple instanced maps.
        {
            GhostData.RelativeSpawnOffset = MyLevel.GetSpawnLocation() - GhostData.GetStartLocation();
            // GhostData.RelativeSpawnDir = MyLevel.GetSpawnRotation() - GhostData.GetStartRotation();
        }
    }
}

private function float PlayFPS()
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
    StartPlay();
}

private function PlayNextFrame()
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

    // Undo any external collision enables.
    if( p.bCollideActors )
    {
        p.SetCollision( false, false, false );
    }

    if( !GhostData.PerformNextMove( p ) )
    {
        p.Velocity = vect( 0, 0, 0 );
        GhostDisabled = true;
        OnGhostEndPlay( self );
    }
}

event Timer()
{
	PlayNextFrame();
}

event Destroyed()
{
	super.Destroyed();
    if( Controller != none )
    {
        Controller.Destroy();
    }
    ClearMarkers();
    OnGhostEndPlay = none;
}

defaultproperties
{
    GhostControllerClass=class'BTGhostController'
    GhostMarkerClass=class'BTClient_GhostMarker'
}