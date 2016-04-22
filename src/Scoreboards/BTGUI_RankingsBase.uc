class BTGUI_RankingsBase extends UT2K4TabPanel
    abstract;

var protected BTClient_Interaction Inter;
var protected editconst bool bIsQuerying;

delegate OnQueryPlayer( int playerId );

simulated final function BTClient_Interaction GetInter()
{
    local int i;

    for( i = 0; i < Controller.ViewportOwner.LocalInteractions.Length; ++ i )
    {
        if( Controller.ViewportOwner.LocalInteractions[i].Class == class'BTClient_Interaction' )
            return BTClient_Interaction(Controller.ViewportOwner.LocalInteractions[i]);
    }
    return none;
}

simulated static function BTClient_ClientReplication GetCRI( PlayerReplicationInfo PRI )
{
    local LinkedReplicationInfo LRI;

    for( LRI = PRI.CustomReplicationInfo; LRI != none; LRI = LRI.NextReplicationInfo )
    {
        if( BTClient_ClientReplication(LRI) != none )
        {
            return BTClient_ClientReplication(LRI);
        }
    }
    return none;
}

event Free()
{
	super.Free();
	Inter = none;
}

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
    Inter = GetInter();
}

function InitPanel()
{
    MyButton.Style = Controller.GetStyle( "BTTabButton", MyButton.FontScale );
}