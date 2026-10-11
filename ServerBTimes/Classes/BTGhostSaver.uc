class BTGhostSaver extends Info;

var private array<struct sGhostInfo{
	// The recorded frames of our player.
	var BTGhostRecorder Recorder;
	var BTGhostData Data;
	var transient bool ExistingData;

	// Index to PDat.Player
	var int PlayerIndex;

	// Package's name e.g. BTGhost_<MapName>_<GhostId>.uvx
	var string MapName;

	// Player's GUID used to assemble a ghost package's name.
	var string GhostId;
	var int SavedMovesCount;
}> SaveQueue;

var private MutBestTimes BT;
var array<BTGhostRecorder> Recorders;
var BTGhostManager Manager;

event PreBeginPlay()
{
    BT = MutBestTimes(Owner);
    Disable( 'Tick' );
}

final function RecordPlayer( PlayerController other )
{
    local int i, j;

    // Leaving player?
    if( other.Player == none )
    	return;

    // Check if this player is being recorded already?
    j = Recorders.Length;
    for( i = 0; i < j; ++ i )
    {
    	if( Recorders[i] == none )
    	{
    		Recorders.Remove( i --, 1 );
    		-- j;
    		continue;
    	}
        if( Recorders[i].Owner == other && BT.bSoloMap )
        {
        	// Restart
            Recorders[i].StartGhostCapturing( BT.GhostPlaybackFPS );
            return;
        }
    }

    Recorders.Length = j + 1;
    Recorders[j] = Spawn( Class'BTGhostRecorder', other );
    Recorders[j].GhostId = other.GetPlayerIdHash();
    if( !BT.bSoloMap )
    {
        Recorders[j].RelativeStartTime = Level.TimeSeconds - BT.MRI.MatchStartTime;
    }
    Recorders[j].StartGhostCapturing( BT.GhostPlaybackFPS );
}

final function EndRecording()
{
	local int i;

    for( i = 0; i < Recorders.Length; ++ i )
    {
        if( Recorders[i] != none )
            Recorders[i].Destroy();
    }
    Recorders.Length = 0;
}

final function bool QueueGhost( PlayerController player, int playerIndex, string MapName )
{
	local int i, j;
	local BTGhostRecorder recorder;
	local BTGhostData data;
	local sGhostInfo ghostInfo;

	// Remove the existing recorder, because we don't want this recorder to get restarted when the owner respawns!
	for( i = 0; i < Recorders.Length; ++ i )
	{
		if( Recorders[i].Owner == player )
		{
			recorder = Recorders[i];
			Recorders.Remove( i, 1 );
			break;
		}
	}

	if( recorder == none )
	{
		Warn( "Tried to save a player's ghost with no recorder!" );
		return false;
	}

	// First ghost reward!
	BT.PDatManager.ProgressAchievementByID( playerIndex, 'ghost_0' );

	// TODO: check existing queue for duplicates, and cancel the current queue if necessary!
	recorder.StopGhostCapturing();

	ghostInfo.Recorder = recorder;
	ghostInfo.PlayerIndex = playerIndex;
	ghostInfo.MapName = MapName;
	ghostInfo.GhostId = recorder.ghostId;
	ghostInfo.SavedMovesCount = 0;

	data = Manager.GetGhostData( ghostInfo.MapName, ghostInfo.GhostId, true );
	if( data == none )
	{
		Warn( "Couldn't create a new ghost data object for" @ ghostInfo.MapName @ ghostInfo.GhostId );
		// Abort saving.
		return false;
	}

	data.UsedGhostFPS = recorder.FramesPerSecond;
	data.RelativeStartTime = recorder.RelativeStartTime;
	data.PLID = recorder.GhostId;
	data.MO.Length = recorder.Frames.Length;
	ghostInfo.data = data;

	j = SaveQueue.Length;
	SaveQueue.Length = j + 1;
	SaveQueue[j] = ghostInfo;

	// Pause any active ghosts that are using the same data object!
	for( i = 0; i < Manager.Ghosts.Length; ++ i )
	{
		if( Manager.Ghosts[i].GhostData == data )
		{
			// Manager.Ghosts[i].PausePlay();
			SaveQueue[j].ExistingData = true;
			break;
		}
	}

	// Disable map traveling if possible.
	if( Level.Game.VotingHandler != none )
	{
		Level.Game.VotingHandler.SetTimer( 0.00, false );
	}
	Enable( 'Tick' );

	BT.FullLog( "Started saving progress for ghost" @ SaveQueue[j].GhostId @ "Existing:" @ SaveQueue[j].ExistingData);
	return true;
}

event Tick( float deltaTime )
{
	local int numFrames, savedMovesCount;
	local BTGhostData data;
	local BTGhostRecorder recorder;

	if (SaveQueue.Length == 0) {
		// Commented, apparently Tick is called at least once before PreBeginPlay.
		// Warn("SaveQueue is empty!!!");
		Disable('Tick');
		return;
	}

	data = SaveQueue[0].Data;
	recorder = SaveQueue[0].Recorder;

	numFrames = recorder.Frames.Length;
	savedMovesCount = SaveQueue[0].SavedMovesCount;
	// BT.FullLog("Save tick:" @ numFrames @ savedMovesCount @ data.PLID);
	if( savedMovesCount < numFrames )
	{
		data.MO[savedMovesCount] = recorder.Frames[savedMovesCount];
		++ SaveQueue[0].SavedMovesCount;
	}

	// Is the current queue finished?
	if( savedMovesCount == numFrames )
	{
		BT.FullLog( "Saving complete!" @ data.MO.Length @ "frames have been saved!"
			@ "MapName:" @ SaveQueue[0].MapName
			@ "GhostId:" @ SaveQueue[0].GhostId
			@ "Existing:" @ SaveQueue[0].ExistingData
		);

		Manager.OnGhostSaved( SaveQueue[0] );
		if( recorder != none )
		{
			recorder.Destroy();
		}

		SaveQueue.Remove( 0, 1 );
		if( SaveQueue.Length == 0 )
		{
			Disable( 'Tick' );

			// Restart map voting.
			if( xVotingHandler(Level.Game.VotingHandler) != none
				&& xVotingHandler(Level.Game.VotingHandler).ScoreBoardTime > 0 )
			{
				// FIXME: causes voting menu to open.
				Level.Game.VotingHandler.SetTimer( 1.00, true );
			}
			return;
		}
	}
}