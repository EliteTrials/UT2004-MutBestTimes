class BTGUI_RecordRankingsScoreboard extends BTGUI_RankingsBase;

// Player's records or records from a map.
var private automated BTGUI_ComboBox SourceCombo;

var private BTGUI_ComboBox RankingsCombo;
var private automated BTGUI_ComboBox MapsQueryCombo;
var private automated BTGUI_ComboBox PlayersQueryCombo;

var private automated BTGUI_RecordRankingsMultiColumnListBox RankingsListBox;
var private automated BTGUI_Footer Footer;
var private bool bWaitingForReplication;

delegate OnQueryPlayerRecord( coerce string mapId, coerce string playerId );

event Free()
{
    super.Free();
    RankingsCombo = none;
}

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
	RankingsListBox.MyScrollBar.PositionChanged = InternalOnScroll;
    RankingsListBox.ContextMenu.OnSelect = InternalOnContext;
    RankingsListBox.List.OnDblClick = InternalOnSelected;

    SourceCombo.OnChange = none;
    SourceCombo.AddItem( "Map" );
    SourceCombo.AddItem( "Player" );
    SourceCombo.OnChange = InternalOnChangeSource;
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

function ShowPanel(bool bShow)
{
    super.ShowPanel(bShow);

    PlayersQueryCombo.SetVisibility( false );
    MapsQueryCombo.SetVisibility( false );
    if( RankingsCombo != none )
    {
        RankingsCombo.SetVisibility( true );
    }
}

private function RequestReplicationChannels()
{
    local BTClient_ClientReplication CRI;

    SourceCombo.DisableMe();

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

    Log( "rep ready with"
        @ "server query:" @ recordsPRI.RecordsQuery
        @ "source:" @ recordsPRI.RecordsSource
    );
    SourceCombo.EnableMe();
    SourceCombo.SetText( recordsPRI.RecordsSource ); // not triggering OnChange???
    // HACK: OnChange is not triggered by SetText because "Levels" is not added as an item.
    if( recordsPRI.RecordsSource ~= "Levels" )
    {
        SourceCombo.OnChange( SourceCombo );
    }
    bWaitingForReplication = false;
    CacheLevels();
}

private function CacheLevels()
{
    local BTClient_ClientReplication CRI;
    local BTClient_LevelReplication myLevel;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    MapsQueryCombo.OnChange = none;
    for( myLevel = CRI.MRI.BaseLevel; myLevel != none; myLevel = myLevel.NextLevel )
    {
        if( myLevel.GetLevelName() == "" )
        {
            Warn( "Tried to cache a level with an unitialized LevelName" @ myLevel.GetFullName( string(CRI.Outer.Name) ) );
            continue;
        }

        MapsQueryCombo.AddItem( myLevel.GetFullName( string(CRI.Level.Outer.Name) ),, "map" );
    }
    MapsQueryCombo.OnChange = InternalOnChangeQuery;
}

private function QueryNextRecordRanks( optional bool bReset )
{
	local BTClient_ClientReplication CRI;

    if( bIsQuerying )
    	return;

    bIsQuerying = true;
    RankingsCombo.DisableMe();
    SourceCombo.DisableMe();

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( bReset )
    {
        RankingsListBox.List.SetIndex( 0 );
    }

    if( bReset )
    {
        CRI.RecordsPRI.RecordsQuery = RankingsCombo.GetText();
    }
    CRI.RecordsPRI.QueryNextRecordRanks( bReset );
	Log("Querying next ranks"
        @ "is querying:" @ bIsQuerying
        @ "is reset:" @ bReset
        @ "server query:" @ CRI.RecordsPRI.RecordsQuery
    );
    Footer.SetText( "Querying..." );
}

protected function InternalOnChangeSource( GUIComponent sender )
{
    local BTClient_ClientReplication CRI;
    local string source;

    Log("Source changed by" @ sender);
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( RankingsCombo != none )
    {
        RankingsCombo.SetVisibility( false );
    }
    source = SourceCombo.GetText();
    // Net hack
    if( CRI.RecordsPRI.RecordsSource == "Levels" && source == "Map" )
    {
        source = "Levels";
    }
    SwitchSourceType( source );
    CRI.RecordsPRI.RecordsSource = source;
    RankingsCombo.SetVisibility( true );
    if( RankingsCombo.GetText() == "" )
    {
        if( RankingsCombo == MapsQueryCombo )
        {
            RankingsCombo.SetText( CRI.RecordsPRI.RecordsQuery );
        }
        else if( RankingsCombo == PlayersQueryCombo )
        {
            RankingsCombo.SetText( string(CRI.PlayerId) );
        }
    }
    RankingsCombo.OnChange( sender );
}

private function SwitchSourceType( string source )
{
    RankingsListBox.List.ColumnHeadings = class'BTGUI_RecordRankingsMultiColumnListBox'.default.ColumnHeadings;
    switch( Locs(source) )
    {
        case "map":
            RankingsCombo = MapsQueryCombo;
            RankingsListBox.List.SortColumn = 3; // Time
            RankingsListBox.List.SortDescending = false;
            RankingsListBox.List.ColumnHeadings[2] = "Player";
            break;

        case "player":
            RankingsCombo = PlayersQueryCombo;
            RankingsListBox.List.SortColumn = 1; // Rating
            RankingsListBox.List.SortDescending = false;
            RankingsListBox.List.ColumnHeadings[2] = "Map";
            break;

        case "levels":
            RankingsCombo = MapsQueryCombo;
            RankingsListBox.List.SortColumn = 0; // #MapId
            RankingsListBox.List.SortDescending = false;
            RankingsListBox.List.ColumnHeadings[1] = "Skill";
            RankingsListBox.List.ColumnHeadings[2] = "Map";
            RankingsListBox.List.ColumnHeadings[3] = "Average Time";
            break;
    }
}

protected function InternalOnChangeQuery( GUIComponent sender )
{
	local BTClient_ClientReplication CRI;
	local BTGUI_RecordRankingsMultiColumnList list;

    Log("Query changed by" @ sender);
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    Log("InternalOnChangeQuery"
        @ "is querying:" @ bIsQuerying
        @ "server query:" @ CRI.RecordsPRI.RecordsQuery
        @ "combo query:" @ RankingsCombo.GetText()
    );
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
    bIsQuerying = bAll; // Don't ever query again if we have received all there is to be received!
    SourceCombo.EnableMe();
    RankingsCombo.EnableMe();

	Log("Query completed!"
        @ "server query:" @ source.RecordsQuery
        @ "source id:" @ source.RecordsSourceId
        @ "source:" @ source.RecordsSource
    );
    SwitchSourceType( source.RecordsSource );
    // Cache this resolved name
    RankingsCombo.OnChange = none;
    // Prevent infinite recursion.
    if( RankingsCombo.FindIndex( source.RecordsQuery ) == -1 )
    {
        RankingsCombo.AddItem( source.RecordsQuery );
    }
    RankingsCombo.SetText( source.RecordsQuery );
    RankingsCombo.OnChange = InternalOnChangeQuery;

	if( !bIsQuerying && !RankingsListBox.MyScrollBar.bVisible )
	{
		QueryNextRecordRanks();
	}
    else
    {
        // If our end user is sorting by other means than Rank, then we should make sure the newly added data gets sorted straight away!
        RankingsListBox.List.NeedsSorting = true;
    }

    if( bAll && source.RecordRanks.Length == 0 )
    {
        Footer.SetText( "No items found for this query!" );
    }
    else
    {
        Footer.SetText( "Query completed!" );
    }
}

protected function InternalOnRecordRanksCleared( BTGUI_RecordRankingsReplicationInfo source )
{
	local BTGUI_RecordRankingsMultiColumnList list;

    list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
    list.Clear();
    Log("Currently queried records cleared!");
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
    local BTClient_ClientReplication CRI;
    local int itemIndex;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    itemIndex = RankingsListBox.List.CurrentListId();
    // Hacky... switch query to level instead of viewing the record owners data.
    if( CRI.RecordsPRI.RecordsSource == "Levels" )
    {
        RankingsCombo.SetText( string(CRI.RecordsPRI.RecordRanks[itemIndex].RankId) );
        RankingsCombo.OnChange( sender ); // this is strange!
        return false;
    }
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

    Begin Object class=BTGUI_ComboBox Name=oMapsComboBox
        WinWidth=0.84
        WinHeight=0.05
        WinLeft=0.16
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        bVisible=false
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
        OnChange=InternalOnChangeQuery
    End Object
    MapsQueryCombo=oMapsComboBox

    Begin Object class=BTGUI_ComboBox Name=oPlayersComboBox
        WinWidth=0.84
        WinHeight=0.05
        WinLeft=0.16
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        bVisible=false
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
        OnChange=InternalOnChangeQuery
    End Object
    PlayersQueryCombo=oPlayersComboBox

    Begin Object Class=BTGUI_RecordRankingsMultiColumnListBox Name=ItemsListBox
        WinWidth=1.0
        WinHeight=0.855
        WinLeft=0.0
        WinTop=0.07
        bVisibleWhenEmpty=true
        bScaleToParent=True
        bBoundToParent=True
        FontScale=FNS_Small
    End Object
    RankingsListBox=ItemsListBox

    Begin Object Class=BTGUI_Footer Name=oFooter
        WinWidth=1.0
        WinHeight=0.05
        WinLeft=0.0
        WinTop=0.935
        bScaleToParent=True
        bBoundToParent=True
    End Object
    Footer=oFooter
}