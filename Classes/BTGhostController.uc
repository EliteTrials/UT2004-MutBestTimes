//=============================================================================
// Copyright 2005 - 2016 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGhostController extends PlayerController;

var private Pawn GhostPawn;

event PostBeginPlay()
{
    if( !bDeleteMe )
    {
        PlayerReplicationInfo = Spawn( PlayerReplicationInfoClass, self,, vect(0,0,0), rot(0,0,0) );
        InitPlayerReplicationInfo();
    }
}

function InitPlayerReplicationInfo()
{
    PlayerReplicationInfo.bNoTeam = !Level.Game.bTeamGame;
    PlayerReplicationInfo.bIsSpectator = true; // hides the bot from the scoreboard(or as spectator board), but can still be spectated.
    PlayerReplicationInfo.bOnlySpectator = false; // So we can still spectate the ghost.
    PlayerReplicationInfo.bBot = true;
    PlayerReplicationInfo.bWelcomed = true; // We don't have to notify players that this ghost entered the game.
    PlayerReplicationInfo.bReadyToPlay = true;
}

function Pawn CreateGhostPawn( BTGhostData data, optional int frameIndex )
{
    local Vector initialLocation;
    local Rotator initialRotation;

    // Log( "Creating pawn for ghost" @ self );
    if( Pawn != none )
    {
        Warn( "Tried to create a new pawn for ghost, but this Controller already posseses a pawn!" );
        return Pawn;
    }
    data.GetFrame( frameIndex, initialLocation, initialRotation );
    Pawn = Spawn( default.PawnClass,,, initialLocation, initialRotation );
    if( Pawn == none )
    {
        Warn( "Couldn't spawn ghost at this location." );
        return none;
    }

    // So we know whether the ghost's pawn was created with CreateGhostPawn or an external source.
    GhostPawn = Pawn;
    Possess( Pawn );
    return Pawn;
}

function Possess( Pawn p )
{
    // Ensure that any remotely created pawn gets the axe. e.g. GameInfo.RestartPlayer
    if( GhostPawn != none && GhostPawn != p && p == Pawn )
    {
        p.Destroy();
        Pawn = GhostPawn;
        return;
    }

    // FIXME: Should be handled inside the Pawn class.
    xPawn(p).Setup( class'xUtil'.static.FindPlayerRecord( PlayerReplicationInfo.CharacterName ) );

    if( p != none )
        p.SetCollision( false, false, false );

    super.Possess( p );
}

event InitInputSystem();
event Reset();
function ClientReset();
function AskForPawn();
function GivePawn(Pawn NewPawn);
function GameHasEnded();
function ClientGameEnded();
function RoundHasEnded();
function ClientRoundEnded();

// End game may force our ghost to spectate or view a player.
function BecomeSpectator();
function ServerViewNextPlayer();
function BecomeActivePlayer();

function ServerReStartPlayer();
function ServerGivePawn();
function bool CanRestartPlayer()
{
    return false;
}

function PawnDied(Pawn P)
{
    // Log("PawnDied!!!!!!!!!!!!!!" @ p);
    // FIXME: Something is replacing our PRI.
    InitPlayerReplicationInfo();
}

event Destroyed()
{
    if( Pawn != none )
    {
        Pawn.Destroy();
    }
    super(Controller).Destroyed();
}

// Don't restart ghosts. Causes the creation of a phantom pawn.
auto state PlayerWaiting
{
    function BeginState();
    function EndState();
    function ServerRestartPlayer();
}

state Dead
{
    function BeginState();
    function ServerReStartPlayer();
}

// Don't TurnOff our pawn!
state GameEnded
{
    function BeginState()
    {
        GotoState('PlayerWalking');
    }

    function Possess( Pawn aPawn )
    {
        global.Possess(aPawn);
    }
}

// Don't TurnOff our pawn!
state RoundEnded
{
    function BeginState()
    {
        GotoState('PlayerWalking');
    }

    function Possess( Pawn aPawn )
    {
        global.Possess(aPawn);
    }
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
    bCollideWorld=false
}