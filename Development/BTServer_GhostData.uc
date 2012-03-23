//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_GhostData Extends Object;

#include DEC_Structs.uc

struct sTinyRot
{
	var byte
		Y,																		// Yaw
		P;                                                                      // Pitch
};

struct sMovesDataType
{
	var vector
		P,  																	// Position
		V,																		// Velocity
		A;																		// Acceleration

	var sTinyRot R; 															// ViewRotation
	var int H; 																	// Health
};

// SAVED \\

var array<sMovesDataType> MO;

var bool bHasStoredData;

var int UsedGhostFPS;

var string
	PackageName,
	PLID;

// The amount of time after the start of the game that this ghost began to record.
var float RelativeStartTime;

//

// NOT-SAVED \\

var transient int CurrentMove;

var transient float
	TZERO,
	TONE;

// The ghost playing the data of this Data Object
var transient BTClient_Ghost Ghost;

// -- Eliot

// Smooth the ghost movements
Final Function InterpolateMove()
{
	local vector NextMove;

 	if( Ghost == None || CurrentMove >= MO.Length-1 || CurrentMove == 0 )
 		return;

 	NextMove = MO[CurrentMove].P + (Ghost.Level.TimeSeconds - TZERO)/(TONE - TZERO) * (MO[CurrentMove+1].P - MO[CurrentMove].P);
	Ghost.SetLocation( NextMove );
}

// Loads the ghost movement
// Called by GhostLoader
Final Function bool LoadNextMoveData()
{
	if( CurrentMove >= MO.Length )
		return False;

	if( Ghost == None || Ghost.Controller == None )
		return True;

	Ghost.Health = MO[CurrentMove].H;
	if( Ghost.Health <= 0 )
	{
		Ghost.bHidden = True;
		return True;
	}
	else Ghost.bHidden = False;

	// Pawns don't use pitch!
	Ghost.SetRotation( GetRotation( MO[CurrentMove].R, True ) );
	Ghost.Controller.SetRotation( GetRotation( MO[CurrentMove].R, False ) );

	if( Ghost.Controller != None )
		Ghost.Controller.FocalPoint = vector(GetRotation( MO[CurrentMove].R, True ) )*15000+Ghost.Location;

	if( MO[CurrentMove].P != Ghost.Location )
		Ghost.SetLocation( MO[CurrentMove].P );

	TZERO = Ghost.Level.TimeSeconds;
	TONE = TZERO + (1.0f/UsedGhostFPS);

	Ghost.Velocity = MO[CurrentMove].V;
	Ghost.Acceleration = MO[CurrentMove].A;

//	if( Ghost.Velocity.Z == 0.0f && Ghost.Physics != PHYS_Walking )
//		Ghost.SetPhysics( PHYS_Walking );

	if( Ghost.PhysicsVolume.bWaterVolume && Ghost.Physics != PHYS_Swimming )
		Ghost.SetPhysics( PHYS_Swimming );
	else if( Ghost.Physics != PHYS_Walking && Ghost.Physics != PHYS_Falling )
		Ghost.SetPhysics( PHYS_Falling );

	return !(++ CurrentMove >= MO.Length);
}

// Get the real rotation from the TinyRot
Final Function rotator GetRotation( sTinyRot TR, optional bool bIgnorePitch )
{
	local rotator Rot;

	// Left, Right
	Rot.Yaw = TR.Y*1024;
	// Up, Down
	if( bIgnorePitch )
		return Rot;

	Rot.Pitch = TR.P*1024;
	return Rot;
}

// Spawns all the neccasery things for our ghost!
// Called by GhostLoader
Final Function BTClient_Ghost InitializeGhost( BTServer_GhostLoader Other, int GhostNum )
{
	// This data object has no moves, don't try spawn a ghost
	if( MO.Length == 0 )
		return None;

	// Incase the ghost already existed?
	if( Ghost != None )
	{
		// Reset then
		CurrentMove = 0;
		return Ghost;
	}

	TZERO = 0.0f;
	TONE = 0.0f;

	// Spawn the ghost!
	Ghost = Other.Spawn( Class'BTClient_Ghost',,, MO[CurrentMove].P, GetRotation( MO[CurrentMove].R ) );
	if( Ghost == None )
	{
		Log( "Failed to spawn the ghost", Name );
		return None;
	}

	// Ghost's can't touch people!
	Ghost.SetCollision( False, False, False );

	// Initialize the Controller!
	Ghost.Controller = Other.Spawn( Class'BTServer_GhostController',,, Ghost.Location, Ghost.Rotation );
	Ghost.Controller.Pawn = Ghost;
	Ghost.Controller.bIsPlayer = False;		// Shame it was though!
	Ghost.Controller.bGodMode = True;		// What else?

	// Initialize the PRI! or GRI!
	Ghost.PlayerReplicationInfo = Other.Spawn( Class'PlayerReplicationInfo', Ghost.Controller );
	Ghost.PlayerReplicationInfo.SetTimer( 0, False );	// Turn that off...
	Ghost.Controller.PlayerReplicationInfo = Ghost.PlayerReplicationInfo;

	// Initialize info for the clients!
	Ghost.PlayerReplicationInfo.PlayerName = Other.Ghosts[GhostNum].GhostName;
	Ghost.PlayerReplicationInfo.CharacterName = Other.Ghosts[GhostNum].GhostChar;
	Ghost.PlayerReplicationInfo.Team = Other.Ghosts[GhostNum].GhostTeam;

	// Intiialize the character
	Ghost.Setup( Class'xUtil'.Static.FindPlayerRecord( Other.Ghosts[GhostNum].GhostChar ) );
	Ghost.Level.Game.bWelcomePending = True;
	/*if( Ghost.Level.Game.BaseMutator != None )
	{
		// Note:	BTimes ignores ghost at modifyplayer, but modifyplayer is called so that mutators such as SantaHats can add a hat to the ghost
		Ghost.Level.Game.BaseMutator.ModifyPlayer( Ghost );
	}*/
	Other.Ghosts[GhostNum].GhostPawn = Ghost;
	return Ghost;
}

// Called by BTimes
Final Function SavePlayerMoves( string ID )
{
	Ghost = None;
	PLID = ID;
	bHasStoredData = True;

	UsedGhostFPS = Class'BTimesMute'.Default.GhostPlaybackFPS;
	Log( "GhostFPS:"$UsedGhostFPS, Name );
}

// Called by BTimes
Final Function ClearGhostData()
{
	MO.Length = 0;
	PLID = "";
	bHasStoredData = False;
	UsedGhostFPS = 0;
	RelativeStartTime = 0f;
}

DefaultProperties
{
}
