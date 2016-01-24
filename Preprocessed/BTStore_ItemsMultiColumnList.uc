/**
 * A list of items the user can buy.
 *
 * Copyright 2011 Eliot Van Uytfanghe. All Rights Reserved.
 */
class BTStore_ItemsMultiColumnList extends GUIMultiColumnList;

var Texture PositiveIcon;

var editconst noexport BTClient_ClientReplication CRI;

function UpdateList()
{
    local int i;
    local int lastSelectedItemIndex;

    if( MyScrollBar != none && CRI != none )
    {
        lastSelectedItemIndex = Index;
        Clear();
        for( i = 0; i < CRI.Items.Length; ++ i )
        {
            AddedItem();
        }
        SetIndex( lastSelectedItemIndex );
        OnDrawItem  = DrawItem;
    }
}

function DrawItem( Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;
    local string price;
    local byte orgStyle;

    if( CRI == none )
        return;

    if( CRI.Items.Length <= i )
        return;

    // Draw the selection border
    if( bSelected )
    {
        SelectedStyle.Draw( Canvas,MenuState, X, Y-2, W, H+2 );
        DrawStyle = SelectedStyle;
    }
    else DrawStyle = Style;
    
    GetCellLeftWidth( 0, CellLeft, CellWidth );
    Canvas.Style = 3;
    switch( CRI.Items[SortData[i].SortItem].Access )
    {
        case 0:
            price = class'BTClient_Interaction'.static.Decimal(CRI.Items[SortData[i].SortItem].Cost) $ "$";
            break;
            
        case 1:
            price = "€Free";
            Canvas.SetDrawColor( 30, 45, 30, 40 );
            Canvas.SetPos( CellLeft+2, Y+2 );
            Canvas.DrawTileClipped( Texture'engine.WhiteSquareTexture', CellWidth-4, H-4, 0, 0, 2, 2);
            break;
        
        case 2:
            price = "€Admin";
            Canvas.SetDrawColor( 45, 30, 30, 40 );
            Canvas.SetPos( CellLeft+2, Y+2 );
            Canvas.DrawTileClipped( Texture'engine.WhiteSquareTexture', CellWidth-4, H-4, 0, 0, 2, 2);
            break;
            
        case 3:
            price = "€€Premium";
            Canvas.SetDrawColor( 30, 45, 45, 40 );
            Canvas.SetPos( CellLeft+2, Y+2 );
            Canvas.DrawTileClipped( Texture'engine.WhiteSquareTexture', CellWidth-4, H-4, 0, 0, 2, 2);
            break;
            
        case 4:
            price = "€€€Private";
            Canvas.SetDrawColor( 30, 30, 45, 40 );
            Canvas.SetPos( CellLeft+2, Y+2 );
            Canvas.DrawTileClipped( Texture'engine.WhiteSquareTexture', CellWidth-4, H-4, 0, 0, 2, 2);
            break;      

        case 5:
            price = "ÿDrop";
            Canvas.SetDrawColor( 64, 0, 128, 40 );
            Canvas.SetPos( CellLeft+2, Y+2 );
            Canvas.DrawTileClipped( Texture'engine.WhiteSquareTexture', CellWidth-4, H-4, 0, 0, 2, 2);
            break;
    }

    DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        CRI.Items[SortData[i].SortItem].Name, FontScale );
        
    GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.DrawText( Canvas, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, price, FontScale );

    Canvas.SetPos( X, Y );
}

function bool InternalOnRightClick( GUIComponent sender )
{
    return OnClick( sender );
}

event Free()
{
    super.Free();
    CRI = none;
    PositiveIcon = none;
}

defaultproperties
{
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
}
