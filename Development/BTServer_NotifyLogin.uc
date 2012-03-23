//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_NotifyLogin Extends Info;

#include DEC_Structs.uc

const NotifyDelay = 2.0;

var int Timers;

var PlayerController Client;

Event PreBeginPlay();
Event PostBeginPlay();

Event Timer()
{
	local int Slot;
	local string GUID;

	if( Client != None )
	{
		GUID = Client.GetPlayerIDHash();
		if( GUID == "" && Timers < 15 )	// if more than 15 trys then drop this replication, Player probably lost connection or is really slow
		{
			++ Timers;
			// Slow delay because we don't want to replicate CustomReplicationInfo too late i.e. after bNetInitial
			SetTimer( 0.5, False );
			return;
		}
		Slot = BTimesMute(Owner).FindPlayerSlot( GUID );
		BTimesMute(Owner).NotifyPostLogin( Client, GUID, Slot );
	}
	Destroy();
	return;
}
