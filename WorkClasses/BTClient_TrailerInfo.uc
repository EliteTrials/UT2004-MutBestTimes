//==============================================================================
// BTClient_TrailerInfo.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
			Dynamic attach trailers to the best players
*/
//	Coded by Eliot
//	Updated @ 26/12/2009
//==============================================================================
Class BTClient_TrailerInfo Extends Info
	NotPlaceable;

var Pawn Pawn, OldPawn;
struct sRankData
{
	var string TrailerTexture;
	var color TrailerColor[2];
};
var sRankData RankSkin;
var Class<BTClient_RankTrailer> TrailerClass;

var const name Bones[2];

Replication
{
	reliable if( bool( int( bool( int( bool( int( bool( int( bStatic ) ) ) ) ) ) ) ) )
		OldPawn;

	reliable if( bNetDirty && (Role == ROLE_Authority) )
		Pawn;

	reliable if( (Role == ROLE_Authority) && bNetInitial )
		RankSkin, TrailerClass;
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	if( Class'BTClient_Config'.static.FindSavedData().bNoTrailers || Class'BTClient_Config'.static.FindSavedData().bProfesionalMode )
	{
		Destroy();
	}
}

Simulated Function PostNetReceive()
{
	local int i;

	Super.PostNetReceive();
	if( Pawn != None && Pawn != OldPawn )
	{
		// Incase this is an update. We shall kill the old trailers to avoid stacking.
		if( Pawn != none )
		{
			for( i = 0; i < Pawn.Attached.Length; ++ i )
			{
				if( Pawn.Attached[i] == none || Pawn.Attached[i].Class != TrailerClass )
					continue;

               	Pawn.Attached[i].Destroy();
				Pawn.Attached.Remove( i, 1 );
				-- i;
           	}
		}

		AddRewards( Pawn );
		OldPawn = Pawn;
	}
}

Simulated Function AddRewards( Pawn Other )
{
	//local BTClient_Glow Glow;
	local xEmitter E;
	local Material M;
	local int i;

	if( Other == None )
		return;

	if( TrailerClass == None )
		TrailerClass = Default.TrailerClass;

	M = Material( DynamicLoadObject( RankSkin.TrailerTexture, Class'Material', True ) );
	for( i = 0; i < 2; i ++ )
	{
		E = Spawn( TrailerClass, Other );
		if( E != None )
		{
			if( M != None )
				E.Skins[0] = M;

			E.mColorRange[0] = RankSkin.TrailerColor[0];
			E.mColorRange[1] = RankSkin.TrailerColor[1];
			Other.AttachToBone( E, Bones[i] );
		}
	}

	/*Glow = Spawn( Class'BTClient_Glow', Other,, (Other.Location - vect( 0, 0, 49 )), (Other.Rotation + rot( 0, -16384, 0 )) );
	if( Glow != None )
	{
		Glow.Emitters[0].SkeletalMeshActor = Other;
		Glow.SetBase( Other );

		//Other.SetOverlayMaterial( FinalBlend'MutantSkins.Shaders.MutantGlowFinal', 600, True );
	}*/
}

Event Tick( float DeltaTime )
{
	if( Role == ROLE_Authority )
	{
		if( PlayerController(Owner) == None )
		{
			Destroy();
			return;
		}
	}
}

DefaultProperties
{
	Bones(0)=LFoot
	Bones(1)=RFoot

	TrailerClass=Class'BTClient_RankTrailer'
	RemoteRole=Role_SimulatedProxy
	bAlwaysRelevant=True
	bAlwaysTick=True
	bNetNotify=True
}
