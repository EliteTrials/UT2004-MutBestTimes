class BTGUI_Store extends MidGamePanel;

var BTClient_Interaction MyInteraction;

var automated GUIImage Stats;
var automated BTStore_ItemsMultiColumnListBox lb_ItemsListBox;
var automated GUIButton b_ColorDialog;
var automated GUIButton b_Edit, b_Buy, b_Donate, b_DisableAll;
var automated GUIImage i_ItemIcon;
var automated GUISectionBackground sb_ItemBackground;
var automated GUIScrollTextBox eb_ItemDescription;
var automated moComboBox cb_Filter;

var protected editconst noexport class<BTStore_ItemsMultiColumnList> ColumnListClass;
var() editinline protected BTClient_ClientReplication ClientData;
var protected bool bWaitingForResponse;

var int lastSelectedItemIndex;
var transient int ItemsNum;

event Free()
{
    ClientData = none;
    MyInteraction = none;
    super.Free();
}

function PostInitPanel()
{
    ClientData = MyInteraction.MRI.CR;
    cb_Filter.INIDefault = Eval( ClientData.Options.StoreFilter != "", ClientData.Options.StoreFilter, "Other" );
}

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if( bShow && ClientData != none )
    {
        BTStore_ItemsMultiColumnList(lb_ItemsListBox.List).CRI = ClientData;
        LoadData();
    }
}

function LoadData()
{
    // No need to request the items for this category, because we've got it cached!
    if( LoadCachedCategory( ClientData.Options.StoreFilter ) )
    {
        ItemsNum = ClientData.Items.Length;
        BTStore_ItemsMultiColumnList(lb_ItemsListBox.List).UpdateList();
        return;
    }

    if( !bWaitingForResponse && PlayerOwner().Level.TimeSeconds > 5 )
    {
        ItemsNum = ClientData.Items.Length;
        ClientData.Items.Length = 0;

        bWaitingForResponse = true;
        PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestStoreItems" @ Eval( cb_Filter.GetText() != "", cb_Filter.GetText(), ClientData.Options.StoreFilter ) );

        DisableComponent( cb_Filter );
        SetTimer( 0.2, true );
    }
}

function LoadComplete()
{
    local int i;

    // Try again?
    if( ClientData.Categories.Length == 0 )
    {
        ClientData.bReceivedCategories = false;
    }

    if( !ClientData.bReceivedCategories && ClientData.Categories.Length > 0 )
    {
        for( i = ClientData.Categories.Length-1; i >= 0; -- i )
        {
            cb_Filter.AddItem( ClientData.Categories[i].Name );
        }
        cb_Filter.MyComboBox.List.OnChange = FilterChanged;
        i = cb_Filter.FindIndex( ClientData.Options.StoreFilter );
        if( i != -1 )
        {
            cb_Filter.SetIndex( i );
        }
        else
        {
            cb_Filter.SetIndex( 0 );
        }
        ClientData.bReceivedCategories = true;
    }
    BTStore_ItemsMultiColumnList(lb_ItemsListBox.List).UpdateList();

    EnableComponent( cb_Filter );
}

event Timer()
{
    if( ClientData.bItemsTransferComplete )
    {
        ClientData.bItemsTransferComplete = false;
        LoadComplete();
        SetTimer( 0.0, false );
        bWaitingForResponse = false;
    }
}

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
    super.InitComponent( MyController, MyOwner );
    lb_ItemsListBox.InitListClass( string(ColumnListClass), ClientData );
    lb_ItemsListBox.ContextMenu.OnSelect = InternalOnSelect;
    lb_ItemsListBox.List.OnDblClick = InternalOnDblClick;
}

function bool InternalOnDblClick( GUIComponent sender )
{
    return BuySelectedItem();
}

/**
    ContextItems(0)="Buy this item"
    ContextItems(1)="Toggle this item"
    ContextItems(2)="Sell this item"
*/
function InternalOnSelect( GUIContextMenu sender, int clickIndex )
{
    switch( clickIndex )
    {
        case 0:
            BuySelectedItem();
            break;
    }
}

final function bool BuySelectedItem()
{
    local int i;

    i = lb_ItemsListBox.List.CurrentListId();
    if( i != -1 )
    {
        if( !PlayerOwner().PlayerReplicationInfo.bAdmin )
        {
            // 2 = Admin, 4 = Private
            if( ClientData.Items[i].Access == 2 || ClientData.Items[i].Access == 4 )
            {
                if( PlayerOwner().Level.NetMode == NM_Client )
                {
                    Log( "Attempt to donate for an item in progress!" );
                    BuyItemOnline( Repl( ClientData.Items[i].Name, " ", "_" ), ClientData.Items[i].ID );
                    return false;
                }
            }
            else if( ClientData.Items[i].Cost > ClientData.BTPoints )
                return false;
        }

        PlayerOwner().ConsoleCommand( "Store Buy" @ ClientData.Items[i].ID );
        //LoadData();
        return true;
    }
    return false;
}

function bool InternalOnClick( GUIComponent Sender )
{
    local int i;

    if( Sender == b_Buy )
    {
        return BuySelectedItem();
    }
    else if( Sender == b_DisableAll )
    {
        PlayerOwner().ConsoleCommand( "Store ToggleItem all" );
        LoadData();
        return true;
    }
    else if( Sender == b_Edit )
    {
        i = lb_ItemsListBox.List.CurrentListId();
        if( i != -1 )
        {
            PlayerOwner().ConsoleCommand( "Store Edit" @ ClientData.Items[i].ID );
        }
        return true;
    }
    else if( Sender == b_Donate )
    {
        BuyItemOnline( "ItemDonation", "ItemRequest" );
        return true;
    }
    else if( Sender == b_ColorDialog )
    {
        PlayerOwner().ConsoleCommand( "PreferedColorDialog" );
        return true;
    }
}

function BuyItemOnline( string itemName, string itemID )
{
    if( !PlatformIs64Bit() )
    {
        PlayerOwner().ConsoleCommand( "Minimize" );
        PlayerOwner().ConsoleCommand( "open http://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=9KT3RZU8569N6&lc=BE&item_name="$itemName$"&item_number="$itemID$"&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted" );
    }
    else
    {
        PlayerOwner().ConsoleCommand( "open http://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=9KT3RZU8569N6&lc=BE&item_name="$itemName$"&item_number="$itemID$"&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted" );
        PlayerOwner().ClientMessage( "Please use CTRL+V in your browser URL bar to donate!" );
    }
}

function bool InternalOnDraw( Canvas C )
{
    local int i;

    i = lb_ItemsListBox.List.CurrentListId();
    if( i == -1 )
        return true;

    if( i > ClientData.Items.Length-1 )
        return true;

    // Update the list length dynamically
    if( ClientData.Items.Length != ItemsNum )
    {
        ItemsNum = ClientData.Items.Length;
        BTStore_ItemsMultiColumnList(lb_ItemsListBox.List).UpdateList();
        return true;
    }

    if( i != lastSelectedItemIndex || lastSelectedItemIndex == -1 )
    {
        if( !ClientData.Items[i].bHasMeta && !bWaitingForResponse )
        {
            //Log( "Requesting item meta data for:" @ ClientData.Items[i].ID );
            PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestStoreItemMeta" @ ClientData.Items[i].ID );
        }
        lastSelectedItemIndex = i;

        if( ClientData.Items[i].bHasMeta )
        {
            UpdateItemDescription( i );
        }
    }

    C.SetPos( i_ItemIcon.ActualLeft(), i_ItemIcon.ActualTop()-16 );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.Font = C.SmallFont;
    C.Style = 3;
    C.DrawText( ClientData.Items[i].ID );

    if( ClientData.Items[i].IconTexture != none )
    {
        C.SetPos( i_ItemIcon.ActualLeft(), i_ItemIcon.ActualTop() );
        C.Style = 5;
        C.DrawTileJustified( ClientData.Items[i].IconTexture, 1, i_ItemIcon.ActualWidth(), i_ItemIcon.ActualHeight() );
    }

    if( ClientData.Items[i].bSync )
    {
        ClientData.Items[i].bSync = false;
        UpdateItemDescription( i );
    }
    return true;
}

final function UpdateItemDescription( int itemIndex )
{
    eb_ItemDescription.MyScrollText.SetContent( ClientData.Items[itemIndex].Desc );
    eb_ItemDescription.MyScrollBar.AlignThumb();
    eb_ItemDescription.MyScrollBar.UpdateGripPosition( 0 );
}

function FilterChanged( GUIComponent sender )
{
    cb_Filter.MyComboBox.ItemChanged( sender );
    CacheCategory( ClientData.Options.StoreFilter );
    ClientData.Options.StoreFilter = cb_Filter.GetText();
    ClientData.Options.SaveConfig();
    LoadData();
}

final function CacheCategory( string categoryName )
{
    local int i;

    for( i = 0; i < ClientData.Categories.Length; ++ i )
    {
        if( ClientData.Categories[i].Name ~= categoryName )
        {
            ClientData.Categories[i].CachedItems = ClientData.Items;
            break;
        }
    }
}

final function bool LoadCachedCategory( string categoryName )
{
    local int i;

    for( i = 0; i < ClientData.Categories.Length; ++ i )
    {
        if( ClientData.Categories[i].Name ~= categoryName )
        {
            if( ClientData.Categories[i].CachedItems.Length == 0 )
                return false;

            ClientData.Items = ClientData.Categories[i].CachedItems;
            return true;
        }
    }
    return false;
}

defaultproperties
{
    WinWidth=0.600000
    WinHeight=1.000000
    WinLeft=0.100000
    WinTop=0.100000

    lastSelectedItemIndex=-1

    Begin Object class=GUIImage name=oStats
        bScaleToParent=True
        bBoundToParent=True
        WinWidth=0.7
        WinHeight=0.025
        WinLeft=0.0
        WinTop=0.01
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
    End object
    Stats=oStats

    begin object Class=BTStore_ItemsMultiColumnListBox Name=oItemsListBox
        WinWidth=0.7
        WinHeight=0.79
        WinLeft=0.0
        WinTop=0.06
        bVisibleWhenEmpty=true
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
    end object
    lb_ItemsListBox=oitemsListBox

    begin object Class=GUIButton Name=oColorDialog
        Caption="Prefered Color"
        WinLeft=0.71
        WinTop=0.005
        WinWidth=0.29
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Edit your prefered color"
    end object
    b_ColorDialog=oColorDialog

    Begin Object class=GUISectionBackground name=render
        Caption="Item Details"
        WinHeight=0.79
        WinLeft=0.71
        WinTop=0.06
        WinWidth=0.29
        HeaderBase=Material'2K4Menus.NewControls.Display99'
    End Object
    sb_ItemBackground=render

    Begin Object class=GUIImage name=oItemImage
        bScaleToParent=True
        bBoundToParent=True
        WinHeight=0.25
        WinLeft=0.73
        WinTop=0.12
        WinWidth=0.25
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        OnDraw=InternalOnDraw
    End Object
    i_ItemIcon=oItemImage

    Begin Object Class=GUIScrollTextBox Name=Desc
        WinHeight=0.415
        WinLeft=0.725
        WinTop=0.38
        WinWidth=0.26
        bBoundToParent=true
        bScaleToParent=true
        bNoTeletype=true
        bVisibleWhenEmpty=true
    End Object
    eb_ItemDescription=Desc

    begin object Class=GUIButton Name=oEdit
        Caption="Edit"
        WinLeft=0.8
        WinTop=0.795
        WinWidth=0.12
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Edit the selected item if available"
    end object
    b_Edit=oEdit

    begin object Class=GUIButton Name=oDisableAll
        Caption="Disable All"
        WinLeft=0.14
        WinTop=0.855
        WinWidth=0.24
        WinHeight=0.08
        OnClick=InternalOnClick
        Hint="Deactivate all your items"
    end object
    b_DisableAll=oDisableAll

    Begin Object class=moComboBox Name=oFilter
        WinLeft=0.40
        WinTop=0.01
        WinWidth=0.3
        WinHeight=0.08

        Caption="Filter"
        INIDefault="Other"
        Hint="Filter items list by category"
        CaptionWidth=0.25
        ComponentJustification=TXTA_Left
        bReadOnly=true
    End Object
    cb_Filter=oFilter

    begin object Class=GUIButton Name=oDonate
        Caption="Donate"
        WinLeft=0.0
        WinTop=0.855
        WinWidth=0.12
        WinHeight=0.08
        OnClick=InternalOnClick
        Hint="Here you can donate to the admins who are working vigorously to update and add new things to the store to show appreciation for all the new things the server has. You can also make requests for personal items if you have made a donation. ÿIf you want to donate make sure you ALERT an admin who can verify it."
    end object
    b_Donate=oDonate

    begin object Class=GUIButton Name=oBuy
        Caption="Buy"
        WinLeft=0.550000
        WinTop=0.855
        WinWidth=0.15
        WinHeight=0.08
        OnClick=InternalOnClick
        Hint="Buy the selected item"
    end object
    b_Buy=oBuy

    ColumnListClass=Class'BTStore_ItemsMultiColumnList'
}
