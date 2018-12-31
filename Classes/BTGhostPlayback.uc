class BTGhostPlayback extends Info;

var const class<BTClient_GhostMarker> GhostMarkerClass;
var const class<BTGhostController> GhostControllerClass;

/** The active player that controls this ghost's playback (GhostFollow). */
var PlayerController    CustomController;
var BTGhostController   Controller;
var string              GhostName;
var string              GhostChar;
var int                 GhostSlot;
var BTGhostData         GhostData;
var bool                GhostDisabled;
var string              GhostPackageName, GhostMapName;

var private MutBestTimes BT;
var private BTClient_LevelReplication MyLevel;
var private int NextFrameIndex;
var private bool bOwnsMarkers;

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
    local float fps;

    if( !BT.bAddGhostTimerPaths || !BT.bSoloMap )
        return;

    ghostLevel = BT.GetObjectiveLevelByFullName( GhostMapName );
    if( ghostLevel != none )
    {
        fps = PlayFPS();
        ghostLevel.PrimaryGhostNumMoves = float(GhostData.MO.Length) + (ghostLevel.TopTime - fps*float(GhostData.MO.Length))/fps;
    }

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
    AddMarkers( ghostLevel );
}

private function AddMarkers( BTClient_LevelReplication ghostLevel )
{
    local int i;
    local BTClient_GhostMarker marker;

    // Log( "Adding frame markers for ghost" @ GhostName @ GhostMapName );
    if( GhostData.MO.Length > 10 && GhostData.MO.Length < 4000 )
    {
        if( ghostLevel != none && BT.MRI.MapLevel == none )
        {
            GhostData.RelativeSpawnOffset = ghostLevel.GetSpawnLocation() - GhostData.GetStartLocation();
        }
        for( i = 0; i < GhostData.MO.Length; ++ i )
        {
            if( (marker == none && VSize( GhostData.MO[0].P - GhostData.MO[i].P ) > 512)
                || (marker != none && VSize( marker.Location - GhostData.RelativeSpawnOffset - GhostData.MO[i].P ) > 512) )
            {
                marker = Spawn( GhostMarkerClass, self,, GhostData.MO[i].P + GhostData.RelativeSpawnOffset );
                marker.MoveIndex = i;
            }
        }
    }
    bOwnsMarkers = true;
}

private function ClearMarkers()
{
    local BTClient_GhostMarker marker;

    if( !bOwnsMarkers )
    {
        return;
    }

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
    bOwnsMarkers = false;
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

/* FIXME:
    initializing replication for: Swaghettis
    BTGhostPlayback RTR-Trials-Of-Korriban-V2E.BTGhostPlayback (Function ServerBTimes.BTGhostPlayback.PlayFPS:0000) Infinite script recursion (250 calls) detected
    Executing UObject::StaticShutdownAfterError
    BTGhostPlayback RTR-Trials-Of-Korriban-V2E.BTGhostPlayback (Function ServerBTimes.BTGhostPlayback.PlayFPS:0000) Infinite script recursion (250 calls) detected
*/
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
    NextFrameIndex = 0;
    GhostDisabled = false;
    StartPlay();
}

private function bool IsDisabled()
{
    return GhostData == none || GhostDisabled || (BT.RDat != none && BT.RDat.Rec[BT.UsedSlot].TMGhostDisabled);
}

private function PlayNextFrame()
{
    local Pawn p;

    if( IsDisabled() )
    	return;

    // Don't play until we have elapsed the same time as when the ghost' began recording.
    if( Level.TimeSeconds - BT.MRI.MatchStartTime < GhostData.RelativeStartTime )
    	return;

    if( CustomController != none
        && (CustomController.PlayerReplicationInfo.bIsSpectator || CustomController.PlayerReplicationInfo.bOnlySpectator)
        && CustomController.ViewTarget != Controller.Pawn )
    {
        // Kill our ghost when our owner/spectator is no longer watching
        // if( Controller.Pawn != none )
        // {
        //     Controller.Pawn.Destroy();
        // }
        // PausePlay();
        // return;
    }

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

        p = Controller.CreateGhostPawn( GhostData, NextFrameIndex );
        if( p == none )
        {
            // Perhaps we tried to spawn the ghost in an invalid location.
            ++ NextFrameIndex;
            return;
        }
        else if( CustomController != none )
        {
            // p.bOnlyRelevantToOwner = true;
            // p.SetOwner( CustomController );
            // Blocks the ghost from being spectated.
            Controller.PlayerReplicationInfo.bOnlySpectator = true;
        }
    }

    // Undo any external collision enables.
    if( p.bCollideActors )
    {
        p.SetCollision( false, false, false );
    }

    if( !GhostData.PerformNextMove( NextFrameIndex, p ) )
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

    PausePlay();
}

defaultproperties
{
    GhostControllerClass=class'BTGhostController'
    GhostMarkerClass=class'BTClient_GhostMarker'
}