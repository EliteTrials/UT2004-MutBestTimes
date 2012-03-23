class BTGUI_Store extends BTGUI_TabBase;

var automated GUIImage Stats;
var automated BTStore_ItemsMultiColumnListBox lb_ItemsListBox;
var automated GUIButton b_ColorDialog;
var automated GUIButton b_Edit, b_Toggle, b_Sell, b_Buy, b_Donate, b_DisableAll;
var automated GUIImage i_ItemIcon;
var automated GUISectionBackground sb_ItemBackground;
var automated GUIScrollTextBox eb_ItemDescription;
var automated moComboBox cb_Filter;

var protected editconst noexport class<BTStore_ItemsMultiColumnList> ColumnListClass;
var() editinline protected BTClient_ClientReplication ClientData;
var protected bool bWaitingForResponse;

var int lastSelectedItemIndex;

event Free()
{
	ClientData = none;
	super.Free();
}

function PostInitPanel()
{
	ClientData = MyMenu.MyInteraction.MRI.CR;

	//DisableComponent( b_ColorDialog );

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
	//BTStore_ItemsMultiColumnList(lb_ItemsListBox.List).UpdateList();

	if( !bWaitingForResponse && PlayerOwner().Level.TimeSeconds > 5 )
	{
		ClientData.Items.Length = 0;
		PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestStoreItems" @ Eval( cb_Filter.GetText() != "", cb_Filter.GetText(), ClientData.Options.StoreFilter ) );

		DisableComponent( cb_Filter );
	    bWaitingForResponse = true;
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
	return ToggleSelectedItem();
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

		case 1:
			ToggleSelectedItem();
			break;

		case 2:
			SellSelectedItem();
			break;
	}
}

final function bool BuySelectedItem()
{
	local int i;

	i = lb_ItemsListBox.List.CurrentListId();
	if( i != -1 )
	{
		if( ClientData.Items[i].bBought )
			return false;

       	if( !PlayerOwner().PlayerReplicationInfo.bAdmin )
       	{
			if( ClientData.Items[i].Cost <= 0 )
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
		LoadData();
		return true;
	}
	return false;
}

final function bool ToggleSelectedItem()
{
	local int i;

	i = lb_ItemsListBox.List.CurrentListId();
	if( i != -1 )
	{
		if( !ClientData.Items[i].bBought )
			return false;

		PlayerOwner().ConsoleCommand( "Store ToggleItem" @ ClientData.Items[i].ID );
		LoadData();
		return true;
	}
	return false;
}

final function bool SellSelectedItem()
{
	local int i;

	i = lb_ItemsListBox.List.CurrentListId();
	if( i != -1 )
	{
		if( !ClientData.Items[i].bBought )
			return false;

		PlayerOwner().ConsoleCommand( "Store Sell" @ ClientData.Items[i].ID );
		LoadData();
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
	else if( Sender == b_Toggle )
	{
	 	return ToggleSelectedItem();
	}
	else if( Sender == b_DisableAll )
	{
		PlayerOwner().ConsoleCommand( "Store ToggleItem all" );
		LoadData();
		return true;
	}
	else if( Sender == b_Sell )
	{
		return SellSelectedItem();
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

	C.DrawText( "Currency:" $ ClientData.BTPoints, true );

	i = lb_ItemsListBox.List.CurrentListId();
	if( i == -1 )
		return true;

	if( i != lastSelectedItemIndex || lastSelectedItemIndex == -1 )
	{
		if( !ClientData.Items[i].bHasMeta && ClientData.bItemsTransferComplete )
		{
			//Log( "Requesting item meta data for:" @ ClientData.Items[i].ID );
			PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestStoreItemMeta" @ ClientData.Items[i].ID );
		}
		lastSelectedItemIndex = i;
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
	ClientData.Options.StoreFilter = cb_Filter.GetText();
	ClientData.Options.SaveConfig();
	LoadData();
}

defaultproperties
{
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
		WinHeight=0.825
		WinLeft=0.0
		WinTop=0.035
		bVisibleWhenEmpty=true
		bScaleToParent=true
		bBoundToParent=true
		FontScale=FNS_Small
	end object
	lb_ItemsListBox=oitemsListBox

	begin object Class=GUIButton Name=oColorDialog
		Caption="Prefered Color"
		WinLeft=0.71
		WinTop=0.01
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
		WinLeft=0.01
		WinTop=0.87
		WinWidth=0.12
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Edit the selected item if available"
	end object
	b_Edit=oEdit

	begin object Class=GUIButton Name=oToggle
		Caption="Toggle"
		WinLeft=0.14
		WinTop=0.87
		WinWidth=0.12
		WinHeight=0.025
		OnClick=InternalOnClick
		Hint="Activate/Deactivate the selected item"
	end object
	b_Toggle=oToggle

	begin object Class=GUIButton Name=oDisableAll
		Caption="All"
		WinLeft=0.14
		WinTop=0.895
		WinWidth=0.12
		WinHeight=0.025
		OnClick=InternalOnClick
		Hint="Deactivate all your items"
	end object
	b_DisableAll=oDisableAll

	begin object Class=GUIButton Name=oSell
		Caption="Sell"
		WinLeft=0.27
		WinTop=0.87
		WinWidth=0.12
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Sell the selected item for 75% of its original price"
	end object
	b_Sell=oSell

	Begin Object class=moComboBox Name=oFilter
		WinLeft=0.40
		WinTop=0.87
		WinWidth=0.3
		WinHeight=0.05

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
		WinLeft=0.74
		WinTop=0.87
		WinWidth=0.12
		WinHeight=0.05
		OnClick=InternalOnClick
		StyleName="BTButton"
		Hint="Here you can donate to the admins who are working vigorously to update and add new things to the store to show appreciation for all the new things the server has. You can also make requests for personal items if you have made a donation. ÿIf you want to donate make sure you ALERT an admin who can verify it."
	end object
	b_Donate=oDonate

	begin object Class=GUIButton Name=oBuy
		Caption="Buy"
		WinLeft=0.87
		WinTop=0.87
		WinWidth=0.12
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Buy the selected item"
	end object
	b_Buy=oBuy

	ColumnListClass=Class'BTStore_ItemsMultiColumnList'
}
