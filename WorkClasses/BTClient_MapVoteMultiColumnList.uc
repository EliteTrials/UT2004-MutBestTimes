class BTClient_MapVoteMultiColumnList extends MapVoteMultiColumnList;

function string GetSelectedMapName()
{
	if( index == -1 )
	{
		return "";
	}
    return ParseMapName(VRI.MapList[MapVoteData[SortData[Index].SortItem]].MapName);
}

final static function string ParseMapName(string mapName)
{
	local int idx;

	idx = InStr(mapName, "$$");
    if( idx != -1 )
    {
    	return Left(mapName, idx);
    }
    return mapName;
}

// STR-MapName$$TIME;COUNT
final static function string ParseMapNameData(string mapName, out string timeString, out string recordsCount)
{
	local int idx, semiIdx;
	local string data;

	idx = InStr(mapName, "$$");
    if( idx != -1 )
    {
    	data = Mid(mapName, idx + 2);
    	semiIdx = InStr(data, ";");
    	if( semiIdx != -1 )
    	{
    		timeString = Left(data, semiIdx);
    		recordsCount = Mid(data, semiIdx + 1);
    	}
    	else
    	{
    		timeString = data;
    		recordsCount = "0";
    	}
    	return Left(mapName, idx);
    }
    timeString = "00:00:00.00";
    recordsCount = "0";
    return mapName;
}

// Ugly copy from parent, to add additional column rendering style.
function DrawItem(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
    local float CellLeft, CellWidth;
    local eMenuState MState;
    local GUIStyles DrawStyle;
    local string mapTxt, timeTxt, recordsCountTxt;

	if( VRI == none )
		return;

	// Draw the drag-n-drop outline
	if (bPending && OutlineStyle != None && (bDropSource || bDropTarget) )
	{
		if ( OutlineStyle.Images[MenuState] != None )
		{
			OutlineStyle.Draw(Canvas, MenuState, ClientBounds[0], Y, ClientBounds[2] - ClientBounds[0], ItemHeight);
			if (DropState == DRP_Source && i != DropIndex)
				OutlineStyle.Draw(Canvas, MenuState, Controller.MouseX - MouseOffset[0], Controller.MouseY - MouseOffset[1] + Y - ClientBounds[1], MouseOffset[2] + MouseOffset[0], ItemHeight);
		}
	}

    // Draw the selection border
    if( bSelected )
    {
        SelectedStyle.Draw(Canvas,MenuState, X, Y-2, W, H+2 );
        DrawStyle = SelectedStyle;
    }
    else
    	DrawStyle = Style;

    if( !VRI.MapList[MapVoteData[SortData[i].SortItem]].bEnabled )
    	MState = MSAT_Disabled;
    else
    	MState = MenuState;

    mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, timeTxt, recordsCountTxt);

    GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		mapTxt, FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		timeTxt, FontScale );    

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(float(VRI.MapList[MapVoteData[SortData[i].SortItem]].PlayCount)/100F), FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapList[MapVoteData[SortData[i].SortItem]].Sequence), FontScale );

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		recordsCountTxt, FontScale );
}

function string GetSortString( int i )
{
	local string ColumnData[5];
	local string mapTxt, timeTxt, recordsCountTxt;

	mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[i]].MapName, timeTxt, recordsCountTxt);

	ColumnData[0] = left(Caps(mapTxt),20);
	ColumnData[1] = right("000000" $ timeTxt,6);
	ColumnData[2] = right("000000" $ float(VRI.MapList[MapVoteData[i]].PlayCount)/100F,6);
	ColumnData[3] = right("000000" $ VRI.MapList[MapVoteData[i]].Sequence,6);
	ColumnData[4] = right("000000" $ recordsCountTxt,6);

	return ColumnData[SortColumn] $ ColumnData[PrevSortColumn];
}

defaultproperties
{
	ColumnHeadings(1)="Time"
	ColumnHeadings(2)="Played Hours"
	ColumnHeadings(3)="Seq"
	ColumnHeadings(4)="Records"

    InitColumnPerc(0)=0.40
    InitColumnPerc(1)=0.2
    InitColumnPerc(2)=0.2
    InitColumnPerc(3)=0.1
    InitColumnPerc(4)=0.1

	ColumnHeadingHints(1)="Best time record on this map."
	ColumnHeadingHints(2)="Number of hours this map has been played for."
	ColumnHeadingHints(3)="Sequence, The number of games that have been played since this map was last played."
	ColumnHeadingHints(4)="Number of records this map has."
}