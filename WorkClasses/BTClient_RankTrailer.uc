//==============================================================================
// BTClient_RankTrailer.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
			The trailer for the best players
*/
//	Coded by Eliot
//	Updated @ XX/XX/2009
//==============================================================================
class BTClient_RankTrailer extends SpeedTrail;

var bool bSet;

simulated event PostBeginPlay()
{
	if( xPawn(Owner).DrawScale != 1.0 )
	{
		mSizeRange[0] *= xPawn(Owner).DrawScale;
		mSizeRange[1] *= xPawn(Owner).DrawScale;
	}
}

simulated event Tick( float dt )
{
	if( xPawn(Owner) == None || xPawn(Owner).bDeRes || xPawn(Owner).bDeleteMe )
	{
		Destroy();
		return;
	}

	if( Abs(xPawn(Owner).Velocity.Z) >= 100 )
	{
		if( !bSet )
		{
			bSet = True;
			mGrowthRate = -20.f;
			mRegenRange[0] = 25.f;
   			mRegenRange[1] = 25.f;
   			//mSpeedRange[0] = VSize( xPawn(Owner).Velocity*0.5 );
			//mSpeedRange[1] = mSpeedRange[0];
		}
   	}
   	else
   	{
   		if( bSet )
   		{
   			bSet = False;
   			mGrowthRate = 12.f;
   			mRegenRange[0] = 10.f;
   			mRegenRange[1] = 10.f;
   			//mSpeedRange[0] = -20.f;
			//mSpeedRange[1] = -20.f;
		}
   	}

	if( !mRegen )
		mRegen = True;
}

DefaultProperties
{
	Physics=PHYS_Trailer

	mColorRange(0)=(R=255,G=0,B=150)
	mColorRange(1)=(R=255,G=150,B=0)
	mRegenRange(0)=5.0
	mRegenRange(1)=5.0
	mMassRange(0)=-0.3
	mMassRange(1)=-0.3
	mGrowthRate=-12.0
	LifeSpan=0

	bSuspendWhenNotVisible=False
	bOwnerNoSee=False

	bReplicateMovement=False

	//AmbientSound=Sound'IndoorAmbience.electricity2'
	//SoundRadius=32
	//SoundVolume=190
	//SoundPitch=64
}
