class BTClient_MapVoteMultiColumnList extends MapVoteMultiColumnList;

var private int _LastGameTypeIndex;
var private string _CurrentFilter;

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
final static function string ParseMapNameData(string mapName, out string timeString, out string recordsCount, out string mapRating)
{
    local int i;
	local string data;
    local array<string> props, prop;

    i = InStr(mapName, "$$");
    if( i != -1 )
    {
        data = Mid(mapName, i + 2);
        mapName = Left(mapName, i);
        Split(data, ";", props);
        for( i = 0; i < props.Length; ++ i )
        {
            Split(props[i], ":", prop);
            switch( prop[0] )
            {
                case "T":
                    timeString = class'BTClient_Interaction'.static.FormatTime(float(prop[1]));
                    break;

                case "N":
                    recordsCount = prop[1];
                    break;

                case "R":
                    mapRating = prop[1];
                    break;
            }
        }
    }

    if( timeString == "" )
    {
        timeString = class'BTClient_Interaction'.static.FormatTime(0.00);
    }

    if( recordsCount == "" )
    {
        recordsCount = "0";
    }

    if( mapRating == "" )
    {
        mapRating = "0.00";
    }
    return mapName;
}

// Ugly copy from parent, to add additional column rendering style.
function DrawItem(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
    local float CellLeft, CellWidth;
    local eMenuState MState;
    local GUIStyles DrawStyle;
    local string mapTxt, timeTxt, recordsCountTxt, mapRatingTxt;

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

    mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, timeTxt, recordsCountTxt, mapRatingTxt);

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

    GetCellLeftWidth( 5, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		mapRatingTxt, FontScale );
}

function string GetSortString( int i )
{
	local string ColumnData[5];
	local string mapTxt, timeTxt, recordsCountTxt, mapRatingTxt;

	mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[i]].MapName, timeTxt, recordsCountTxt, mapRatingTxt);

	ColumnData[0] = left(Caps(mapTxt),20);
	ColumnData[1] = timeTxt;
	ColumnData[2] = string(float(VRI.MapList[MapVoteData[i]].PlayCount)/100F);
	ColumnData[3] = right("000000" $ VRI.MapList[MapVoteData[i]].Sequence,6);
    ColumnData[4] = right("000000" $ recordsCountTxt,6);
	ColumnData[5] = right("000000" $ mapRatingTxt,6);

	return ColumnData[SortColumn] $ ColumnData[PrevSortColumn];
}

delegate OnFilterVotingList( GUIComponent sender, string filter );

function InternalOnFilterVotingList( GUIComponent sender, string filter )
{
    _CurrentFilter = filter;
    Clear();
    LoadList( VRI, _LastGameTypeIndex );
}

// Copy from parent, to add filtering of map names.
function LoadList(VotingReplicationInfo LoadVRI, int GameTypeIndex)
{
    local int m,p,l;
    local array<string> PrefixList;
    local string filter;

    VRI = LoadVRI;

    Split(VRI.GameConfig[GameTypeIndex].Prefix, ",", PrefixList);
    filter = Locs(_CurrentFilter);
    for( m=0; m<VRI.MapList.Length; m++)
    {
        if( filter != "" && InStr(Locs(VRI.MapList[m].MapName), filter) == -1 )
            continue;

        for( p=0; p<PreFixList.Length; p++)
        {
            if( left(VRI.MapList[m].MapName, len(PrefixList[p])) ~= PrefixList[p] )
            {
                l = MapVoteData.Length;
                MapVoteData.Insert(l,1);
                MapVoteData[l] = m;
                AddedItem();
                break;
            }
        } //p
    } //m
    OnDrawItem  = DrawItem;

    _LastGameTypeIndex = GameTypeIndex;
}

defaultproperties
{
	ColumnHeadings(1)="Time"
	ColumnHeadings(2)="Played Hours"
	ColumnHeadings(3)="Seq"
    ColumnHeadings(4)="Records"
	ColumnHeadings(5)="Rating"

    InitColumnPerc(0)=0.40
    InitColumnPerc(1)=0.2
    InitColumnPerc(2)=0.1
    InitColumnPerc(3)=0.1
    InitColumnPerc(4)=0.1
    InitColumnPerc(5)=0.1

	ColumnHeadingHints(1)="Best time record on this map."
	ColumnHeadingHints(2)="Number of hours this map has been played for."
	ColumnHeadingHints(3)="Sequence, The number of games that have been played since this map was last played."
    ColumnHeadingHints(4)="Number of records this map has."
	ColumnHeadingHints(5)="Players rating of this map."

    OnFilterVotingList=InternalOnFilterVotingList
}