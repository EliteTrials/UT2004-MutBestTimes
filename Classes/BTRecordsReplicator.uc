class BTRecordsReplicator extends Info;

var private BTGUI_RecordRankingsReplicationInfo Client;

var private BTServer_RecordsData RecordsSource;
var private BTServer_PlayersData PlayersSource;

var private int CurrentIndex;
var private int NumItemsToSkip, NumItemsToReplicate, MaxItemsToReplicate;

// Index to a map or player.
var private int SourceIndex;
var private float HighestAcquiredPoints;

final function Initialize( BTGUI_RecordRankingsReplicationInfo recordsPRI, int queriedPageIndex, string query )
{
	local MutBestTimes BT;
    local string sourceQuery;
    local int colonIndex;
    local BTClient_LevelReplication myLevel;

    BT = MutBestTimes(Owner);
    RecordsSource = BT.RDat;
    PlayersSource = BT.PDat;
    Client = recordsPRI;

    colonIndex = InStr( query, ":" );
    if( colonIndex != -1 )
    {
        sourceQuery = Left( query, colonIndex );
        query = Mid( query, colonIndex + 1 );
    }
    else
    {
        // Default to map, assume that query is the map's name.
        sourceQuery = "map";
    }

    switch( sourceQuery )
    {
        case "levels":
        case "map":
            myLevel = BT.GetObjectiveLevelByName( query, true );
            if( myLevel != none )
            {
                query = myLevel.GetFullName( BT.CurrentMapName );
            }
            SourceIndex = BT.QueryMapIndex( query );
            if( SourceIndex != -1 && RecordsSource.Rec[SourceIndex].SubLevels.Length == 0 )
            {
                GotoState( 'SendMapRecords');
            }
            else
            {
                GotoState( 'SendMapLevels' );
            }
            break;

        case "player":
            SourceIndex = BT.QueryPlayerIndex( query );
            GotoState( 'SendPlayerRecords');
            break;

        default:
            Warn("Received unknown query source" @ sourceQuery$":"$query);
            Done( true );
            return;
    }

    MaxItemsToReplicate = BT.MaxRankedPlayers;
    NumItemsToSkip = queriedPageIndex*MaxItemsToReplicate;
    if( !InitializeSource() )
    {
        Warn("Bad query" @ query);
        Done( true );
    }
    Client.NetUpdateTime = Level.TimeSeconds - 1;
}

private function Done( bool hasReceivedAll )
{
    Client.ClientDoneRecordRanks( hasReceivedAll );
    Destroy();
}

event Tick( float deltaTime );
protected function bool InitializeSource();
protected function SendRecordRank( int rankIndex );

state SendRecords
{
    event Tick( float deltaTime )
    {
        if( Client == none )
        {
            Destroy();
            return;
        }

        if( CurrentIndex >= NumItemsToReplicate )
        {
            Done( NumItemsToReplicate < MaxItemsToReplicate );
            return;
        }

        SendRecordRank( NumItemsToSkip + CurrentIndex );
        ++ CurrentIndex;
    }
}

state SendMapRecords extends SendRecords
{
    protected function bool InitializeSource()
    {
        local int numItems;

        if( SourceIndex == -1 )
        {
            return false;
        }

        Client.RecordsQuery = RecordsSource.Rec[SourceIndex].TMN;
        Client.RecordsSourceId = SourceIndex + 1;
        Client.RecordsSource = "Map";

        numItems = RecordsSource.Rec[SourceIndex].PSRL.Length;
        if( numItems == 0 )
        {
            return false;
        }
        NumItemsToReplicate = Min( numItems - NumItemsToSkip, MaxItemsToReplicate );
        HighestAcquiredPoints = RecordsSource.Rec[SourceIndex].PSRL[0].Points;
        return true;
    }

    // TODO set SoloRank+1
    protected function SendRecordRank( int rankIndex )
    {
        local int playerIndex;
        local BTGUI_RecordRankingsReplicationInfo.sRecordRank recordRank;

        playerIndex = RecordsSource.Rec[SourceIndex].PSRL[rankIndex].PLs - 1;

        recordRank.PlayerId     = playerIndex + 1;
        recordRank.CountryCode  = PlayersSource.Player[playerIndex].IpCountry;
        recordRank.Name         = PlayersSource.Player[playerIndex].PLName;

        if( HighestAcquiredPoints == 0 ) recordRank.Points = -MaxInt;
        else recordRank.Points = RecordsSource.Rec[SourceIndex].PSRL[rankIndex].Points;///HighestAcquiredPoints*10.00;

        recordRank.Time         = RecordsSource.Rec[SourceIndex].PSRL[rankIndex].SRT;
        recordRank.Date         = RecordsSource.DateToCompactDate(
            RecordsSource.Rec[SourceIndex].PSRL[rankIndex].SRD[2],
            RecordsSource.Rec[SourceIndex].PSRL[rankIndex].SRD[1],
            RecordsSource.Rec[SourceIndex].PSRL[rankIndex].SRD[0]
        );
        recordRank.Flags        = RecordsSource.Rec[SourceIndex].PSRL[rankIndex].Flags;
        if( recordRank.Time == RecordsSource.Rec[SourceIndex].PSRL[0].SRT )
        {
            recordRank.Flags = recordRank.Flags | 0x04/**RFLAG_STAR*/;
        }
        Client.ClientAddRecordRank( recordRank );
    }
}

state SendPlayerRecords extends SendRecords
{
    protected function bool InitializeSource()
    {
        local int numItems;

        if( SourceIndex == -1 )
        {
            return false;
        }

        Client.RecordsQuery = PlayersSource.Player[SourceIndex].PLName;
        Client.RecordsSourceId = SourceIndex + 1;
        Client.RecordsSource = "Player";

        numItems = PlayersSource.Player[SourceIndex].RankedRecords.Length;
        if( numItems == 0 )
        {
            return false;
        }
        NumItemsToReplicate = Min( numItems - NumItemsToSkip, MaxItemsToReplicate );
        HighestAcquiredPoints = PlayersSource.Player[SourceIndex].PLPoints[0]; // All time ELO
        return true;
    }

    // TODO set SoloRank+1
    protected function SendRecordRank( int index )
    {
        local int playerIndex, mapIndex, recordIndex;
        local BTGUI_RecordRankingsReplicationInfo.sRecordRank recordRank;

        mapIndex = PlayersSource.Player[SourceIndex].RankedRecords[index] >> 16;
        recordIndex = PlayersSource.Player[SourceIndex].RankedRecords[index] & 0x0000FFFF;
        playerIndex = SourceIndex;

        // HACK: Use PlayerId as RankId
        recordRank.PlayerId     = playerIndex + 1;
        recordRank.RankId       = recordIndex + 1;
        recordRank.Name         = RecordsSource.Rec[mapIndex].TMN;
        recordRank.Points       = RecordsSource.Rec[mapIndex].PSRL[recordIndex].Points;///RecordsSource.Rec[mapIndex].PSRL[0].Points*10.00;
        recordRank.Time         = RecordsSource.Rec[mapIndex].PSRL[recordIndex].SRT;
        recordRank.Date         = RecordsSource.DateToCompactDate(
            RecordsSource.Rec[mapIndex].PSRL[recordIndex].SRD[2],
            RecordsSource.Rec[mapIndex].PSRL[recordIndex].SRD[1],
            RecordsSource.Rec[mapIndex].PSRL[recordIndex].SRD[0]
        );
        recordRank.Flags        = RecordsSource.Rec[mapIndex].PSRL[recordIndex].Flags;
        if( RecordsSource.Rec[mapIndex].bIgnoreStats )
        {
            recordRank.Flags = recordRank.Flags | 0x02/**RFLAG_UNRANKED*/;
        }
        if( recordRank.Time == RecordsSource.Rec[mapIndex].PSRL[0].SRT )
        {
            recordRank.Flags = recordRank.Flags | 0x04/**RFLAG_STAR*/;
        }
        Client.ClientAddRecordRank( recordRank );
    }
}

state SendMapLevels extends SendRecords
{
    protected function bool InitializeSource()
    {
        local int numItems;

        if( SourceIndex == -1 )
        {
            return false;
        }

        Client.RecordsQuery = RecordsSource.Rec[SourceIndex].TMN;
        Client.RecordsSourceId = SourceIndex + 1;
        Client.RecordsSource = "Levels";

        numItems = RecordsSource.Rec[SourceIndex].SubLevels.Length;
        if( numItems == 0 )
        {
            return false;
        }
        NumItemsToReplicate = Min( numItems - NumItemsToSkip, MaxItemsToReplicate );
        return true;
    }

    protected function SendRecordRank( int index )
    {
        local int mapIndex;
        local BTGUI_RecordRankingsReplicationInfo.sRecordRank recordRank;

        mapIndex = RecordsSource.Rec[SourceIndex].SubLevels[index];

        // HACK: Use PlayerId as RankId
        recordRank.PlayerId     = 0;
        recordRank.RankId       = mapIndex + 1;
        recordRank.Name         = RecordsSource.Rec[mapIndex].TMN;
        if( RecordsSource.Rec[mapIndex].PSRL.Length > 0 )
        {
            // Points is realized as map difficulty (rating)
            recordRank.Points   = RecordsSource.Rec[mapIndex].Rating;
            // Time is realized as the average time it takes for the top players to complete this level.
            recordRank.Time     = RecordsSource.Rec[mapIndex].AverageRecordTime;
            // Date is realized as the registration date as oppossed to the last record date.
            recordRank.Date     = RecordsSource.Rec[mapIndex].RegisterDate;
        }
        if( RecordsSource.Rec[mapIndex].bIgnoreStats )
        {
            recordRank.Flags = recordRank.Flags | 0x02/**RFLAG_UNRANKED*/;
        }
        Client.ClientAddRecordRank( recordRank );
    }
}