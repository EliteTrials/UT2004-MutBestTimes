class BTGUI_RecordRankingsScoreboard extends BTGUI_RankingsBase;

// Player's records or records from a map.
var automated BTGUI_ComboBox SourceCombo;
var automated BTGUI_ComboBox RankingsCombo;
var automated BTGUI_RecordRankingsMultiColumnListBox RankingsListBox;
var private bool bWaitingForReplication;
var private string _LastQuery;

delegate OnQueryPlayerRecord( coerce string mapId, coerce string playerId );

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
	RankingsListBox.MyScrollBar.PositionChanged = InternalOnScroll;
    RankingsListBox.ContextMenu.OnSelect = InternalOnContext;
    RankingsListBox.List.OnDblClick = InternalOnSelected;
    RankingsCombo.DisableMe();
    SourceCombo.DisableMe();
    SourceCombo.AddItem( "Map" );
    SourceCombo.AddItem( "Player" );
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
	recordsPRI.OnRecordRankUpdated = InternalOnRecordRankUpdated;
	recordsPRI.OnRecordRanksDone = InternalOnRecordRanksDone;
	recordsPRI.OnRecordRanksCleared = InternalOnRecordRanksCleared;

	// Note: Will trigger OnChangeRankingsCategory
	RankingsCombo.SetText( recordsPRI.RecordsQuery );
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
    SourceCombo.DisableMe();

    if( bReset )
    {
        RankingsListBox.List.SetIndex( 0 );
    }

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.RecordsPRI.RecordsQuery = RankingsCombo.GetText();
    CRI.RecordsPRI.QueryNextRecordRanks( bReset );
	// Log("Querying next ranks" @ bIsQuerying @ bReset @ CRI.RecordsPRI.RecordsQuery );
}

protected function InternalOnChangeSource( GUIComponent sender )
{
    local BTClient_ClientReplication CRI;
    local string source, query;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( CRI.RecordsPRI == none ) // We haven't received ReplicationReady yet!
        return;

    // Map/Player
    source = SourceCombo.GetText();
    query = RankingsCombo.GetText();
    if( source == CRI.RecordsPRI.RecordsSource )
        return;

    CRI.RecordsPRI.RecordsSource = source;
    switch( source )
    {
        case "map":
            RankingsCombo.SetText( Eval( _LastQuery == "", string(CRI.RecordsPRI.RecordsSourceId), _LastQuery ) );
            RankingsListBox.List.SortColumn = 3; // Time
            RankingsListBox.List.ColumnHeadings[2] = "Map";
            break;

        case "player":
            RankingsCombo.SetText( Eval( _LastQuery == "", CRI.PlayerId, _LastQuery ) );
            RankingsListBox.List.SortColumn = 1; // Rating
            RankingsListBox.List.ColumnHeadings[2] = "Player";
            break;
    }

    _LastQuery = query;
    // Can be PlayerId or PlayerName
    RankingsCombo.OnChange( self ); // ??? wtf stopped working by itself!
}

protected function InternalOnChangeRankingsCategory( GUIComponent sender )
{
	local BTClient_ClientReplication CRI;
	local BTGUI_RecordRankingsMultiColumnList list;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    // Log("InternalOnChangeRankingsCategory" @ bIsQuerying @ CRI.RecordsPRI.RecordsQuery @ RankingsCombo.GetText() );

    bIsQuerying = false; // renable querying

    // TODO:
	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	// list.Ranks = CRI.RecordsPRI.RecordRanks;
	list.Clear();

	CRI.RecordsPRI.RecordRanks.Length = 0;
    QueryNextRecordRanks( true );
}

protected function InternalOnRecordRankReceived( int index, BTGUI_RecordRankingsReplicationInfo source )
{
	local BTGUI_RecordRankingsMultiColumnList list;

	// Log("Received a rank packet");
	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	list.AddedItem();
}

protected function InternalOnRecordRankUpdated( int index, BTGUI_RecordRankingsReplicationInfo source, optional bool bRemoved )
{
    if( bRemoved )
    {
        RankingsListBox.List.RemovedItem( index );
    }
    else
    {
        RankingsListBox.List.UpdatedItem( index );
    }
}

protected function InternalOnRecordRanksDone( BTGUI_RecordRankingsReplicationInfo source, bool bAll )
{
	local BTClient_ClientReplication CRI;

    bIsQuerying = bAll; // Don't ever query again if we have received all there is to be received!
    SourceCombo.EnableMe();
    RankingsCombo.EnableMe();

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
	// Log("Query completed!" @ CRI.RecordsPRI.RecordsQuery @ CRI.RecordsPRI.RecordsSourceId @ CRI.RecordsPRI.RecordsSource);
    if( RankingsCombo.GetText() != CRI.RecordsPRI.RecordsQuery )
    {
    	RankingsCombo.OnChange = none;
		RankingsCombo.SetText( CRI.RecordsPRI.RecordsQuery );
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

protected function InternalOnRecordRanksCleared( BTGUI_RecordRankingsReplicationInfo source )
{
	local BTGUI_RecordRankingsMultiColumnList list;

	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	list.Clear();
    QueryNextRecordRanks( true );
}

protected function InternalOnScroll( int newPos )
{
    if( newPos > RankingsListBox.MyScrollBar.ItemCount-15 )
    {
        QueryNextRecordRanks();
    }
}

protected function InternalOnContext( GUIContextMenu sender, int clickIndex )
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

protected function bool InternalOnSelected( GUIComponent sender )
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
    OnQueryPlayerRecord( GetItemMapId( itemIndex ), CRI.RecordsPRI.RecordRanks[itemIndex].PlayerId );
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
    local string playerId, mapId;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    playerId = string(CRI.RecordsPRI.RecordRanks[itemIndex].PlayerId);
    mapId = GetItemMapId( itemIndex );
    PlayerOwner().ConsoleCommand( "BT ErasePlayerRecord" @ playerId @ mapId );
}

final function string GetItemMapId( int itemIndex )
{
    local BTClient_ClientReplication CRI;
    local string mapId;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    switch( CRI.RecordsPRI.RecordsSource )
    {
        case "map":
            mapId = string(CRI.RecordsPRI.RecordsSourceId);
            break;

        case "player":
            // Delete by map name matching instead, FIXME: Replicate a safe mapId per record?
            mapId = CRI.RecordsPRI.RecordRanks[itemIndex].Name;
            break;
    }
    return mapId;
}

defaultproperties
{
    Begin Object class=BTGUI_ComboBox Name=oSourceCombo
        WinWidth=0.15
        WinHeight=0.05
        WinLeft=0.0
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
        bReadOnly=true
        OnChange=InternalOnChangeSource
    End Object
    SourceCombo=oSourceCombo

    Begin Object class=BTGUI_ComboBox Name=RanksComboBox
        WinWidth=0.84
        WinHeight=0.05
        WinLeft=0.16
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