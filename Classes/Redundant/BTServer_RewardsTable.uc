//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class BTServer_RewardsTable extends Object
	config(MutBestTimes_Rewards);

struct sLevel
{
	var class<Actor> Reward;
	var int ObjectivesReq;
	var int PointsReq;
	var int HijacksReq;
	var int RecordsReq;
	var int DReq, QReq, AReq;
};

struct sReward
{
	var int Id;
	var array<sLevel> Levels;
};

var globalconfig array<sReward> RewardsTableList;

//===MutBestTimes::ModifyPlayer
/*if( RewardsTable != none )
{
	DonateRewardsTo( Other, CRI.myPlayerSlot );
}

final function bool CanHaveReward( int playerSlot, BTServer_RewardsTable.sLevel rewardItem )
{
	return
		PDat.Player[playerSlot].PLObjectives >= rewardItem.ObjectivesReq
		&& PDat.Player[playerSlot].PLHijacks >= rewardItem.HijacksReq
		&& (rewardItem.AReq == 0 ^^ (PDat.Player[playerSlot].PLARank > 0 && PDat.Player[playerSlot].PLARank <= rewardItem.AReq))
			&& SortedOverallTop[PDat.Player[playerSlot].PLARank-1].PLPoints >= rewardItem.PointsReq
			&& SortedOverallTop[PDat.Player[playerSlot].PLARank-1].PLRecords >= rewardItem.RecordsReq
		&& (rewardItem.QReq == 0 ^^ (PDat.Player[playerSlot].PLQRank > 0 && PDat.Player[playerSlot].PLQRank <= rewardItem.QReq))
		&& (rewardItem.DReq == 0 ^^ (PDat.Player[playerSlot].PLDRank > 0 && PDat.Player[playerSlot].PLDRank <= rewardItem.DReq))
	;
}

final function DonateRewardsTo( Pawn other, int playerSlot )
{
	local int i, j;

	for( i = 0; i < RewardsTable.RewardsTableList.Length; ++ i )
	{
		for( j = RewardsTable.RewardsTableList[i].Levels.Length - 1; j >= 0; -- j )
		{
			if( CanHaveReward( playerSlot, RewardsTable.RewardsTableList[i].Levels[j] ) )
			{
				Spawn( RewardsTable.RewardsTableList[i].Levels[j].Reward, other,, other.Location, other.Rotation );
				break;
			}
		}
	}
}*/
