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
    local int playerIndex;

    if( client != None )
    {
        playerIndex = MutBestTimes(Owner).FastFindPlayerSlot( Client )-1;
        if( playerIndex != -1 )
        {
            MutBestTimes(Owner).UpdatePlayerStand( Client, playerIndex, true );
        }
    }
    Destroy();
}
