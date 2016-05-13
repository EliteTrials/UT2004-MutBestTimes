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
    super.InitComponent( MyController, MyOwner );
    Style = Controller.GetStyle( "BTMultiColumnList", FontScale );
}

function float InternalGetItemHeight( Canvas C )
{
    local float xl, yl;

    Style.TextSize( C, MenuState, "T", xl, yl, FontScale );
    return yl + 8;
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
final static function string ParseMapNameData(string mapName, out string timeString, out string recordsCount, out string mapRating, out string recordHolder)
{
    local int i;
	local string data;
    local array<string> props, prop;

    i = InStr(mapName, "$$");
    if( i != -1 )
    {
        data = Mid(mapName, i + 2);
        mapName = Left(mapName, i);
        Split(data, " ", props);
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

                case "P":
                    recordHolder = prop[1];
                    break;
            }
        }
    }
    return mapName;
}

// Ugly copy from parent, to add additional column rendering style.
function DrawItem(Canvas C, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;
    local string mapTxt, timeTxt, recordsCountTxt, mapRatingTxt, holderTxt;

	if( VRI == none )
		return;

    mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[SortData[i].SortItem]].MapName, timeTxt, recordsCountTxt, mapRatingTxt, holderTxt);
    Y += 2;
    H -= 2;

    C.Style = 1;
    C.SetPos( X, Y );
    if( bSelected )
    {
        C.DrawColor = #0x33333394;
    }
    else
    {
        C.DrawColor = #0x22222282;
    }
    C.DrawTile( Texture'BTScoreBoardBG', W, H, 0, 0, 256, 256 );

    // Draw the selection border
    DrawStyle = Style;

    if( !VRI.MapList[MapVoteData[SortData[i].SortItem]].bEnabled )
        MenuState = MSAT_Disabled;
    else
        MenuState = MSAT_Blurry;

    C.DrawColor = #0xFFFFFFFF;
    GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 0 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(int(float(VRI.MapList[MapVoteData[SortData[i].SortItem]].PlayCount)/100F))$"h", FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 1 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        mapTxt, FontScale );

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 2 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        recordsCountTxt, FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 3 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        timeTxt, FontScale );

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 4 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        holderTxt, FontScale );

    GetCellLeftWidth( 5, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 5 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        mapRatingTxt, FontScale );

    GetCellLeftWidth( 6, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 6 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Right,
        string(VRI.MapList[MapVoteData[SortData[i].SortItem]].Sequence), FontScale );

    DrawStyle.FontColors[0] = DrawStyle.default.FontColors[0];
}

function Color GetColumnColor( int column )
{
    switch( column )
    {
        case 0:
            return #0x666666FF;

        case 1:
            return #0xFFFFFFFF;

        case 2:
            return #0x666666FF;

        case 3:
            return #0xCCCCAAFF;

        case 4:
            return #0xFFFFFFFF;

        case 5:
            return #0x666666FF;

        case 6:
            return #0x666666FF;
    }
    return #0xFFFFFFFF;
}

static function string MyPadLeft( string Src, byte StrLen, optional string PadStr )
{
    if ( PadStr == "" )
        PadStr = " ";

    while ( Len(Src) < StrLen )
        Src = PadStr $ Src;

    return src;
}

function string GetSortString( int i )
{
	local string mapTxt, timeTxt, recordsCountTxt, mapRatingTxt, holderTxt;

	mapTxt = ParseMapNameData(VRI.MapList[MapVoteData[i]].MapName, timeTxt, recordsCountTxt, mapRatingTxt, holderTxt);
    switch( SortColumn )
    {
        // MapRating
        case 5:
            return MyPadLeft(mapRatingTxt, 5, "0");

        case 1:
            return left(Caps(mapTxt),20);

        case 3:
            return timeTxt;

        case 4:
            return Caps(class'GUIComponent'.static.StripColorCodes(holderTxt));

        case 0:
            return MyPadLeft(string(float(VRI.MapList[MapVoteData[i]].PlayCount)/100F), 8, "0");

        case 2:
            return MyPadLeft(recordsCountTxt, 4, "0");

        case 6:
            return MyPadLeft(string(VRI.MapList[MapVoteData[i]].Sequence), 8, "0");
    }

    return MyPadLeft(string(i), 4, "0");
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
    local bool hasMatch;

    mapName = Locs(mapName);
    Split(Locs(VRI.GameConfig[GameTypeIndex].Prefix), ",", PrefixList);
    for( p=0; p<PreFixList.Length; p++)
    {
        if( MatchesFilter(mapname, PreFixList[p]) )
        {
            hasMatch = true;
            break;
        }
    }

    filter = Locs(_CurrentFilter);
    if( filter != "" )
    {
        hasMatch = MatchesFilter(mapName, filter, false);
        if( !hasMatch )
        {
            hasMatch = MatchesFilter(mapName, filter, true);
        }
    }

    return !hasMatch;
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
    if( f == "*" )
    {
        return Left(t, 1) == f;
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
    StyleName="BTMultiColumnList"
    SelectedStyleName="BTListSelection"
    SelectedBKColor=(R=255,G=255,B=255,A=255)

    InitColumnPerc(0)=0.06
    InitColumnPerc(1)=0.36
    InitColumnPerc(2)=0.08
    InitColumnPerc(3)=0.11
    InitColumnPerc(4)=0.21
    InitColumnPerc(5)=0.08
    InitColumnPerc(6)=0.10

    ColumnHeadings(0)="Hours"
    ColumnHeadings(1)="Map Name"
    ColumnHeadings(2)="Records"
    ColumnHeadings(3)="Time"
    ColumnHeadings(4)="Set By"
	ColumnHeadings(5)="Thumbs"
    ColumnHeadings(6)="Seq"

	ColumnHeadingHints(0)="Number of hours this map has been played for."
    ColumnHeadingHints(1)="Map Name."
    ColumnHeadingHints(2)="Number of records this map has."
    ColumnHeadingHints(3)="Best time record on this map."
    ColumnHeadingHints(4)="Best time set by."
    ColumnHeadingHints(5)="Players rating of this map."
    ColumnHeadingHints(6)="Sequence, The number of games that have been played since this map was last played."

    OnFilterVotingList=InternalOnFilterVotingList
    GetItemHeight=InternalGetItemHeight
}