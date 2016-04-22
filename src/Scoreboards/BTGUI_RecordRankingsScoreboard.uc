class BTGUI_RecordRankingsScoreboard extends BTGUI_RankingsBase;

var automated BTGUI_ComboBox RankingsCombo;
var automated BTGUI_RecordRankingsMultiColumnListBox RankingsListBox;
var private bool bWaitingForReplication;

delegate OnQueryPlayerRecord( int mapId, int playerId );

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
	RankingsListBox.MyScrollBar.PositionChanged = InternalOnScroll;
    RankingsListBox.ContextMenu.OnSelect = InternalOnContext;
    RankingsListBox.List.OnDblClick = InternalOnSelected;
}

event Opened( GUIComponent sender )
{
    local BTClient_ClientReplication CRI;

    super.Opened( sender );
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( CRI == none )
        return;

    if( CRI.RecordsPRI == none && !bWaitingForReplication )
    {
        bWaitingForReplication = true;
        RequestReplicationChannels();
    }
}

private function RequestReplicationChannels()
{
    local BTClient_ClientReplication CRI;

    // bWaitingForReplication = true;
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.ServerRequestRecordRanks( -1 ); // This will request our replication channel(s)
}

// Wait for the ready event, before we request ranks.
function RepReady( BTGUI_ScoreboardReplicationInfo repSource )
{
	local BTGUI_RecordRankingsReplicationInfo recordsPRI;

    recordsPRI = BTGUI_RecordRankingsReplicationInfo(repSource);
    if( recordsPRI == none )
        return;

	// Start receiving updates.
	recordsPRI.OnRecordRankReceived = InternalOnRecordRankReceived;
	recordsPRI.OnRecordRanksDone = InternalOnRecordRanksDone;
	recordsPRI.OnRecordRanksCleared = InternalOnRecordRanksCleared;

	// Note: Will trigger OnChangeRankingsCategory
	RankingsCombo.SetText( recordsPRI.RecordsMapName );
    RankingsCombo.OnChange( self ); // ??? wtf stopped working by itself!
    bWaitingForReplication = false;
}

private function QueryNextRecordRanks( optional bool bReset )
{
	local BTClient_ClientReplication CRI;

    if( bIsQuerying )
    	return;

    bIsQuerying = true;
    RankingsCombo.DisableMe();
    RankingsListBox.List.SetIndex( 0 );

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.RecordsPRI.RecordsMapName = RankingsCombo.GetText();
    CRI.RecordsPRI.QueryNextRecordRanks( bReset );

	// Log("Querying next ranks" @ bIsQuerying @ bReset @ CRI.RecordsPRI.RecordsMapName );
}

function InternalOnChangeRankingsCategory( GUIComponent sender )
{
	local BTClient_ClientReplication CRI;
	local BTGUI_RecordRankingsMultiColumnList list;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    // Log("InternalOnChangeRankingsCategory" @ bIsQuerying @ CRI.RecordsPRI.RecordsMapName @ RankingsCombo.GetText() );

    bIsQuerying = false; // renable querying

    // TODO:
	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	// list.Ranks = CRI.RecordsPRI.RecordRanks;
	list.Clear();

	CRI.RecordsPRI.RecordRanks.Length = 0;
    QueryNextRecordRanks( true );
}

function InternalOnRecordRankReceived( int index, BTGUI_RecordRankingsReplicationInfo source )
{
	local BTGUI_RecordRankingsMultiColumnList list;

	// Log("Received a rank packet");
	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	list.AddedItem();
}

function InternalOnRecordRanksDone( BTGUI_RecordRankingsReplicationInfo source, bool bAll )
{
	local BTClient_ClientReplication CRI;

	// Log("Query completed");
	bIsQuerying = bAll; // Don't ever query again if we have received all there is to be received!
    RankingsCombo.EnableMe();

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( RankingsCombo.GetText() != CRI.RecordsPRI.RecordsMapName )
    {
    	RankingsCombo.OnChange = none;
		RankingsCombo.SetText( CRI.RecordsPRI.RecordsMapName );
		RankingsCombo.OnChange = InternalOnChangeRankingsCategory;
    }

	if( !bIsQuerying && !RankingsListBox.MyScrollBar.bVisible )
	{
		QueryNextRecordRanks();
	}
    else
    {
        // If our end user is sorting by other means than Rank, then we should make sure the newly added data gets sorted straight away!
        RankingsListBox.List.NeedsSorting = true;
    }
}

function InternalOnRecordRanksCleared( BTGUI_RecordRankingsReplicationInfo source )
{
	local BTGUI_RecordRankingsMultiColumnList list;

	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	list.Clear();
    QueryNextRecordRanks( true );
}

function InternalOnScroll( int newPos )
{
    if( newPos > RankingsListBox.MyScrollBar.ItemCount-15 )
    {
        QueryNextRecordRanks();
    }
}

function InternalOnContext( GUIContextMenu sender, int clickIndex )
{
    switch( clickIndex )
    {
        // Record
        case 0:
            ViewPlayerRecord( RankingsListBox.List.CurrentListId() );
            break;

        // Player
        case 1:
            ViewPlayer( RankingsListBox.List.CurrentListId() );
            break;

        // Erase
        case 2:
            ErasePlayerRecord( RankingsListBox.List.CurrentListId() );
            break;
    }
}

function bool InternalOnSelected( GUIComponent sender )
{
    local int itemIndex;

    itemIndex = RankingsListBox.List.CurrentListId();
    ViewPlayerRecord( itemIndex );
    return false;
}

private function ViewPlayerRecord( int itemIndex )
{
    local BTClient_ClientReplication CRI;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    OnQueryPlayerRecord( CRI.RecordsPRI.RecordsMapId, CRI.RecordsPRI.RecordRanks[itemIndex].PlayerId );
}

private function ViewPlayer( int itemIndex )
{
    local BTClient_ClientReplication CRI;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    OnQueryPlayer( CRI.RecordsPRI.RecordRanks[itemIndex].PlayerId );
}

private function ErasePlayerRecord( int itemIndex )
{
    local BTClient_ClientReplication CRI;
    local int playerId;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    playerId = CRI.RecordsPRI.RecordRanks[itemIndex].PlayerId;
    PlayerOwner().ConsoleCommand( "mutate ErasePlayerRecord" @ playerId );
}

defaultproperties
{
    Begin Object class=BTGUI_ComboBox Name=RanksComboBox
        WinWidth=1.0
        WinHeight=0.05
        WinLeft=0.0
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
        OnChange=InternalOnChangeRankingsCategory
    End Object
    RankingsCombo=RanksComboBox

    Begin Object Class=BTGUI_RecordRankingsMultiColumnListBox Name=ItemsListBox
        WinWidth=1.0
        WinHeight=0.915
        WinLeft=0.0
        WinTop=0.07
        bVisibleWhenEmpty=true
        bScaleToParent=True
        bBoundToParent=True
        FontScale=FNS_Small
    End Object
    RankingsListBox=ItemsListBox
}