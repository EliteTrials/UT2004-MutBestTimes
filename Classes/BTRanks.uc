class BTRanks extends Info;

const MIN_MAP_RECORDS = 1;
const MAX_MAP_RECORDS = 15;
const MIN_PLAYER_RECORDS = 5;

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
    local float time;

    Clock( time );
    BT.MRI.RecordsCount = 0;
    for( mapIndex = 0; mapIndex < RDat.Rec.Length; ++ mapIndex )
    {
        // DebugLog("Caching map" @ RDat.Rec[mapIndex].TMN);
        CacheRecord( mapIndex );
    }
    UnClock( time );
    Log( "CacheRecords() timespent" @ time );
}

final function CacheRecord( int mapIndex )
{
    local int recordIndex, playerSlot;
    local bool isRanked;

    isRanked = IsRankedMap( mapIndex );
    if( isRanked )
    {
        ++ BT.MRI.RecordsCount;
    }

    for( recordIndex = 0; recordIndex < RDat.Rec[mapIndex].PSRL.Length; ++ recordIndex )
    {
        playerSlot = RDat.Rec[mapIndex].PSRL[recordIndex].PLs;
        if( playerSlot == 0 )
            continue;

        -- playerSlot;
        PDat.Player[playerSlot].Records[PDat.Player[playerSlot].Records.Length] = (mapIndex << 16) | (recordIndex & 0x0000FFFF);

        if( isRanked )
        {
        	AddTopRankedRecord( playerSlot, mapIndex, recordIndex );
        }
    }
}

final function AddTopRankedRecord( int playerSlot, int mapIndex, int recordIndex )
{
	local int curMapIndex, curRecIndex;
	local int i;
    local float points;

    points = RDat.Rec[mapIndex].PSRL[recordIndex].Points;
    for( i = 0; i < PDat.Player[playerSlot].RankedRecords.Length; ++ i )
    {
    	curMapIndex = PDat.Player[playerSlot].RankedRecords[i] >> 16;
		curRecIndex = PDat.Player[playerSlot].RankedRecords[i] & 0x0000FFFF;

    	if( RDat.Rec[curMapIndex].PSRL[curRecIndex].Points < points )
    	{
    		PDat.Player[playerSlot].RankedRecords.Insert( i, 1 );
    		PDat.Player[playerSlot].RankedRecords[i] = (mapIndex << 16) | (recordIndex & 0x0000FFFF);
    		return;
    	}
    }
	PDat.Player[playerSlot].RankedRecords[PDat.Player[playerSlot].RankedRecords.Length] = (mapIndex << 16) | (recordIndex & 0x0000FFFF);
}

final function CachePlayers()
{
    local int i;
    local int ly, lm, ld;
    local float time;

    Clock( time );
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
        CachePlayer( i );
        ++ PDat.TotalActivePlayersCount;
    }
    UnClock( time );
    Log( "CacheRecords() timespent" @ time );
}

final function CachePlayer( int playerSlot )
{
    local int i, mapIndex, recordIndex, numRankedRecords;

    PDat.Player[playerSlot].PLPoints[0] = 0;
    PDat.Player[playerSlot].PLPoints[1] = 0;
    PDat.Player[playerSlot].PLPoints[2] = 0;

	for( i = 0; i < PDat.Player[playerSlot].Records.Length; ++ i )
	{
    	mapIndex = PDat.Player[playerSlot].Records[i] >> 16;
		recordIndex = PDat.Player[playerSlot].Records[i] & 0x0000FFFF;

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

    numRankedRecords = Min( PDat.Player[playerSlot].RankedRecords.Length, MAX_MAP_RECORDS );
    for( i = 0; i < numRankedRecords; ++ i )
    {
        mapIndex = PDat.Player[playerSlot].RankedRecords[i] >> 16;
        recordIndex = PDat.Player[playerSlot].RankedRecords[i] & 0x0000FFFF;

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
	   	PDat.Player[playerSlot].PLPoints[0] /= PDat.Player[playerSlot].PLRankedRecords[0];
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

final function CachePlayerRecord( int playerSlot, int mapIndex, int recordIndex, int listIndex, optional bool bAddPoints )
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
		RateMapTimes( i );
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
    local int i;

    // Cache the points for all maps to reduce the time spent calculating stats.
    Log("Caching record stats");
    if( BT.bDebugMode || RDat.StatsNeedUpdate() )
    {
    	CacheRecordPoints();
    }
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
    return mean / values.Length;
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

final function RateMapTimes( int mapIndex )
{
	local int i;
	local array<float> times;
	local float timeMean, timeStd;

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
		times[i] = (times[i] - timeMean) / timeStd;
		RDat.Rec[mapIndex].PSRL[i].Points = -100.0*times[i];
	}
}

final function bool IsRankedMap( int mapIndex )
{
	return !(RDat.Rec[mapIndex].bIgnoreStats || RDat.Rec[mapIndex].PSRL.Length < MIN_MAP_RECORDS);
}

defaultproperties
{
}