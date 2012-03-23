//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_SoloMode extends BTServer_TrialMode;

static function bool DetectMode( MutBestTimes M )
{
	return M.Objectives.Length == 1;
}

protected function InitializeMode()
{
	super.InitializeMode();
	bSoloMap = true;
	MRI.bSoloMap = true;
	Objectives[0].Event = 'BT_SOLORECORD';
	Tag = 'BT_SOLORECORD';

	// Remove objective sounds, we got our own!
	Objectives[0].Announcer_DisabledObjective = none;
	Objectives[0].Announcer_ObjectiveInfo = none;
	Objectives[0].Announcer_DefendObjective = none;

	if( Objectives[0].IsA('LCAKeyObjective') || Objectives[0].IsA('LCA_KeyObjective') )
	{
		bKeyMap = true;
		MRI.bKeyMap = true;
	}
	else if( Objectives[0].IsA('TriggeredObjective') )
	{
		bAlwaysKillClientSpawnPlayersNearTriggers = true;
	}
}

function bool ClientExecuted( PlayerController sender, string command, array<string> params )
{
	switch( command )
	{
		case "resetcheckpoint":
			if( bQuickStart )
			{
				break;
			}
			ResetCheckPoint( sender );
			break;

		default:
			return false;
			break;
	}
	return true;
}

defaultproperties
{
	ModeName="Solo"
	ModePrefix="STR"

	ExperienceBonus=5
}
