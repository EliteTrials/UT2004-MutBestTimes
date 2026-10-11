class BTGUI_ScoreboardReplicationInfo extends Info;

var BTClient_ClientReplication CRI;

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

simulated event PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	if( CRI != none && Level.NetMode != NM_DedicatedServer )
	{
		if( !bNetOwner && Level.NetMode == NM_Client )
		{
			Log("Destroying duplicated rep socket"@self);
			Destroy();
			return;
		}
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
		return;

	// Log("RepReady" @ self, Name);
	menu.ReplicationReady( self );
}

defaultproperties
{
	bAlwaysRelevant=false
	bOnlyRelevantToOwner=true
	RemoteRole=ROLE_SimulatedProxy
    bStatic=false
    bNoDelete=false
}