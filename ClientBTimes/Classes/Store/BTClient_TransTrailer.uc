//==============================================================================
// BTClient_TransTrailer.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Second trailer for the best players
*/
//  Coded by Eliot
//  Updated @ XX/XX/2009
//
// OBSOLETE!
//==============================================================================
Class BTClient_TransTrailer Extends TransTrail;

Simulated Function Tick( float dt )
{
    if( xPawn(Owner) == None || xPawn(Owner).bDeRes || xPawn(Owner).bDeleteMe )
    {
        Destroy();
        return;
    }

    if( !mRegen )
        mRegen = True;
}
