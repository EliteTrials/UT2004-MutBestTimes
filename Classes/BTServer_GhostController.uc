//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GhostController extends PlayerController;

var BTServer_GhostData Data;

event PostBeginPlay();
function InitPlayerReplicationInfo();

// We should not interfere with the Controller's pitch!
// function AdjustView( float deltaTime )
// {
//     super(Controller).AdjustView( deltaTime );
// }

// function ClientSetRotation( rotator NewRotation )
// {
//     SetRotation(NewRotation);
//     if ( Pawn != None )
//     {
//         NewRotation.Roll  = 0;
//         Pawn.SetRotation( NewRotation );
//     }
// }

function GameHasEnded();
function ClientGameEnded();
function RoundHasEnded();
function ClientRoundEnded();
function ClientReset();
// function AskForPawn();

function PawnDied(Pawn P)
{
    if ( Pawn != P )
        return;

    if ( Pawn != None )
    {
        SetLocation(Pawn.Location);
        Pawn.UnPossessed();
    }
    Pawn = None;
    PendingMover = None;
}

function Reset()
{
    super.Reset();
    if( Pawn != none )
    {
        Pawn.SetCollision( false, false, false );
    }
}

state GameEnded
{
ignores SeePlayer, HearNoise, KilledBy, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange, TakeDamage, ReceiveWarning;

    function BeginState()
    {
    }
}

state RoundEnded
{
ignores SeePlayer, HearNoise, KilledBy, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange, TakeDamage, ReceiveWarning;

    function BeginState()
    {
    }
}

defaultproperties
{
    PlayerReplicationInfoClass=class'PlayerReplicationInfo'
    PawnClass=class'BTClient_Ghost'
    bGodMode=true
    bCanOpenDoors=false
}