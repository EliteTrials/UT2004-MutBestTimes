//=============================================================================
// Copyright 2005 - 2016 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class BTGhostData extends Object;

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

/** What version this object was saved in. */
var int DataVersion;

/** Player's GUID. */
var string PLID;

/** The amount of time after the start of the game that this ghost began to record. */
var float RelativeStartTime;

var transient int CurrentMove;
var transient vector RelativeSpawnOffset;
var transient rotator RelativeSpawnDir;

final function vector GetStartLocation()
{
    if( MO.Length == 0 )
        return vect(0, 0, 0);

    return MO[0].P;
}

final function GetCurrentMove( out Vector p, out Rotator r )
{
    p = MO[CurrentMove].P + RelativeSpawnOffset;
    r = TinyRotToRot( MO[CurrentMove].R );
}

/**
 * Plays the next movement for Ghost.
 * Returns true if more moves are available.
 */
final function bool PerformNextMove( Pawn p )
{
    if( MO.Length == 0 )
        CurrentMove = 0;

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
        p.SetLocation( MO[CurrentMove].P + RelativeSpawnOffset );
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

final function Init()
{
    DataVersion = Version;
}

final function Free()
{
}