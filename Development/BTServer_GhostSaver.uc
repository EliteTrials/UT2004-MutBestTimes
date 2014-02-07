//=============================================================================
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GhostSaver extends Info
	dependson(BTServer_GhostData);

var PlayerController ImitatedPlayer;
var float RelativeStartTime;
var array<BTServer_GhostData.sMovesDataType> MovementsData;

final function StartGhostCapturing( float framesPerSecond )
{
	// Cleanup any previously captured moves.
	MovementsData.Length = 0;
	SetTimer( 1.0f/framesPerSecond, true );
	Timer();
}

final function StopGhostCapturing()
{
	SetTimer( 0.0, false );
}

protected final function CaptureGhostFrame()
{
	local int nextMove;

	nextMove = MovementsData.Length;
	MovementsData.Length = nextMove + 1;
	if( ImitatedPlayer.Pawn == none )
	{
		if( nextMove == 0 )
		{
			MovementsData[nextMove].P = ImitatedPlayer.Pawn.Location;
			MovementsData[nextMove].R = MiniRot( ImitatedPlayer.Rotation );	
		}
		// No health, invisible ghost!
		MovementsData[nextMove].H = 0;
		return;
	}

	MovementsData[nextMove].H = ImitatedPlayer.Pawn.Health;
	MovementsData[nextMove].P = ImitatedPlayer.Pawn.Location;
	MovementsData[nextMove].V = ImitatedPlayer.Pawn.Velocity;
	MovementsData[nextMove].A = ImitatedPlayer.Pawn.Acceleration;
	MovementsData[nextMove].R = MiniRot( ImitatedPlayer.Rotation );	
}

// Save the current movement of ImitatedPlayer every Timer event
event Timer()
{
	// Clean ourself if the player is no longer valid
	if( ImitatedPlayer == none )
	{
		Destroy();
		return;
	}
	CaptureGhostFrame();
}

// Converts a rotator struct to a small compressed rotator struct
// Converted back to a normal rotator struct when ghost is being loaded
static final function BTServer_GhostData.sTinyRot MiniRot( Rotator MR )
{
	local BTServer_GhostData.sTinyRot TR;

	MR.Yaw /= 1024;
	MR.Pitch /= 1024;

	while( MR.Yaw > 64 )
		MR.Yaw -= 64;

	while( MR.Yaw < 0 )
		MR.Yaw += 64;

	while( MR.Pitch > 64 )
		MR.Pitch -= 64;

	while( MR.Pitch < 0 )
		MR.Pitch += 64;

	TR.Y = MR.Yaw;
	TR.P = MR.Pitch;
	return TR;
}