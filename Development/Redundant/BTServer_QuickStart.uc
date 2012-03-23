//==============================================================================
// BTServer_QuickStart.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
// Coded by 'Eliot van uytfanghe'
// This file belongs to ServerBTimes
//==============================================================================
class BTServer_QuickStart extends Object within MutBestTimes
	transient;

struct sAutoUsesRec
{
	struct __0XFFFEFF__0XFFFFFF__0XFEFFFF__0XFEFFFF__0XFBFEFFC___0XFFFFBF__
	{
	};

	struct __0XFFDFFB__0XFEEEBF__0XCCEEFF__0XFFCCEE__0XFFFFFFC___0XFFEFFF__
	{
	};

	struct __0XFFECEF__0XB0FFFF__0XEEFFEF__0XFBF0FF__0XFBECCFC___0XEFCFFF__
	{
	};

	struct __0XF0ECEC__0XFFE0FF__0XFCCFEF__0XFBFFFD__0XFDEB0EC___0XFFCEFF__
	{
	};

	struct __0XEFEFCF__0XFF0CFF__0XFFEFEF__0XFEECFF__0XFDF00FC___0XFFCFCF__
	{
	};
};

/*Replication
{
	reliable if( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) )
		X;
}

var int X;

event Timer()
{
	//BTimesMute(Owner).FullLog( "*** QuickStart:Timer"@X$" ***" );

	if( X > 0 && X <= 5 )
   		Level.Game.BroadcastLocalizedMessage( Class'BTClient_QuickStartSound', X );

	if( X == 0 )
	{
		AssaultGame.bGameEnded = false;
		AssaultGame.GotoState( 'MatchInProgress' );
		MRI.EndMsg = "* QuickStart - Next round initializing... *";
		MRI.NetUpdateTime = Level.TimeSeconds - 1;
		self.SetTimer( 0.5, false );
	}
	else if( X == -1 )
	{
		BTServer_VotingHandler(Level.Game.VotingHandler).DisableMidGameVote();
		bQuickStart = false;
		AssaultGame.StartNewRound();
		QuickStartReady();
		self.SetTimer( 0, false );
		self.Destroy();
		return;
	}

	if( X != 0 )
	{
		MRI.EndMsg = "* QuickStart - Next round in "$X$"... *";
		MRI.NetUpdateTime = Level.TimeSeconds - 1;
	}
	-- X;
}*/

/*Function ResetObjectives()
{
	local GameObjective Obj;

	for( Obj = BTimesMute(Owner).AssaultGame.Teams[0].AI.Objectives; Obj != None; Obj = Obj.NextObjective )
	{
		Obj.Reset();
		Obj.NetUpdateTime = Level.TimeSeconds - 1;
	}
}

Function Ready()
{
	local Controller C;
	local PlayerController PC;

	for( C = Level.ControllerList; C != None; C = C.NextController )
	{
		PC = PlayerController(C);
		if( PC != None && PC.IsDead() )
		{
			BTimesMute(Owner).AssaultGame.RestartPlayer( PC );
			ASPlayerReplicationInfo(PC.PlayerReplicationInfo).bAutoRespawn = False;
			continue;
		}

		if( C.Pawn != None && C.Pawn.IsA('RedeemerWarhead') )
			C.Pawn.Fire( 1 );
	}

	BTimesMute(Owner).AssaultGame.StartNewRound();
}*/
