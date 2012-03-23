//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_NameUpdateDelay Extends Info;

var PlayerController Client;

Event PreBeginPlay();
Event PostBeginPlay();

Event Timer()
{
	local int Slot;

	if( Client != None )
	{
		Slot = MutBestTimes(Owner).FastFindPlayerSlot( Client );
		if( Slot > 0 )
		{
  			MutBestTimes(Owner).UpdatePlayerSlot( Client, Slot - 1, True );
  		}
  	}
	Destroy();
}
