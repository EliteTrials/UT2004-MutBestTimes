class BTGUI_RankingsBase extends UT2K4TabPanel
    abstract;

var protected BTClient_Interaction Inter;
var protected editconst bool bIsQuerying;

static function BTClient_ClientReplication GetCRI( PlayerReplicationInfo PRI )
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

delegate OnQueryPlayer( coerce string playerId );

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

protected function BTClient_Interaction GetInter()
{
    local int i;
    local Player player;

    player = Controller.ViewportOwner;
    for( i = 0; i < player.LocalInteractions.Length; ++ i )
    {
        if( player.LocalInteractions[i].Class == class'BTClient_Interaction' )
            return BTClient_Interaction(player.LocalInteractions[i]);
    }
    return none;
}