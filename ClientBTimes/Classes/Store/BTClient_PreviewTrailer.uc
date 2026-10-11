//==============================================================================
// BTClient_PreviewTrailer.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Enhanced RankTrailer for the TrailerMenu
*/
//  Coded by Eliot
//  Updated @ XX/XX/2009
//==============================================================================
Class BTClient_PreviewTrailer Extends BTClient_RankTrailer;

Function PostBeginPlay();
Function Tick( float Delta );

DefaultProperties
{
    bAlwaysTick=True
    DrawScale=4
}
