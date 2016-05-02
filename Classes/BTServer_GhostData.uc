//=============================================================================
// Copyright 2005 - 2016 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class BTServer_GhostData extends Object;

const Version = 4;

struct sTinyRot
{
    var byte
        Y,                                                                      // Yaw
        P;                                                                      // Pitch
};

struct sMovesDataType
{
    var Vector
        P,                                                                      // Position
        V,                                                                      // Velocity
        A;                                                                      // Acceleration

    var sTinyRot R;                                                             // ViewRotation
    var int H;                                                                  // Health
};

var array<sMovesDataType> MO;
var int UsedGhostFPS;

/** The file name this object resides in. */
var string PackageName;

/** What version this object was saved in. */
var int DataVersion;

/** Player's GUID. */
var string PLID;

/** The amount of time after the start of the game that this ghost began to record. */
var float RelativeStartTime;

var transient int CurrentMove;

final function GetCurrentMove( out Vector p, out Rotator r )
{
    p = MO[CurrentMove].P;
    r = TinyRotToRot( MO[CurrentMove].R );
}

/**
 * Plays the next movement for Ghost.
 * Returns true if more moves are available.
 */
final function bool PerformNextMove( Pawn p )
{
    if( CurrentMove >= MO.Length )
        return false;

    if( p != none )
    {
        if( p.Health != MO[CurrentMove].H )
        {
            p.Health = MO[CurrentMove].H;
            p.bHidden = p.Health <= 0;
        }

        // Pawns don't use pitch!
        p.SetLocation( MO[CurrentMove].P );
        p.SetRotation( TinyRotToRot( MO[CurrentMove].R, true ) );
        p.SetViewRotation( TinyRotToRot( MO[CurrentMove].R ) );
        p.Velocity = MO[CurrentMove].V;
        p.Acceleration = MO[CurrentMove].A;
        p.NetUpdateTime = p.Level.TimeSeconds - 1;
    }
    return !(++ CurrentMove >= MO.Length);
}

// Get the real rotation from the TinyRot
final function Rotator TinyRotToRot( sTinyRot TR, optional bool bIgnorePitch )
{
    local Rotator Rot;

    // Left, Right
    Rot.Yaw = TR.Y*1024;
    // Up, Down
    if( bIgnorePitch )
        return Rot;

    Rot.Pitch = TR.P*1024;
    return Rot;
}

// Called by BTimes
final function Presave( MutBestTimes BT, string playerGUID )
{
    PLID = playerGUID;

    UsedGhostFPS = BT.GhostPlaybackFPS;
    DataVersion = Version;
}

// Called by BTimes
final function ClearGhostData()
{
    MO.Length = 0;
    PLID = "";
    UsedGhostFPS = 0;
    RelativeStartTime = 0f;
}

final function Free()
{
}