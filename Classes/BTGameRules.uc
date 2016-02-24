//=============================================================================
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGameRules extends GameRules;

var array<Controller> LastHitsBy, Injureds;
var MutBestTimes BT;

event PostBeginPlay()
{
    super.PostBeginPlay();
    BT = MutBestTimes(Owner);
}

function ScoreObjective( PlayerReplicationInfo scorer, int score )
{
    local PlayerController PC, LastHitBy;
    local Pawn P;
    local int i, max;

    super.ScoreObjective(scorer, score);
    if( BT.ModeIsTrials() && scorer != none )
    {
        PC = PlayerController(scorer.Owner);
        if( PC == none )
            return;

        score = Min( score, 10 );
        if( !BT.bSoloMap )
        {
            P = PC.Pawn;
            if( P != none )
            {
                for( i = Injureds.Length - 1; i >= 0; -- i )
                {
                    if( max > 2 )
                        break;

                    // Set LastHitBy and clean all injureds of this user.
                    if( Injureds[i] == P.Controller )
                    {
                        ++ max;
                        //Log( "LastHitBy Found!", Name );

                        LastHitBy = PlayerController(LastHitsBy[i]);
                        if( LastHitBy != none )
                        {
                            LastHitBy.PlayerReplicationInfo.score += score*2.00;
                            ASPlayerReplicationInfo(LastHitBy.PlayerReplicationInfo).DisabledObjectivesCount ++;
                            BT.ObjectiveCompleted( LastHitBy.PlayerReplicationInfo, score);
                        }
                    }
                }
                // Clean all
                Injureds.Length = 0;
                LastHitsBy.Length = 0;
            }
        }
        // Double the score reward but cap to 10 incase the Level Designer did input a ridiculous number!
        scorer.score += score;
        BT.ObjectiveCompleted( scorer, score);

        // If this objective did not end the game,
        // - then we should check whether all objectives have been completed,
        // - to see if we need to end the game ourselves.
        if( !Level.Game.bGameEnded )
        {
            for( i = 0; i < BT.Objectives.Length; ++ i )
            {
                if( BT.Objectives[i] != none && BT.Objectives[i].bActive )
                {
                    return;
                }
            }

            // If there's no end game trigger, then we should end it ourselves.
            if( !FindRoundEnd() )
            {
                ASGameInfo(Level.Game).EndRound( ERER_AttackersWin, P, "Attackers Win!" );
            }
        }
    }
}

private final function bool FindRoundEnd()
{
    local Trigger_ASRoundEnd TRoundEnd;

    foreach AllActors( Class'Trigger_ASRoundEnd', TRoundEnd )
        return true;

    return false;
}

function bool PreventDeath( Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation )
{
    //local Pawn Clone;
    local Controller C;

    // FIXME: if bDisableForceSpawn is true then features like !Wager will break.
    if( !BT.ModeIsTrials() || BT.bDisableForceRespawn || Level.Game.bGameEnded )
        return super.PreventDeath(Killed,Killer,damageType,HitLocation);

    if( !Killed.IsA('Monster') && ((Killed != none && Killed.Controller == Killer) || (Killer == none && (Killed != none && Killed.Controller != none))) )
    {
        if( PlayerController(Killed.Controller) != none && Killed.PlayerReplicationInfo != none && PlayerController(Killed.Controller).CanRestartPlayer() )
        {
            // Player dead was caused by leaving.
            if( PlayerController(Killed.Controller).Player == none )
                return False;

            if( (!BT.IsCompetitiveModeActive() && Killed.GetTeamNum() != MutBestTimes(Owner).AssaultGame.CurrentAttackingTeam) || Killed.Tag == 'IGNOREQUICKRESPAWN' )
                return Super.PreventDeath(Killed,Killer,damageType,HitLocation);

            C = Killed.Controller;

            if( Killed.DrivenVehicle != none )
            {
                Killed.DrivenVehicle.DriverDied();
                Killed.DrivenVehicle = none;
            }

            if( Killed.LastStartSpot != none )
            {
                if( Killed.LastStartSpot.Class != Class'BTServer_ClientStartPoint' )   // Died without a 'ClientSpawn'
                {
                    ++ TeamPlayerReplicationInfo(Killed.PlayerReplicationInfo).Suicides;
                    Killed.PlayerReplicationInfo.Deaths += 1;

                    // Quick Respawn but with gibbing.
                    /*if( Killed.Controller != Killer ) // Otherwise user probably suicided then we should cause no gibbing.
                    {
                        //Log( "Died without a client spawn and no suicide damtype!" );
                        Clone = Killed;
                        Killed.Controller.Pawn = none;
                        Killed.PlayerReplicationInfo = none;
                        Level.Game.RestartPlayer( Killed.Controller );
                        Clone.Controller.PawnDied( Clone );
                        Clone.Controller = none;
                        // Give other mutators a chance to know about a players dead, but without giving the chance to overwrite the return value.
                        Super.PreventDeath(C.Pawn,Killer,damageType,HitLocation);
                        return False;
                    }*/
                    // Should not be called with gibbing or message will be duplicated ;).
                    Level.Game.BroadcastDeathMessage( none, Killed.Controller, damageType );
                }
            }
            BT.CurMode.ModePlayerKilled( C );
            // Quick Respawn with no gibbing.
            RespawnPlayer( Killed );
            // Give other mutators a chance to know about a players dead, but without giving the chance to overwrite the return value.
            Super.PreventDeath(C.Pawn,Killer,damageType,HitLocation);
            return True;
        }
    }
    return Super.PreventDeath(Killed,Killer,damageType,HitLocation);
}

final function RespawnPlayer( Pawn player )
{
    Level.Game.RestartPlayer( player.Controller );
    player.Controller.PawnDied( player );
    if( player != none )
        player.Destroy();
}

function ScoreKill(Controller Killer, Controller Killed)
{
    local int playerSlot;
    local int expReward;
    local Controller C;

    // Monster killed by a HUMAN
    if( MonsterController(Killed) != none && PlayerController(Killer) != none )
    {
        expReward = Monster(Killed.Pawn).ScoringValue;
        if( Monster(Killed.Pawn).bBoss )
        {
            expReward /= Level.Game.NumPlayers+Level.Game.NumBots;
            Level.Game.Broadcast( self, "Everyone has been rewarded with" @ expReward @ "experience for killing a boss!", 'CriticalEvent' );
            for( C = Level.ControllerList; C != none; C = C.NextController )
            {
                if( PlayerController(C) != none && C.PlayerReplicationInfo != none &&
                    !C.PlayerReplicationInfo.bIsSpectator )
                {
                    playerSlot = BT.FastFindPlayerSlot( PlayerController(C) )-1;
                    if( playerSlot != -1 )
                    {
                        BT.PDat.AddExperience( playerSlot, expReward );
                    }
                }
            }
        }
        else
        {
            playerSlot = BT.FastFindPlayerSlot( PlayerController(Killer) )-1;
            if( playerSlot != -1 )
            {
                BT.PDat.AddExperience( playerSlot, expReward );
            }
        }
    }

    super.ScoreKill( Killer, Killed );
}

function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local int i, j;
    local BTClient_ClientReplication CRI;

    // Skip monsters...
    if( Monster(injured) != none || Monster(instigatedBy) != none )
        return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);

    if( BT.ModeIsTrials() )
    {
        if( instigatedBy != none && injured != none )
        {
            if( BT.bEnableInstigatorEmpathy && Instigatedby.GetTeam() != injured.GetTeam() )
            {
                if( !BT.IsCompetitiveModeActive() )
                {
                    instigatedBy.TakeDamage( Damage, instigatedBy, HitLocation, vect(0,0,0), damageType );
                }

                Damage = 0;
            }

            CRI = BT.GetRep( injured.Controller );
            if( !BT.CurMode.ConfigClass.default.bDisableWeaponBoosting || (CRI != none && CRI.bPermitBoosting) )
            {
                // Do nothing :D
            }
            else if( injured != instigatedBy )
            {
                Momentum = vect(0,0,0);
            }
            return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);
        }

        // Enemies never should deal damage in Trials
        if( injured != instigatedBy && instigatedBy != none && (instigatedBy.GetTeam() == injured.GetTeam()) )
        {
            if( BT.bSoloMap && !BT.bGroupMap )
                return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);

            if( DamageType == Class'DamTypeShockBeam' || DamageType == Class'DamTypeONSGrenade')
            {
                // Scan all hits and remove all clones.
                j = Injureds.Length;
                for( i = 0; i < j; ++ i )
                {
                    if( Injureds[i] == injured.Controller )
                    {
                        Injureds.Remove( i, 1 );
                        LastHitsBy.Remove( i, 1 );
                        -- j;
                        -- i;
                    }
                }

                j = LastHitsBy.Length;
                LastHitsBy.Length = j + 1;
                LastHitsBy[j] = instigatedBy.Controller;

                j = Injureds.Length;
                Injureds.Length = j + 1;
                Injureds[j] = injured.Controller;
            }
        }
    }
    return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);
}

function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string incomingName )
{
    local PlayerStart S;
    local NavigationPoint CS;
    local BTServer_TeamPlayerStart X;
    local array<BTServer_TeamPlayerStart> AVS;
    local int i, j;
    local string newPawn;

    if( BT.ModeIsTrials() && Player != none && Player.PlayerReplicationInfo != none && Player.PlayerReplicationInfo.Team != none )
    {
        if( ASGameInfo(Level.Game) != none )
        {
            foreach DynamicActors( class'BTServer_TeamPlayerStart', X )
            {
                if( X.MyTeam == Player.PlayerReplicationInfo.Team.TeamIndex )
                {
                    AVS.Length = i+1;
                    AVS[i++] = X;
                }
            }
            if( i > 0 )
                return AVS[Rand(i)];
        }

        BT.FindClientSpawn( Player, CS );
        if( CS != none )
            return CS;

        // Always check after client so that client still functions even when user has a checkpoint!
        if( BT.CheckPointHandler != none )
        {
            CS = BT.CheckPointHandler.FindCheckPointStart( Player );
            if( CS != none )
                return CS;
        }

        if( BT.bNoRandomSpawnLocation )
        {
            foreach AllActors( class'PlayerStart', S )
            {
                if( IsValidPlayerStart( s ) )
                {
                    Player.Event = '';
                    if( ASGameInfo(Level.Game) != none )
                    {
                        j = ASGameInfo(Level.Game).SpawnManagers.Length;
                        if( j > 0 )
                        {
                            for( i = 0; i < j; ++ i )
                            {
                                if( ASGameInfo(Level.Game).SpawnManagers[i] == none )
                                    continue;

                                if( ASGameInfo(Level.Game).SpawnManagers[i].ApprovePlayerStart( S, Player.PlayerReplicationInfo.Team.TeamIndex, Player ) )
                                {
                                    newPawn = ASGameInfo(Level.Game).SpawnManagers[i].PawnClassOverride( Player, S, Player.PlayerReplicationInfo.Team.TeamIndex );
                                    if( newPawn != "" )
                                        ASPlayerReplicationInfo(Player.PlayerReplicationInfo).PawnOverrideClass = newPawn;

                                    return S;
                                }
                            }
                            continue;
                        }
                        else return S;
                    }
                    else
                    {
                        if( S.TeamNumber == Player.PlayerReplicationInfo.Team.TeamIndex )
                        {
                            return s;
                        }
                    }
                }
            }
        }
    }
    return super.FindPlayerStart( Player, InTeam, incomingName );
}

final function bool IsValidPlayerStart( PlayerStart s )
{
    // Despite configured with bEnabled=false, something is enabling them at run-time, so ensure that no player can spawn on any these two!
    return s.bEnabled && !s.IsA( 'BTServer_ClientStartPoint' ) && !s.IsA( 'BTServer_CheckPointNavigation' );
}