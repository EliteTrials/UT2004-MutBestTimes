//==============================================================================
// BTClient_VRI.uc (C) 2007-2008 Eliot and .:..:. All Rights Reserved
/* Tasks:
			Replace MapVotingPage
			Faster replication
*/
//	Coded by Eliot
//	Updated @ XX/XX/2008
//==============================================================================
Class BTClient_VRI Extends VotingReplicationInfo;

/*Simulated Function OpenWindow()
{
	local GUIController GC;

 	GC = GetController();
 	if( GC != None )
 	{
		if( GC.FindMenuByClass( Class'BTClient_MapVotingPage' ) == None )
			GC.OpenMenu( string( Class'BTClient_MapVotingPage' ) );
	}
}*/

DefaultProperties
{
	NetPriority=1.5
	NetUpdateFrequency=2
}

