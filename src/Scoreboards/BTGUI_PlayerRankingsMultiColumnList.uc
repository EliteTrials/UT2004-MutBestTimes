class BTGUI_PlayerRankingsMultiColumnList extends GUIMultiColumnList;

var BTGUI_PlayerRankingsReplicationInfo Rankings;

// Which rankings replication actor this GUIList should represent.
var byte RanksId;

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

function float InternalGetItemHeight( Canvas C )
{
    local float xl, yl;

    C.StrLen( "T", xl, yl );
    return yl + 8;
}

function DrawItem(Canvas C, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;

    Y += 2;
    H -= 4;

    C.Style = 1;
    C.SetPos( X, Y );
    if( bSelected )
    {
        C.DrawColor = #0x33333386;
    }
    else
    {
        C.DrawColor = #0x22222266;
    }
    C.DrawTile( Texture'BTScoreBoardBG', W, H, 0, 0, 256, 256 );

    MenuState = MSAT_Blurry;
    DrawStyle = Style;
    GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = #0x666666FF;
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(SortData[i].SortItem + 1), FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = #0x91A79DFF;
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[SortData[i].SortItem].AP), FontScale );

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = #0xFFFFF0FF;
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(int(Rankings.PlayerRanks[SortData[i].SortItem].Points)), FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = #0xFFFFFFFF;
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        Rankings.PlayerRanks[SortData[i].SortItem].Name, FontScale );

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = #0xAAAAAAFF;
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[SortData[i].SortItem].Hijacks >> 16), FontScale );

    GetCellLeftWidth( 5, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = #0xAAAAAAFF;
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[SortData[i].SortItem].Hijacks & 0x0000FFFF), FontScale );

    DrawStyle.FontColors[0] = DrawStyle.default.FontColors[0];

    // C.DrawColor = Lighten( C.DrawColor, 50F );
}

static function string MyPadLeft( coerce string Src, byte StrLen, optional string PadStr )
{
    if ( PadStr == "" )
        PadStr = " ";

    while ( Len(Src) < StrLen )
        Src = PadStr $ Src;

    return src;
}

function string GetSortString( int i )
{
    switch( SortColumn )
    {
        case 0:
            return MyPadLeft( i, 4, "0" );

        case 1:
            return MyPadLeft( Rankings.PlayerRanks[i].AP, 4, "0" );

        case 2:
            return MyPadLeft( int(Rankings.PlayerRanks[i].Points), 4, "0" );

        case 3:
            return Rankings.PlayerRanks[i].Name;

        case 4:
            return MyPadLeft( Rankings.PlayerRanks[i].Hijacks >> 16, 4, "0" );

        case 5:
            return MyPadLeft( Rankings.PlayerRanks[i].Hijacks & 0x0000FFFF, 4, "0" );
    }
    return string(i);
}

defaultproperties
{
	StyleName="BTMultiColumnList"
    SelectedStyleName="BTListSelection"
    SelectedBKColor=(R=255,G=255,B=255,A=255)

    bSorted=true
    SortColumn=2
    SortDescending=false
    ExpandLastColumn=true
    InitColumnPerc(0)=0.06
    InitColumnPerc(1)=0.09
    InitColumnPerc(2)=0.09
    InitColumnPerc(3)=0.50
    InitColumnPerc(4)=0.12
    InitColumnPerc(5)=0.12

    OnDrawItem=DrawItem
    GetItemHeight=InternalGetItemHeight
}