class BTGUI_ScoreboardReplicationInfo extends ReplicationInfo;

var protected BTClient_ClientReplication CRI;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if( Level.NetMode != NM_DedicatedServer )
	{
		CRI = class'BTClient_ClientReplication'.static.GetRep( Level.GetLocalPlayerController() );
	}
	else
	{
		CRI = class'BTClient_ClientReplication'.static.GetRep( PlayerController(Owner) );
	}
}

defaultproperties
{
	bAlwaysRelevant=true
	bOnlyRelevantToOwner=true
}