class BTQueryDataReplicationInfo extends ReplicationInfo;

var() const class<BTGUI_QueryDataPanel> DataPanelClass;

replication
{
	reliable if( Role < ROLE_Authority )
		Abandon;
}

simulated event PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	if( Level.NetMode != NM_DedicatedServer )
	{
		// Need a minor delay so that we can initialize after specific variables have been set(offline only).
		SetTimer( 0.05, false );
	}
}

simulated event Timer()
{
	RepReady();
}

simulated function RepReady()
{
	local BTGUI_RankingsMenu menu;

	menu = class'BTGUI_RankingsMenu'.static.GetMenu( Level.GetLocalPlayerController() );
	if( menu == none)
	{
		Warn("Received query replication data, but no menu was found");
		return;
	}

	// Log("RepReady" @ self, Name);
	menu.PassQueryReceived( self );
}

// When the client is certain that this actor is no longer needed, it may request the server to destroy it!
simulated function Abandon()
{
	Destroy();
}

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
	// bTearOff=true
	// bNetTemporary=true
	bReplicateMovement=false
	NetPriority=0.5
}