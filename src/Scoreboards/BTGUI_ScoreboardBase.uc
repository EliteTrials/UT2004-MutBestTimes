class BTGUI_ScoreboardBase extends FloatingWindow;

final function BTClient_Interaction GetInter()
{
	local int i;

	for( i = 0; i < Controller.ViewportOwner.LocalInteractions.Length; ++ i )
	{
		if( Controller.ViewportOwner.LocalInteractions[i].Class == class'BTClient_Interaction' )
			return BTClient_Interaction(Controller.ViewportOwner.LocalInteractions[i]);
	}
	return none;
}

final function BTGUI_ScoreboardReplicationInfo GetRep()
{
	local BTGUI_ScoreboardReplicationInfo rep;

	foreach PlayerOwner().DynamicActors( class'BTGUI_ScoreboardReplicationInfo', rep )
	{
		if( rep.MenuClass == class )
		{
			return rep;
		}
	}
	return none;
}

defaultproperties
{
	bAllowedAsLast=true
}