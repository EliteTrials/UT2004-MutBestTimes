//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_Mode extends Object within MutBestTimes
	abstract
	hidedropdown;

/** The human friendly name for this mode. */
var editconst const noexport string ModeName;

/** The Server-MapName state mapprefix to use for this mode. */
var editconst const noexport string ModePrefix;

/** Reference to the owner that spawned this TrialMode instance. */
//var editconst noexport MutBestTimes Master;

var() int ExperienceBonus;
var() float DropChanceBonus;

static function bool DetectMode( MutBestTimes M )
{
	return False;
}

protected function InitializeMode()
{
}

function ModePostBeginPlay()
{
}

function ModeMatchStarting()
{
}

function ModeReset()
{
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
}

function ModePlayerKilled( Controller player )
{

}

function PreRestartRound()
{
	
}

function PostRestartRound()
{
	
}

/** 
 * Called when a player sets a new best or persoanl record. 
 * @rankUps not implemented!
 */
function PlayerMadeRecord( PlayerController player, int rankSlot, int rankUps )
{

}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
	local name achievementID;

	if( AchievementsManager.TestMap( Level.Title, playSeconds, achievementID ) )
	{
		PDat.ProgressAchievementByID( playerSlot, achievementID );
	}
}

function PlayerCompletedObjective( PlayerController player, BTClient_ClientReplication LRI, float score )
{

}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
	local string S, Color;

	if( InStr( ServerState.MapName, "AS-" ) != -1 )
	{
		// Catch color.
		Color = Left( ServerState.MapName, InStr( ServerState.MapName, "AS-" ) );
		// MapName without prefix.
		S = Mid( ServerState.MapName, InStr( ServerState.MapName, "-" ) );

		ServerState.MapName = Color $ ModePrefix $ S;
	}
}

function bool ChatCommandExecuted( PlayerController sender, string command, string value )
{
	local bool bmissed;

	switch( command )
	{
		case "vote":
			sender.ConsoleCommand( "ShowVoteMenu" );
			break;

		case "revote":
			Mutate( "votemap" @ CurrentMapName, sender );
			break;

		case "votemap":
			Mutate( "votemap" @ value, sender );
			break;
			
		case "spec":
			if( !sender.PlayerReplicationInfo.bOnlySpectator )
				sender.BecomeSpectator();
			break;
			
		case "join":
			if( sender.PlayerReplicationInfo.bOnlySpectator )
				sender.BecomeActivePlayer();
			break;

		case "title":
			sender.ConsoleCommand( "BT SetTitle" @ value );
			break;

		default:
			bmissed = true;
			break;
	}
	
	if( !bmissed )
	{
		return true;
	}
	return false;
}

function bool ClientExecuted( PlayerController sender, string command, optional array<string> params )
{
	return false;
}

function bool AdminExecuted( PlayerController sender, string command, optional array<string> params )
{
	return false;
}

function FinalObjectiveCompleted( PlayerController PC )
{
}

final static function BTServer_Mode NewInstance( MutBestTimes M )
{
	local BTServer_Mode Mode;

	Mode = new(M) default.class;
	//Mode = M.Spawn( default.class, M );
	//Mode.Master = M;
	Mode.InitializeMode();
	return Mode;
}

function bool ShouldEnd()
{
	return true;
}

function Free()
{
}

defaultproperties
{
	ExperienceBonus=0
}
