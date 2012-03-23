//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_GhostSaver Extends Actor
	DependsOn(BTServer_GhostData)
	Transient;

// The player we will save movements from
var PlayerController ImitatedPlayer;
var float RelativeStartTime;

// Saved movements
// Will be moved to GhostData when saving
var() array<BTServer_GhostData.sMovesDataType> MovementsData;

// Sets a single movement to begin with
Final Function SetInitialMoveData()
{
	local int NextMove;

	if( ImitatedPlayer == None )
	{
		Destroy();
		return;
	}

	NextMove = MovementsData.Length;
	MovementsData.Length = NextMove + 1;
	if( ImitatedPlayer.Pawn == None )
	{
		// No health, invisible ghost!
		MovementsData[NextMove].H = 0;
		MovementsData[NextMove].P = ImitatedPlayer.Location;
		MovementsData[NextMove].R = MiniRot( ImitatedPlayer.Rotation );
		return;
	}
	MovementsData[NextMove].H = ImitatedPlayer.Pawn.Health;
	MovementsData[NextMove].P = ImitatedPlayer.Pawn.Location;
	MovementsData[NextMove].V = ImitatedPlayer.Pawn.Velocity;
	MovementsData[NextMove].A = ImitatedPlayer.Pawn.Acceleration;
	MovementsData[NextMove].R = MiniRot( ImitatedPlayer.Rotation );
}

// Save the current movement of ImitatedPlayer every Timer event
Event Timer()
{
	local int NextMove;

	// Clean ourself if the player is no longer valid
	if( ImitatedPlayer == None )
	{
		Destroy();
		return;
	}

	NextMove = MovementsData.Length;
	MovementsData.Length = NextMove + 1;
	if( ImitatedPlayer.Pawn == None )
	{
		// No health, invisible ghost!
		MovementsData[NextMove].H = 0;
		return;
	}

	MovementsData[NextMove].H = ImitatedPlayer.Pawn.Health;
	MovementsData[NextMove].P = ImitatedPlayer.Pawn.Location;
	MovementsData[NextMove].V = ImitatedPlayer.Pawn.Velocity;
	MovementsData[NextMove].A = ImitatedPlayer.Pawn.Acceleration;
	MovementsData[NextMove].R = MiniRot( ImitatedPlayer.Rotation );
}

// Converts a rotator struct to a small compressed rotator struct
// Converted back to a normal rotator struct when ghost is being loaded
Static Final Function BTServer_GhostData.sTinyRot MiniRot( Rotator MR )
{
	local BTServer_GhostData.sTinyRot TR;

	MR.Yaw /= 1024;
	MR.Pitch /= 1024;

	While( MR.Yaw > 64 )
		MR.Yaw -= 64;

	While( MR.Yaw < 0 )
		MR.Yaw += 64;

	While( MR.Pitch > 64 )
		MR.Pitch -= 64;

	While( MR.Pitch < 0 )
		MR.Pitch += 64;

	TR.Y = MR.Yaw;
	TR.P = MR.Pitch;
	return TR;
}

DefaultProperties
{
}
