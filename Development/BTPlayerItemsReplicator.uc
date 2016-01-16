class BTPlayerItemsReplicator extends Info;

var protected BTClient_ClientReplication CR;
var protected MutBestTimes BT;

var int CurrentItemIndex;
var int MaxItemsPerTick;
var int NumItems;

final function Initialize( BTClient_ClientReplication client, string selector )
{
    if( client == none )
        return;

    BT = MutBestTimes(Owner);
    CR = client;

    NumItems = BT.PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems.Length;
    if( NumItems == 0 )
    {
        CR.ClientSendItemsCompleted();
        Destroy();
        return;
    }

    MaxItemsPerTick = Max( Min( BT.MaxItemsToReplicatePerTick, NumItems ), NumItems*float(Level.NetMode == NM_Standalone) );
}

final private function SendRepData( int index )
{
    local BTClient_ClientReplication.sPlayerItemClient item;
    local int itemIndex;

    item.Id = BT.PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[index].ID;
    item.bEnabled = BT.PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[index].bEnabled;

    itemIndex = BT.Store.FindItemByID( item.Id );
    item.Name = BT.Store.Items[itemIndex].Name;
    item.IconTexture = BT.Store.Items[itemIndex].CachedIMG;
    CR.ClientSendPlayerItem(item);
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
        SendRepData( CurrentItemIndex ++ );
        if( CurrentItemIndex == NumItems )
        {
            CR.ClientSendItemsCompleted();
            Destroy();
            return;
        }
    }
}