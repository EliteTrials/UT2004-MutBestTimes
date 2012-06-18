//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGameRules extends GameRules;

var array<Controller> LastHitsBy, Injureds;
var MutBestTimes BT;

#include DEC_Structs.uc

const EXP_Dead = 1;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	BT = MutBestTimes(Owner);
}

private final function AddObjective( PlayerController PC )
{
	BT.NotifyObjectiveAccomplished( PC );
}

function ScoreObjective( PlayerReplicationInfo Scorer, Int Score )
{
	local PlayerController PC, LastHitBy;
	local Pawn P;
	local int i, j, Max;

	if( BT.IsTrials() && Scorer != None )
	{
		PC = PlayerController(Scorer.Owner);
		if( PC == None )
			return;

		if( !BT.bSoloMap )
		{
			P = PC.Pawn;
			if( P != None )
			{
				for( i = Injureds.Length - 1; i >= 0; -- i )
				{
					if( Max > 2 )
						break;

					// Set LastHitBy and clean all injureds of this user.
					if( Injureds[i] == P.Controller )
					{
						++ Max;
						//Log( "LastHitBy Found!", Name );

						LastHitBy = PlayerController(LastHitsBy[i]);
						if( LastHitBy != None )
						{
							LastHitBy.PlayerReplicationInfo.Score += Min( Score*2, 20 );
							ASPlayerReplicationInfo(LastHitBy.PlayerReplicationInfo).DisabledObjectivesCount ++;
							AddObjective( LastHitBy );
						}
					}
				}
				// Clean all
				Injureds.Length = 0;
				LastHitsBy.Length = 0;
			}
			// Note the time this objective was completed in.
			BT.AddObjectiveTime( BT.AssaultGame.LastDisabledObjective );
		}
		// Double the score reward but cap to 10 incase the Level Designer did input a ridiculous number!
		Scorer.Score += Min( Score, 10 );
		AddObjective( PC );

		// Solo handles the ending...
		if( BT.bSoloMap )
		{
			Super.ScoreObjective(Scorer,Score);
			return;
		}

		BT.ObjectiveCompleted( Scorer );

		// Find out if the obj ended the level
		if( Level.Game.bGameEnded )
		{
			// Did end
			Super.ScoreObjective(Scorer,Score);
			return;
		}

		j = BT.Objectives.Length;
		for( i = 0; i < j; ++ i )
		{
			if( BT.Objectives[i] != None && BT.Objectives[i].bActive )
			{
				// might have end... but theres still this objective active, so don't end it
				Super.ScoreObjective(Scorer,Score);
				return;
			}
		}

		if( FindRoundEnd() )
		{
			// Map has ability to end
			Super.ScoreObjective(Scorer,Score);
			return;
		}

		// End it, none of above was true!
		ASGameInfo(Level.Game).EndRound( ERER_AttackersWin, P, "Attackers Win!" );
	}
	super.ScoreObjective( Scorer, Score );
}

private final function bool FindRoundEnd()
{
	local Trigger_ASRoundEnd TRoundEnd;

	ForEach AllActors( Class'Trigger_ASRoundEnd', TRoundEnd )
		return True;

	return False;
}

/*Function bool OverridePickupQuery( Pawn Other, Pickup item, out byte bAllowPickup )
{
	local GameRules GR;

	if( TournamentPickup(Item) != None )
	{
		if( Skips > 0 )
		{
			Skips --;
			bAllowPickup = 0;
			return True;
		}
		Skips = 1;
		GR = Level.Game.GameRulesModifiers;
		Level.Game.GameRulesModifiers = None;
		Item.Touch( Other );
		if( !Item.IsInState( 'Pickup' ) )
		{
			Item.GotoState( 'Pickup' );
			Item.RespawnEffect();
		}
		Level.Game.GameRulesModifiers = GR;
		bAllowPickup = 0;
		return True;
	}
	return Super.OverridePickupQuery(Other,Item,bAllowPickup);
}*/

function bool PreventDeath( Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation )
{
	//local Pawn Clone;
	//local int i;
	local Controller C;

	if( !BT.IsTrials() || BT.bDisableForceRespawn || Level.Game.bGameEnded )
		return Super.PreventDeath(Killed,Killer,damageType,HitLocation);

	if( !Killed.IsA('Monster') && ((Killed != None && Killed.Controller == Killer) || (Killer == None && (Killed != None && Killed.Controller != None))) )
	{
		if( PlayerController(Killed.Controller) != None && Killed.PlayerReplicationInfo != None && PlayerController(Killed.Controller).CanRestartPlayer() )
		{
			// Player dead was caused by leaving.
			if( PlayerController(Killed.Controller).Player == None )
				return False;

			if( (!BT.IsCompetitive() && Killed.GetTeamNum() != BTimesMute(Owner).AssaultGame.CurrentAttackingTeam) || Killed.Tag == 'IGNOREQUICKRESPAWN' )
				return Super.PreventDeath(Killed,Killer,damageType,HitLocation);

			C = Killed.Controller;

			if( Killed.DrivenVehicle != None )
			{
				Killed.DrivenVehicle.DriverDied();
				Killed.DrivenVehicle = None;
			}

			if( Killed.LastStartSpot != None )
			{
				if( Killed.LastStartSpot.Class != Class'BTServer_ClientStartPoint' )   // Died without a 'ClientSpawn'
				{
					++ TeamPlayerReplicationInfo(Killed.PlayerReplicationInfo).Suicides;
					Killed.PlayerReplicationInfo.Deaths += 1;

					// Quick Respawn but with gibbing.
					/*if( Killed.Controller != Killer )	// Otherwise user probably suicided then we should cause no gibbing.
					{
						//Log( "Died without a client spawn and no suicide damtype!" );
						Clone = Killed;
						Killed.Controller.Pawn = None;
						Killed.PlayerReplicationInfo = None;
						Level.Game.RestartPlayer( Killed.Controller );
						Clone.Controller.PawnDied( Clone );
						Clone.Controller = None;
						// Give other mutators a chance to know about a players dead, but without giving the chance to overwrite the return value.
						Super.PreventDeath(C.Pawn,Killer,damageType,HitLocation);
						return False;
					}*/
					// Should not be called with gibbing or message will be duplicated ;).
					Level.Game.BroadcastDeathMessage( None, Killed.Controller, damageType );

					//if( !BT.bQuickStart )
					//	BT.PDat.RemoveExperience( BT.GetRep( PlayerController(Killed.Controller) ).myPlayerSlot, EXP_Dead );
				}
			}
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
	if( player != None )
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
	//local Pawn Clone;
	local int i, j;
	local BTClient_ClientReplication CRI;

	// Skip monsters...
	if( Monster(injured) != None || Monster(instigatedBy) != None )
		return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);

	if( BT.ModeIsTrials() )
	{
		if( instigatedBy != None && injured != None )
		{
			if( Instigatedby.GetTeam() != injured.GetTeam() )
			{
				if( !BT.IsCompetitive() )
				{
					instigatedBy.TakeDamage( Damage, instigatedBy, HitLocation, vect(0,0,0), damageType );
				}

				Damage = 0;
			}
			
			CRI = BT.GetRep( injured.Controller );
			if( CRI != none && CRI.bPermitBoosting )
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
		if( BT.IsTrials() )
		{
			if( injured != instigatedBy && instigatedBy != None && (instigatedBy.GetTeam() == injured.GetTeam()) )
			{
				if( BT.bSoloMap )
					return Super.NetDamage(OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType);

				//Log( "Team Naded | ShockBeam", Name );
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
					//Log( "TRUE", Name );
					LastHitsBy.Length = j + 1;
					LastHitsBy[j] = instigatedBy.Controller;

					j = Injureds.Length;
					Injureds.Length = j + 1;
					Injureds[j] = injured.Controller;
				}
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

	if( BT.ModeIsTrials() && Player != None && Player.PlayerReplicationInfo != None && Player.PlayerReplicationInfo.Team != None )
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
		if( CS != None )
			return CS;
				
		// Only attackers! aka the red team
		if( ASGameInfo(Level.Game) != none 
			&& Player.PlayerReplicationInfo.Team.TeamIndex == ASGameInfo(Level.Game).CurrentAttackingTeam )
		{
			// Always check after client so that client still functions even when user has a checkpoint!
			if( BT.CheckPointHandler != None )
			{
				CS = BT.CheckPointHandler.FindCheckPointStart( Player );
				if( CS != None )
					return CS;
			}
		}

		if( BT.bNoRandomSpawnLocation )
		{
			foreach AllActors( class'PlayerStart', S )
			{
				if( S.bEnabled && !S.IsA( 'BTServer_ClientStartPoint' ) && !S.IsA( 'BTServer_CheckPointNavigation' ) )
				{
					Player.Event = '';
					if( ASGameInfo(Level.Game) != none )
					{
						j = ASGameInfo(Level.Game).SpawnManagers.Length;
						if( j > 0 )
						{
							for( i = 0; i < j; ++ i )
							{
								if( ASGameInfo(Level.Game).SpawnManagers[i] == None )
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
