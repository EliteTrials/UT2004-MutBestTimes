class BTStatsReplicator extends Info;

var private BTGUI_PlayerRankingsReplicationInfo Client;

var private BTServer_RecordsData RecordsSource;
var private BTServer_PlayersData PlayersSource;

var private int CurrentIndex;
var private int NumItemsToSkip, NumItemsToReplicate, MaxItemsToReplicate;

var private BTRanksList RanksList;

final function Initialize( BTClient_ClientReplication CRI, int queriedPageIndex, byte queriedRanksId )
{
    local MutBestTimes BT;
    local int numItems;

    BT = MutBestTimes(Owner);
    RecordsSource = BT.RDat;
    PlayersSource = BT.PDat;
    Client = CRI.Rankings[queriedRanksId];

    switch( queriedRanksId )
    {
        case 0:
            RanksList = BT.Ranks.OverallTopList;
            break;

        case 1:
            RanksList = BT.Ranks.QuarterlyTopList;
            break;

        case 2:
            RanksList = BT.Ranks.DailyTopList;
            break;
    }

    numItems = RanksList.Items.Length;
    if( numItems == 0 )
    {
        Client.ClientDonePlayerRanks( true );
        Destroy();
        return;
    }
    MaxItemsToReplicate = BT.MaxRankedPlayers;
    NumItemsToSkip = queriedPageIndex*MaxItemsToReplicate;
    NumItemsToReplicate = Min( numItems - NumItemsToSkip, MaxItemsToReplicate );
}

event Tick( float deltaTime )
{
    if( Client == none )
    {
        Destroy();
        return;
    }

    if( CurrentIndex >= NumItemsToReplicate )
    {
        Client.ClientDonePlayerRanks( NumItemsToReplicate < MaxItemsToReplicate );
        Destroy(); // We are done here
        return;
    }

    SendPlayerRank( NumItemsToSkip + CurrentIndex );
    ++ CurrentIndex;
}

final function SendPlayerRank( int rankIndex )
{
    local int playerIndex;
    local BTGUI_PlayerRankingsReplicationInfo.sPlayerRank playerRank;

    playerIndex = RanksList.Items[rankIndex];
    playerRank.PlayerId     = playerIndex + 1;
    playerRank.CountryCode  = PlayersSource.Player[playerIndex].IpCountry;
    playerRank.Name         = PlayersSource.Player[playerIndex].PLName;
    playerRank.Points       = PlayersSource.Player[playerIndex].PLPoints[RanksList.RanksTable];
    if (RanksList.RanksTable == 0) {
        playerRank.PointsChange = playerRank.Points - PlayersSource.Player[playerIndex].LastKnownPoints;
    }
    playerRank.AP           = PlayersSource.Player[playerIndex].PLAchiev;
    playerRank.Hijacks      = PlayersSource.Player[playerIndex].PLRankedRecords[RanksList.RanksTable] << 16 | PlayersSource.Player[playerIndex].PLTopRecords[RanksList.RanksTable];

    Client.ClientAddPlayerRank( playerRank );
}