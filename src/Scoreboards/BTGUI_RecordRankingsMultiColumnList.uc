class BTGUI_RecordRankingsMultiColumnList extends GUIMultiColumnList;

var array<BTGUI_RecordRankingsReplicationInfo.sRecordRank> Ranks;

var transient BTClient_ClientReplication CRI;
var protected transient bool
    bItemIsSelected,
    bItemIsOwner,
    bItemIsClientSpawn;

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
    local float xl, yl;

    bItemIsSelected = bSelected;
    bItemIsOwner = CRI != none
        && CRI.RecordsPRI != none
        && CRI.RecordsPRI.RecordRanks[SortData[i].SortItem].PlayerId == CRI.PlayerId;

    Y += 2;
    H -= 2;

    C.Style = 1;
    C.SetPos( X, Y );
    if( bItemIsOwner )
    {
        C.DrawColor = #0x4E4E3382;
        if( bSelected )
        {
            C.DrawColor.A = 0x94;
        }
    }
    else if( bSelected )
    {
        C.DrawColor = #0x33333394;
    }
    else
    {
        C.DrawColor = #0x22222282;
    }

    C.DrawTile( Texture'BTScoreBoardBG', W, H, 0, 0, 256, 256 );

    if( CRI == none )
    {
        CRI = class'BTClient_ClientReplication'.static.GetRep( PlayerOwner() );
    }

    // Not yet replicated?
    if( CRI == none || CRI.RecordsPRI == none )
    {
        return;
    }

    bItemIsClientSpawn = (CRI.RecordsPRI.RecordRanks[SortData[i].SortItem].Flags & 0x01/**RFLAG_CP*/) != 0;

    MenuState = MSAT_Blurry;
    DrawStyle = Style;
    GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 0 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(SortData[i].SortItem + 1), FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 1 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(CRI.RecordsPRI.RecordRanks[SortData[i].SortItem].Points), FontScale );

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 2 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        CRI.RecordsPRI.RecordRanks[SortData[i].SortItem].Name, FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 3 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        class'BTClient_Interaction'.static.FormatTimeCompact( CRI.RecordsPRI.RecordRanks[SortData[i].SortItem].Time ), FontScale );

    if( bItemIsClientSpawn )
    {
        DrawStyle.TextSize( C, MenuState, "T", xl, yl, FontScale );

        xl = 54f/76f*yl;
        C.SetPos( CellLeft + (CellWidth - xl), Y );
        C.DrawColor = #0xFB607FFF;
        C.DrawTile( Texture'HudContent.Generic.Hud', xl, yl, 340, 130, 54, 76 );
    }

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 4 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        class'BTClient_Interaction'.static.CompactDateToString( CRI.RecordsPRI.RecordRanks[SortData[i].SortItem].Date ), FontScale );

    DrawStyle.FontColors[0] = DrawStyle.default.FontColors[0];
}

function Color GetColumnColor( int column )
{
    if( bItemIsOwner && (column != 3 || !bItemIsClientSpawn) )
    {
        return #0xFFFF00FF;
    }

    if( bItemIsSelected )
    {
        return #0xFFFFFFFF;
    }

    switch( column )
    {
        case 0:
            return #0x666666FF;

        case 1:
            return #0xCCCCC0FF;

        case 2:
            return #0xFFFFFFFF;

        case 3:
            if( bItemIsClientSpawn )
            {
                return #0xCB304FFF;
            }
            return #0xAAAAAAFF;

        case 4:
            return #0xAAAAAAFF;
    }
    return #0xFFFFFFFF;
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
    // Not yet replicated?
    if( CRI == none || CRI.RecordsPRI == none )
    {
        return string(i);
    }

    switch( SortColumn )
    {
        case 0:
            return MyPadLeft( i, 4, "0" );

        case 1:
            return MyPadLeft( int(CRI.RecordsPRI.RecordRanks[i].Points*100f), 4, "0" );

        case 2:
            return CRI.RecordsPRI.RecordRanks[i].Name;

        case 3:
            return class'BTClient_Interaction'.static.FormatTimeCompact( CRI.RecordsPRI.RecordRanks[i].Time );

        case 4:
            return MyPadLeft( CRI.RecordsPRI.RecordRanks[i].Date, 8, "0" );
    }
    return string(i);
}

defaultproperties
{
	StyleName="BTMultiColumnList"
    SelectedStyleName="BTListSelection"
    SelectedBKColor=(R=255,G=255,B=255,A=255)

    bSorted=true
    SortColumn=3
    SortDescending=false
    ExpandLastColumn=true
    InitColumnPerc(0)=0.065
    InitColumnPerc(1)=0.125
    InitColumnPerc(2)=0.435
    InitColumnPerc(3)=0.20
    InitColumnPerc(4)=0.165

    OnDrawItem=DrawItem
    GetItemHeight=InternalGetItemHeight
}