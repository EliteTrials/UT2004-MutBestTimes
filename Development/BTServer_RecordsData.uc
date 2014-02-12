//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_RecordsData extends Object
    hidedropdown;

const Version = 2;

struct sSoloRecord
{
    /** Index into the PlayerList.
     * 0 = none.
     * The index is 1 value higher and so should always be decremented by 1 to get the real index.
     */
    var int PLs;

    /** Solo Record Time as seconds.ms */
    var float SRT;

    /** Solo Record Data as Day/Month/Year */
    var int SRD[3];

    /** Additional given points by this record e.g. Keys or GroupTasks. */
    var int ExtraPoints;

    /** Objectives that were completed during recording this record. */
    var int ObjectivesCount;
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

    // A cached average of record times.
    var float AverageRecordTIme;
};

/** The list of all records made on this server. */
var array<sBTRecordInfo> Rec;
var int DataVersion;

final function bool ConvertData()
{
    local int i, j, l;
    local int y, m, d;

    if( DataVersion >= Version )
    {
        return false;
    }

    Log( "Updating the data format of records to version" @ Version @ "from version" @ DataVersion, 'MutBestTimes' );
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
    DataVersion = Version;
    return true;
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

defaultproperties
{
}
