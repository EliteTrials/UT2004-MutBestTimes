//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_RecordsData extends Object
    hidedropdown;

const VERSION = 3;
const POINTS_VERSION = 1;

const RFLAG_CP = 0x01;

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

    /** Trial map Previous Time. */
    var /**deprecated*/ float TMPT;

    /** (OBSOLETE) The time it took to complete an objective. */
    var /**deprecated*/ array<float> ObjCompT;

    /** (Regular) The index of the players that own this record. */
    var /**deprecated*/ int PLs[4];

    /** The amount of objectives each player did in this record.
     * Only the first index(0) is used in Solo and Group records.
     */
    var /**deprecated*/ int Objs[4];

    /** Amount of times this record was hijacked(beaten). */
    var int TMHijacks;

    /** Amount of contributors this record had(anyone who did an objective is counted, goes beyond 4). */
    var int TMContributors;

    /** Amount of times people have failed to beat this record, this includes revotes but not deaths. */
    var int TMFailures;

    /** Amount of times people have completed this map. */
    var int TMFinish;

    /** (OBOSLETE(was used to display the reward people might get for beating the record))
     * Amount of points this record gave last time it was recorded.
     */
    var /**deprecated*/ float TMPoints;

    /** The Ghost is disabled on this map. */
    var bool TMGhostDisabled;

    /** All individual records */
    var array<sSoloRecord> PSRL;

    /** The calculated or set rating of this map
     * i.e. How difficult is this map? How long? each pros should increment the rating,
     * this can then be used to scale up the points reward for this record.
     */
    var int TMRating;

    /** The rating is already set by an admin or automatic by the calculation,
     * this is used to disable the auto rating for this map so that admins can overwrite it.
     */
    var bool TMRatingSet;

    /** Whether to ignore any point rewards for this record. */
    var bool bIgnoreStats;

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
};

/** The list of all records made on this server. FIXME: Should be called Maps, as it currently stands ambiguous with solo records. */
var array<sBTRecordInfo> Rec;
var int DataVersion;
var int SavedPointsVersion;
var transient MutBestTimes BT;

final function Free()
{
    BT = none;
}

final function Init( MutBestTimes mut )
{
    BT = mut;
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

                // The top record was beaten by the old save file, copy over all of the records data.
                Rec[mapIdx].TMContributors = other.Rec[i].TMContributors;
                // Fails since the last hijack.
                Rec[mapIdx].TMFailures = other.Rec[i].TMFailures;
            }

            // Re-sort the player records.
            SortRecords( mapIdx );
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
    return Level.Year << 16 | Level.Month << 8 | Level.Day;
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

final function int FindRecordSlot( int mapSlot, int playerSlot )
{
    local int i;

    for( i = 0; i < Rec[mapSlot].PSRL.Length; ++ i )
    {
        if( Rec[mapSlot].PSRL[i].PLs == playerSlot )
        {
            return i;
        }
    }
    return -1;
}

final function SortRecords( int mapSlot )
{
    local int i, j, y, z;
    local sSoloRecord tmp;

    j = Rec[mapSlot].PSRL.Length;
    for( i = 0; i < (j - 1); ++ i )
    {
        z = i;
        for( y = (i + 1); y < j; ++ y )
            if( Rec[mapSlot].PSRL[y].SRT < Rec[mapSlot].PSRL[z].SRT )
                z = y;

        tmp = Rec[mapSlot].PSRL[z];
        Rec[mapSlot].PSRL[z] = Rec[mapSlot].PSRL[i];
        Rec[mapSlot].PSRL[i] = tmp;
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
    Rec[recordSlot].Rating = Rec[recordSlot].Likers.Length/(Rec[recordSlot].Dislikers.Length + Rec[recordSlot].Likers.Length);
}

final function string GetMapRating( int recordSlot )
{
    return string(Rec[recordSlot].Rating*10);
}

defaultproperties
{
}
