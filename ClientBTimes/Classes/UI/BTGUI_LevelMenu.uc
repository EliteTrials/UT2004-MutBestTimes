class BTGUI_LevelMenu extends BTGUI_ScoreboardBase;

var automated BTGUI_LevelItemsListBox   ItemsListBox;
var GUIContextMenu                      ItemsContextMenu;

var() const Texture TileMat;
var() const Texture FooterTexture;

var() private array<struct sLevel {
    var string Title;
    var BTClient_LevelReplication LI;
}> LevelItems;

var private RenderDevice RenderDevice;

function Free()
{
    local int i;

    super.Free();

    RenderDevice = none;
    for (i = 0; i < LevelItems.Length; ++ i) {
        LevelItems[i].LI = none;
    }
    LevelItems.Length = 0; // does this properly unreference objects for garbage-collection? :/
}

function InitComponent( GUIController InController, GUIComponent InOwner )
{
    super.InitComponent( InController, InOwner );
    ItemsListBox.List.OnDrawItem = InternalOnDrawItem;
    ItemsListBox.List.OnRightClick = InternalOnListRightClick;
    ItemsListBox.List.OnDblClick = InternalOnListDblClick;
    ItemsListBox.List.bAllowEmptyItems = true;
    ItemsListBox.ContextMenu.OnSelect = InternalOnSelect;

    BuildLevelItems();
}

private function BuildLevelItems()
{
    local BTClient_LevelReplication LI;
    local BTClient_MutatorReplicationInfo MRI;
    local int i;
    local string title;
    local bool wasSorted;

    MRI = class'BTClient_ClientReplication'.static.GetRep( PlayerOwner() ).MRI;
    if (MRI == none) {
        Warn("No MRI but we do have a CRI?");
        return;
    }

    ItemsListBox.List.Clear();
    LevelItems.Length = 0;

    for (LI = MRI.BaseLevel; LI != none; LI = LI.NextLevel) {
        title = LI.GetLevelName();

        for (i = 0; i < LevelItems.Length; ++ i) {
            if (StrCmp(title, LevelItems[i].Title) < 0) {
                LevelItems.Insert(i, 1);
                LevelItems[i].Title = title;
                LevelItems[i].LI = LI;
                wasSorted = true;
                break;
            }
        }

        if (!wasSorted) {
            i = LevelItems.Length;
            LevelItems.Length = i + 1;
            LevelItems[i].Title = title;
            LevelItems[i].LI = LI;
        }
        wasSorted = false;
    }

    for (i = 0; i < LevelItems.Length; ++ i) {
        ItemsListBox.List.Add( TileMat, i, 0 );
    }
}

function InternalOnDrawItem( Canvas C, int Item, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local string SavedUseStencil;

    local float XL, YL;
    local GUIVertImageList list;
    local float oldClipX, oldClipY;
    local float footerHeight;
    local sLevel itemEl;
    local string s;

    if (RenderDevice == none)
    {
        RenderDevice = GameEngine(FindObject("Package.GameEngine", class'GameEngine')).GRenDev;
    }

    if (RenderDevice != none) {
        SavedUseStencil = RenderDevice.GetPropertyText("UseStencil");
        RenderDevice.SetPropertyText("UseStencil", "false");
    }

    list = ItemsListBox.List;
    X += int((float(Item - list.Top)%float(list.NoVisibleCols)))*(w+list.HorzBorder);
    Y += int(((float(Item - list.Top)/float(list.NoVisibleCols)%float(list.NoVisibleRows))))*(h+list.VertBorder);
    w -= list.HorzBorder*list.NoVisibleCols;
    h -= list.VertBorder*list.VertBorder;

    itemEl = LevelItems[item];

    oldClipX = C.ClipX;
    oldClipY = C.ClipY;
    C.ClipX = X + W;
    C.ClipY = Y + H;
    C.Font = Font'UT2003Fonts.jFontSmallText800x600';

    C.StrLen( "T", XL, YL );
    footerHeight = YL*2 + 8*2;

    // RENDER: Background
    // C.DrawColor = #0xEEEEFF88;
    // C.OrgX = int(X);
    // C.OrgY = int(Y);
    // C.SetPos( 0, 0 );
    // C.DrawTileClipped( TileMat, int(w), int(h) - footerHeight, 0, 0, TileMat.MaterialUSize(), TileMat.MaterialVSize() );

    C.OrgX = 0;
    C.OrgY = 0;

    C.Style = 1;
    if (itemEl.LI != none && itemEl.LI.MyTeleporter != none) {
        C.Clear(false, true);
        C.DrawPortal(
            X, Y,
            int(w), int(h),
            itemEl.LI.MyTeleporter,
            itemEl.LI.MyTeleporter.Location, itemEL.LI.MyTeleporter.Rotation, 90, false
        );
    }

    // RENDER: Name
    // Footer
    C.TextSize( itemEl.Title, XL, YL );
    C.OrgX = int(X);
    C.OrgY = int(Y) + h - footerHeight;
    C.ClipX = w;
    C.SetPos( 0, 0 );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.DrawTileClipped( FooterTexture, w, footerHeight, 0, 0, 256, 64 );

    C.OrgX = X + 4;
    C.OrgY = Y + h - footerHeight;
    C.ClipX = W - 8;
    C.SetPos( 0, 8 );
    C.DrawTextClipped( itemEl.Title );

    s = class'BTClient_Interaction'.static.FormatTimeCompact(itemEL.LI.TopTime);
    C.StrLen(s, XL, YL);
    C.SetPos(w - XL - 12, 8);
    C.DrawColor = class'HUD'.default.GoldColor;
    C.DrawTextClipped(s);

    s = itemEl.LI.TopRanks;
    C.StrLen(%s, XL, YL);
    C.SetPos(w - XL - 12, 8 + YL);
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.DrawTextClipped(s);

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
    C.OrgX = 0;
    C.OrgY = 0;

    if (RenderDevice != none) {
        RenderDevice.SetPropertyText("UseStencil", SavedUseStencil);
    }
}

function bool InternalOnListRightClick( GUIComponent sender )
{
    return false;
}

function bool InternalOnListDblClick( GUIComponent sender )
{
    local int i;

    i = ItemsListBox.List.GetItem();
    if (i == 0) {
        return false;
    }

    Controller.ConsoleCommand("GotoLevel" @ LevelItems[i].Title);
    Controller.CloseMenu(true);
    return true;
}

function InternalOnSelect( GUIContextMenu sender, int clickIndex )
{
    switch( clickIndex )
    {
    }
}

function bool InternalOnClick( GUIComponent sender )
{
    return false;
}

defaultproperties
{
    TileMat=itemBackground
    FooterTexture=itemBar

	WindowName="Level Selection"
	bPersistent=false
	bAllowedAsLast=true

    FadeTime=1.0
    MinPageHeight=0.4
    MinPageWidth=0.8

    DefaultLeft=0.1
	DefaultTop=0.1
	DefaultWidth=0.8
	DefaultHeight=0.8

    begin object class=BTGUI_LevelItemsListBox name=oItemsListBox
        WinWidth=0.99
        WinLeft=0.005
        WinTop=0.065
        WinHeight=0.925
        bBoundToParent=true
        bScaleToParent=true

        CellStyle=Cell_FixedCount
        NoVisibleCols=3
        NoVisibleRows=3
        TabOrder=0

        VertBorder=2
        HorzBorder=1
    end object
    ItemsListBox=oItemsListBox
}

#include classes/BTColorHashUtil.uci
#include classes/BTColorStripUtil.uci