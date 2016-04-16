class BTRecordsReplicator extends Info;

var private BTGUI_RecordRankingsReplicationInfo Client;

var private BTServer_RecordsData RecordsSource;
var private BTServer_PlayersData PlayersSource;

var private int MapIndex;
var private int CurrentIndex;
var private int NumItemsToSkip, NumItemsToReplicate, MaxItemsToReplicate;
var private float HighestAcquiredPoints;

final function Initialize( BTGUI_RecordRankingsReplicationInfo recordsPRI, int queriedPageIndex, string mapName )
{
	local MutBestTimes BT;
	local int numItems;

    BT = MutBestTimes(Owner);
    RecordsSource = BT.RDat;
    PlayersSource = BT.PDat;
    Client = recordsPRI;

    MapIndex = RecordsSource.FindRecordMatch( mapName );
    if( MapIndex == -1 )
    {
    	Warn("Tried looking for a non existing map!" @ mapName);
        Client.ClientDoneRecordRanks( true );
    	Destroy();
    	return;
    }
    Client.RecordsMapName = RecordsSource.Rec[MapIndex].TMN;

    numItems = RecordsSource.Rec[MapIndex].PSRL.Length;
    if( numItems == 0 )
    {
	    Client.ClientDoneRecordRanks( true );
    	Destroy();
    	return;
    }
    MaxItemsToReplicate = BT.MaxRankedPlayers;
    NumItemsToSkip = queriedPageIndex*MaxItemsToReplicate;
    NumItemsToReplicate = Min( numItems - NumItemsToSkip, MaxItemsToReplicate );
    HighestAcquiredPoints = RecordsSource.Rec[MapIndex].PSRL[0].Points;
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
	    Client.ClientDoneRecordRanks( NumItemsToReplicate < MaxItemsToReplicate );
		Destroy(); // We are done here
		return;
	}

	SendRecordRank( NumItemsToSkip + CurrentIndex );
	++ CurrentIndex;
}

// TODO set SoloRank+1
final function SendRecordRank( int rankIndex )
{
    local int playerIndex;
    local BTGUI_RecordRankingsReplicationInfo.sRecordRank recordRank;

    playerIndex = RecordsSource.Rec[MapIndex].PSRL[rankIndex].PLs - 1;

    recordRank.PlayerId     = playerIndex + 1;
    recordRank.Name 		= PlayersSource.Player[playerIndex].PLName;
    recordRank.Points       = RecordsSource.Rec[MapIndex].PSRL[rankIndex].Points/HighestAcquiredPoints*10.00;
    recordRank.Time         = RecordsSource.Rec[MapIndex].PSRL[rankIndex].SRT;
    recordRank.Date       	= RecordsSource.DateToCompactDate(
        RecordsSource.Rec[MapIndex].PSRL[rankIndex].SRD[2],
        RecordsSource.Rec[MapIndex].PSRL[rankIndex].SRD[1],
        RecordsSource.Rec[MapIndex].PSRL[rankIndex].SRD[0]
    );
	recordRank.Flags        = RecordsSource.Rec[MapIndex].PSRL[rankIndex].Flags;
    Client.ClientAddRecordRank( recordRank );
}