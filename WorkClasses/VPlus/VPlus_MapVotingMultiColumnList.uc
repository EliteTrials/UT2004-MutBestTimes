/**
 * A list of maps the user can select and sort.
 *
 * Copyright 2010 Eliot Van Uytfanghe. All Rights Reserved.
 */
class VPlus_MapVotingMultiColumnList extends VPlus_VotingMultiColumnList;

function DrawItem( Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local float CellLeft, CellWidth;
    local eMenuState MState;
    local GUIStyles DrawStyle;

	if( VRI == none )
		return;

   	// Only draw maps that meet the filter condition!.
	if( Left( VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, Len( VPanel.GetFilter() ) ) ~= VPanel.GetFilter() )
	{
	    // Draw the selection border
	    if( bSelected )
	    {
	        SelectedStyle.Draw( Canvas,MenuState, X, Y-2, W, H+2 );
	        DrawStyle = SelectedStyle;
	    }
	    else DrawStyle = Style;

	    if( !VRI.MapList[MapVoteData[SortData[i].SortItem]].bEnabled )
	    	MState = MSAT_Disabled;
	    else MState = MenuState;

	    GetCellLeftWidth( 0, CellLeft, CellWidth );
	    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
			VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, FontScale );

	    GetCellLeftWidth( 1, CellLeft, CellWidth );
	    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
			VRI.MapList[MapVoteData[SortData[i].SortItem]].PlayCount, FontScale );

	    GetCellLeftWidth( 2, CellLeft, CellWidth );
	    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
			VRI.MapList[MapVoteData[SortData[i].SortItem]].Sequence, FontScale );
	}
}

defaultproperties
{
    ColumnHeadings(0)="Map Name"
	ColumnHeadings(1)="Played"
	ColumnHeadings(2)="Seq"

    InitColumnPerc(0)=0.6
    InitColumnPerc(1)=0.2
    InitColumnPerc(2)=0.2

	ColumnHeadingHints(0)="Map Name"
	ColumnHeadingHints(1)="Number of times the map has been played."
	ColumnHeadingHints(2)="Sequence, The number of games that have been played since this map was last played."
}
