//=============================================================================
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGhostRecorder extends Info
    dependson(BTGhostData);

var string GhostId;
var private Controller Player;
var float RelativeStartTime;
var array<BTGhostData.sMovesDataType> Frames;
var float FramesPerSecond;

event PreBeginPlay()
{
    Player = Controller(Owner);
}

final function StartGhostCapturing( float fps )
{
    // Cleanup any previously captured moves.
    Frames.Length = 0;
    FramesPerSecond = fps;
    SetTimer( 1.0f/FramesPerSecond, true );
    Timer();
}

final function StopGhostCapturing()
{
    SetTimer( 0.0, false );
}

protected final function CaptureGhostFrame()
{
    local int nextFrame;
    local Pawn p;

    p = Player.Pawn;
    nextFrame = Frames.Length;
    Frames.Length = nextFrame + 1;
    if( p == none )
    {
        if( nextFrame == 0 )
        {
            Frames[nextFrame].P = p.Location;
            Frames[nextFrame].R = MiniRot( Player.Rotation );
        }
        // No health, invisible ghost!
        Frames[nextFrame].H = 0;
        return;
    }

    Frames[nextFrame].H = p.Health;
    Frames[nextFrame].P = p.Location;
    Frames[nextFrame].V = p.Velocity;
    Frames[nextFrame].A = p.Acceleration;
    Frames[nextFrame].R = MiniRot( Player.Rotation );
}

// Save the current movement of ImitatedPlayer every Timer event
event Timer()
{
    // Clean ourself if the player is no longer valid
    if( Player == none )
    {
        Destroy();
        return;
    }
    CaptureGhostFrame();
}

// Converts a rotator struct to a small compressed rotator struct
// Converted back to a normal rotator struct when ghost is being loaded
static final function BTGhostData.sTinyRot MiniRot( Rotator MR )
{
    local BTGhostData.sTinyRot TR;

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