class BTGUI_RecordRankingsMultiColumnListBox extends GUIMultiColumnListBox;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(class'BTGUI_RecordRankingsMultiColumnList');
    super.InitComponent( MyController, MyOwner );
}

// final function SwitchRankings( byte newRanksId, BTGUI_RecordRankingsReplicationInfo source )
// {
//     List.Hide();
//     if( RankingLists[newRanksId] == none )
//     {
//         RankingLists[newRanksId] = BTGUI_RecordRankingsMultiColumnList(AddComponent(DefaultListClass));
//     }
//     else
//     {
//         AppendComponent( RankingLists[newRanksId] );
//     }
//     RankingLists[newRanksId].RanksId = newRanksId;
//     RankingLists[newRanksId].Rankings = source;

//     RemoveComponent( List );
//     InitBaseList( RankingLists[newRanksId] );
// }

defaultproperties
{
    DefaultListClass="" // Manually initialized in InitComponent.
    ColumnHeadings(0)="#"
    ColumnHeadings(1)="Rating"
    ColumnHeadings(2)="Player"
    ColumnHeadings(3)="Time"
    ColumnHeadings(4)="Date"
    bDisplayHeader=true

    Begin Object Class=BTClient_MultiColumnListHeader Name=MyHeader
    End Object
    Header=MyHeader

    Begin Object Class=GUIVertScrollBar Name=TheScrollbar
        bVisible=false
    End Object
    MyScrollBar=TheScrollbar
}