class BTGUI_RecordRankingsMultiColumnList extends GUIMultiColumnList;

var array<BTGUI_RecordRankingsReplicationInfo.sRecordRank> Ranks;

var transient BTClient_ClientReplication CRI;
var protected transient bool
    bItemIsSelected,
    bItemIsOwner,
    bItemIsClientSpawn,
    bItemIsUnRanked,
    bItemHasStar;

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
    CRI = none;
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
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;
    local float xl, yl;
    local BTGUI_RecordRankingsReplicationInfo recordsPRI;
    local int sortItem;

    if( CRI == none )
    {
        CRI = class'BTClient_ClientReplication'.static.GetRep( PlayerOwner() );
    }

    // Not yet replicated?
    if( CRI == none || CRI.RecordsPRI == none )
    {
        return;
    }

    recordsPRI = CRI.RecordsPRI;
    sortItem = SortData[i].SortItem;
    bItemIsSelected = bSelected;
    bItemIsOwner = recordsPRI.RecordRanks[sortItem].RankId == 0
        && recordsPRI.RecordRanks[sortItem].PlayerId == CRI.PlayerId;
    bItemIsClientSpawn = (recordsPRI.RecordRanks[sortItem].Flags & 0x01/**RFLAG_CP*/) != 0;
    bItemIsUnRanked = (recordsPRI.RecordRanks[sortItem].Flags & 0x02/**RFLAG_UNRANKED*/) != 0;
    bItemHasStar = (recordsPRI.RecordRanks[sortItem].Flags & 0x04/**RFLAG_STAR*/) != 0;

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
    else if( bItemIsUnRanked )
    {
        C.DrawColor = #0x4E0E0382;
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
		Eval( recordsPRI.RecordRanks[sortItem].RankId == 0, sortItem + 1, recordsPRI.RecordRanks[sortItem].RankId ), FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 1 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        Eval( recordsPRI.RecordRanks[sortItem].Points == -MaxInt, "N/A", recordsPRI.RecordRanks[sortItem].Points ), FontScale );

    GetCellLeftWidth( 2, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 2 );

    if( recordsPRI.RecordRanks[sortItem].CountryCode != "" )
    {
        DrawStyle.TextSize( C, MenuState, "M", xl, yl, FontScale );
        yl = yl*0.8 - 2.0;
        xl = 10f/8f*yl;
        C.DrawColor = class'HUD'.default.WhiteColor;
        if( recordsPRI.RecordRanks[sortItem].CountryFlag == none )
        {
            recordsPRI.RecordRanks[sortItem].CountryFlag
                = Texture(DynamicLoadObject(
                    Class.Outer.Name$"."$recordsPRI.RecordRanks[sortItem].CountryCode,
                    class'Texture',
                    true
                ));
        }
        if( recordsPRI.RecordRanks[sortItem].CountryFlag != none )
        {
            C.SetPos( CellLeft, Y + H*0.5 - yl*0.5 );
            C.DrawTile( recordsPRI.RecordRanks[sortItem].CountryFlag, xl, yl, 1, 0, 15, 10 );
        }
        else
        {
            DrawStyle.DrawText( C, MenuState, CellLeft, Y, 32, H, TXTA_Left,
                recordsPRI.RecordRanks[sortItem].CountryCode, FontScale );
        }
        CellLeft += xl + 8;
        CellWidth -= xl + 8;
    }
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        recordsPRI.RecordRanks[sortItem].Name, FontScale );

    GetCellLeftWidth( 3, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 3 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        class'BTClient_Interaction'.static.FormatTimeCompact( recordsPRI.RecordRanks[sortItem].Time ), FontScale );

    if( bItemHasStar )
    {
        C.SetPos( CellLeft + (CellWidth - H) - 2/**cellspacing*/, Y );
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.DrawTile( ColorModifier'Star', H, H, 0, 0, 128, 128 );

        // Shifts the next icon.
        CellLeft -= H + 2;
    }

    if( bItemIsClientSpawn )
    {
        DrawStyle.TextSize( C, MenuState, "T", xl, yl, FontScale );

        xl = 54f/76f*yl;
        C.SetPos( CellLeft + (CellWidth - xl) - 2/**cellspacing*/, Y + H*0.5 - yl*0.5 );
        C.DrawColor = #0xFB607FFF;
        C.DrawTile( Texture'HudContent.Generic.Hud', xl, yl, 340, 130, 54, 76 );
    }

    GetCellLeftWidth( 4, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = GetColumnColor( 4 );
    DrawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        class'BTClient_Interaction'.static.CompactDateToString( recordsPRI.RecordRanks[sortItem].Date ), FontScale );

    DrawStyle.FontColors[0] = DrawStyle.default.FontColors[0];
}

function Color GetColumnColor( int column )
{
    if( (column != 3 || !bItemIsClientSpawn) )
    {
        if( bItemIsSelected )
        {
            return #0xFFFFFFFF;
        }

        if( bItemIsOwner )
        {
            return #0xFFFF00FF;
        }
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
            return #0xCCCCAAFF;

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
            return Eval(
                CRI.RecordsPRI.RecordRanks[i].RankId == 0,
                MyPadLeft( i + 1, 4, "0" ),
                MyPadLeft( CRI.RecordsPRI.RecordRanks[i].RankId, 4, "0" )
            );

        // Note: Always sort rating by the received index, assuming that this index represents rating on the server's side.
        case 1:
            return MyPadLeft( i, 4, "0" );

        case 2:
            return CRI.RecordsPRI.RecordRanks[i].Name;

        case 3:
            return class'BTClient_Interaction'.static.FormatTime( CRI.RecordsPRI.RecordRanks[i].Time, true );

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
    ColumnHeadingHints(0)="Record rank; Achieved by setting a better time."
    ColumnHeadingHints(1)="Performance Rating. Based on the players performance relative to that of other players, and the map's rated difficulty. The performance is hidden and represented as (performance*best/10.00)."
    ColumnHeadingHints(2)="Name"
    ColumnHeadingHints(3)="The player's record time."
    ColumnHeadingHints(4)="The date when the player did set this record time. In the following order Day/Month/Year."

    OnDrawItem=DrawItem
    GetItemHeight=InternalGetItemHeight
}