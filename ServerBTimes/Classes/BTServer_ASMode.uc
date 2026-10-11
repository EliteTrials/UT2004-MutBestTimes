//=============================================================================
// This mode serves the meaning of all Modes whom are built upon Assault.
// For example: Regular, Solo and Group are built upon Assault, and therefor shall extend this class.
//
// Where as TrialMode is any mode which wants Rankings and Records.
// For example: InvasionMode does not extend TrialMode but BunnyMode does extend TrialMode but not ASMode.
//
// This class serves no use on its own, it shall be inherited by any class whom want to take advantage of Assault features.
//
// Copyright 2005-2012 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_ASMode extends BTServer_TrialMode
    abstract;

function ModePostBeginPlay()
{
    local BTServer_ForceTeamRespawn B;
    local Triggers Tr;

    super.ModePostBeginPlay();

    // We only need one round. Every round is a game end, unless increased by BTimes itself.
    AssaultGame.RoundLimit = 1;

    // We need to watch out for the end of Practice Round.
    Spawn( class'BTPracticeRoundDetector', Outer );

    // We need to replace all the team respawn triggers, to ensure that our ghosts will be ignored.
    foreach AllActors( class'Triggers', Tr )
    {
        if( Trigger_ASForceTeamRespawn(Tr) != none )
        {
            if( Tr.bNoDelete || Tr.bStatic )
                continue;

            B = Spawn( Class'BTServer_ForceTeamRespawn' );
            B.Tag = Tr.Tag;
            Tr.Destroy();
            continue;
        }

        // We need a list of triggers.
        // If a user whom might be using Client Spawn, he shall be killed by any of those listed triggers.
        if( CanSetClientSpawn() && (bTriggersKillClientSpawnPlayers || bAlwaysKillClientSpawnPlayersNearTriggers) )
        {
            if( Tr.Event != '' && Tr.bCollideActors )
                Triggers[Triggers.Length] = Tr;
        }
    }
}

function ModeReset()
{
    super.ModeReset();
    if( AssaultGame.CurrentRound > 1 )
    {
        // Reset scores etc.
        AssaultGame.PracticeRoundEnded();
        ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundTimeLimit = 0;  // Adjust it again cause assault probably adjusted it.
        MatchStarting();

        if( IsCompetitiveModeActive() )
        {
            MRI.TeamTime[0] = 0.0f;
            MRI.TeamTime[1] = 0.0f;
        }
    }
}

function PreRestartRound()
{
    super.PreRestartRound();
    // Fool Assault from knowing the game has ended.
    AssaultGame.bGameEnded = false;
    AssaultGame.GotoState( 'MatchInProgress' );
}

function PostRestartRound()
{
    local int curObjIndex;

    super.PostRestartRound();
    AssaultGame.StartNewRound();

    if( !bLCAMap )
    {
        // Keep red team as the attackers!
        AssaultGame.CurrentAttackingTeam = 0;
        ASGameReplicationInfo(Level.Game.GameReplicationInfo).bTeamZeroIsAttacking = True;
        Level.Game.GameReplicationInfo.NetUpdateTime = Level.TimeSeconds - 1;
        for( curObjIndex = 0; curObjIndex < Objectives.Length; ++ curObjIndex )
        {
            if( Objectives[curObjIndex] != none )
            {
                Objectives[curObjIndex].DefenderTeamIndex = 1;
                Objectives[curObjIndex].NetUpdateTime = Level.TimeSeconds - 1;
            }
        }
    }

    // Even though, reset destroys the pawn already,
    // we still have to kill them here again because otherwise the teams won't be fixed in some cases
    KillAllPawns( true );
}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
    local BTChallenges.sChallenge chall;

    super.PlayerCompletedMap( player, playerSlot, playSeconds );
    if( InStr( Locs(Level.Author), "haydon" ) != -1 || InStr( Locs(Level.Author), "eliot" ) != -1 )
    {
        PDatManager.ProgressAchievementByType( playerSlot, 'FinishQuality', 1 );
    }

    // Complete any map 200 times
    PDatManager.ProgressAchievementByType( playerSlot, 'Finish', 1 );
    if( ChallengesManager.IsTodaysChallenge( CurrentMapName ) )
    {
        chall = ChallengesManager.DailyChallenge;
        chall.Title = Repl( chall.Title, "%MAPNAME%", CurrentMapName );
        chall.ID = Repl( chall.ID, "%MAPNAME%", CurrentMapName );
        PlayerEarnedTrophy( playerSlot, chall );
    }
}

function bool ChatCommandExecuted( PlayerController sender, string command, string value )
{
    local bool bmissed;

    switch( command )
    {
        case "red":
            sender.ServerChangeTeam( 0 );
            break;

        case "blue":
            sender.ServerChangeTeam( 1 );
            break;

        default:
            bmissed = true;
            break;
    }

    if( !bmissed )
        return true;

    return super.ChatCommandExecuted( sender, command, value );
}

defaultproperties
{
}