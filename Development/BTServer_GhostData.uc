//=============================================================================
// Copyright 2005-2014 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
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
var transient float
    TZERO,
    TONE;

// The ghost playing the data of this Data Object
var transient BTClient_Ghost Ghost;
var transient BTServer_GhostController Controller;

final function InterpolateMove()
{
    local Vector NextMove;

    if( Ghost == none || CurrentMove >= MO.Length-1 || CurrentMove == 0 )
        return;

    NextMove = MO[CurrentMove].P + (Ghost.Level.TimeSeconds - TZERO)/(TONE - TZERO) * (MO[CurrentMove+1].P - MO[CurrentMove].P);
    Ghost.SetLocation( NextMove );
}

/**
 * Plays the next movement for Ghost.
 * Returns true if more moves are available.
 */
final function bool LoadNextMoveData()
{
    if( CurrentMove >= MO.Length )
        return false;

    // Pawns don't use pitch!
    Controller.SetRotation( TinyRotToRot( MO[CurrentMove].R, false ) );
    Controller.FocalPoint = vector(TinyRotToRot( MO[CurrentMove].R, true ) )*15000 + Ghost.Location;

    if( Ghost != none )
    {
        Controller.FocalPoint += Ghost.Location;
        Ghost.Health = MO[CurrentMove].H;
        if( Ghost.Health <= 0 )
        {
            Ghost.bHidden = true;
        }
        else
        {
            Ghost.bHidden = false;
        }
        Ghost.SetRotation( TinyRotToRot( MO[CurrentMove].R, true ) );

        if( MO[CurrentMove].P != Ghost.Location )
            Ghost.SetLocation( MO[CurrentMove].P );

        Ghost.Velocity = MO[CurrentMove].V;
        Ghost.Acceleration = MO[CurrentMove].A;

    //  if( Ghost.Velocity.Z == 0.0f && Ghost.Physics != PHYS_Walking )
    //      Ghost.SetPhysics( PHYS_Walking );

        if( Ghost.PhysicsVolume.bWaterVolume && Ghost.Physics != PHYS_Swimming )
            Ghost.SetPhysics( PHYS_Swimming );
        else if( Ghost.Physics != PHYS_Walking && Ghost.Physics != PHYS_Falling )
            Ghost.SetPhysics( PHYS_Falling );
    }

    TZERO = Controller.Level.TimeSeconds;
    TONE = TZERO + 1.0f/UsedGhostFPS;
    return !(++ CurrentMove >= MO.Length);
}

// Get the real rotation from the TinyRot
private function Rotator TinyRotToRot( sTinyRot TR, optional bool bIgnorePitch )
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

// Spawns all the neccasery things for our ghost!
// Called by GhostLoader
final function BTClient_Ghost InitializeGhost( BTServer_GhostLoader other, int ghostIndex )
{
    // This data object has no moves, don't try spawn a ghost
    if( MO.Length == 0 )
        return none;

    // Incase the ghost already existed?
    if( Ghost != none )
    {
        // Reset then
        CurrentMove = 0;
        return Ghost;
    }

    TZERO = 0.0f;
    TONE = 0.0f;

    // Spawn the ghost!
    Ghost = other.Spawn( Class'BTClient_Ghost',,, MO[CurrentMove].P, TinyRotToRot( MO[CurrentMove].R ) );
    if( Ghost == none )
    {
        Log( "Failed to spawn the ghost", Name );
        return none;
    }

    // Ghost's can't touch people!
    Ghost.SetCollision( false, false, false );

    // Initialize the Controller!
    Ghost.Controller = other.Spawn( class'BTServer_GhostController',,, Ghost.Location, Ghost.Rotation );
    Ghost.Controller.PlayerReplicationInfo = other.Spawn( class'PlayerReplicationInfo', Ghost.Controller );
    Ghost.Controller.Pawn = Ghost;
    Ghost.Controller.bIsPlayer = false;     // Shame it was though!
    Ghost.Controller.bGodMode = true;       // What else?
    Controller = BTServer_GhostController(Ghost.Controller);

    // Initialize the PRI! or GRI!
    Ghost.PlayerReplicationInfo = Ghost.Controller.PlayerReplicationInfo;
    Ghost.PlayerReplicationInfo.PlayerName = other.Ghosts[ghostIndex].GhostName;
    Ghost.PlayerReplicationInfo.CharacterName = other.Ghosts[ghostIndex].GhostChar;
    Ghost.PlayerReplicationInfo.Team = other.Ghosts[ghostIndex].GhostTeam;
    Ghost.Controller.Possess( Ghost );


    // Intiialize the character
    Ghost.Setup( class'xUtil'.static.FindPlayerRecord( other.Ghosts[ghostIndex].GhostChar ) );
    Ghost.Level.Game.bWelcomePending = true;
    /*if( Ghost.Level.Game.BaseMutator != None )
    {
        // Note:    BTimes ignores ghost at modifyplayer, but modifyplayer is called so that mutators such as SantaHats can add a hat to the ghost
        Ghost.Level.Game.BaseMutator.ModifyPlayer( Ghost );
    }*/
    return Ghost;
}

// Called by BTimes
final function Presave( MutBestTimes BT, string playerGUID )
{
    Ghost = none;
    Controller = none;
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
    Ghost = none;
    Controller = none;
}