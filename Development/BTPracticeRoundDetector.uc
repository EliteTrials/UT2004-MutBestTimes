//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTPracticeRoundDetector extends Info;

var protected BTimesMute BT;

event PostBeginPlay()
{
	super.PostBeginPlay();
	BT = BTimesMute(Owner);
	SetTimer( 0.2, true );
}

event Timer()
{
	if( BT == none )
	{
		Destroy();
		return;
	}

	if( BT.AssaultGame.IsPracticeRound() )
		BT.bPracticeRound = true;

	// Wait till practice round ends.
	if( BT.bPracticeRound )
	{
		if( BT.AssaultGame.IsPracticeRound() )
			return;

		BT.FullLog( "*** Practice Round Ended! ***" );
		BT.bPracticeRound = false;
		BT.MatchStarting();
		Destroy();
		return;
	}
}
