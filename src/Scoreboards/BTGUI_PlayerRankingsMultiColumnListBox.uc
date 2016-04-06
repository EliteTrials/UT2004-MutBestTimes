class BTGUI_PlayerRankingsMultiColumnListBox extends GUIMultiColumnListBox;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(class'BTGUI_PlayerRankingsMultiColumnList');
    super.InitComponent(MyController,MyOwner);
}

function InternalOnScroll( int newPos )
{
    local BTGUI_PlayerRankingsReplicationInfo ranksRep;

    if( newPos > MyScrollBar.ItemCount-5 )
    {
        ranksRep = BTGUI_PlayerRankingsReplicationInfo(BTGUI_PlayerRankingsScoreboard(MenuOwner).GetBoardRep());
        ranksRep.QueryNextPlayerRanks();
    }
}

defaultproperties
{
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