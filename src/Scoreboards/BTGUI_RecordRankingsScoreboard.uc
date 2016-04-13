class BTGUI_RecordRankingsScoreboard extends BTGUI_RankingsBase;

var automated GUIComboBox RankingsCombo;
var automated BTGUI_RecordRankingsMultiColumnListBox RankingsListBox;

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
	RankingsListBox.MyScrollBar.PositionChanged = InternalOnScroll;
    RankingsCombo.Edit.bAlwaysNotify = true;
    // RankingsCombo.Edit.bReadOnly = true;
  	RankingsCombo.Edit.Style = Controller.GetStyle("BTEditBox", RankingsCombo.Edit.FontScale);
    RankingsCombo.MyShowListBtn.Style = Controller.GetStyle("BTButton", RankingsCombo.MyShowListBtn.FontScale);
    RankingsCombo.List.Style = Controller.GetStyle("BTMultiColumnList", RankingsCombo.List.FontScale);
    RankingsCombo.List.SelectedStyle = Controller.GetStyle("BTMultiColumnList", RankingsCombo.List.FontScale);
    RankingsCombo.AddItem( "STR-TechChallenge-01-A" );
    RankingsCombo.AddItem( "STR-TechChallenge-01-B" );
    RankingsCombo.AddItem( "STR-TechChallenge-02-B" );
    RankingsCombo.AddItem( "STR-TechChallenge-02-Com" );
    RankingsCombo.AddItem( "STR-TechChallenge-03-Part2" );
    RankingsCombo.AddItem( "STR-TechChallenge-03" );
    RankingsCombo.AddItem( "STR-TechChallenge-04-A" );
    RankingsCombo.AddItem( "STR-TechChallenge-05" );
    RankingsCombo.AddItem( "STR-TechChallenge-06-b00n-V2" );
    RankingsCombo.AddItem( "STR-TechChallenge-06-b00n" );
    RankingsCombo.AddItem( "STR-TechChallenge-06" );
    RankingsCombo.AddItem( "STR-TechChallenge-07" );
    RankingsCombo.AddItem( "STR-TechChallenge-08-Short" );
    RankingsCombo.AddItem( "STR-TechChallenge-08-Long" );
    RankingsCombo.AddItem( "STR-TechChallenge-09-Com" );
    RankingsCombo.AddItem( "STR-TechChallenge-10" );
    RankingsCombo.AddItem( "STR-TechChallenge-11" );
    RankingsCombo.AddItem( "STR-TechChallenge-12" );
    RankingsCombo.AddItem( "STR-TechChallenge-13-Com" );
    RankingsCombo.AddItem( "STR-TechChallenge-14" );
    RankingsCombo.AddItem( "STR-TechChallenge-15-A" );
    RankingsCombo.AddItem( "STR-TechChallenge-17" );
    RankingsCombo.SetText( string(Outer.Name), true );
    RankingsCombo.OnChange = InternalOnChangeRankingsCategory;
}

event ShowPanel( bool bShow )
{
	local BTClient_ClientReplication CRI;

	super.ShowPanel( bShow );
	if( !bShow )
		return;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    if( CRI.RecordsPRI == none )
    {
    	RequestReplicationChannels();
    }
}

function RequestReplicationChannels()
{
	local BTClient_ClientReplication CRI;

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.OnClientNotify = InternalOnClientNotify;
    CRI.ServerRequestRecordRanks( -1 ); // Initialize replication channels.
	PlayerOwner().ClientMessage("Requesting channel" @ RankingsCombo.GetText());
}

function QueryNextRecordRanks( optional bool bReset )
{
	local BTClient_ClientReplication CRI;

	// PlayerOwner().ClientMessage("Querying next ranks" @ bIsQuerying);
    if( bIsQuerying )
    	return;

    bIsQuerying = true;
    RankingsCombo.DisableMe();
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
    CRI.RecordsPRI.RecordsMapName = RankingsCombo.GetText();
    CRI.RecordsPRI.QueryNextRecordRanks( bReset );
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
	CRI.RecordsPRI.OnRecordRankReceived = InternalOnRecordRankReceived;
	CRI.RecordsPRI.OnRecordRanksDone = InternalOnRecordRanksDone;
	CRI.RecordsPRI.OnRecordRanksCleared = InternalOnRecordRanksCleared;

	// Note: Will trigger OnChangeRankingsCategory
	RankingsCombo.SetText( CRI.RecordsPRI.RecordsMapName );
}

function InternalOnChangeRankingsCategory( GUIComponent sender )
{
	local BTClient_ClientReplication CRI;
	local BTGUI_RecordRankingsMultiColumnList list;

	bIsQuerying = false; // renable querying
    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );

    // TODO:
	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	list.Ranks = CRI.RecordsPRI.RecordRanks;
	list.Clear();

	CRI.RecordsPRI.RecordRanks.Length = 0;
    QueryNextRecordRanks( true );
}

function InternalOnRecordRankReceived( int index, BTGUI_RecordRankingsReplicationInfo source )
{
	local BTGUI_RecordRankingsMultiColumnList list;

	// PlayerOwner().ClientMessage("Received a rank packet");
	list = BTGUI_RecordRankingsMultiColumnList(RankingsListBox.List);
	list.AddedItem();
}

function InternalOnRecordRanksDone( BTGUI_RecordRankingsReplicationInfo source, bool bAll )
{
	local BTClient_ClientReplication CRI;

	// PlayerOwner().ClientMessage("Query completed");
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

defaultproperties
{
    Begin Object class=GUIComboBox Name=RanksComboBox
        WinWidth=1.0
        WinHeight=0.045
        WinLeft=0.0
        WinTop=0.01
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        bIgnoreChangeWhenTyping=true
    End Object
    RankingsCombo=RanksComboBox

    Begin Object Class=BTGUI_RecordRankingsMultiColumnListBox Name=ItemsListBox
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