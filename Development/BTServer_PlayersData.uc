//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_PlayersData extends Object
	hidedropdown;

#exec obj load file="..\System\ClientBTimesV4C.u"

struct sBTPlayerInfo
{
	var string
		PLID,																	// GUID
		PLNAME,																	// NAME
		PLCHAR;																	// CHARACTER

	var int
		PLObjectives,															// OBJECTIVES
		PLHijacks,																// BROKEN RECORDS
		PLSF,																	// SOLO FINISH
		PLAP;

	/** Index to their All Time, Quarterly and Daily rank! */
	var transient int PLARank, PLQRank, PLDRank;

	var array<string>
		RecentLostRecords,
		RecentSetRecords;

	// First 16 bits are the Year, next 8 bits is Month, last 8 bits is Day.
	var int RegisterDate;
	var int LastPlayedDate;

	/** Amount of times this player has played a map inc revotes. */
	var int Played;

	/** How many hours this player has played. */
	var float PlayHours;

	var transient float _LastLoginTime;

	struct sAchievementProgress
	{
		/** ID of this achievement that this player is working on. */
		var name ID;

		/** Progress of <type> this player has reached so far! */
  		var int Progress;	// -1 indicates the achievement is earned if it is not a progress achievement.
	};

	/** All achievements that this player is working on */
	var array<sAchievementProgress> Achievements;

	struct sLevel
	{
		/** The total "experience" this player earned playing on this server. */
		var int Experience;

		/** The amount of not-spent points this player has. */
		var int BTPoints;
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
};

var array<sBTPlayerInfo> Player;

var int TotalCurrencySpent;
var int TotalItemsBought;

var transient MutBestTimes BT;

final function StringToArray( string s, out array<string> a )
{
	local int i;

	a.Length = Len( s );
	if( a.Length == 1 )
	{
		a[0] = s;
		return;
	}

	for( i = 0; i < a.Length; ++ i )
	{
		a[i] = Mid( Left( s, i + 1), i );
	}
}

function int CodePointFromCharacter( string char )
{
	local int i;

	i = Asc( char );
	if( char > "9" )
	{
		return i - (48 + 7);
	}
	return i - 48;
}

function string CharacterFromCodePoint( int codePoint )
{
	if( codePoint > 9 )
	{
		return Chr( 48 + 7 + codePoint );
	}
	return Chr( 48 + codePoint );
}

function string GenerateCheckCharacter( array<string> input )
{
	local int i, factor, sum, n, addend, remainder;

    factor = 2;
    n = 9;

    // Starting from the right and working leftwards is easier since
    // the initial "factor" will always be "2"
    for (i = input.Length - 1; i >= 0; i--) {
            addend = factor * CodePointFromCharacter( input[i] );

            // Alternate the "factor" that each "codePoint" is multiplied by
            factor = 1 + (1 * int(factor != 2));

            // Sum the digits of the "addend" as expressed in base "n"
            addend = (addend / n) + (addend % n);
            sum += addend;
    }

    // Calculate the number that must be added to the "sum"
    // to make it divisible by "n"
    remainder = sum % n;
    return CharacterFromCodePoint( (n - remainder) % n );
}

function bool ValidateCheckCharacter( array<string> input )
{
	local int i, factor, sum, n, addend, remainder;

    factor = 1;
    n = 9;

    for (i = input.Length - 1; i >= 0; i--) {
            addend = factor * CodePointFromCharacter( input[i] );

            // Alternate the "factor" that each "codePoint" is multiplied by
            factor = 1 + (1 * int(factor == 2));

            // Sum the digits of the "addend" as expressed in base "n"
            addend = (addend / n) + (addend % n);
            sum += addend;
    }

    remainder = sum % n;
	return (remainder == 0);;
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

final function bool UseItem( int playerSlot, string id )
{
	local int i, j;

	if( playerSlot == -1 )
		return false;

 	j = Player[playerSlot].Inventory.BoughtItems.Length;
 	for( i = 0; i < j; ++ i )
 	{
 		if( Player[playerSlot].Inventory.BoughtItems[i].ID ~= id )
 		{
 			return Player[playerSlot].Inventory.BoughtItems[i].bEnabled;
 		}
 	}
 	return false;
}

final function bool HasItem( int playerSlot, string id, optional out int itemSlot )
{
	local int i, j;

	if( playerSlot == -1 )
		return false;

	itemSlot = -1;
 	j = Player[playerSlot].Inventory.BoughtItems.Length;
 	for( i = 0; i < j; ++ i )
 	{
 		if( Player[playerSlot].Inventory.BoughtItems[i].ID ~= id )
 		{
 			itemSlot = i;
 			return true;
 		}
 	}
 	return false;
}

final function GiveItem( int playerSlot, string id )
{
	local int j;

	if( playerSlot == -1 )
		return;

	j = Player[playerSlot].Inventory.BoughtItems.Length;
	Player[playerSlot].Inventory.BoughtItems.Length = j + 1;
 	Player[playerSlot].Inventory.BoughtItems[j].ID = id;
 	ToggleItem( playerSlot, id );

	++ TotalItemsBought;
	// MRI
	BT.A123341.TotalItemsBought = TotalItemsBought;
}

final function RemoveItem( int playerSlot, string id )
{
	local int i;

	if( playerSlot == -1 )
		return;

	if( HasItem( playerSlot, id, i ) )
	{
		Player[playerSlot].Inventory.BoughtItems.Remove( i, 1 );
	}
}

final function ToggleItem( int playerSlot, string id )
{
	local int i, itemSlot, storeSlot;
	local string Type;

	if( id ~= "all" )
	{
		for( i = 0; i < Player[playerSlot].Inventory.BoughtItems.Length; ++ i )
		{
			Player[playerSlot].Inventory.BoughtItems[i].bEnabled = false;
		}
		return;
	}

	if( HasItem( playerSlot, id, itemSlot ) )
	{
		Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled = !Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled;

		// Disable all other items of the same Type!
		if( Player[playerSlot].Inventory.BoughtItems[itemSlot].bEnabled )
		{
			storeSlot = BT.Store.FindItemByID( ID );
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
				}
			}
		}
	}
}

final function bool ItemEnabled( int playerSlot, string id )
{
	local int i;

	if( HasItem( playerSlot, id, i ) )
	{
		return Player[playerSlot].Inventory.BoughtItems[i].bEnabled;
	}
	return false;
}

final function GetItemState( int playerSlot, string id, out byte bBought, out byte bEnabled )
{
	local int i;

	if( HasItem( playerSlot, id, i ) )
	{
		bBought = 1;
		bEnabled = byte(Player[playerSlot].Inventory.BoughtItems[i].bEnabled);
	}
}

final function bool HasCurrencyPoints( int playerSlot, int amount )
{
	return Player[playerSlot].LevelData.BTPoints >= amount;
}

final function SpendCurrencyPoints( int playerSlot, int amount )
{
	if( amount == 0 )
		return;

	Player[playerSlot].LevelData.BTPoints = Max( Player[playerSlot].LevelData.BTPoints - amount, 0 );
	BT.NotifySpentCurrency( playerSlot, amount );

	TotalCurrencySpent += amount;
	// MRI
	BT.A123341.TotalCurrencySpent = TotalCurrencySpent;
}

final function GiveCurrencyPoints( int playerSlot, int amount )
{
	if( amount == 0 )
		return;

 	if( HasItem( playerSlot, "cur_bonus_1" ) )
	{
		amount *= 2;
	}
	Player[playerSlot].LevelData.BTPoints += amount;
	BT.NotifyGiveCurrency( playerSlot, amount );
}

/** Make sure the playerSlot's are incremented by 1 when calling. */
final function AddExperienceList( array<int> playerSlots, int experience )
{
	local int i;

	for( i = 0; i < playerSlots.Length; ++ i )
	{
		if( playerSlots[i] > 0 )
		{
			AddExperience( playerSlots[i]-1, experience );
		}
	}
}

final function AddExperience( int playerSlot, int experience )
{
	local int preLevel, postLevel;
	local int expPoints;

	if( experience <= 0 )
		return;

	preLevel = GetLevel( playerSlot );
	if( preLevel >= BT.MaxLevel )
		return;

	expPoints = experience;
	if( BT.A1233451 != none )
	{
		expPoints += BT.A1233451.ExperienceBonus;
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

final function RemoveExperience( int playerSlot, int experience )
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

final function int FindAchievementByIDSTRING( int playerSlot, string id )
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

final function int FindAchievementByID( int playerSlot, name id )
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

final private function int CreateAchievementSlot( BTAchievements manager, int playerSlot, name id )
{
	if( playerSlot == -1 )
		return -1;

	// Make sure that this is actually an achieveable achievement!
	if( manager.FindAchievementByID( id ) != -1 )
	{
		Player[playerSlot].Achievements.Insert( 0, 1 );
		Player[playerSlot].Achievements[0].ID = id;
		return 0;
	}
	return -1;	// Was not achieveable!
}

final function DeleteAchievements( int playerSlot )
{
	if( playerSlot == -1 )
		return;

	Player[playerSlot].Achievements.Length = 0;
}

final function ProgressAchievementByID( int playerSlot, name id, optional int count )
{
	local int achSlot;//, oldProgress, req;

	if( playerSlot == -1 )
		return;

	achSlot = FindAchievementByID( playerSlot, id );
	if( achSlot == -1 )
	{
		achSlot = CreateAchievementSlot( BT.AchievementsManager, playerSlot, id );
	}

	ProgressAchievementBySlot( playerSlot, achSlot, count );
}

final function ProgressAchievementByType( int playerSlot, name type, optional int count )
{
	local int i, slot;

	if( playerSlot == -1 )
		return;

	// Make sure that this player has an slot for all those possible achievement types!
	for( i = 0; i < BT.AchievementsManager.Achievements.Length; ++ i )
	{
		if( BT.AchievementsManager.Achievements[i].Type == type )
		{
			slot = FindAchievementByID( playerSlot, BT.AchievementsManager.Achievements[i].ID );
			if( slot == -1 )
			{
				CreateAchievementSlot( BT.AchievementsManager, playerSlot, BT.AchievementsManager.Achievements[i].ID );
			}
		}
	}

	for( i = 0; i < Player[playerSlot].Achievements.Length; ++ i )
	{
		if( BT.AchievementsManager.Achievements[BT.AchievementsManager.FindAchievementByID( Player[playerSlot].Achievements[i].ID )].Type == type )
		{
			ProgressAchievementBySlot( playerSlot, i, count );
		}
	}
}

final function int CountEarnedAchievements( int playerSlot )
{
	local int i, numAchievements;

	for( i = 0; i < Player[playerSlot].Achievements.Length; ++ i )
	{
		if( Player[playerSlot].Achievements[i].Progress == -1
			|| Player[playerSlot].Achievements[i].Progress >= GetCountForAchievement( Player[playerSlot].Achievements[i].ID ) )
		{
			++ numAchievements;
		}
	}
	return numAchievements;
}

final private function int GetCountForAchievement( name id )
{
	local int achIndex;

	achIndex = BT.AchievementsManager.FindAchievementByID( id );
	if( achIndex == -1 )
		return 0;

	return BT.AchievementsManager.Achievements[achIndex].Count;
}

final private function ProgressAchievementBySlot( int playerSlot, int achSlot, optional int count )
{
	local int req;
	local int preProgress, postProgress;

	if( playerSlot == -1 || achSlot == -1 )
		return;

	req = BT.AchievementsManager.Achievements[BT.AchievementsManager.FindAchievementByID( Player[playerSlot].Achievements[achSlot].ID )].Count;

	if( req == 0 )
	{
		if( Player[playerSlot].Achievements[achSlot].Progress != -1 )
		{
			Player[playerSlot].Achievements[achSlot].Progress = -1;
			BT.AchievementEarned( playerSlot, Player[playerSlot].Achievements[achSlot].ID );
		}
		return;
	}

	preProgress = Player[playerSlot].Achievements[achSlot].Progress;
	Player[playerSlot].Achievements[achSlot].Progress += count;
	postProgress = Player[playerSlot].Achievements[achSlot].Progress;


	/// Notify BT about this achievement completion, so that it can broadcast the achievement!
	if( postProgress >= req && preProgress < req ) // Make sure that it wasn't previously earned!
	{
		BT.AchievementEarned( playerSlot, Player[playerSlot].Achievements[achSlot].ID );
	}
	else if( postProgress < req )
	{
		BT.AchievementProgressed( playerSlot, Player[playerSlot].Achievements[achSlot].ID );
	}
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
