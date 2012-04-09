//=============================================================================
// Copyright 2005-2012 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_BunnyMode extends BTServer_TrialMode;

static function bool DetectMode( MutBestTimes M )
{
	return CTFGame(M.Level.Game) != none;
}

protected function InitializeMode()
{
	super.InitializeMode();
	bSoloMap = true;
	MRI.bSoloMap = true;
}

defaultproperties
{
	ModeName="BT"
	ModePrefix="CTF"

	ExperienceBonus=5
}
