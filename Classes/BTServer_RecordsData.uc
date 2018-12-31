//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_RecordsData extends Object
    hidedropdown;

const VERSION = 3;
const POINTS_VERSION = 1;

const RFLAG_CP = 0x01;
// ONLY USED DURING REPLICATION
    const RFLAG_UNRANKED = 0x02;
    const RFLAG_STAR = 0x04;
// --End
const RFLAG_GHOST = 0x08;

struct sSoloRecord
{
    /** Index into the PlayerList.
     * 0 = none.
     * The index is 1 value higher and so should always be decremented by 1 to get the real index.
     */
    var int PLs;

    /** Awarded points for this record time. */
    var float Points;

    /** Solo Record Time as seconds.ms */
    var float SRT;

    /** Solo Record Data as Day/Month/Year */
    var int SRD[3];

    /** Additional given points by this record e.g. Keys or GroupTasks. */
    var int ExtraPoints;

    /** Objectives that were completed during recording this record. */
    var int ObjectivesCount;

    /** Holds certain conditions for this record, such as if a player set this record with a client spawn. */
    var int Flags;
};

struct long sBTRecordInfo
{
    /** Trial Map name. */
    var string TMN;

    /** Trial Map Time. */
    var /**deprecated*/ float TMT;

    /** (Regular) The index of the players that own this record. */
    var /**deprecated*/ int PLs[4];

    /** The amount of objectives each player did in this record.
     * Only the first index(0) is used in Solo and Group records.
     */
    var /**deprecated*/ int Objs[4];

    /** Amount of times this record was hijacked(beaten). */
    var int TMHijacks;

    /** Amount of times people have failed to beat this record, this includes revotes but not deaths. */
    var int TMFailures;

    /** Amount of times people have completed this map. */
    var int TMFinish;

    /** The Ghost is disabled on this map. */
    var bool TMGhostDisabled;

    /** All individual records */
    var array<sSoloRecord> PSRL;

    /** Whether to ignore any point rewards for this record. */
    var bool bIgnoreStats;

    /** True if we have this map in our maps folder. */
    var transient bool bMapIsActive;

    // First 16 bits are the Year, next 8 bits is Month, last 8 bits is Day.
    var int RegisterDate;
    var int LastPlayedDate;

    // Last time this record was updated(in case of Solo any personal rec will update this as well)
    var int LastRecordedDate;

    /** Amount of times this map has been played inc revotes. */
    var int Played;

    /** How many hours this map has been played for. */
    var float PlayHours;

    /** Various booleans for this record. */
    var int RecordFlags;

    /** [Cached] The average record time of this map. Calculated from @PSRL. */
    var float AverageRecordTime;

    /** [Cached] Players rating of this map. Calculated from @Dislikers and @Likers. */
    var float Rating;

    /** List of players (index) whom rated this map as "like". */
    var array<int> Dislikers;

    /** List of players (index) whom rated this map as "dislike". */
    var array<int> Likers;

    /** List of map indexes to levels that belong to this map. Used to track whether if those levels are active.  */
    var array<int> SubLevels;
};

/** The list of all records made on this server. FIXME: Should be called Maps, as it currently stands ambiguous with solo records. */
var array<sBTRecordInfo> Rec;
var int DataVersion;
var int SavedPointsVersion;
var transient bool bCachVerified;

final function Init( MutBestTimes mut )
{
    ConvertData();
}

final function bool ConvertData()
{
    local int i, j, l;
    local int y, m, d;

    if( DataVersion >= VERSION )
    {
        return false;
    }

    Log( "Updating the data format of records to version" @ VERSION @ "from version" @ DataVersion, 'MutBestTimes' );
    if( DataVersion == 0 )
    {
        for( i = 0; i < Rec.Length; ++ i )
        {
            // Make each solo/group record have atleast one objective.
            for( j = 0; j < Rec[i].PSRL.Length; ++ j )
            {
                Rec[i].PSRL[j].ObjectivesCount = 1;
            }

            // Convert RTR records to the solo format.
            if( Rec[i].TMT != 0 && Rec[i].PLs[0] != 0 && Rec[i].PSRL.Length == 0 )
            {
                GetCompactDate( Rec[i].LastRecordedDate, y, m, d );
                for( l = 0; l < 4; ++ l )
                {
                    if( Rec[i].PLs[l] == 0 )
                    {
                        break;
                    }
                    j = Rec[i].PSRL.Length;
                    Rec[i].PSRL.Length = j + 1;
                    Rec[i].PSRL[j].PLs = Rec[i].PLs[l];
                    Rec[i].PSRL[j].SRT = Rec[i].TMT;
                    Rec[i].PSRL[j].SRD[0] = d;
                    Rec[i].PSRL[j].SRD[1] = m;
                    Rec[i].PSRL[j].SRD[2] = y;
                    Rec[i].PSRL[j].ObjectivesCount = Rec[i].Objs[l];
                    Rec[i].PLs[l] = 0; // deprecated
                }
                Rec[i].TMT = 0; // deprecated
            }
        }
    }
    DataVersion = VERSION;
    return true;
}

final function bool StatsNeedUpdate()
{
    local bool needsUpdate;

    needsUpdate = SavedPointsVersion < POINTS_VERSION;
    if( needsUpdate )
    {
        SavedPointsVersion = POINTS_VERSION;
    }
    return needsUpdate;
}

/**
 * Takes another copy of BTServer_RecordsData, and imports its best records into the current instance.
 * The mapping of player slots is assumed to be identical to that of the current PlayersData instance!
 * The importing RecordsData is also assumed to be unique and thus not derived from the current RecordsData. (i.e. it has to be a save from a pre-reset)
 */
final function MergeDataFrom( BTServer_PlayersData PDat, BTServer_RecordsData other, optional bool onlyMergeTime )
{
    local int i, mapIdx;
    local int j, recIdx;
    local bool bBestReplaced;

    // First convert the old format to our newest format, if possible at all? (compatible as far 2009)
    other.ConvertData();

    for( i = 0; i < other.Rec.Length; ++ i )
    {
        mapIdx = FindRecord( other.Rec[i].TMN );
        if( mapIdx != -1 )
        {
            // Add the old PlayedCount to our record instance.
            if( !onlyMergeTime )
            {
                Rec[mapIdx].Played += other.Rec[i].Played;
                Rec[mapIdx].PlayHours += other.Rec[i].PlayHours;
                Rec[mapIdx].TMHijacks += other.Rec[i].TMHijacks;
                Rec[mapIdx].TMFinish += other.Rec[i].TMFinish;
            }

            for( j = 0; j < other.Rec[i].PSRL.Length; ++ j )
            {
                recIdx = FindRecordSlot( mapIdx, other.Rec[i].PSRL[j].PLs );
                if( recIdx == -1 )
                {
                    // We didn't have this individuals record, so let's add it.
                    recIdx = Rec[mapIdx].PSRL.Length;
                    Rec[mapIdx].PSRL.Length = recIdx + 1;

                    // Log( "Adding new record to" @ other.Rec[i].TMN, 'MutBestTimes' );
                }

                // Copy all the data over, if this is a new record, or if the time is faster.
                if( Rec[mapIdx].PSRL[recIdx].SRT == 0.0 || Rec[mapIdx].PSRL[recIdx].SRT > other.Rec[i].PSRL[j].SRT )
                {
                    // Log( "Adding improved record to" @ other.Rec[i].TMN, 'MutBestTimes' );
                    Rec[mapIdx].PSRL[recIdx].PLs = other.Rec[i].PSRL[j].PLs;
                    Rec[mapIdx].PSRL[recIdx].SRT = other.Rec[i].PSRL[j].SRT;
                    Rec[mapIdx].PSRL[recIdx].SRD[0] = other.Rec[i].PSRL[j].SRD[0];
                    Rec[mapIdx].PSRL[recIdx].SRD[1] = other.Rec[i].PSRL[j].SRD[1];
                    Rec[mapIdx].PSRL[recIdx].SRD[2] = other.Rec[i].PSRL[j].SRD[2];
                    Rec[mapIdx].PSRL[recIdx].ExtraPoints = other.Rec[i].PSRL[j].ExtraPoints;
                    Rec[mapIdx].PSRL[recIdx].ObjectivesCount = other.Rec[i].PSRL[j].ObjectivesCount;
                    Rec[mapIdx].PSRL[recIdx].Flags = other.Rec[i].PSRL[j].Flags;

                    // Our first record time was improved.
                    if( recIdx == 0 )
                    {
                        // Log( "Adding best record to" @ other.Rec[i].TMN, 'MutBestTimes' );
                        bBestReplaced = true;
                    }
                }
            }

            if( bBestReplaced )
            {
                bBestReplaced = false;

                // Fails since the last hijack.
                Rec[mapIdx].TMFailures = other.Rec[i].TMFailures;
            }

            // Re-sort the player records.
            SortRecords( Rec[mapIdx].PSRL );
        }
        else
        {
            // We don't have this map, copy the entire map's data.
            mapIdx = Rec.Length;
            Rec.Length = mapIdx + 1;
            Rec[mapIdx] = other.Rec[i];
            Log( "Registering new record" @ other.Rec[i].TMN, 'MutBestTimes' );
        }
    }
}

final function int CreateRecord( string mapName, int registerDate )
{
    local int i;

    i = Rec.Length - 1;
    Rec.Insert( i, 1 );
    Rec[i].TMN = mapName;
    Rec[i].RegisterDate = registerDate;
    return i;
}

final static function int MakeCompactDate( LevelInfo Level )
{
    return DateToCompactDate( Level.Year, Level.Month, Level.Day );
}

final static function int DateToCompactDate( int year, int month, int day )
{
    return year << 16 | month << 8 | day;
}

final static function GetCompactDate( int date, out int year, out int month, out int day )
{
    year = date >> 16;
    month = byte(date >> 8);
    day = byte(date & 0xFF);
}

final function int FindRecord( string mapName )
{
    local int i;

    for( i = 0; i < Rec.Length; ++ i )
    {
        if( Rec[i].TMN ~= mapName )
        {
            return i;
        }
    }
    return -1;
}

final function int FindRecordMatch( string mapName )
{
    local int i;

    i = FindRecord( mapName );
    if( i != -1 )
        return i;

    mapName = Locs( mapName );
    for( i = 0; i < Rec.Length; ++ i )
    {
        if( InStr( Locs( Rec[i].TMN ), mapName ) != -1 )
        {
            return i;
        }
    }
    return -1;
}

final function int FindRecordSlot( int mapIndex, int playerId )
{
    local int i, j;

    j = Rec[mapIndex].PSRL.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Rec[mapIndex].PSRL[i].PLs == playerId )
        {
            return i;
        }
    }
    return -1;
}

// 0 = no rank
final function int GetPlayerRank( int mapIndex, int playerId )
{
    local int rank;

    rank = FindRecordSlot( mapIndex, playerId );
    if( rank != -1 )
        return rank + 1;

    return 0;
}

final function int OpenRecordSlot( out array<sSoloRecord> times, float recordTime )
{
    local int i, j, k;
    local float p;

    if( times.Length == 0 )
    {
        times.Length = 1;
        return 0;
    }

    j = times.Length - 1;
    while( i <= j )
    {
        k = (i + j)/2;
        p = times[k].SRT;
        if( recordTime < p )
        {
            j = k - 1;
        }
        else if( recordTime > p )
        {
            i = k + 1;
        }
        else break;
    }
    k += int(recordTime >= p);
    times.Insert( k, 1 );
    return k;
}

final function SortRecords( out array<sSoloRecord> times )
{
    local int i, j, y, z;
    local sSoloRecord tmp;

    j = times.Length;
    for( i = 0; i < (j - 1); ++ i )
    {
        z = i;
        for( y = (i + 1); y < j; ++ y )
            if( times[y].SRT < times[z].SRT )
                z = y;

        tmp = times[z];
        times[z] = times[i];
        times[i] = tmp;
    }
}

final function bool PlayerLikeMap( int recordSlot, int playerSlot )
{
    local int i;

    for( i = 0; i < Rec[recordSlot].Likers.Length; ++ i )
    {
        if( Rec[recordSlot].Likers[i] == playerSlot )
        {
            return false;
        }
    }

    for( i = 0; i < Rec[recordSlot].Dislikers.Length; ++ i )
    {
        if( Rec[recordSlot].Dislikers[i] == playerSlot )
        {
            Rec[recordSlot].Dislikers.Remove( i, 1 );
            break;
        }
    }

    Rec[recordSlot].Likers[Rec[recordSlot].Likers.Length] = playerSlot;
    UpdateMapRating( recordSlot );
    return true;
}

final function bool PlayerDislikeMap( int recordSlot, int playerSlot )
{
    local int i;

    for( i = 0; i < Rec[recordSlot].Dislikers.Length; ++ i )
    {
        if( Rec[recordSlot].Dislikers[i] == playerSlot )
        {
            return false;
        }
    }

    for( i = 0; i < Rec[recordSlot].Likers.Length; ++ i )
    {
        if( Rec[recordSlot].Likers[i] == playerSlot )
        {
            Rec[recordSlot].Likers.Remove( i, 1 );
            break;
        }
    }

    Rec[recordSlot].Dislikers[Rec[recordSlot].Dislikers.Length] = playerSlot;
    UpdateMapRating( recordSlot );
    return true;
}

private function UpdateMapRating( int recordSlot )
{
    Rec[recordSlot].Rating = float(Rec[recordSlot].Likers.Length)/float(Rec[recordSlot].Dislikers.Length + Rec[recordSlot].Likers.Length);
}

final function string GetMapRating( int recordSlot )
{
    return string(Rec[recordSlot].Rating*10.00);
}

defaultproperties
{
}
