//=============================================================================
// Copyright 2005 - 2016 Eliot Van Uytfanghe. All Rights Reserved.
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
event Reset();
function ClientReset();
function AskForPawn();

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

state GameEnded
{
    function BeginState();
}

state RoundEnded
{
    function BeginState();
}

state Spectating
{
    function BeginState();
    function EndState();
}

defaultproperties
{
    PlayerReplicationInfoClass=class'PlayerReplicationInfo'
    PawnClass=class'BTClient_Ghost'
    bGodMode=true
    bCanOpenDoors=false
    bIsPlayer=false
}