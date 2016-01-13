class BTClient_MapVoteMultiColumnList extends MapVoteMultiColumnList;

var private string _CurrentFilter;

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent(MyController,MyOwner);
    Style = Controller.GetStyle("BTMultiColumnList", FontScale);
}

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
                    mapRating = Right( "0"$prop[1], 5 );
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
        mapRating = "00.00";
    }
    return mapName;
}

// Ugly copy from parent, to add additional column rendering style.
function DrawItem(Canvas C, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
    local float CellLeft, CellWidth;
    local eMenuState MState;
    local GUIStyles DrawStyle;
    local string mapTxt, timeTxt, recordsCountTxt, mapRatingTxt;

	if( VRI == none )
		return;

    mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, timeTxt, recordsCountTxt, mapRatingTxt);
    Y += 2;
    H -= 4;
    X += 4;
    W -= 8;

    C.Style = 1;
    C.SetPos( X, Y );
    if( bSelected )
    {
        C.DrawColor = #0x222222BB;
    }
    else
    {
        C.DrawColor = #0x22222244;
    }
    C.DrawTile( Texture'BTScoreBoardBG', W, H, 0, 0, 256, 256 );

    // Draw the selection border
    DrawStyle = Style;

    if( !VRI.MapList[MapVoteData[SortData[i].SortItem]].bEnabled )
        MState = MSAT_Disabled;
    else
        MState = MenuState;

    GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.DrawText( C, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
        mapRatingTxt, FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    C.DrawColor = #0xFFFFFFFF;
    DrawStyle.DrawText( C, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		mapTxt, FontScale );

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.DrawText( C, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		timeTxt, FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.DrawText( C, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(float(VRI.MapList[MapVoteData[SortData[i].SortItem]].PlayCount)/100F), FontScale );

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.DrawText( C, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(VRI.MapList[MapVoteData[SortData[i].SortItem]].Sequence), FontScale );

    GetCellLeftWidth( 5, CellLeft, CellWidth );
    DrawStyle.DrawText( C, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
        recordsCountTxt, FontScale );
}

function string GetSortString( int i )
{
	local string ColumnData[5];
	local string mapTxt, timeTxt, recordsCountTxt, mapRatingTxt;

	mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[i]].MapName, timeTxt, recordsCountTxt, mapRatingTxt);

	ColumnData[0] = right("000000" $ mapRatingTxt,6);
    ColumnData[1] = left(Caps(mapTxt),20);
    ColumnData[2] = timeTxt;
    ColumnData[3] = string(float(VRI.MapList[MapVoteData[i]].PlayCount)/100F);
    ColumnData[4] = right("000000" $ VRI.MapList[MapVoteData[i]].Sequence,6);
    ColumnData[5] = right("000000" $ recordsCountTxt,6);

	return ColumnData[SortColumn] $ ColumnData[PrevSortColumn];
}

delegate OnFilterVotingList( GUIComponent sender, string filter, int gameTypeIndex );

function InternalOnFilterVotingList( GUIComponent sender, string filter, int gameTypeIndex )
{
    _CurrentFilter = filter;
    Clear();
    LoadList( VRI, gameTypeIndex );
}

// Copy from parent, to add filtering of map names.
function LoadList(VotingReplicationInfo LoadVRI, int GameTypeIndex)
{
    local int m,l;

    VRI = LoadVRI;
    for( m=0; m<VRI.MapList.Length; m++)
    {
        if( IsFiltered( LoadVRI, GameTypeIndex, ParseMapName(VRI.MapList[m].MapName) ) )
            continue;

        l = MapVoteData.Length;
        MapVoteData.Insert(l,1);
        MapVoteData[l] = m;
        AddedItem();
    }
    OnDrawItem  = DrawItem;
}

function bool IsFiltered( VotingReplicationInfo LoadVRI, int GameTypeIndex, string mapName )
{
    local array<string> PrefixList;
    local string filter;
    local int p;

    mapName = Locs(mapName);
    filter = Locs(_CurrentFilter);
    if( filter != "" && !MatchesFilter(mapName, filter, true) )
        return true;

    Split(Locs(VRI.GameConfig[GameTypeIndex].Prefix), ",", PrefixList);
    for( p=0; p<PreFixList.Length; p++)
    {
        if( MatchesFilter(mapname, PreFixList[p]) )
        {
            return false;
        }
    }
    return true;
}

private function bool MatchesFilter( string test, string filter, optional bool bNoPrefix )
{
    local string f, t, v, k;
    local int i;

    // e.g. prefix: STR-*\d, mapname: STR-TechChallenge-01
    // becomes
    //  prefix: STR-*01
    f = filter;
    t = test;
    if( f == "*" && Left(t, 1) == f )
    {
        return true;
    }

    i = InStr(f, "##");
    if( i != -1 )
    {
        if( int(Right(t, 2)) == 0 )
            return false;

        f = Repl(f, "##", Right(t, 2));
    }

    i = InStr(f, "*");
    if( i == 0 )
    {
        v = Mid(f, i+1);
        if( Right( t, Len(v) ) == v )
            return true;
    }
    else if( i != -1 )
    {
        // f:"STR-*-D"
        // v="STR-"
        v = Left(f, i);
        // k="-D"
        k = Mid(f, i+1);
        if( Left(t, Len(v)) == v && Right(t, Len(k)) == k )
            return true;
    }

    if( (bNoPrefix || InStr(f, "~") == 0) && InStr(t, Mid(f, 1)) != -1 )
    {
        return true;
    }

    if( !bNoPrefix && Left(t, Len(f)) == f )
    {
        return true;
    }
    return false;
}

defaultproperties
{
	ColumnHeadings(0)="Rating"
    ColumnHeadings(1)="Map Name"
    ColumnHeadings(2)="Time"
    ColumnHeadings(3)="Played Hours"
    ColumnHeadings(4)="Seq"
    ColumnHeadings(5)="Records"

    InitColumnPerc(0)=0.2
    InitColumnPerc(1)=0.4
    InitColumnPerc(2)=0.1
    InitColumnPerc(3)=0.1
    InitColumnPerc(4)=0.1
    InitColumnPerc(5)=0.1

    ColumnHeadingHints(0)="Players rating of this map."
	ColumnHeadingHints(1)="Map Name."
    ColumnHeadingHints(2)="Best time record on this map."
	ColumnHeadingHints(3)="Number of hours this map has been played for."
	ColumnHeadingHints(4)="Sequence, The number of games that have been played since this map was last played."
    ColumnHeadingHints(5)="Number of records this map has."

    OnFilterVotingList=InternalOnFilterVotingList

    StyleName="BTMultiColumnList"
}