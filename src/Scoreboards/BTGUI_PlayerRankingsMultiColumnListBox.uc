class BTGUI_PlayerRankingsMultiColumnListBox extends GUIMultiColumnListBox;

var const array<string> RankingRanges, RankingRangeIds;
var array<BTGUI_PlayerRankingsMultiColumnList> RankingLists;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;

	DefaultListClass = string(class'BTGUI_PlayerRankingsMultiColumnList');
    super.InitComponent(MyController,MyOwner);

    // Skip first list
    RankingLists[RankingLists.Length] = BTGUI_PlayerRankingsMultiColumnList(List);
    for( i = 1; i < RankingRanges.Length; ++ i )
    {
        RankingLists[RankingLists.Length] = BTGUI_PlayerRankingsMultiColumnList(AddComponent(DefaultListClass));
        RankingLists[RankingLists.Length - 1].Hide();
    }

    QueryNextPlayerRanks();
}

function InternalOnScroll( int newPos )
{
    if( newPos > MyScrollBar.ItemCount-15 )
    {
        QueryNextPlayerRanks();
    }
}

function QueryNextPlayerRanks()
{
    local BTClient_ClientReplication CRI;

    CRI = class'BTClient_ClientReplication'.static.GetRep( PlayerOwner() );
    CRI.PRRI.QueryNextPlayerRanks();
}

defaultproperties
{
    RankingRangeIds(0)="All"
    RankingRangeIds(1)="Monthly"
    RankingRangeIds(2)="Daily"
    RankingRanges(0)="All Time"
    RankingRanges(1)="Monthly"
    RankingRanges(2)="Daily"

    DefaultListClass="" // Manually initialized in InitComponent.
    StyleName="NoBackground"

    ColumnHeadings(0)="#"
    ColumnHeadings(1)="AP"
    ColumnHeadings(2)="ELO"
    ColumnHeadings(3)="Player"
    ColumnHeadings(4)="Records"
    ColumnHeadings(5)="Hijacks"
    bDisplayHeader=true

    Begin Object Class=BTClient_MultiColumnListHeader Name=MyHeader
    End Object
    Header=MyHeader

    Begin Object Class=GUIVertScrollBar Name=TheScrollbar
        bVisible=false
        PositionChanged=InternalOnScroll
    End Object
    MyScrollBar=TheScrollbar
}