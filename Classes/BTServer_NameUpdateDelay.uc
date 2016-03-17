//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_NameUpdateDelay extends Info;

var PlayerController Client;

event PreBeginPlay()
{
    SetTimer( 0.25, false );
}

event PostBeginPlay();

event Timer()
{
    local int playerSlot;

    if( client != None )
    {
        playerSlot = MutBestTimes(Owner).FastFindPlayerSlot( Client );
        if( playerSlot != -1 )
        {
            MutBestTimes(Owner).UpdatePlayerSlot( Client, playerSlot-1, true );
        }
    }
    Destroy();
}
