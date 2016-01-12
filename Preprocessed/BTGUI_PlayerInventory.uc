//=============================================================================
// Copyright 2011-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGUI_PlayerInventory extends BTGUI_StatsTab
    dependson(BTClient_ClientReplication);

var Texture TileMat;

var automated GUITreeListBox        CategoriesListBox;
var automated GUISectionBackground  ItemsBackground, CategoriesBackground;
var automated GUIVertImageListBox   ItemsListBox;
var GUIContextMenu                  ItemsContextMenu;

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if( CRI == none )
    {
        Log( "ShowPanel, CRI not found!" );
        return;
    }

    ItemsListBox.List.OnDrawItem = InternalOnDrawItem;
    ItemsListBox.List.OnRightClick = InternalOnListRightClick;
    ItemsListBox.List.OnDblClick = InternalOnListDblClick;
    if( bShow && CRI.PlayerItems.Length == 0 )
    {
        CRI.OnPlayerItemReceived = InternalOnPlayerItemReceived;
        CRI.ServerRequestPlayerItems();
        CRI.OnPlayerItemRemoved = InternalOnPlayerItemRemoved;
        CRI.OnPlayerItemUpdated = InternalOnPlayerItemUpdated;
    }
}

function InternalOnPlayerItemReceived( int index )
{
    local BTClient_ClientReplication.sPlayerItemClient item;
    local Material icon;

    item = CRI.PlayerItems[index];
    icon = item.IconTexture;
    if( icon == none )
    {
        icon = class'BTUI_AchievementState'.default.AchievementDefaultIcon;
    }

    ItemsListBox.List.Add( icon, index, 0 );
}

// Assuming the list represents that exact order of CRI.PlayerItems
function InternalOnPlayerItemRemoved( int index )
{
    local int i;

    ItemsListBox.List.Remove( index );
    for( i = index; i < ItemsListBox.List.Elements.Length; ++ i )
    {
        -- ItemsListBox.List.Elements[i].Item;
    }
}

function InternalOnPlayerItemUpdated( int index )
{
}

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

function InternalOnDrawItem( Canvas C, int Item, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local BTClient_ClientReplication.sPlayerItemClient playerItem;
    local float XL, YL;
    local GUIVertImageList list;
    local float iconSize;
    local float oldClipX, oldClipY;
    local float footerHeight;

    list = ItemsListBox.List;
    X += int((float(Item - list.Top)%float(list.NoVisibleCols)))*(w+list.HorzBorder);
    Y += int(((float(Item - list.Top)/float(list.NoVisibleCols)%float(list.NoVisibleRows))))*(h+list.VertBorder);
    w -= list.HorzBorder*list.NoVisibleCols;
    h -= list.VertBorder*list.VertBorder;
    playerItem = CRI.PlayerItems[Item];

    oldClipX = C.ClipX;
    oldClipY = C.ClipY;
    C.ClipX = X + W;
    C.ClipY = Y + H;
    C.Font = Font'UT2003Fonts.jFontSmallText800x600';
    C.Style = 1;

    C.StrLen( "T", XL, YL );
    footerHeight = YL + 4;

    // RENDER: Background
    C.DrawColor = CRI.Options.CTable;
    if( bSelected || bPending )
    {
        C.DrawColor = #0x8E8EFEFF;
    }
    else C.DrawColor = #0xEEEEEE88;
    C.OrgX = int(X);
    C.OrgY = int(Y);
    C.SetPos( 0, 0 );
    C.DrawTileClipped( TileMat, int(w), int(h), 0, 0, TileMat.MaterialUSize(), TileMat.MaterialVSize() );

    // RENDER: Icon
    C.DrawColor = class'HUD'.default.WhiteColor;
    iconSize = h - 16 - footerHeight;
    C.OrgX = X;
    C.OrgY = Y;
    C.SetPos( w*0.5 - iconSize*0.5 + 2, 12 );
    C.DrawTileClipped( playerItem.IconTexture, iconSize - 8, iconSize - 8, 0.0, 0.0, playerItem.IconTexture.MaterialUSize(), playerItem.IconTexture.MaterialVSize() );

    C.TextSize( "X", XL, YL );
    C.OrgX = X;
    C.OrgY = Y;
    C.ClipX = W;
    C.SetPos( w - 8 - XL, 8 );
    C.DrawColor = class'HUD'.default.BlackColor;
    C.DrawTileClipped( TileMat, XL, YL, 0, 0, TileMat.MaterialUSize(), TileMat.MaterialVSize() );
    C.SetPos( w - 8 - XL, 8 );
    C.DrawColor = #0x222222FF;
    C.DrawBox( C, XL, YL );

    if( playerItem.bEnabled )
    {
        // TODO: Checked icon
        C.SetPos( w - 8 - XL, 8 );
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.DrawTextClipped( "X" );
    }

    // RENDER: Name
    // Footer
    C.TextSize( playerItem.Name, XL, YL );
    C.OrgX = int(X);
    C.OrgY = int(Y) + h - footerHeight;
    C.ClipX = w;
    C.SetPos( 0, 0 );
    C.DrawColor = #0x3C3935CC;
    C.DrawTileClipped( TileMat, w, footerHeight, 0, 0, 256, 256 );

    C.OrgX = X + 4;
    C.OrgY = Y + h - footerHeight;
    C.ClipX = W - 8;
    C.SetPos( w*0.5 - XL*0.5, 0 );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.DrawTextClipped( playerItem.Name );

    C.OrgX = X-2;
    C.OrgY = Y-2;
    C.ClipX = W;
    C.ClipY = H;
    C.SetPos( 0, 0 );
    C.DrawColor = #0x222222FF;
    C.DrawBox( C, w, h );

    C.ClipX = oldClipX;
    C.ClipY = oldClipY;
    C.OrgX = X + W;
    C.OrgY = Y + H;
}

function bool InternalOnListRightClick( GUIComponent sender )
{
    return false;
}

function bool InternalOnListDblClick( GUIComponent sender )
{
    return ToggleSelectedItem();
}

function InternalOnSelect( GUIContextMenu sender, int clickIndex )
{
    switch( clickIndex )
    {
        case 0:
            ToggleSelectedItem();
            break;

        case 1:
            SellSelectedItem();
            break;
    }
}


final function bool ToggleSelectedItem()
{
    local int i;

    i = ItemsListBox.List.GetItem();
    if( i != -1 )
    {
        CRI.ServerToggleItem( CRI.PlayerItems[i].ID );
        return true;
    }
    return false;
}

final function bool SellSelectedItem()
{
    local int i;

    i = ItemsListBox.List.GetItem();
    if( i != -1 )
    {
        CRI.ServerSellItem( CRI.PlayerItems[i].ID );
        return true;
    }
    return false;
}

defaultproperties
{
    OnKeyEvent=OnKeyEvent
    TileMat=Texture'BTScoreBoardBG'

    begin object class=GUISectionBackground name=oItemsBackground
        WinWidth=0.700000
        WinHeight=0.92
        WinLeft=0.300000
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
        Caption="Your Items"
        HeaderBar=none
        HeaderBase=none
    end object
    ItemsBackground=oItemsBackground

    begin object class=GUIVertImageListBox name=oItemsListBox
        WinWidth=0.690000
        WinHeight=0.820000
        WinLeft=0.300000
        WinTop=0.070000
        bBoundToParent=true
        bScaleToParent=true

        CellStyle=Cell_FixedCount
        NoVisibleRows=5
        NoVisibleCols=6
        TabOrder=0

        VertBorder=2
        HorzBorder=1

    end object
    ItemsListBox=oItemsListBox

    begin object class=GUIContextMenu name=oContextMenu
        ContextItems(0)="Equip/Unequip Item"
        ContextItems(1)="Sell Item"
        OnSelect=InternalOnSelect
    end object
    ContextMenu=oContextMenu
}
