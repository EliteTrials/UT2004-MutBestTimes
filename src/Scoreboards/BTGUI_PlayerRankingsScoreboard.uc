class BTGUI_PlayerRankingsScoreboard extends UT2K4TabPanel;

var const array<string> RankingCategories;

var automated GUIComboBox RankingsCombo;
var automated BTGUI_PlayerRankingsMultiColumnListBox RankingsListBox;

var private BTClient_Interaction Inter;
var private editconst bool bIsQuerying;

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

    for( LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
    {
        if( BTClient_ClientReplication(LRI) != None )
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
	local int i;

	super.InitComponent( myController, myOwner );
	RankingsListBox.MyScrollBar.PositionChanged = InternalOnScroll;
    RankingsCombo.Edit.bAlwaysNotify = true;
    RankingsCombo.Edit.bReadOnly = true;
  	RankingsCombo.Edit.Style = Controller.GetStyle("BTEditBox", RankingsCombo.Edit.FontScale);
    RankingsCombo.MyShowListBtn.Style = Controller.GetStyle("BTButton", RankingsCombo.MyShowListBtn.FontScale);
    RankingsCombo.List.Style = Controller.GetStyle("BTMultiColumnList", RankingsCombo.List.FontScale);
    RankingsCombo.List.SelectedStyle = Controller.GetStyle("BTMultiColumnList", RankingsCombo.List.FontScale);

    Inter = GetInter();
	for( i = 0; i < RankingCategories.Length; ++ i )
	{
	    RankingsCombo.AddItem( RankingCategories[i], none, string(i) );
	}
}

event Opened( GUIComponent sender )
{
	local BTClient_ClientReplication CRI;

	super.Opened( sender );

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( CRI.Rankings[GetCurrentRanksId()] == none )
    {
    	RequestReplicationChannels();
    }
}

function InitPanel()
{
    MyButton.Style = Controller.GetStyle("BTTabButton", MyButton.FontScale);
}

function RequestReplicationChannels()
{
	local BTClient_ClientReplication CRI;
	local byte ranksId;

	ranksId = GetCurrentRanksId();
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.OnClientNotify = InternalOnClientNotify;
    CRI.ServerRequestPlayerRanks( -1, ranksId ); // Initialize replication channels.
	// PlayerOwner().ClientMessage("Requesting channel" @ ranksId);
}

function QueryNextPlayerRanks()
{
	local BTClient_ClientReplication CRI;

	// PlayerOwner().ClientMessage("Querying next ranks" @ bIsQuerying);
    if( bIsQuerying )
    	return;

    bIsQuerying = true;
    RankingsCombo.DisableMe();
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.Rankings[GetCurrentRanksId()].QueryNextPlayerRanks();;
}

final function byte GetCurrentRanksId()
{
	return byte(RankingsCombo.GetExtra());
}

// Wait for the ready event, before we request ranks.
function InternalOnClientNotify( string message, byte ranksId )
{
	local BTClient_ClientReplication CRI;

	// PlayerOwner().ClientMessage("Received notification" @ message @ ranksId);
	if( message != "Ready" )
		return;

	// Start receiving updates.
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
	CRI.Rankings[ranksId].OnPlayerRankReceived = InternalOnPlayerRankReceived;
	CRI.Rankings[ranksId].OnPlayerRanksDone = InternalOnPlayerRanksDone;
	RankingsListBox.SwitchRankings( ranksId, CRI.Rankings[ranksId] );
    QueryNextPlayerRanks();
}

function InternalOnChangeRankingsCategory( GUIComponent sender )
{
    local BTGUI_PlayerRankingsMultiColumnList list;
	local BTClient_ClientReplication CRI;
	local byte ranksId;

	bIsQuerying = false; // renable querying
	ranksId = GetCurrentRanksId();
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
	if( CRI.Rankings[ranksId] == none )
	{
		// PlayerOwner().ClientMessage("Requesting new rankings channel" @ ranksId);
    	CRI.OnClientNotify = InternalOnClientNotify;
    	CRI.ServerRequestPlayerRanks( -1, ranksId ); // Initialize replication channels.
    	return;
	}
	RankingsListBox.SwitchRankings( ranksId, CRI.Rankings[ranksId] );

    list = RankingsListBox.RankingLists[ranksId];
    // t_WindowTitle.SetCaption(
    //     WindowName @ "(" $ list.ItemCount $ "/" $ Inter.MRI.RankedPlayersCount $ ") out of"
    //     @ Inter.MRI.PlayersCount
    // );
}

function InternalOnPlayerRankReceived( int index, BTGUI_PlayerRankingsReplicationInfo source )
{
	local BTGUI_PlayerRankingsMultiColumnList list;

	// PlayerOwner().ClientMessage("Received a rank packet");
	list = RankingsListBox.RankingLists[source.RanksId];
	if( list == none )
	{
		Warn("Received a rank for a non existing rankings list!");
		return;
	}
	list.AddedItem();
	if( Inter == none ) // None once this menu is reopened :<?
    	Inter = GetInter();

	// t_WindowTitle.SetCaption(
	// 	WindowName @ "(" $ list.ItemCount $ "/" $ Inter.MRI.RankedPlayersCount $ ") out of"
	// 	@ Inter.MRI.PlayersCount
	// );
}

function InternalOnPlayerRanksDone( BTGUI_PlayerRankingsReplicationInfo source, bool bAll )
{
	// PlayerOwner().ClientMessage("Query completed");
	bIsQuerying = bAll; // Don't ever query again if we have received all there is to be received!
    RankingsCombo.EnableMe();

	if( !bIsQuerying && !RankingsListBox.MyScrollBar.bVisible )
	{
		QueryNextPlayerRanks();
	}
}

function InternalOnScroll( int newPos )
{
    if( newPos > RankingsListBox.MyScrollBar.ItemCount-15 )
    {
        QueryNextPlayerRanks();
    }
}

defaultproperties
{
    RankingCategories(0)="All Time"
    RankingCategories(1)="Monthly"
    RankingCategories(2)="Daily"

    Begin Object class=GUIComboBox Name=RanksComboBox
        WinWidth=0.3
        WinHeight=0.034286
        WinLeft=0.01
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
        OnChange=InternalOnChangeRankingsCategory
    End Object
    RankingsCombo=RanksComboBox

    Begin Object Class=BTGUI_PlayerRankingsMultiColumnListBox Name=ItemsListBox
        WinWidth=1.0
        WinHeight=0.92
        WinLeft=0.0
        WinTop=0.065
        bVisibleWhenEmpty=true
        bScaleToParent=True
        bBoundToParent=True
        FontScale=FNS_Small
    End Object
    RankingsListBox=ItemsListBox
}