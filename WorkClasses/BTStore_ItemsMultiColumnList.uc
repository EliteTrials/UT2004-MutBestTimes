/**
 * A list of items the user can buy.
 *
 * Copyright 2011 Eliot Van Uytfanghe. All Rights Reserved.
 */
class BTStore_ItemsMultiColumnList extends GUIMultiColumnList;

#exec texture import name=positiveIcon file=Images/positive.tga group="icons" mips=off DXT=5 alpha=1

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
	local eMenuState MState;
	local GUIStyles DrawStyle;

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

	MState = MenuState;

	GetCellLeftWidth( 0, CellLeft, CellWidth );
	if( CRI.Items[SortData[i].SortItem].bBought )
	{
		Canvas.SetPos( CellLeft, Y );
		Canvas.Style = 5;
		Canvas.SetDrawColor( 255, 255, 255 );
		Canvas.DrawTileJustified( PositiveIcon, 1, H, H );
		Canvas.Style = 3;
		CellLeft += H + 4;
	}
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		CRI.Items[SortData[i].SortItem].Name, FontScale );

	GetCellLeftWidth( 1, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		Eval( CRI.Items[SortData[i].SortItem].Cost > 0, string(CRI.Items[SortData[i].SortItem].Cost), "ÿAdmin" ), FontScale );

	GetCellLeftWidth( 2, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		Eval( CRI.Items[SortData[i].SortItem].bEnabled, "Yes", "No" ), FontScale );

	/*GetCellLeftWidth( 3, CellLeft, CellWidth );
	DrawStyle.DrawText( Canvas, MState, CellLeft, Y, CellWidth, H, TXTA_Left,
		CRI.Items[SortData[i].SortItem].Desc, FontScale );*/
}

function bool InternalOnRightClick( GUIComponent sender )
{
	return OnClick( sender );
}

event Free()
{
	super.Free();
	CRI = none;
}

defaultproperties
{
	OnRightClick=InternalOnRightClick

	PositiveIcon=positiveIcon

	ColumnHeadings(0)="Item"
	ColumnHeadings(1)="Price"
	ColumnHeadings(2)="Active"
	//ColumnHeadings(3)="Desc"

	InitColumnPerc(0)=0.75
	InitColumnPerc(1)=0.10
	InitColumnPerc(2)=0.15
	//InitColumnPerc(3)=0.5

	ColumnHeadingHints(0)="ID of the item"
	ColumnHeadingHints(1)="Price of the item"
	ColumnHeadingHints(2)="Whether the item is activated"
	//ColumnHeadingHints(3)="Description for item"

	SortColumn=0
	SortDescending=true
}
