//=============================================================================
// Copyright 2011-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGUI_PlayerInventory extends BTGUI_StatsTab
    dependson(BTClient_ClientReplication);

#exec texture import name=itemBackground file=content/itemBg.tga mips=off DXT=1 LODSet=5
#exec texture import name=itemBar file=content/itemBar.tga mips=off DXT=1 LODSet=5
#exec texture import name=itemUnChecked file=content/itemUnChecked.tga mips=off DXT=1 LODSet=5
#exec texture import name=itemChecked file=content/itemChecked.tga mips=off DXT=1 LODSet=5

var Texture TileMat;
var Texture FooterTexture;
var Texture CheckedTexture, UnCheckedTexture;

var automated GUITreeListBox        CategoriesListBox;
var automated GUISectionBackground  ItemsBackground, CategoriesBackground;
var automated GUIVertImageListBox   ItemsListBox;
var GUIContextMenu                  ItemsContextMenu;

var automated BTGUI_ComPetPanel     PetPanel;

var() Color RarityColor[7];
var() name RarityTitle[7];

event Free()
{
    super.Free();
}

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
    ItemsListBox.List.OnChange = InternalOnListChange;
    if( bShow && CRI.PlayerItems.Length == 0 )
    {
        CRI.OnPlayerItemReceived = InternalOnPlayerItemReceived;
        CRI.ServerRequestPlayerItems();
        CRI.OnPlayerItemRemoved = InternalOnPlayerItemRemoved;
        CRI.OnPlayerItemUpdated = InternalOnPlayerItemUpdated;
    }

    PetPanel.mInv = self;
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
    local Texture stateTex;

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
    footerHeight = YL*2 + 8*2;

    // RENDER: Background
    if( bSelected || bPending )
    {
        C.DrawColor = #0x8E8EFEFF;
    }
    else C.DrawColor = #0xEEEEEE88;
    C.OrgX = int(X);
    C.OrgY = int(Y);
    C.SetPos( 0, 0 );
    C.DrawTileClipped( TileMat, int(w), int(h) - footerHeight, 0, 0, TileMat.MaterialUSize(), TileMat.MaterialVSize() );

    // RENDER: Icon
    if( playerItem.IconTexture != none )
    {
        C.DrawColor = class'HUD'.default.WhiteColor;
        iconSize = h - 16 - footerHeight;
        C.OrgX = X;
        C.OrgY = Y;
        C.SetPos( w*0.5 - iconSize*0.5 + 2, 12 );
        C.DrawTileClipped( playerItem.IconTexture, iconSize - 8, iconSize - 8, 0.0, 0.0, playerItem.IconTexture.MaterialUSize(), playerItem.IconTexture.MaterialVSize() );
        C.OrgX = X;
        C.OrgY = Y;
        C.ClipX = W;
    }

    if( playerItem.bEnabled )
    {
        stateTex = CheckedTexture;
    }
    else
    {
        stateTex = UnCheckedTexture;
    }

    C.SetPos( w - 16 - 8, 8 );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.Style = 5;
    C.DrawTileClipped( stateTex, 16, 16, 0, 0, stateTex.MaterialUSize(), stateTex.MaterialVSize() );
    C.Style = 1;

    // RENDER: Name
    // Footer
    C.TextSize( playerItem.Name, XL, YL );
    C.OrgX = int(X);
    C.OrgY = int(Y) + h - footerHeight;
    C.ClipX = w;
    C.SetPos( 0, 0 );
    C.DrawColor = RarityColor[playerItem.Rarity];
    C.DrawTileClipped( FooterTexture, w, footerHeight, 0, 0, 256, 64 );

    C.OrgX = X + 4;
    C.OrgY = Y + h - footerHeight;
    C.ClipX = W - 8;
    C.SetPos( 0, 8 );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.DrawTextClipped( playerItem.Name );
    C.CurX = w*0.5;
    C.CurY = YL + 8;
    C.SetPos( 0, YL + 12 );
    C.DrawColor = RarityColor[playerItem.Rarity];
    C.DrawTextClipped( RarityTitle[playerItem.Rarity] );

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

function InternalOnListChange( GUIComponent sender )
{
    local int i;

    i = ItemsListBox.List.GetItem();
    if( i != -1 )
    {
        PetPanel.SpinnyDude.PlayNextAnim();
        PetPanel.SpinnyDude.SetOverlayMaterial( CRI.PlayerItems[i].IconTexture, 999999, true );
    }
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

        case 2:
            DestroySelectedItem();
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

final function bool DestroySelectedItem()
{
    local int i;

    i = ItemsListBox.List.GetItem();
    if( i != -1 )
    {
        CRI.ServerDestroyItem( CRI.PlayerItems[i].ID );
        return true;
    }
    return false;
}

defaultproperties
{
    RarityColor[0]=(R=231,G=207,B=182,A=255)
    RarityColor[1]=(R=96,G=164,B=218,A=255)
    RarityColor[2]=(R=26,G=147,B=6,A=255)
    RarityColor[3]=(R=252,G=208,B=11,A=255)
    RarityColor[4]=(R=255,G=164,B=5,A=255)
    RarityColor[5]=(R=251,G=62,B=141,A=255)
    RarityColor[6]=(R=76,G=19,B=157,A=255)

    RarityTitle[0]=Basic
    RarityTitle[1]=Fine
    RarityTitle[2]=Uncommon
    RarityTitle[3]=Rare
    RarityTitle[4]=Exotic
    RarityTitle[5]=Ascended
    RarityTitle[6]=Legendary

    OnKeyEvent=OnKeyEvent
    TileMat=itemBackground
    FooterTexture=itemBar
    CheckedTexture=ItemChecked
    UnCheckedTexture=ItemUnChecked

    begin object class=BTGUI_ComPetPanel name=oPetPanel
        WinWidth=0.300000
        WinHeight=0.41
        WinLeft=0.0
        WinTop=0.48
        bBoundToParent=true
        bScaleToParent=true
    end object
    PetPanel=oPetPanel

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
        NoVisibleCols=5
        NoVisibleRows=4
        TabOrder=0

        VertBorder=2
        HorzBorder=1
    end object
    ItemsListBox=oItemsListBox

    begin object class=GUIContextMenu name=oContextMenu
        ContextItems(0)="Equip/Unequip Item"
        ContextItems(1)="Sell Item to Vendor"
        ContextItems(2)="Destroy Item"
        OnSelect=InternalOnSelect
    end object
    ContextMenu=oContextMenu
}
