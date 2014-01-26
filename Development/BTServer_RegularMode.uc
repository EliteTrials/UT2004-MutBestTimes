//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_RegularMode extends BTServer_ASMode;

static function bool DetectMode( MutBestTimes M )
{
	// Not solo then were obviously a team mode
	return !Class'BTServer_SoloMode'.static.DetectMode( M );
}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
	super.PlayerCompletedMap( player, playerSlot, playSeconds );

	// Completed a regular map.
	PDat.ProgressAchievementByID( playerSlot, 'mode_2' );
	// Has 10 or more regular records.
	if( PDat.FindAchievementByID( playerSlot, 'records_4' ) == -1 && CountRecordsNum( regularNum, playerSlot ) >= 10 )
	{
		// Regular gamer.
		PDat.ProgressAchievementByID( playerSlot, 'records_4' );
	}
}

defaultproperties
{
	ModeName="Regular"
	ModePrefix="RTR"

	DropChanceBonus=1.0
	ExperienceBonus=25
	
	// 60 Seconds
	MinRecordTime=60.00
	// Obsolete
	MaxRecordTIme=0.00
}
