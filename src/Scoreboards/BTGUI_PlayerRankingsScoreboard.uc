class BTGUI_PlayerRankingsScoreboard extends BTGUI_RankingsBase;

var const array<string> RankingCategories;

var automated BTGUI_ComboBox RankingsCombo;
var automated BTGUI_PlayerRankingsMultiColumnListBox RankingsListBox;
var private bool bWaitingForReplication;

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	local int i;

	super.InitComponent( myController, myOwner );
	RankingsListBox.MyScrollBar.PositionChanged = InternalOnScroll;
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
    if( CRI == none )
        return;

    if( CRI.Rankings[GetCurrentRanksId()] == none && !bWaitingForReplication)
    {
        bWaitingForReplication = true;
        RequestReplicationChannels();
    }
}

function RequestReplicationChannels()
{
	local BTClient_ClientReplication CRI;
	local byte ranksId;

	ranksId = GetCurrentRanksId();
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
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
function RepReady( BTGUI_ScoreboardReplicationInfo source )
{
    local BTGUI_PlayerRankingsReplicationInfo ranksRep;

    ranksRep = BTGUI_PlayerRankingsReplicationInfo(source);
    if( ranksRep == none ) // Not meant for this instance
        return;

	// Start receiving updates.
	ranksRep.OnPlayerRankReceived = InternalOnPlayerRankReceived;
	ranksRep.OnPlayerRanksDone = InternalOnPlayerRanksDone;
	RankingsListBox.SwitchRankings( ranksRep.RanksId, ranksRep );
    QueryNextPlayerRanks();
    bWaitingForReplication = false;
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
    RankingCategories(0)="Ranks - All Time"
    RankingCategories(1)="Ranks - This Month"
    RankingCategories(2)="Ranks - Today"

    Begin Object class=BTGUI_ComboBox Name=RanksComboBox
        WinWidth=0.38
        WinHeight=0.045
        WinLeft=0.0
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
        bReadOnly=true
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