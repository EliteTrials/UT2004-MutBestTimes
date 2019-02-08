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

var transient vector RelativeSpawnOffset;
var transient rotator RelativeSpawnDir;
var transient bool bIsDirty;

final function vector GetStartLocation()
{
    if( MO.Length == 0 )
        return vect(0, 0, 0);

    return MO[0].P;
}

final function GetFrame( int frameIndex, out Vector p, out Rotator r )
{
    p = MO[frameIndex].P + RelativeSpawnOffset;
    r = TinyRotToRot( MO[frameIndex].R );
}

/**
 * Plays the next movement for Ghost.
 * Returns true if more moves are available.
 */
final function bool PerformNextMove( out int nextMove, Pawn p )
{
    if( MO.Length == 0 )
        nextMove = 0;

    if( nextMove >= MO.Length )
        return false;

    if( p != none )
    {
        if( p.Health != MO[nextMove].H )
        {
            p.Health = MO[nextMove].H;
            p.bHidden = p.Health <= 0;
        }

        // Pawns don't use pitch!
        p.SetLocation( MO[nextMove].P + RelativeSpawnOffset );
        p.SetRotation( TinyRotToRot( MO[nextMove].R, true ) );
        p.SetViewRotation( TinyRotToRot( MO[nextMove].R ) );
        p.Velocity = MO[nextMove].V;
        p.Acceleration = MO[nextMove].A;
        p.NetUpdateTime = p.Level.TimeSeconds - 1;
    }
    return !(++ nextMove >= MO.Length);
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