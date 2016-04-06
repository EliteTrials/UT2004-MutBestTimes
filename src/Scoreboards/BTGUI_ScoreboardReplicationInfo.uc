class BTGUI_ScoreboardReplicationInfo extends ReplicationInfo;

var() const class<FloatingWindow> MenuClass;

event PostBeginPlay()
{
	super.PostBeginPlay();
	if( Level.NetMode == NM_Standalone )
	{
		OpenMenu();
	}
}

simulated event PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	OpenMenu();
}

simulated function OpenMenu()
{
	local PlayerController PC;

	PC = Level.GetLocalPlayerController();
	if( PC == none )
	{
		Destroy();
		return;
	}

	PC.ClientOpenMenu( string(MenuClass), false );
}

defaultproperties
{
	bAlwaysRelevant=true
	bOnlyRelevantToOwner=true
}