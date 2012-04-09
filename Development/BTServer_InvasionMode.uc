//=============================================================================
// Copyright 2005-2012 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_InvasionMode extends BTServer_TrialMode;

static function bool DetectMode( MutBestTimes M )
{
	return Invasion(M.Level.Game) != none;
}

protected function InitializeMode()
{
	super.InitializeMode();
}

defaultproperties
{
	ModeName="Inv"
	ModePrefix="DM"

	ExperienceBonus=5
}
