class BTGUI_RecordRankingsMultiColumnListBox extends GUIMultiColumnListBox;

var() const localized string EraseRecordName;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(class'BTGUI_RecordRankingsMultiColumnList');
    super.InitComponent( MyController, MyOwner );
}

function bool InternalOnOpen( GUIContextMenu Sender )
{
    if( PlayerOwner().PlayerReplicationInfo.bAdmin || PlayerOwner().Level.NetMode == NM_Standalone )
    {
        ContextMenu.AddItem( EraseRecordName );
    }
    return true;
}

function bool InternalOnClose( GUIContextMenu Sender )
{
    ContextMenu.RemoveItemByName( EraseRecordName );
    return true;
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
    EraseRecordName="Erase Record"

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

    Begin Object Class=GUIContextMenu Name=oContextMenu
        ContextItems(0)="View Record Details"
        ContextItems(1)="View Player Details"
        OnOpen=InternalOnOpen
        OnClose=InternalOnClose
        StyleName="BTContextMenu"
        SelectionStyleName="BTListSelection"
    End Object
    ContextMenu=oContextMenu
}