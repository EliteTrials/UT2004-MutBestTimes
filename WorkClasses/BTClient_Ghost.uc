//==============================================================================
// BTClient_Ghost.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
// An unique pawn for the in-game ghost controller
/* Tasks:
			Make the skin pulse between white and blue just like an assault objective
			Overwrite name drawing code
*/
//	Coded by Eliot
//	Updated @ 08/12/2009
/*
	Latest Changes:
			Support Shader skins
			Clear certain functions
			ignore TurnOff() because we changed ghostcontroller from playercontroller back to AIController
*/
//==============================================================================
Class BTClient_Ghost Extends xPawn
	Config(ClientBTimes);

var Shader S, HeadS;
var FadeColor FC;

var() globalconfig color FadeColor1, FadeColor2;

Simulated Function TickFX( float DeltaTime )
{
	if( Skins[0] == S && Skins[1] == HeadS )
		return;

	RemoveSkins();

	FC = FadeColor(Level.ObjectPool.AllocateObject( Class'FadeColor' ));
	FC.Color1 = FadeColor1;
	FC.Color2 = FadeColor2;
	FC.FadePeriod = 0.33f;
	FC.FadePhase = 0.0f;

	S = Shader(Level.ObjectPool.AllocateObject( Class'Shader' ));
	S.Specular = FC;
	S.OutputBlending = OB_Translucent;

	if( Skins[0].IsA('Shader') )
	{
		S.Diffuse = Shader(Skins[0]).Diffuse;
	}
	else S.Diffuse = Skins[0];

	Skins[0] = S;

	HeadS = Shader(Level.ObjectPool.AllocateObject( Class'Shader' ));
	HeadS.Specular = FC;
	HeadS.OutputBlending = OB_Translucent;

	if( Skins[1].IsA('Shader') )
	{
		HeadS.Diffuse = Shader(Skins[1]).Diffuse;
	}
	else HeadS.Diffuse = Skins[1];

	Skins[1] = HeadS;
}

Simulated Function RemoveSkins()
{
	if( S != None )
	{
		S.OutputBlending = S.Default.OutputBlending;
		S.Specular = S.Default.Specular;
		S.Diffuse = S.Default.Diffuse;
		Level.ObjectPool.FreeObject( S );
		S = None;
	}

	if( HeadS != None )
	{
		HeadS.OutputBlending = HeadS.Default.OutputBlending;
		HeadS.Specular = HeadS.Default.Specular;
		HeadS.Diffuse = HeadS.Default.Diffuse;
		Level.ObjectPool.FreeObject( HeadS );
		HeadS = None;
	}

	if( FC != None )
	{
		FC.Color1 = FC.Default.Color1;
		FC.Color2 = FC.Default.Color2;
		FC.FadePeriod = FC.Default.FadePeriod;
		FC.FadePhase = FC.Default.FadePhase;
		Level.ObjectPool.FreeObject( FC );
		FC = None;
	}
}

Simulated Function Destroyed()
{
	Super.Destroyed();

	if( Level.NetMode != NM_DedicatedServer )
		RemoveSkins();
}

simulated function PostRender2D( Canvas C, float ScreenLocX, float ScreenLocY );

function AddVelocity( vector NewVelocity);
function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType);
function Suicide();

function bool IsInPain()
{
	return false;
}

function bool TouchingWaterVolume()
{
	return false;
}

function GiveWeapon(string aClassName );
function CreateInventory(string InventoryClassName);

simulated function FootStepping(int Side);
event Landed(vector v);

simulated function TurnOff();
function Reset()
{
	bTearOff = False;
}

DefaultProperties
{
	FadeColor1=(R=0,G=0,B=255,A=255)
	FadeColor2=(R=0,G=0,B=0,A=255)
	bScriptPostRender=True

	FootstepVolume=0.0
	GruntVolume=0.0
	TransientSoundVolume=0.0
	RagImpactVolume=0.0
	
	bAlwaysRelevant=True
}
