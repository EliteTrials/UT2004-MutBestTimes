//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_RegularMode extends BTServer_TrialMode;

static function bool DetectMode( MutBestTimes M )
{
	// Not solo then were obviously a team mode
	return !Class'BTServer_SoloMode'.static.DetectMode( M );
}

defaultproperties
{
	ModeName="Regular"
	ModePrefix="RTR"

	ExperienceBonus=25
}
