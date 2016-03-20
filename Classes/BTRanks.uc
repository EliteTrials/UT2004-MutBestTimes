class BTRanks extends Info;

const MIN_MAP_RECORDS = 10;
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
    Log( "CacheRecords() timespent" @ time );
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
    local float time;

    Clock( time );
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        // Skips most players that are inactive, as this is the most common case.
        if( PDat.Player[i].LastPlayedDate == 0 )
            continue;

        // Skip inactive players.
        RDat.GetCompactDate( PDat.Player[i].LastPlayedDate, ly, lm, ld );
        if( !BT.bDebugMode && BT.GetDaysSince( ly, lm, ld ) > BT.DaysCountToConsiderPlayerInactive )
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
    local int i, mapIndex, recordIndex;

    PDat.Player[playerSlot].PLPoints[0] = 0;
    PDat.Player[playerSlot].PLPoints[1] = 0;
    PDat.Player[playerSlot].PLPoints[2] = 0;

    // Players with lesser than 10 records will not be ranked, however we still want to be able to display the amount of records that have been set!
    if( PDat.Player[playerSlot].Records.Length < MIN_PLAYER_RECORDS )
    {
    	for( i = 0; i < PDat.Player[playerSlot].Records.Length; ++ i )
    	{
        	mapIndex = PDat.Player[playerSlot].Records[i] >> 16;
    		recordIndex = PDat.Player[playerSlot].Records[i] & 0x0000FFFF;
    		CachePlayerRecord( playerSlot, mapIndex, recordIndex, 0, false );
    	}
    	return;
    }

    for( i = 0; i < PDat.Player[playerSlot].Records.Length; ++ i )
    {
        mapIndex = PDat.Player[playerSlot].Records[i] >> 16;
        recordIndex = PDat.Player[playerSlot].Records[i] & 0x0000FFFF;

        if( RDat.Rec[mapIndex].PSRL.Length < MIN_MAP_RECORDS || recordIndex+1 >= MAX_MAP_RECORDS )
        {
    		CachePlayerRecord( playerSlot, mapIndex, recordIndex, 0, false );
        	continue;
        }

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

final function CachePlayerRecord( int playerSlot, int mapIndex, int recordIndex, int listIndex, optional bool bRanked )
{
	if( bRanked )
	{
		// Log("Adding" @ RDat.Rec[mapIndex].PSRL[recordIndex].Points @ "points to" @ PDat.Player[playerSlot].PLPoints[listIndex]);
    	PDat.Player[playerSlot].PLPoints[listIndex] += RDat.Rec[mapIndex].PSRL[recordIndex].Points;
    	++ PDat.Player[playerSlot].PLRankedRecords[listIndex];
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
    CacheRecords();
    if( BT.bDebugMode || RDat.StatsNeedUpdate() )
    {
    	CacheRecordPoints();
    }

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
		times[i] = Loge(Loge(RDat.Rec[mapIndex].PSRL[i].SRT));
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

final function RateMapTimes( int mapIndex )
{
	local int i;
	local array<float> times;
	local float meanTime, std, tmpStd;

	if( RDat.Rec[mapIndex].bIgnoreStats || RDat.Rec[mapIndex].PSRL.Length < MIN_MAP_RECORDS )
	{
		ResetRecordCache( mapIndex );
		return;
	}

	// log(log(time))
	LogTimes( mapIndex, times );
	// time_transformed
	meanTime = Mean( times );
	// Log("mean" @ meanTime);
	// z_val = (time_transformed - mean(time_transformed))./std(time_transformed);
	for( i = 0; i < times.Length; ++ i )
	{
		tmpStd = Square((times[i] - meanTime)*100.0);
		std += tmpStd;
		// Log("time" @ RDat.Rec[mapIndex].PSRL[i].SRT);
		// Log("loged time" @ times[i]);
		// Log("squared time" @ tmpStd);
	}
	std = Sqrt(std/float(times.Length - 1));
	// Log("std"@std);
	for( i = 0; i < times.Length; ++ i )
	{
		/* z_val */
		// log(std);
		times[i] = (times[i] - meanTime)*100.0 / std;
		// log(times[i]);
		// elo_diff = -100*z_val;
		RDat.Rec[mapIndex].PSRL[i].Points = times[i]*-100;
		// log(RDat.Rec[mapIndex].PSRL[i].Points);
	}
}

defaultproperties
{
}