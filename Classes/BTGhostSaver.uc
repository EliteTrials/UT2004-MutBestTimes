class BTGhostSaver extends Info;

var private array<struct sGhostInfo{
	// The recorded frames of our player.
	var BTGhostRecorder Recorder;
	var BTGhostData Data;
	var transient bool ExistingData;

	// Index to PDat.Player
	var int PlayerIndex;

	// Package's main name i.e. usually the map's name, e.g. BTGhost_<PackageId>.uvx
	var string PackageId;

	// Player's GUID, used to set the ghost data's object name
	// e.g. (package) BTGhost_<PackageId>.uvx -> (object) BTGhost_<GhostId>
	var string GhostId;
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
        if( Recorders[i].Owner == other )
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

final function PauseRecording()
{
	local int i;

    for( i = 0; i < Recorders.Length; ++ i )
    {
        if( Recorders[i] != none )
            Recorders[i].StopGhostCapturing();
    }
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

final function QueueGhost( PlayerController player, int playerIndex, string packageId )
{
	local int i, j;
	local BTGhostRecorder recorder;

	// Remove the existing recorder, because we don't want this recorder to get restarted if the owner respawns!
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
		return;
	}

	// TODO: check existing queue for duplicates, and cancel the current queue if necessary!
	recorder.StopGhostCapturing();

	j = SaveQueue.Length;
	SaveQueue.Length = j + 1;
	SaveQueue[j].Recorder = recorder;
	SaveQueue[j].PlayerIndex = playerIndex;
	SaveQueue[j].PackageId = packageId;
	SaveQueue[j].GhostId = recorder.ghostId;

	// First ghost reward!
	BT.PDat.ProgressAchievementByID( playerIndex, 'ghost_0' );
	// Disable map traveling if possible.
	if( Level.Game.VotingHandler != none )
	{
		Level.Game.VotingHandler.SetTimer( 0.00, false );
	}
	Enable( 'Tick' );
}

event Tick( float deltaTime )
{
	local int i, qIdx, nextFrame, numFrames;
	local BTGhostData data;
	local BTGhostRecorder recorder;

	if( SaveQueue.Length == 0 )
	{
		Disable( 'Tick' );
		return;
	}

	qIdx = 0;
	recorder = SaveQueue[qIdx].Recorder;
	data = SaveQueue[qIdx].Data;
	if( data == none )
	{
		data = Manager.GetGhostData( SaveQueue[qIdx].PackageId, SaveQueue[qIdx].GhostId );
		if( data == none )
		{
			data = Manager.CreateGhostData( SaveQueue[qIdx].PackageId, SaveQueue[qIdx].GhostId );
			if( data == none )
			{
				Warn( "Couldn't create a new ghost data object for" @ SaveQueue[qIdx].PackageId @ SaveQueue[qIdx].GhostId );
				// Abort saving.
				SaveQueue.Remove( qIdx, 1 );
				return;
			}
		}
		else
		{
			data.Init(); // new version
			data.MO.Length = 0;
			Manager.DirtyGhostPackage( SaveQueue[qIdx].PackageId );
		}

		data.UsedGhostFPS = recorder.FramesPerSecond;
		data.PLID = BT.PDat.Player[SaveQueue[qIdx].PlayerIndex].PLID;
		data.RelativeStartTime = recorder.RelativeStartTime;
		SaveQueue[qIdx].Data = data;

		for( i = 0; i < Manager.Ghosts.Length; ++ i )
		{
			if( Manager.Ghosts[i].GhostData == data )
			{
				SaveQueue[qIdx].ExistingData = true;
				Manager.Ghosts[i].PausePlay();
				break;
			}
		}
		// BT.FullLog( "Started saving progress for ghost" @ SaveQueue[qIdx].GhostId
			// @ "Existing:" @ SaveQueue[qIdx].ExistingData
		// );
	}
	numFrames = recorder.Frames.Length;
	if( data.MO.Length < numFrames )
	{
		nextFrame = data.MO.Length;
	 	data.MO.Length = nextFrame + 1;
		data.MO[nextFrame] = recorder.Frames[nextFrame];
	}

	if( numFrames == 0 || data.MO.Length == numFrames )
	{
		// BT.FullLog( "Saving complete!" @ data.MO.Length @ "frames have been saved!"
		// 	@ "PackageId:" @ SaveQueue[qIdx].PackageId
		// 	@ "GhostId:" @ SaveQueue[qIdx].GhostId
		// 	@ "Existing:" @ SaveQueue[qIdx].ExistingData
		// );

		if( SaveQueue[qIdx].ExistingData )
		{
			for( i = 0; i < Manager.Ghosts.Length; ++ i )
			{
				if( Manager.Ghosts[i].GhostData == data )
				{
					// Install our new markers
					if( Manager.GetGhostRank( Manager.Ghosts[i] ) == 1 )
					{
						Manager.Ghosts[i].InstallMarkers( true );
					}
					Manager.Ghosts[i].RestartPlay();
					break;
				}
			}
		}
		else
		{
			Manager.CreateGhostPlayback( data, SaveQueue[qIdx].PackageId, true );
			Manager.SqueezeGhosts( BT.bSoloMap && !BT.bGroupMap );
		}

		if( recorder != none )
		{
			recorder.Destroy();
		}
		SaveQueue.Remove( qIdx, 1 );
		if( SaveQueue.Length == 0 && Level.Game.VotingHandler != none )
		{
			Level.Game.VotingHandler.SetTimer( 1.00, true );
		}

		// FIXME: Force view #1 ghost on the correct map
		// if( !BT.bDontEndGameOnRecord )
		// {
		// 	Manager.ForceViewGhost();
		// }
	}
}