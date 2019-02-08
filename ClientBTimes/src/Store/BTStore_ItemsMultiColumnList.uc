//=============================================================================
// Copyright 2011-2019 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTStore_ItemsMultiColumnList extends GUIMultiColumnList;

var const Texture PositiveIcon;

// Necessary to access the player's replicated items
var editconst noexport BTClient_ClientReplication CRI;

event Free()
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

function UpdateList()
{
    local int i;
    local int lastSelectedItemIndex;

    CRI = class'BTClient_ClientReplication'.static.GetCRI(PlayerOwner().PlayerReplicationInfo);
    if( MyScrollBar != none && CRI != none )
    {
        lastSelectedItemIndex = Index;
        Clear();
        for( i = 0; i < CRI.Items.Length; ++ i )
        {
            AddedItem();
        }
        SetIndex( lastSelectedItemIndex );
    }
}

function DrawItem( Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;
    local string priceText;

    if( CRI == none )
        return;

    if( CRI.Items.Length <= i )
        return;

    Y += 2;
    H -= 2;

    Canvas.Style = 1;
    Canvas.SetPos( X, Y );

    GetCellLeftWidth( 0, CellLeft, CellWidth );
    Canvas.Style = 3;
    switch( CRI.Items[SortData[i].SortItem].Access )
    {
        case 0:
            Canvas.DrawColor = #0x22222282;
            priceText = "$" $ class'BTClient_Interaction'.static.Decimal(CRI.Items[SortData[i].SortItem].Cost);
            break;

        case 1:
            priceText = "Free";
            Canvas.SetDrawColor( 30, 45, 30, 40 );
            break;

        case 2:
            priceText = "Admin";
            Canvas.SetDrawColor( 45, 30, 30, 40 );
            break;

        case 3:
            priceText = "Premium";
            Canvas.SetDrawColor( 30, 45, 45, 40 );
            break;

        case 4:
            priceText = "Private";
            Canvas.SetDrawColor( 30, 30, 45, 40 );
            break;

        case 5:
            priceText = "Drop";
            Canvas.SetDrawColor( 64, 0, 128, 40 );
            break;
    }

    if( bSelected )
    {
        Canvas.DrawColor = #0x33333394;
    }

    Canvas.DrawTile( Texture'BTScoreBoardBG', W, H, 0, 0, 256, 256 );

    MenuState = MSAT_Blurry;
    DrawStyle = Style;

    DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        CRI.Items[SortData[i].SortItem].Name, FontScale );

    GetCellLeftWidth( 1, CellLeft, CellWidth );
    Canvas.SetDrawColor( 255, 255, 255 );
    DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, priceText, FontScale );

    Canvas.SetPos( X, Y );
}

function bool InternalOnRightClick( GUIComponent sender )
{
    return OnClick( sender );
}

defaultproperties
{
    StyleName="BTMultiColumnList"
    SelectedStyleName="BTListSelection"
    SelectedBKColor=(R=255,G=255,B=255,A=255)

    OnRightClick=InternalOnRightClick

    PositiveIcon=ItemChecked

    ColumnHeadings(0)="Item"
    ColumnHeadings(1)="Price"

    InitColumnPerc(0)=0.80
    InitColumnPerc(1)=0.20

    ColumnHeadingHints(0)="ID of the item"
    ColumnHeadingHints(1)="Price of the item"

    SortColumn=0
    SortDescending=true

    OnDrawItem=DrawItem
    GetItemHeight=InternalGetItemHeight
}

#include classes/BTColorHashUtil.uci