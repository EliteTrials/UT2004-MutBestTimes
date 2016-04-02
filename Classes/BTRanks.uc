class BTRanks extends Info;

const MIN_MAP_RECORDS = 5;
const MAX_MAP_RECORDS = 15;
const MIN_PLAYER_RECORDS = 10;

var BTRanksList
	OverallTopList,
	QuarterlyTopList,
	DailyTopList;

var private MutBestTimes BT;
var protected BTServer_PlayersData PDat;
var protected BTServer_RecordsData RDat;
var private array<CacheManager.MapRecord> CachedMaps;

event PostBeginPlay()
{
	BT = MutBestTimes(Owner);
	PDat = BT.PDat;
	RDat = BT.RDat;
}

final function DebugLog( coerce string str )
{
	Log( str );
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

/** Caches the awarded points for every map's times. */
final function CacheRecords()
{
    local int mapIndex;
    // local float time1;

    // Clock( time1 );
    BT.MRI.RecordsCount = 0;
    for( mapIndex = 0; mapIndex < RDat.Rec.Length; ++ mapIndex )
    {
    	if( !RDat.Rec[mapIndex].bMapIsActive && !BT.bDebugMode )
    		continue;

        CacheRecord( mapIndex );
    }
    // UnClock( time1 );
    // Log( "CacheRecords() timespent" @ time1 $"ms" );
}

final function CacheRecord( int mapIndex )
{
    local int recordIndex, playerSlot, j;
    local bool isRanked;
    // local float time1;

    isRanked = IsRankedMap( mapIndex );
    if( isRanked )
    {
        ++ BT.MRI.RecordsCount;
    }

    // Clock( time1 );
    j = RDat.Rec[mapIndex].PSRL.Length;
    for( recordIndex = 0; recordIndex < j; ++ recordIndex )
    {
        playerSlot = RDat.Rec[mapIndex].PSRL[recordIndex].PLs;
        if( playerSlot == 0 )
            continue;

        -- playerSlot;
        PDat.Player[playerSlot].Records[PDat.Player[playerSlot].Records.Length] = (mapIndex << 16) | (recordIndex & 0x0000FFFF);

        if( isRanked )
        {
        	InsertRankedRecord(
        		PDat.Player[playerSlot].RankedRecords,
        		PDat.Player[playerSlot].Records[PDat.Player[playerSlot].Records.Length-1],
        		RDat.Rec[mapIndex].PSRL[recordIndex].Points
    		);
        }
    }
    // UnClock( time1 );
    // Log( "CacheRecord() timespent" @ time1 $"ms" );
}

private function InsertRankedRecord( out array<int> rankedRecords, int recordReference, float recordPoints )
{
	local int i, j, k;
    local float p;

    if( rankedRecords.Length == 0 )
    {
    	RankedRecords[rankedRecords.Length] = recordReference;
    	return;
    }

    j = rankedRecords.Length - 1;
    while( i <= j )
    {
    	k = (i + j)/2;
    	p = RDat.Rec[rankedRecords[k] >> 16].PSRL[rankedRecords[k] & 0x0000FFFF].Points;
    	if( recordPoints < p )
    	{
    		i = k + 1;
    	}
    	else if( recordPoints > p )
    	{
    		j = k - 1;
    	}
    	else break;
    }
    k += int(recordPoints < p);
	rankedRecords.Insert( k, 1 );
	rankedRecords[k] = recordReference;
}

final function CachePlayers()
{
    local int i;
    local int ly, lm, ld;
    local float time1;

    Clock( time1 );
    PDat.TotalActivePlayersCount = 0;
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
        CachePlayer( i, PDat.Player[i].Records, PDat.Player[i].RankedRecords );
        ++ PDat.TotalActivePlayersCount;
    }
    UnClock( time1 );
    Log( "CachePlayers() timespent" @ time1 $"ms" );
}

final function CachePlayer( int playerSlot, out array<int> records, out array<int> rankedRecords )
{
	local int mapIndex, recordIndex, mapIndex2, recordIndex2;
    local int i;
    local int numRankedRecords;

    PDat.Player[playerSlot].PLPoints[0] = 0;
    PDat.Player[playerSlot].PLPoints[1] = 0;
    PDat.Player[playerSlot].PLPoints[2] = 0;

	for( i = 0; i < records.Length; ++ i )
	{
    	mapIndex = records[i] >> 16;
		recordIndex = records[i] & 0x0000FFFF;

        CachePlayerRecord( playerSlot, mapIndex, recordIndex, 0, false );
        if( Level.Year == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[2]
        	&& Level.Month == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[1] ) // Monthly
        {
            CachePlayerRecord( playerSlot, mapIndex, recordIndex, 1, false );
            if( Level.Year == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[2]
            	&& Level.Month == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[1]
            	&& Level.Day == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[0] )
            {
            	CachePlayerRecord( playerSlot, mapIndex, recordIndex, 2, false );
            }
        }
	}

    numRankedRecords = Min( rankedRecords.Length, MAX_MAP_RECORDS );
    for( i = 0; i < numRankedRecords; ++ i )
    {
        mapIndex = rankedRecords[i] >> 16;
        recordIndex = rankedRecords[i] & 0x0000FFFF;

        // All time
        CachePlayerRecord( playerSlot, mapIndex, recordIndex, 0, true );
        if( Level.Year == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[2]
        	&& Level.Month == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[1] ) // Monthly
        {
            CachePlayerRecord( playerSlot, mapIndex, recordIndex, 1, true );
            if( Level.Year == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[2]
            	&& Level.Month == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[1]
            	&& Level.Day == RDat.Rec[mapIndex].PSRL[recordIndex].SRD[0] )
            {
            	CachePlayerRecord( playerSlot, mapIndex, recordIndex, 2, true );
            }
        }
    }

    if( PDat.Player[playerSlot].PLRankedRecords[0] >= MIN_PLAYER_RECORDS )
    {
    	PDat.Player[playerSlot].PLPoints[0] = (numRankedRecords - 1)/2.0;

       	mapIndex = PDat.Player[playerSlot].RankedRecords[int(PDat.Player[playerSlot].PLPoints[0])] >> 16;
        recordIndex = PDat.Player[playerSlot].RankedRecords[int(PDat.Player[playerSlot].PLPoints[0])] & 0x0000FFFF;

        mapIndex2 = PDat.Player[playerSlot].RankedRecords[int(PDat.Player[playerSlot].PLPoints[0] + 0.5)] >> 16;
        recordIndex2 = PDat.Player[playerSlot].RankedRecords[int(PDat.Player[playerSlot].PLPoints[0] + 0.5)] & 0x0000FFFF;

		PDat.Player[playerSlot].PLPoints[0] = (RDat.Rec[mapIndex].PSRL[recordIndex].Points + RDat.Rec[mapIndex2].PSRL[recordIndex2].Points)/2.0;

	   	// PDat.Player[playerSlot].PLPoints[0] /= PDat.Player[playerSlot].PLRankedRecords[0];
   	    if( PDat.Player[playerSlot].PLRankedRecords[1] >= MIN_PLAYER_RECORDS )
	    {
		   	PDat.Player[playerSlot].PLPoints[1] /= PDat.Player[playerSlot].PLRankedRecords[1];
   	   	    if( PDat.Player[playerSlot].PLRankedRecords[2] >= MIN_PLAYER_RECORDS )
		    {
			   	PDat.Player[playerSlot].PLPoints[2] /= PDat.Player[playerSlot].PLRankedRecords[2];
		    }
		    else
		    {
			   	PDat.Player[playerSlot].PLPoints[2] = 0;
		    }
	    }
	    else
	    {
		   	PDat.Player[playerSlot].PLPoints[1] = 0;
		   	PDat.Player[playerSlot].PLPoints[2] = 0;
	    }
    }
    else
    {
	   	PDat.Player[playerSlot].PLPoints[0] = 0;
	   	PDat.Player[playerSlot].PLPoints[1] = 0;
	   	PDat.Player[playerSlot].PLPoints[2] = 0;
    }
}

private function CachePlayerRecord( int playerSlot, int mapIndex, int recordIndex, int listIndex, optional bool bAddPoints )
{
	if( bAddPoints )
	{
    	PDat.Player[playerSlot].PLPoints[listIndex] += RDat.Rec[mapIndex].PSRL[recordIndex].Points;
    	++ PDat.Player[playerSlot].PLRankedRecords[listIndex];
    	return;
	}

    ++ PDat.Player[playerSlot].PLPersonalRecords[listIndex];
    // If the personal best time equals that of the #1 ranked time then it counts as Top Record,
    // - i.e. tied times with the best player are considered #1 as well!
    if( RDat.Rec[mapIndex].PSRL[recordIndex].SRT == RDat.Rec[mapIndex].PSRL[0].SRT )
    {
        ++ PDat.Player[playerSlot].PLTopRecords[listIndex];
    }
}

final function CacheRecordPoints()
{
	local int i;

	for( i = 0; i < RDat.Rec.Length; ++ i )
	{
		CalcRecordPoints( i );
	}
}

final function ResetRecordCache( int mapIndex )
{
	local int i;

	for( i = 0; i < RDat.Rec[mapIndex].PSRL.Length; ++ i )
	{
		RDat.Rec[mapIndex].PSRL[i].Points = 0;
	}
}

final function CalcTopLists()
{
    local int i, mapIndex;

    // Cache the points for all maps to reduce the time spent calculating stats.
    // DebugLog("Caching record stats");
	class'CacheManager'.static.GetMapList( CachedMaps );
	for( i = 0; i < CachedMaps.Length; ++ i )
	{
		mapIndex = BT.RDat.FindRecord( CachedMaps[i].MapName );
		if( mapIndex == -1 )
			continue;

		BT.RDat.Rec[mapIndex].bMapIsActive = true;
	}
    if( BT.bDebugMode || RDat.StatsNeedUpdate() )
    {
    	CacheRecordPoints();
    }
    CacheRecords();

    // DebugLog("Caching player stats");
    CachePlayers();

    OverallTopList = new (BT) class'BTRanksList';
    OverallTopList.RanksTable = 0;
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        if( !PDat.Player[i].bIsActive || PDat.Player[i].PLPoints[OverallTopList.RanksTable] <= 0 )
            continue;

        OverallTopList.Items[OverallTopList.Items.Length] = i;
    }
    // DebugLog( "Sorting ranks" );
    OverallTopList.Sort();

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

final function LogTimes( int mapIndex, out array<float> times )
{
	local int i;

	times.Length = Min( RDat.Rec[mapIndex].PSRL.Length, MAX_MAP_RECORDS );
	for( i = 0; i < times.Length; ++ i )
	{
		times[i] = loge( loge( RDat.Rec[mapIndex].PSRL[i].SRT ) );
	}
}

final static function float Mean( out array<float> values )
{
    local int i;
    local float mean;

    for( i = 0; i < values.Length; ++ i )
    {
        mean += values[i];
    }
    return mean/values.Length;
}

final static function float Std( out array<float> values, float meanValue )
{
	local int i;
	local float variance;

	for( i = 0; i < values.Length; ++ i )
	{
		variance += Square( values[i] - meanValue );
	}
	return Sqrt( variance/float(values.Length - 1) );
}

final function CalcRecordPoints( int mapIndex )
{
	local int i;
	local array<float> times;
	local float timeMean, timeStd, timeMedian;

	if( !IsRankedMap( mapIndex ) )
	{
		ResetRecordCache( mapIndex );
		return;
	}

	LogTimes( mapIndex, times );
	timeMean = Mean( times );
	timeStd = Std( times, timeMean );
	for( i = 0; i < times.Length; ++ i )
	{
		times[i] = -100.0*((times[i] - timeMean)/timeStd);
	}

	timeMedian = (times.Length - 1)/2.0;
	timeMedian = (times[int(timeMedian)] + times[int(timeMedian + 0.5)])/2.0;
	for( i = 0; i < times.Length; ++ i )
	{
		RDat.Rec[mapIndex].PSRL[i].Points = times[i] + timeMedian;
	}
}

final function bool IsRankedMap( int mapIndex )
{
	return !(RDat.Rec[mapIndex].bIgnoreStats || RDat.Rec[mapIndex].PSRL.Length < MIN_MAP_RECORDS);
}

defaultproperties
{
}