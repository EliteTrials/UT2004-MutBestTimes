//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_GhostController Extends AIController;//MessagingSpectator;

event PostBeginPlay();
function InitPlayerReplicationInfo();

function GameHasEnded();
function ClientGameEnded();
function RoundHasEnded();
function ClientRoundEnded();
function ClientReset();

function Reset()
{
    Super.Reset();

    if( Pawn != None )
    {
        Pawn.SetCollision( False, False, False );
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