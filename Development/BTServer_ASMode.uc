//=============================================================================
// This mode serves the meaning of all Modes whom are built upon Assault.
// For example: Regular, Solo and Group are built upon Assault, and therefor shall extend this class.
//
// Where as TrialMode is any mode which wants Rankings and Records.
// For example: InvasionMode does not extend TrialMode but BunnyMode does extend TrialMode but not ASMode.
//
// This class serves no use on its own, it shall be inherited by any class whom want to take advantage of Assault features.
//
// Copyright 2005-2012 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_ASMode extends BTServer_TrialMode
	abstract;
	
function ModePostBeginPlay()
{
	local BTServer_ForceTeamRespawn B;
	local Triggers Tr;
	
	super.ModePostBeginPlay();
	
	// We only need one round. Every round is a game end, unless increased by BTimes itself.
	AssaultGame.RoundLimit = 1;
	
	// We need to watch out for the end of Practice Round.
	Spawn( Class'BTServer_EventTimer', Outer );
	
	if( bSpawnGhost )
	{
		FullLog( "Loading Ghost Playback data" );
		if( GhostManager == none )
		{
			GhostManager = Spawn( class'BTServer_GhostLoader', Outer );
		}

		GhostManager.LoadGhosts( CurrentMapName, GhostDataFileName );
	}
	
	// We need to replace all the team respawn triggers, to ensure that our ghosts will be ignored.
	foreach AllActors( class'Triggers', Tr )
	{
		if( Trigger_ASForceTeamRespawn(Tr) != none )
		{
			if( Tr.bNoDelete || Tr.bStatic )
				continue;

			B = Spawn( Class'BTServer_ForceTeamRespawn' );
			B.Tag = Tr.Tag;
			Tr.Destroy();
			continue;
		}

		// We need a list of triggers. 
		// If a user whom might be using Client Spawn, he shall be killed by any of those listed triggers.
		if( bAllowClientSpawn && (bTriggersKillClientSpawnPlayers || bAlwaysKillClientSpawnPlayersNearTriggers) )
		{
			if( Tr.Event != '' && Tr.bCollideActors )
				Triggers[Triggers.Length] = Tr;
		}
	}
}
	
function ModeReset()
{
	super.ModeReset();
	if( AssaultGame.CurrentRound > 1 )
	{
		// Reset scores etc.
		AssaultGame.PracticeRoundEnded();
		ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundTimeLimit = 0;	// Adjust it again cause assault probably adjusted it.
			
		MatchStarting();

		// Reset!
		//ObjCompT = RDat.Rec[UsedSlot].ObjCompT;

		if( IsCompetitive() )
		{
			MRI.TeamTime[0] = 0.0f;
			MRI.TeamTime[1] = 0.0f;
		}
	}
}

defaultproperties
{
}