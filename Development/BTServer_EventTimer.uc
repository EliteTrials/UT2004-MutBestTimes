//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_EventTimer Extends Info;

#include DEC_Structs.uc

var BTimesMute M;

Event PostBeginPlay()
{
	Super.PostBeginPlay();
	M = BTimesMute(Owner);
	SetTimer( 0.2, True );
}

Event Timer()
{
	if( M == None )
	{
		Destroy();
		return;
	}

	// Spawn ghost at the same time from when the player joined the game.
	/*if( M.bPrepearGhost && Level.TimeSeconds>=(M.RoundBegTime+M.CurrentData.LoginTime) )
	{
		M.ActivateGhostPL();
		M.bPrepearGhost = False;
	}*/

	if( M.AssaultGame.IsPracticeRound() )
		M.bPracticeRound = True;

	// Wait till practice round ends.
	if( M.bPracticeRound )
	{
		if( M.AssaultGame.IsPracticeRound() )
			return;

		M.FullLog( "*** Practice Round Ended! ***" );
		M.bPracticeRound = False;
		M.MatchStarting();
		Destroy();
		return;
	}
}
