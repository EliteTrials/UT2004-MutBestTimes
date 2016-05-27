class BTGUI_PlayerRankingsMultiColumnList extends GUIMultiColumnList;

var BTGUI_PlayerRankingsReplicationInfo Rankings;

// Which rankings replication actor this GUIList should represent.
var byte RanksId;

var protected transient bool
    bItemIsSelected,
    bItemIsOwner;

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

function Free()
{
    super.Free();
    Rankings = none;
}

function float InternalGetItemHeight( Canvas C )
{
    local float xl, yl;

    Style.TextSize( C, MenuState, "T", xl, yl, FontScale );
    return yl + 8;
}

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    super.InitComponent( MyController, MyOwner );
    Style = Controller.GetStyle( "BTMultiColumnList", FontScale );
}

function DrawItem(Canvas C, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
    local int sortItem;
    local float xl, yl;
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;

    sortItem = SortData[i].SortItem;
    bItemIsSelected = bSelected;
    bItemIsOwner = Rankings.CRI != none
        && Rankings.PlayerRanks[sortItem].PlayerId == Rankings.CRI.PlayerId;

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

    MenuState = MSAT_Blurry;
    DrawStyle = Style;
    GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 0 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
		string(sortItem + 1), FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 1 );

    if( Rankings.PlayerRanks[sortItem].CountryCode != "" )
    {
        DrawStyle.TextSize( C, MenuState, "M", xl, yl, FontScale );
        yl = yl*0.8 - 2.0;
        xl = 10f/8f*yl;
        C.DrawColor = class'HUD'.default.WhiteColor;
        if( Rankings.PlayerRanks[sortItem].CountryFlag == none )
        {
            Rankings.PlayerRanks[sortItem].CountryFlag
                = Texture(DynamicLoadObject(
                    Class.Outer.Name$"."$Rankings.PlayerRanks[sortItem].CountryCode,
                    class'Texture',
                    true
                ));
        }
        if( Rankings.PlayerRanks[sortItem].CountryFlag != none )
        {
            C.SetPos( CellLeft, Y + H*0.5 - yl*0.5 );
            C.DrawTile( Rankings.PlayerRanks[sortItem].CountryFlag, xl, yl, 1, 0, 15, 10 );
        }
        else
        {
            DrawStyle.DrawText( C, MenuState, CellLeft, Y, 32, H, TXTA_Left,
                Rankings.PlayerRanks[sortItem].CountryCode, FontScale );
        }
        CellLeft += xl + 8;
        CellWidth -= xl + 8;
    }
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        Rankings.PlayerRanks[sortItem].Name, FontScale );

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 2 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[sortItem].Points), FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 3 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[sortItem].Hijacks >> 16), FontScale );

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 4 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[sortItem].Hijacks & 0x0000FFFF), FontScale );

    GetCellLeftWidth( 5, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 5 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        string(Rankings.PlayerRanks[sortItem].AP), FontScale );

    DrawStyle.FontColors[0] = DrawStyle.default.FontColors[0];

    // C.DrawColor = Lighten( C.DrawColor, 50F );
}

function Color GetColumnColor( int column )
{
    if( bItemIsSelected )
    {
        return #0xFFFFFFFF;
    }

    if( bItemIsOwner )
    {
        return #0xFFFF00FF;
    }

    switch( column )
    {
        case 0:
            return #0x666666FF;

        case 2:
            return #0xCCCCC0FF;

        case 1:
            return #0xFFFFFFFF;

        case 3:
            return #0xAAAAAAFF;

        case 4:
            return #0xAAAAAAFF;

        case 5:
            return #0x91A79DFF;
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
    switch( SortColumn )
    {
        case 0:
        case 2:
            return MyPadLeft( i, 4, "0" );

        case 1:
            return Rankings.PlayerRanks[i].Name;

        case 3:
            return MyPadLeft( Rankings.PlayerRanks[i].Hijacks >> 16, 4, "0" );

        case 4:
            return MyPadLeft( Rankings.PlayerRanks[i].Hijacks & 0x0000FFFF, 4, "0" );

        case 5:
            return MyPadLeft( Rankings.PlayerRanks[i].AP, 4, "0" );
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
    InitColumnPerc(0)=0.08
    InitColumnPerc(1)=0.445
    InitColumnPerc(2)=0.15
    InitColumnPerc(3)=0.11
    InitColumnPerc(4)=0.11
    InitColumnPerc(5)=0.08
    ColumnHeadingHints(0)="The player's rank; Calculated by the player's performance (ELO)."
    ColumnHeadingHints(1)="Player's name."
    ColumnHeadingHints(2)="Performance Rating. A players rating is determined by your best performance on competitive maps that are rated by comparison to other performers."
    ColumnHeadingHints(3)="Number of records that the player has set a time on."
    ColumnHeadingHints(4)="Stars are the amount of top records a player has, i.e. #1 time."
    ColumnHeadingHints(5)="Achievement Points"

    OnDrawItem=DrawItem
    GetItemHeight=InternalGetItemHeight
}