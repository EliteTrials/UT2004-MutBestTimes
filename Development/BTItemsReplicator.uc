class BTItemsReplicator extends Info;

var protected BTClient_ClientReplication CR;
var protected MutBestTimes BT;

var array<int> IndexedItems;
var int CurrentItemIndex;
var int MaxItemsPerTick;

final function Initialize( BTClient_ClientReplication client, string selector, bool selectAdminItems )
{
	local int i, j;

	if( client == none )
		return;

	StopWatch( false );
	BT = MutBestTimes(Owner);
	CR = client;
	if( selector ~= "Premium" )
	{
		for( i = 0; i < BT.Store.Items.Length; ++ i )
		{
			if( BT.Store.Items[i].Access != Premium )
			{
				continue;
			}
		
			j = IndexedItems.Length;
			IndexedItems.Length = j + 1;
			IndexedItems[j] = i;
		}
	}
	else
	{
		// Admin items
		for( i = 0; i < BT.Store.Items.Length; ++ i )
		{
			// Skip if item access is either buy or free, or not in requested category.
			if( (BT.Store.Items[i].Access < Admin || BT.Store.Items[i].Access == Drop) || InStr( BT.Store.Items[i].CachedCategory, "&"$selector ) == -1 )
			{
				continue;
			}
		
			// Show if player is an admin, requested category is "Admin" or player owns said admin item.
			if( selectAdminItems || BT.PDat.HasItem( CR.myPlayerSlot, BT.Store.Items[i].ID ) )
			{
				j = IndexedItems.Length;
				IndexedItems.Length = j + 1;
				IndexedItems[j] = i;
			}
		}
	
		// Non-Admin items
		if( !(selector ~= "Admin") )
		{	
			for( i = 0; i < BT.Store.Items.Length; ++ i )
			{
				// Skip if admin/premium/private, or not in requested category, unless item is a drop and is owned by player.
				if( (BT.Store.Items[i].Access >= Admin && BT.Store.Items[i].Access != Drop) || InStr( BT.Store.Items[i].CachedCategory, "&"$selector ) == -1 )
				{
					continue;
				}

				if( BT.Store.Items[i].Access == Drop && !BT.PDat.HasItem( CR.myPlayerSlot, BT.store.Items[i].ID ) )
				{
					continue;
				}
	
				j = IndexedItems.Length;
				IndexedItems.Length = j + 1;
				IndexedItems[j] = i;
			}
		}
	}
	MaxItemsPerTick = Max( Min( BT.MaxItemsToReplicatePerTick, IndexedItems.Length ), IndexedItems.Length*float(Level.NetMode == NM_Standalone) );
}

final private function SendRepData( int index )
{
	local int playerItemSlot;
	local bool hasItem, isEnabled;

	hasItem = BT.PDat.HasItem( CR.myPlayerSlot, BT.Store.Items[index].ID, playerItemSlot );
	if( playerItemSlot != -1 )
	{
		isEnabled = BT.PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[playerItemSlot].bEnabled;
	}
	CR.ClientSendItem( 
		BT.Store.Items[index].Name,
		BT.Store.Items[index].ID,
		class'BTClient_ClientReplication'.static.CompressStoreData( 
			BT.Store.Items[index].Cost, 
			hasItem, 
			isEnabled,
			BT.Store.Items[index].Access
		)
	);
}

event Tick( float deltaTime )
{
	local int i;

	if( CR == none )
	{
		Destroy();
		return;
	}

	for( i = 0; i < MaxItemsPerTick; ++ i )
	{
		SendRepData( IndexedItems[CurrentItemIndex] );
		++ CurrentItemIndex;
		if( CurrentItemIndex == IndexedItems.Length )
		{
			CR.ClientSendItemsCompleted();
			Destroy();
			return;
		}
	}
}

event Destroyed()
{
	super.Destroyed();
	StopWatch( true );
}