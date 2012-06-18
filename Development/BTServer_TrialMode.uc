//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_TrialMode extends BTServer_Mode;

var() float MinRecordTime;
var() float MaxRecordTime;
var() float PointsPenalty;

function ModeReset()
{
	super.ModeReset();
	RecordByTeam = RT_None;
}

function ModePostBeginPlay()
{
	RDat.Rec[UsedSlot].AverageRecordTIme = GetAverageRecordTime( UsedSlot );
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
	super.ModeModifyPlayer( other, c, CRI );
	
	other.SetCollision( true, false, false );
}

function bool ChatCommandExecuted( PlayerController sender, string command )
{
	local bool bmissed;
	
	switch( command )
	{
		case "cp":
			Mutate( "clientspawn", sender );
			break;
			
		case "revote":
			Mutate( "votemap" @ CurrentMapName, sender );
			break;
			
		case "vote":
			sender.ConsoleCommand( "ShowVoteMenu" );
			break;
			
		case "spec":
			if( !sender.PlayerReplicationInfo.bOnlySpectator )
				sender.BecomeSpectator();
				
			break;
			
		case "join":
			if( sender.PlayerReplicationInfo.bOnlySpectator )
				sender.BecomeActivePlayer();
				
			break;
			
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
		
	return super.ChatCommandExecuted( sender, command );
}

defaultproperties
{
	ModeName="Normal"
	ModePrefix="NTR"
	PointsPenalty=0.25
}