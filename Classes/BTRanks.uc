class BTRanks extends Info;

var BTRanksList
	OverallTopList,
	QuarterlyTopList,
	DailyTopList;

var private MutBestTimes BT;
var protected BTServer_PlayersData PDat;
var protected BTServer_RecordsData RDat;

event PostBeginPlay()
{
	BT = MutBestTimes(Owner);
	PDat = BT.PDat;
	RDat = BT.RDat;
    CalcTopLists();
}

/** Caches the awarded points for every map's times. */
final function CacheRecords()
{
    local int mapIndex;
    local float time;

    Clock( time );
    for( mapIndex = 0; mapIndex < RDat.Rec.Length; ++ mapIndex )
    {
        // This map is no longer in maplist so don't give any points for the record on it.
        if( RDat.Rec[mapIndex].bIgnoreStats )
            continue;

        // Just skip any map that isn't recorded yet, waste of performance and should not be counted towards the total records count anyway!
        if( RDat.Rec[mapIndex].PSRL.Length == 0 )
            continue;

        ++ BT.MRI.RecordsCount;
        CacheRecord( mapIndex );
    }
    UnClock( time );
    Log( time );
}

final function CacheRecord( int mapIndex )
{
    local int recordIndex, playerSlot;

    for( recordIndex = 0; recordIndex < RDat.Rec[mapIndex].PSRL.Length; ++ recordIndex )
    {
        playerSlot = RDat.Rec[mapIndex].PSRL[recordIndex].PLs;
        if( playerSlot == 0 )
            continue;

        -- playerSlot;
        // Register this record's index to the owner.
        // RDat.Rec[mapIndex].PSRL[recordIndex].Points = CalcRecordPoints( mapIndex, recordIndex );
        PDat.Player[playerSlot].Records[PDat.Player[playerSlot].Records.Length] = (mapIndex << 16) | (recordIndex & 0x0000FFFF);
    }
}

final function CachePlayers()
{
    local int i;
    local int ly, lm, ld;

    StopWatch( false );
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        // Skips most players that are inactive, as this is the most common case.
        if( PDat.Player[i].LastPlayedDate == 0 )
            continue;

        // Skip inactive players.
        RDat.GetCompactDate( PDat.Player[i].LastPlayedDate, ly, lm, ld );
        if( BT.GetDaysSince( ly, lm, ld ) > BT.DaysCountToConsiderPlayerInactive )
            continue;

        PDat.Player[i].bIsActive = true;
        CachePlayer( i );
        ++ PDat.TotalActivePlayersCount;
    }
    StopWatch( true );
}

final function CachePlayer( int playerSlot )
{
    local int i, mapIndex, recordIndex;
    local int recordsAge;

    for( i = 0; i < PDat.Player[playerSlot].Records.Length; ++ i )
    {
        mapIndex = PDat.Player[playerSlot].Records[i] >> 16;
        recordIndex = PDat.Player[playerSlot].Records[i] & 0x0000FFFF;

        recordsAge = BT.GetDaysSince( RDat.Rec[mapIndex].PSRL[recordIndex].SRD[2], RDat.Rec[mapIndex].PSRL[recordIndex].SRD[1], RDat.Rec[mapIndex].PSRL[recordIndex].SRD[0] );
        // All time
        CachePlayerRecord( playerSlot, mapIndex, recordIndex, 0 );
        if( recordsAge <= 30 ) // Monthly
            CachePlayerRecord( playerSlot, mapIndex, recordIndex, 1 );
        if( recordsAge == 0 ) // Daily
            CachePlayerRecord( playerSlot, mapIndex, recordIndex, 2 );
    }
}

final function CachePlayerRecord( int playerSlot, int mapIndex, int recordIndex, int listIndex )
{
    PDat.Player[playerSlot].PLPoints[listIndex] += RDat.Rec[mapIndex].PSRL[recordIndex].Points;
    ++ PDat.Player[playerSlot].PLPersonalRecords[listIndex];

    // If the personal best time equals that of the #1 ranked time then it counts as Top Record,
    // - i.e. tied times with the best player are considered #1 as well!
    if( RDat.Rec[mapIndex].PSRL[recordIndex].SRT == RDat.Rec[mapIndex].PSRL[0].SRT )
    {
        ++ PDat.Player[playerSlot].PLTopRecords[listIndex];
    }
}

final function CalcTopLists()
{
    local int i;

    // Cache the points for all maps to reduce the time spent calculating stats.
    Log("Caching record stats");
    CacheRecords();
    Log("Caching player stats");
    CachePlayers();

    OverallTopList = new (BT) class'BTRanksList';
    OverallTopList.RanksTable = 0;
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        if( !PDat.Player[i].bIsActive || PDat.Player[i].PLPoints[OverallTopList.RanksTable] <= 0 )
            continue;

        OverallTopList.Items[OverallTopList.Items.Length] = i;
    }
    Log( "Sorting ranks" );
    StopWatch( false );
    OverallTopList.Sort();
    StopWatch(true);

    QuarterlyTopList = new (BT) class'BTRanksList';
    QuarterlyTopList.RanksTable = 1;
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        if( !PDat.Player[i].bIsActive || PDat.Player[i].PLPoints[QuarterlyTopList.RanksTable] <= 0 )
            continue;

        QuarterlyTopList.Items[QuarterlyTopList.Items.Length] = i;
    }
    QuarterlyTopList.Sort();

    DailyTopList = new (BT) class'BTRanksList';
    DailyTopList.RanksTable = 2;
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        if( !PDat.Player[i].bIsActive || PDat.Player[i].PLPoints[DailyTopList.RanksTable] <= 0 )
            continue;

        DailyTopList.Items[DailyTopList.Items.Length] = i;
    }
    DailyTopList.Sort();
}

defaultproperties
{
}