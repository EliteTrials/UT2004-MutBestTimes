class BTPlayersDataManager extends Info
    dependson(BTServer_PlayersData);

var const noexport string PlayersDataFileName;

var private BTServer_PlayersData PDat;
var private MutBestTimes BT;

final function BTServer_PlayersData Init()
{
    BT = MutBestTimes(Owner);
    PDat = Level.Game.LoadDataObject( class'BTServer_PlayersData', PlayersDataFileName, PlayersDataFileName );
    if( PDat == none )
    {
        PDat = Level.Game.CreateDataObject( class'BTServer_PlayersData', PlayersDataFileName, PlayersDataFileName );
    }
    PDat.Init( BT );
    return PDat;
}

final function Save()
{
    if( PDat != None )
    {
        Level.Game.SavePackage( PlayersDataFileName );
    }
}

final function GiveItem( BTClient_ClientReplication CRI, string itemId )
{
    local int invIndex, itemIndex, playerSlot;
    local BTClient_ClientReplication.sPlayerItemClient item;

    playerSlot = CRI.myPlayerSlot;
    if( playerSlot == -1 )
        return;

    // TODO: Support stackable items.
    invIndex = PDat.Player[playerSlot].Inventory.BoughtItems.Length;
    PDat.Player[playerSlot].Inventory.BoughtItems.Length = invIndex + 1;
    PDat.Player[playerSlot].Inventory.BoughtItems[invIndex].ID = itemId;
    ++ PDat.TotalItemsBought;

    BT.Store.OnItemAcquired( CRI, itemId );

    // Notify our player that an item has been added to his inventory, to give UIs a chance to reflect changes.
    itemIndex = BT.Store.FindItemByID( itemId );
    item.Id = itemId;
    item.Name = BT.Store.Items[itemIndex].Name;
    item.IconTexture = BT.Store.Items[itemIndex].CachedIMG;
    item.Rarity = BT.Store.Items[itemIndex].Rarity;
    item.ItemClass = BT.Store.Items[itemIndex].ItemClass;
    CRI.ClientSendPlayerItem( item );
}

final function ToggleItem( int playerSlot, string itemId )
{
    local int i, playerItemIndex, storeItemIndex;
    local string type;
    local bool isEnabled;
    local int j;

    if( itemId ~= "all" )
    {
        j = PDat.Player[playerSlot].Inventory.BoughtItems.Length;
        for( i = 0; i < j; ++ i )
        {
            PDat.Player[playerSlot].Inventory.BoughtItems[i].bEnabled = false;
            BT.Store.ItemToggled( playerSlot, PDat.Player[playerSlot].Inventory.BoughtItems[i].ID, false );
        }
        return;
    }

    if( !PDat.HasItem( playerSlot, itemId, playerItemIndex ) )
    {
        return;
    }

    isEnabled = !PDat.Player[playerSlot].Inventory.BoughtItems[playerItemIndex].bEnabled;
    PDat.Player[playerSlot].Inventory.BoughtItems[playerItemIndex].bEnabled = isEnabled;
    BT.Store.ItemToggled( playerSlot, PDat.Player[playerSlot].Inventory.BoughtItems[playerItemIndex].ID, isEnabled );
}

final function SilentRemoveItem( int playerSlot, string itemId )
{
    PDat.SilentRemoveItem( BT, playerSlot, itemId );
}

final function RemoveItem( BTClient_ClientReplication CRI, string itemId )
{
    PDat.RemoveItem( BT, CRI, itemId );
}

final function ProgressAchievementByID( int playerSlot, name achievementId, optional int count )
{
    local int achSlot;//, oldProgress, req;

    if( playerSlot == -1 )
        return;

    achSlot = PDat.FindAchievementStatusByID( playerSlot, achievementId );
    if( achSlot == -1 )
    {
        achSlot = PDat.CreateAchievementStatus( playerSlot, achievementId );
    }

    ProgressAchievementBySlot( playerSlot, achSlot, count );
}

final function ProgressAchievementByType( int playerSlot, name type, optional int count )
{
    local int i, slot;
    local BTAchievements achManager;

    if( playerSlot == -1 )
        return;

    achManager = BT.AchievementsManager;

    // Make sure that this player has an slot for all those possible achievement types!
    for( i = 0; i < achManager.Achievements.Length; ++ i )
    {
        if( achManager.Achievements[i].Type == type )
        {
            slot = PDat.FindAchievementStatusByID( playerSlot, achManager.Achievements[i].ID );
            if( slot != -1 )
                continue;

            PDat.CreateAchievementStatus( playerSlot, achManager.Achievements[i].ID );
        }
    }

    for( i = 0; i < PDat.Player[playerSlot].Achievements.Length; ++ i )
    {
        slot = achManager.FindAchievementByID( PDat.Player[playerSlot].Achievements[i].ID );
        if( slot == -1 ) // Retired?
            continue; // This is an achievement track for a no-longer-existing achievement.

        if( achManager.Achievements[slot].Type == type )
        {
            ProgressAchievementBySlot( playerSlot, i, count );
        }
    }
}

private function ProgressAchievementBySlot( int playerSlot, int achSlot, optional int count )
{
    local int req;
    local int preProgress, postProgress;
    local name achievementId;

    if( playerSlot == -1 || achSlot == -1 )
        return;

    achievementId = PDat.Player[playerSlot].Achievements[achSlot].ID;
    req = BT.AchievementsManager.GetCountForAchievement( achievementId );
    if( req == 0 )
    {
        if( PDat.Player[playerSlot].Achievements[achSlot].Progress != -1 ) // -1 == completed
        {
            PDat.Player[playerSlot].Achievements[achSlot].Progress = -1;
            BT.AchievementEarned( playerSlot, achievementId );
        }
    }
    else
    {
        preProgress = PDat.Player[playerSlot].Achievements[achSlot].Progress;
        PDat.Player[playerSlot].Achievements[achSlot].Progress += count;
        postProgress = preProgress + count;

        /// Notify BT about this achievement completion, so that it can broadcast the achievement!
        if( postProgress >= req && preProgress < req ) // Make sure that it wasn't previously earned!
        {
            BT.AchievementEarned( playerSlot, achievementId );
        }
        else if( postProgress < req )
        {
            BT.AchievementProgressed( playerSlot, achievementId );
        }
    }
}

defaultproperties
{
    PlayersDataFileName="BestTimes_PlayersData"
}