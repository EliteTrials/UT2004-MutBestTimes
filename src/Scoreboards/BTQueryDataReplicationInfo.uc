class BTQueryDataReplicationInfo extends ReplicationInfo;

var() const class<BTGUI_QueryDataPanel> DataPanelClass;

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


defaultproperties
{
	bAlwaysRelevant=true
	bOnlyRelevantToOwner=true
}