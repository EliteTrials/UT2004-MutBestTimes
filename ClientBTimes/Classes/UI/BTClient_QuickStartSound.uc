//==============================================================================
// BTClient_QuickStartSound.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Play countdown sounds for the QuickStart feature
*/
//  Coded by Eliot
//  Updated @ XX/XX/2009
//==============================================================================
Class BTClient_QuickStartSound Extends CriticalEventPlus;

var name CountDownSound[5];

Static Function ClientReceive
    (
        PlayerController P,
        optional int Switch,
        optional PlayerReplicationInfo RelatedPRI_1,
        optional PlayerReplicationInfo RelatedPRI_2,
        optional Object OptionalObject
    )
{
    Super.ClientReceive(P,Switch,RelatedPRI_1,RelatedPRI_2,OptionalObject);
    if( Switch > 0 && Switch <= 5 && P != None )
        P.QueueAnnouncement( Default.CountDownSound[Switch-1], 1, AP_InstantOrQueueSwitch, 1 );
}

DefaultProperties
{
    bIsUnique=True

    CountDownSound(0)=One
    CountDownSound(1)=Two
    CountDownSound(2)=Three
    CountDownSound(3)=Four
    CountDownSound(4)=Five
}
