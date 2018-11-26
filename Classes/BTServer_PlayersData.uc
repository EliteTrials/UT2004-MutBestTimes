//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_PlayersData extends Object
    dependson(BTStructs)
    hidedropdown;

#exec obj load file="ClientBTimesV7.u"

struct sBTPlayerInfo
{
    var string
        PLID,                                                                   // GUID
        PLNAME,                                                                 // NAME
        PLCHAR;                                                                 // CHARACTER

    var int
        PLObjectives,                                                           // OBJECTIVES
        PLHijacks,                                                              // BROKEN RECORDS
        PLSF,                                                                   // SOLO FINISH
        PLAP,
        PLAchiev;                                                               // Achievement points

    /** Last known rank(PLARank) since leaving. */
    var int LastKnownRank;

    /** Last known ranking score since leaving. */
    var float LastKnownPoints;

    var array<string>
        RecentLostRecords,
        RecentSetRecords;

    // First 16 bits are the Year, next 8 bits is Month, last 8 bits is Day.
    var int RegisterDate;
    var int LastPlayedDate;
    var string LastIpAddress;
    var string IpCountry;

    /** Amount of times this player has played a map inc revotes. */
    var int Played;

    /** How many hours this player has played. */
    var float PlayHours;

    var transient float _LastLoginTime;
    var transient bool bIsActive;

    /** Index(+1) to their All Time, Quarterly and Daily rank! */
    var transient int PLARank, PLQRank, PLDRank;
    var transient float PLPoints[3];
    var transient int PLPersonalRecords[3];
    var transient int PLTopRecords[3];
    var transient int PLRankedRecords[3];

    // bitmasked indexes to all maps that the player has a record on, including its personal time index which is shifted to the right.
    var transient array<int> Records;
    var transient array<int> RankedRecords;

    // a.k.a AchievementStatus
    struct sAchievementProgress
    {
        /** ID of this achievement that this player is working on. */
        var name ID;

        /** Progress of <type> this player has reached so far! */
        var int Progress;   // -1 indicates the achievement is earned if it is not a progressable achievement.
    };

    /** All achievements that this player is working on */
    var array<sAchievementProgress> Achievements;

    struct sLevel
    {
        /** The total "experience" this player earned playing on this server. */
        var int Experience;

        /** The amount of not-spent points this player has. */
        var int BTPoints; // *Currency
    };

    var sLevel LevelData;

    struct sInventory
    {
        var() BTClient_TrailerInfo.sRankData TrailerSettings;
        //var transient BTClient_TrailerInfo CurTrailerInfo;

        struct sBoughtItem
        {
            var string ID;
            var bool bEnabled;
            var string RawData;
            /** Number of copies this player owns. */
            var byte Count;
        };

        var array<sBoughtItem> BoughtItems;
    };

    var sInventory Inventory;

    struct sTrophy
    {
        var string ID;
    };

    var array<sTrophy> Trophies;

    /** Various booleans for this player. */
    var int PlayerFlags;

    var bool bHasPremium;
    var string Title;

    /** Amount of points this player has scored for his voted team. */
    var float TeamPointsContribution;

    /** Whether this player had voted, contributed and that team won. When joining a reward will be given based on this. */
    var bool bPendingTeamReward;
};

var array<sBTPlayerInfo> Player;
var int TotalCurrencySpent;
var int TotalItemsBought;
var int DayTest;
var transient int TotalActivePlayersCount;
var transient bool bCachedData;

final function Free()
{
}

final function Init( MutBestTimes mut )
{
}

final function InvalidateCache()
{
    local int i;

    for( i = 0; i < Player.Length; ++ i )
    {
        Player[i].bIsActive = false;
        Player[i].PLARank = 0;
        Player[i].PLQRank = 0;
        Player[i].PLDRank = 0;
        Player[i].PLPoints[0] = 0;
        Player[i].PLPoints[1] = 0;
        Player[i].PLPoints[2] = 0;
        Player[i].PLPersonalRecords[0] = 0;
        Player[i].PLPersonalRecords[1] = 0;
        Player[i].PLPersonalRecords[2] = 0;
        Player[i].PLTopRecords[0] = 0;
        Player[i].PLTopRecords[1] = 0;
        Player[i].PLTopRecords[2] = 0;
        Player[i].PLRankedRecords[0] = 0;
        Player[i].PLRankedRecords[1] = 0;
        Player[i].PLRankedRecords[2] = 0;
        Player[i].Records.Length = 0;
        Player[i].RankedRecords.Length = 0;
    }
}

final function bool HasTrophy( int playerSlot, string trophyID )
{
    local int i, j;

    if( playerSlot == -1 )
        return false;

    j = Player[playerSlot].Trophies.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Player[playerSlot].Trophies[i].ID ~= trophyID )
        {
            return true;
        }
    }
    return false;
}

final function AddTrophy( int playerSlot, string trophyID )
{
    local int j;

    if( playerSlot == -1 )
        return;

    j = Player[playerSlot].Trophies.Length;
    Player[playerSlot].Trophies.Length = j + 1;
    Player[playerSlot].Trophies[j].ID = trophyID;
}

final function bool IsUsingItemById( int playerSlot, string itemId )
{
    local int i, j;

    if( playerSlot == -1 )
        return false;

    j = Player[playerSlot].Inventory.BoughtItems.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Player[playerSlot].Inventory.BoughtItems[i].ID ~= itemId )
        {
            return Player[playerSlot].Inventory.BoughtItems[i].bEnabled;
        }
    }
    return false;
}

final function bool HasItem( int playerSlot, string itemId, optional out int itemSlot )
{
    local int i, j;

    if( playerSlot == -1 )
        return false;

    itemSlot = -1;
    j = Player[playerSlot].Inventory.BoughtItems.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Player[playerSlot].Inventory.BoughtItems[i].ID ~= itemId )
        {
            itemSlot = i;
            return true;
        }
    }
    return false;
}

final function SilentRemoveItem( MutBestTimes BT, int playerSlot, string itemId )
{
    local int i;

    if( playerSlot == -1 )
        return;

    if( HasItem( playerSlot, itemId, i ) )
    {
        BT.Store.ItemRemoved( playerSlot, itemId );
        Player[playerSlot].Inventory.BoughtItems.Remove( i, 1 );
    }
}

final function RemoveItem( MutBestTimes BT, BTClient_ClientReplication CRI, string itemId )
{
    local int i, playerSlot;

    playerSlot = CRI.myPlayerSlot;
    if( playerSlot == -1 )
        return;

    if( HasItem( playerSlot, itemId, i ) )
    {
        BT.Store.ItemRemoved( playerSlot, itemId );
        Player[playerSlot].Inventory.BoughtItems.Remove( i, 1 );
        CRI.ClientNotifyItemRemoved( itemId );
    }
}

final function ToggleItem( MutBestTimes BT, int playerSlot, string itemId )
{
    local int i, itemSlot, storeSlot;
    local string type;

    if( itemId ~= "all" )
    {
        for( i = 0; i < Player[playerSlot].Inventory.BoughtItems.Length; ++ i )
        {
            Player[playerSlot].Inventory.BoughtItems[i].bEnabled = false;
            BT.Store.ItemToggled( playerSlot, Player[playerSlot].Inventory.BoughtItems[i].ID, false );
        }
        return;
    }

    if( HasItem( playerSlot, itemId, itemSlot ) )
    {
        Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled = !Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled;
        BT.Store.ItemToggled( playerSlot, Player[playerSlot].Inventory.BoughtItems[itemSlot].ID, Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled );

        // Disable all other items of the same Type!
        if( Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled )
        {
            storeSlot = BT.Store.FindItemByID( itemId );
            if( storeSlot == -1 )
                return;

            type = BT.Store.Items[storeSlot].Type;
            if( type == "" )
                return;

            for( i = 0; i < Player[playerSlot].Inventory.BoughtItems.Length; ++ i )
            {
                if( i == itemSlot )
                    continue;

                storeSlot = BT.Store.FindItemByID( Player[playerSlot].Inventory.BoughtItems[i].ID );
                if( storeSlot == -1 )
                    continue;

                if( BT.Store.Items[storeSlot].Type ~= type )
                {
                    Player[playerSlot].Inventory.BoughtItems[i].bEnabled = false;
                    BT.Store.ItemToggled( playerSlot, Player[playerSlot].Inventory.BoughtItems[i].ID, false );
                }
            }
        }
    }
}

final function GetItemState( int playerSlot, string itemId, out byte bBought, out byte bEnabled )
{
    local int i;

    if( HasItem( playerSlot, itemId, i ) )
    {
        bBought = 1;
        bEnabled = byte(Player[playerSlot].Inventory.BoughtItems[i].bEnabled);
    }
}

final function bool HasCurrencyPoints( int playerSlot, int amount )
{
    return Player[playerSlot].LevelData.BTPoints >= amount;
}

final function SpendCurrencyPoints( MutBestTimes BT, int playerSlot, int amount )
{
    if( amount == 0 )
        return;

    Player[playerSlot].LevelData.BTPoints = Max( Player[playerSlot].LevelData.BTPoints - amount, 0 );
    BT.NotifySpentCurrency( playerSlot, amount );

    TotalCurrencySpent += amount;
}

final function GiveCurrencyPoints( MutBestTimes BT, int playerSlot, int amount, optional bool shouldIgnoreBonuses )
{
    if( amount == 0 )
        return;

    if( amount > 0 && !shouldIgnoreBonuses && HasItem( playerSlot, "cur_bonus_1" ) )
    {
        amount *= 2;
    }
    Player[playerSlot].LevelData.BTPoints += amount;
    BT.NotifyGiveCurrency( playerSlot, amount );
}

final function GiveAchievementPoints( MutBestTimes BT, int playerSlot, int amount )
{
    Player[playerSlot].PLAchiev += amount;
    BT.NotifyAchievementPointsEarned( playerSlot, amount );
}

/** Make sure the playerSlot's are incremented by 1 when calling. */
final function AddExperienceList( MutBestTimes BT, array<BTStructs.sPlayerReference> playerSlots, int experience )
{
    local int i;

    for( i = 0; i < playerSlots.Length; ++ i )
    {
        if( playerSlots[i].PlayerSlot > 0 )
        {
            AddExperience( BT, playerSlots[i].PlayerSlot-1, experience );
        }
    }
}

final function AddExperience( MutBestTimes BT, int playerSlot, int experience )
{
    local int preLevel, postLevel;
    local int expPoints;

    if( experience <= 0 )
        return;

    preLevel = GetLevel( playerSlot );
    if( preLevel >= BT.MaxLevel )
        return;

    expPoints = experience;
    if( BT.CurMode != none )
    {
        expPoints += BT.CurMode.ExperienceBonus;
    }

    if( HasItem( playerSlot, "exp_bonus_1" ) )
    {
        expPoints *= 2;
    }
    else if( HasItem( playerSlot, "exp_bonus_2" ) )
    {
        expPoints *= 3;
    }
    Player[playerSlot].LevelData.Experience += expPoints;
    BT.NotifyExperienceAdded( playerSlot, expPoints );
    postLevel = GetLevel( playerSlot );
    if( postLevel > preLevel )
    {
        Player[playerSlot].LevelData.BTPoints += (BT.PointsPerLevel * (postLevel - preLevel)) * postLevel;

        BT.NotifyLevelUp( playerSlot, postLevel );
    }
}

final function RemoveExperience( MutBestTimes BT, int playerSlot, int experience )
{
    local int preLevel, postLevel;

    if( Player[playerSlot].LevelData.Experience <= 0 || experience <= 0 )
        return;

    preLevel = GetLevel( playerSlot );
    Player[playerSlot].LevelData.Experience = Max( Player[playerSlot].LevelData.Experience - experience, 0 );
    BT.NotifyExperienceRemoved( playerSlot, experience );
    postLevel = GetLevel( playerSlot );
    if( postLevel < preLevel )
    {
        Player[playerSlot].LevelData.BTPoints = Max( Player[playerSlot].LevelData.BTPoints - (BT.PointsPerLevel * (preLevel - postLevel)), 0 );

        BT.NotifyLevelDown( playerSlot, postLevel );
    }
}

final function int GetLevel( int playerSlot, optional out float levelPercent )
{
    local float experienceTest, lastExperienceTest;
    local int levelNum;

    while( true )
    {
        lastExperienceTest = experienceTest;

        experienceTest += (100 * ((1.0f + 0.01f * (levelNum-1)) * levelNum));
        if( Player[playerSlot].LevelData.Experience < experienceTest )
        {
            break;
        }
        ++ levelNum;
    }

    levelPercent = (float(Player[playerSlot].LevelData.Experience) - lastExperienceTest) / (experienceTest - lastExperienceTest);
    return levelNum;
}

final function int FindAchievementStatusByIDSTRING( int playerSlot, string id )
{
    local int i;

    if( playerSlot == -1 )
        return -1;

    for( i = 0; i < Player[playerSlot].Achievements.Length; ++ i )
    {
        if( string(Player[playerSlot].Achievements[i].ID) ~= id )
        {
            return i;
        }
    }
    return -1;
}

final function int FindAchievementStatusByID( int playerSlot, name id )
{
    local int i;

    if( playerSlot == -1 )
        return -1;

    for( i = 0; i < Player[playerSlot].Achievements.Length; ++ i )
    {
        if( Player[playerSlot].Achievements[i].ID == id )
        {
            return i;
        }
    }
    return -1;
}

final function int CreateAchievementStatus( int playerSlot, name achievementId )
{
    if( playerSlot == -1 )
        return -1;

    // Make sure that this is actually an achieveable achievement!
    Player[playerSlot].Achievements.Insert( 0, 1 );
    Player[playerSlot].Achievements[0].ID = achievementId;
    return 0;
}

final function DeleteAchievementsStatus( int playerSlot )
{
    if( playerSlot == -1 )
        return;

    Player[playerSlot].Achievements.Length = 0;
}

final function bool HasCompletedAchievement( MutBestTimes BT, int playerSlot, int achievementIndex )
{
    local name achievementId;
    local int achievementStatusIdx;

    achievementId = BT.AchievementsManager.Achievements[achievementIndex].ID;
    achievementStatusIdx = FindAchievementStatusByID( playerSlot, achievementId );
    if( achievementStatusIdx == -1 )
    {
        return false;
    }

    return Player[playerSlot].Achievements[achievementStatusIdx].Progress == -1
                || Player[playerSlot].Achievements[achievementStatusIdx].Progress >= BT.AchievementsManager.Achievements[achievementIndex].Count;
}

final function int CountCompletedAchievements( MutBestTimes BT, int playerSlot )
{
    local int i, numAchievements;

    for( i = 0; i < Player[playerSlot].Achievements.Length; ++ i )
    {
        if( Player[playerSlot].Achievements[i].Progress == -1
            || Player[playerSlot].Achievements[i].Progress >= BT.AchievementsManager.GetCountForAchievement( Player[playerSlot].Achievements[i].ID ) )
        {
            ++ numAchievements;
        }
    }
    return numAchievements;
}

/** Strips all color tags from A. */
static final preoperator string %( string A )
{
    local int i;

    while( true )
    {
        i = InStr( A, Chr( 0x1B ) );
        if( i != -1 )
        {
            A = Left( A, i ) $ Mid( A, i + 4 );
            continue;
        }
        break;
    }
    return A;
}

final function int FindPlayer( string playerName )
{
    local int i;

    for( i = 0; i < Player.Length; ++ i )
    {
        if( %Player[i].PLNAME == playerName )
        {
            return i;
        }
    }
    return -1;
}

final function int FindPlayerByID( string playerID )
{
    local int i;

    for( i = 0; i < Player.Length; ++ i )
    {
        if( Player[i].PLID == playerID )
        {
            return i;
        }
    }
    return -1;
}

defaultproperties
{
    DayTest=-1
}
