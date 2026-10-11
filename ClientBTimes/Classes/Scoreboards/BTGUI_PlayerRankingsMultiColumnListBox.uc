class BTGUI_PlayerRankingsMultiColumnListBox extends GUIMultiColumnListBox;

var BTGUI_PlayerRankingsMultiColumnList RankingLists[3];

event Free()
{
    super.Free();
    RankingLists[0] = none;
    RankingLists[1] = none;
    RankingLists[2] = none;
}

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(class'BTGUI_PlayerRankingsMultiColumnList');
    super.InitComponent( MyController, MyOwner );

    // Skip first list
    RankingLists[0] = BTGUI_PlayerRankingsMultiColumnList(List);
}

final function SwitchRankings( byte newRanksId, BTGUI_PlayerRankingsReplicationInfo source )
{
    List.Hide();
    if( RankingLists[newRanksId] == none )
    {
        RankingLists[newRanksId] = BTGUI_PlayerRankingsMultiColumnList(AddComponent(DefaultListClass));
    }
    else
    {
        AppendComponent( RankingLists[newRanksId] );
    }
    RankingLists[newRanksId].RanksId = newRanksId;
    RankingLists[newRanksId].Rankings = source;

    RemoveComponent( List );
    InitBaseList( RankingLists[newRanksId] );
}

defaultproperties
{
    DefaultListClass="" // Manually initialized in InitComponent.
    ColumnHeadings(0)="#"
    ColumnHeadings(1)="Player"
    ColumnHeadings(2)="ELO"
    ColumnHeadings(3)="Recs"
    ColumnHeadings(4)="Stars"
    ColumnHeadings(5)="AP"
    bDisplayHeader=true

    Begin Object Class=BTClient_MultiColumnListHeader Name=MyHeader
        HeadingIcons(0)=none
        HeadingIcons(1)=none
        HeadingIcons(2)=none
        HeadingIcons(3)=none
        HeadingIcons(4)=ColorModifier'Star'
        HeadingIcons(5)=none
    End Object
    Header=MyHeader

    Begin Object Class=GUIVertScrollBar Name=TheScrollbar
        bVisible=false
    End Object
    MyScrollBar=TheScrollbar

    Begin Object Class=GUIContextMenu Name=oContextMenu
        ContextItems(0)="View Player Details"
        // OnOpen=InternalOnOpen
        // OnClose=InternalOnClose
        StyleName="BTContextMenu"
        SelectionStyleName="BTListSelection"
    End Object
    ContextMenu=oContextMenu
}