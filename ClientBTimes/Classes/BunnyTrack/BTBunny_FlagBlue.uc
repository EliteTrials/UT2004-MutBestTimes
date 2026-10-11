class BTBunny_FlagBlue extends xBlueFlag;

event Destroyed()
{
    if( HomeBase != none )
    {
        HomeBase.bHidden = false;
    }
    super.Destroyed();
}

function Drop( vector newVel )
{
    ClearHolder();
    UnrealMPGameInfo(Level.Game).GameEvent("flag_returned_timeout",""$Team.TeamIndex,None);
    BroadcastLocalizedMessage( MessageClass, 3, None, None, Team );
    Destroy();
}