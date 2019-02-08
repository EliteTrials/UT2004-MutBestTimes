//=============================================================================
// Copyright 2011-2018 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGUI_PlayerInventory extends BTGUI_StatsTab
    dependson(BTClient_ClientReplication);

#exec texture import name=itemBackground file="Resources/itemBg.tga" mips=off DXT=1 LODSet=5
#exec texture import name=itemBar file="Resources/itemBar.tga" mips=off DXT=1 LODSet=5
#exec texture import name=itemUnChecked file="Resources/itemUnChecked.tga" mips=off DXT=1 LODSet=5
#exec texture import name=itemChecked file="Resources/itemChecked.tga" mips=off DXT=1 LODSet=5

var() const Texture TileMat;
var() const Texture FooterTexture;
var() const Texture CheckedTexture, UnCheckedTexture;

var automated GUITreeListBox            CategoriesListBox;
var automated GUISectionBackground      ItemsBackground, CategoriesBackground;
var automated BTGUI_PlayerItemsListBox  ItemsListBox;
var GUIContextMenu                      ItemsContextMenu;

var automated AltSectionBackground          PreviewBackground;
var automated BTGUI_PawnPreviewComponent    PawnPreview;

var() const Color RarityColor[7];
var() const name RarityTitle[7];

var automated GUIButton b_ActivateKey, b_ColorDialog;
var automated GUIEditBox eb_Key;

function InitComponent( GUIController InController, GUIComponent InOwner )
{
    super.InitComponent( InController, InOwner );
    ItemsListBox.List.OnDrawItem = InternalOnDrawItem;
    ItemsListBox.List.OnRightClick = InternalOnListRightClick;
    ItemsListBox.List.OnDblClick = InternalOnListDblClick;
    ItemsListBox.List.OnChange = InternalOnListChange;
    ItemsListBox.List.bAllowEmptyItems = true;
    ItemsListBox.ContextMenu.OnSelect = InternalOnSelect;
}

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if (bShow) {
        PawnPreview.InitPawn3D();
        if (CRI != none && CRI.PlayerItems.Length == 0)
        {
            CRI.OnPlayerItemReceived = InternalOnPlayerItemReceived;
            CRI.ServerRequestPlayerItems();

            CRI.OnPlayerItemRemoved = InternalOnPlayerItemRemoved;
            CRI.OnPlayerItemUpdated = InternalOnPlayerItemUpdated;
        }
    }
    else {
        PawnPreview.DestroyPawn3D();
    }
}

function InternalOnPlayerItemReceived( int index )
{
    // itemChecked is just a placeholder otherwise the list won't accept our item.
    ItemsListBox.List.Add( Texture'itemChecked', index, 0 );
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
    C.DrawColor = #0xEEEEEE88;
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
    if( bSelected || bPending )
    {
        C.DrawColor = #0x8E8EFEFF;
    }
    else
    {
        C.DrawColor = #0x222222FF;
    }
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
        PawnPreview.ApplyPlayerItem( CRI.PlayerItems[i] );
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
            EditSelectedItem();
            break;

        case 2:
            SellSelectedItem();
            break;

        case 3:
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

final function bool EditSelectedItem()
{
    local int i;

    i = ItemsListBox.List.GetItem();
    if( i != -1 )
    {
        PlayerOwner().ConsoleCommand( "Store Edit" @ CRI.PlayerItems[i].ID );
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

function bool InternalOnClick( GUIComponent sender )
{
    if( sender == b_ActivateKey )
    {
        if( eb_Key.GetText() == "" )
        {
            PlayerOwner().ClientMessage( "Please input a valid key." );
            return false;
        }

        PlayerOwner().ConsoleCommand( "ActivateKey" @ eb_Key.GetText() );
        return true;
    }
    else if( Sender == b_ColorDialog )
    {
        PlayerOwner().ConsoleCommand( "PreferedColorDialog" );
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

    begin object class=AltSectionBackground name=oPreviewBackground
        WinWidth=0.300000
        WinHeight=0.88
        WinLeft=0.0
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
        Caption="Preview"
    end object
    PreviewBackground=oPreviewBackground

    begin object class=BTGUI_PawnPreviewComponent name=oPawnPreview
        WinWidth=0.300000
        WinHeight=0.88
        WinLeft=0.0
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
    end object
    PawnPreview=oPawnPreview

    // begin object class=GUISectionBackground name=oItemsBackground
    //     WinWidth=0.690000
    //     WinHeight=0.88
    //     WinLeft=0.310000
    //     WinTop=0.01
    //     bBoundToParent=true
    //     bScaleToParent=true
    //     Caption="Your Items"
    //     HeaderBase=Texture'XInterface.S_UTClassic'
    //     HeaderBar=Shader'Achievement_Effect'
    // end object
    // ItemsBackground=oItemsBackground

    begin object class=BTGUI_PlayerItemsListBox name=oItemsListBox
        WinHeight=0.870000
        WinLeft=0.31000
        WinTop=0.010000
        WinWidth=0.690000
        bBoundToParent=true
        bScaleToParent=true

        CellStyle=Cell_FixedCount
        NoVisibleCols=4
        NoVisibleRows=4
        TabOrder=0

        VertBorder=2
        HorzBorder=1
    end object
    ItemsListBox=oItemsListBox

    begin object class=GUIButton name=oActivateKey
        Caption="Activate Key"
        WinTop=0.9
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Activate a BestTimes key"
    end object
    b_ActivateKey=oActivateKey

    begin object class=GUIEditBox name=oKey
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.9
        WinLeft=0.26
        WinWidth=0.74
        WinHeight=0.05
        Hint="A BestTimes key"
    end object
    eb_Key=oKey

    begin object Class=GUIButton Name=oColorDialog
        Caption="Preferred Color"
        WinLeft=0.01
        WinTop=0.79
        WinWidth=0.28
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Edit your preferred color"
        StyleName="LadderButtonHi"
    end object
    b_ColorDialog=oColorDialog
}

#include classes/BTColorHashUtil.uci