//=============================================================================
// Copyright 2005-2014 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class MutBestTimes extends Mutator
    config(MutBestTimes)
    dependson(BTStructs)
    dependson(BTServer_PlayersData)
    dependson(BTServer_RecordsData)
    dependson(BTAchievements)
    dependson(BTChallenges)
    dependson(BTActivateKey);

#exec obj load file="..\System\TrialGroup.u"
// #exec obj load file="..\Sounds\Stock\AnnouncerFemale2k4.uax"
#exec obj load file="..\Sounds\Stock\AnnouncerSexy.uax"

//#include DEC_Structs.uc

//==============================================================================
// Macros
//  Major Version // Major modification
//  Minor Version  // minor new features
//  Build Number // compile/test count, resets??
//  Revision // quick fix
const BTVersion                         = "4.0.0.0";
const MaxPlayers                        = 3;                                    // Note: Setting this higher than 4 will cause the extra players to not receive any points for the record!.
const MaxRecentRecords                  = 15;                                   // The max recent records that is saved.
const MaxPlayerRecentRecords            = 5;                                    // The max recent records that are saved per player.
const MaxHistoryLength                  = 25;
const MaxRecentMaps                     = 20;
const BTCredits                         = "(C) 2005-2014 Eliot and .:..:. All Rights Reserved";     // copyright
const BTAuthor                          = "2e216ede3cf7a275764b04b5ccdd005d";   // Author guid, gives access to some admin commands...

// Points Related.
const PointsPerObjective                = 0.25f;

const EXP_ImprovedRecord                = 25;
const EXP_FirstRecord                   = 40;
const EXP_TiedRecord                    = 30;
const EXP_FailRecord                    = 3;
const EXP_Objective                     = 4;

const META_DECOMPILER_VAR_AUTHOR                = "Eliot Van Uytfanghe";
const META_DECOMPILER_VAR_COPYRIGHT             = "(C) 2005-2014 Eliot and .:..:. All Rights Reserved";
const META_DECOMPILER_EVENT_ONLOAD_MESSAGE      = "Please, only decompile this for learning purposes, do not edit the author/copyright information!";

const groupNum = 2;
const soloNum = 1;
const regularNum = 0;

struct sPointsList
{
    var const int
        PPlayer[3];
};

struct sSharedPoints
{
    var const sPointsList
        PlayerPoints[3];
};

// A bound player account to sPlayer. Accessed by PLSlot
struct sPlayerStats                                                             // Temporary stats, calculated every map!
{
    var string
        PLID;

    var float
        PLPoints;

    var int
        PLSlot,                                                                 // Slot to the real account, Note:This slot is not incremented by 1!
        PLRecords,                                                              // Amount of holding records.
        PLTopRecords;
};

struct KeepScoreSE                                                              // structure to hold data of a leaving player, removed when a new round or map starts.
{                                                                               // usefull for people who disconnect and end up losing their stats.
    var string
        ClientID;

    var int
        Score,                                                                  // the score this player had.
        Objectives,                                                             // how many objs this player had.
        FinalObjectives,                                                        // how many final objs this player had(0/1duh).
        LeftOnRound;                                                            // which round the player leaved.

    var Controller
        ClientFlesh;
};

struct sClientSpawn                                                             // structure holding a player his own playerstart
{
    var int TeamIndex;
    var int
        PHealth,
        PShield;

    var BTServer_ClientStartPoint
        PStart;

    var array< class<Weapon> >
        PWeapons;

    var PlayerController
        PC;
};

struct sCmdInfo
{
    var string Cmd;
    var array<string> Params;
    var string Help;
};

struct sRacer
{
    var Controller Leader;
    var Controller Stalker;
};

var const class<BTServer_ClientStartPoint>          ClientStartPointClass;
var const class<BTClient_TrailerInfo>               TrailerInfoClass;
var const class<BTClient_RankTrailer>               RankTrailerClass;
var const class<BTServer_CheckPointNavigation>      CheckPointNavigationClass;
var const class<BTServer_CheckPoint>                CheckPointHandlerClass;
var const class<BTServer_HttpNotificator>           NotifyClass;

var array<GameObjective>                            Objectives;                 // An array containig all objectives for ClientSpawn performance
var array<Triggers>                                 Triggers;                   // An array containig all triggers for ClientSpawn performance
var private array<KeepScoreSE>                      KeepScoreTable;             // Backed up score from leaving players.
var array<sPlayerStats>                             SortedOverallTop;           // An array containing all the data of PDat.Player, but in order by points.
var array<sPlayerStats>                             SortedQuarterlyTop;
var array<sPlayerStats>                             SortedDailyTop;
var array<float>                                    ObjCompT;                   // Temporary Objective Complete Times, moves to saved BMTL.ObjCompT when new rec.
var array<sClientSpawn>                             ClientPlayerStarts;         // Current playerstarts in the current map, cleaned when user performs 'DeleteClientSpawn' or when server travels or on QuickStart
var const float                                     RPScale[10];                // List of points scaling values
var private const array<sCmdInfo>                   Commands;
var const array<int>                                ObjectiveLevels;
var const array<class<BTServer_Mode> >              TrialModes;
var array<sRacer>                                   Racers;
var BTServer_CheckPoint                             CheckPointHandler;

struct sTrailerInfo
{
    var BTClient_TrailerInfo T;
    var int P;
};

var array<sTrailerInfo>                             Trailers;

//var private editconst BTServer_SecondsTest            TimerTest;              // For Testing time sync purpose between second and milliseconds.
var BTClient_MutatorReplicationInfo                 MRI;                        // Contains all the data clients might want to use.
var ASGameInfo                                      AssaultGame;                // reference to ASGameInfo
var UTServerAdminSpectator                          WebAdminActor;              // For Logging, messaging

//===============<GHOST VARS>=====================================
// Rewards related.
const Objectives_GhostFollow            = 15000;
const GhostFollowPrice                  = 25;
const GhostFollowDiePrice               = 1;

var private SMovDat                                 OldGhostData;               // Old ghost data object, only used for converting to new ghost data object system
var BTServer_GhostLoader                            GhostManager;               // Currently used ghost data loader.
var array<BTServer_GhostSaver>                      RecordingPlayers;           // Players we are currently recording.

// Que of ghosts yet to be saved in 'GhostSave's state. Array of playerslots starting with index 0, -1 = none.
var private array<int>                              NewGhostsQue;
struct sNewGhostsInfo
{
    var BTServer_GhostSaver Moves;
    var BTServer_GhostData GhostData;
};
var private array<sNewGhostsInfo>                   NewGhostsInfo;
var PlayerController                                LeadingGhost;               // PlayerController the ghost should reset CurrentMove for

// "GhostFollow <PlayerName>" was used on a player by an Admin.
var bool                                            bGhostWasAdminAwarded;

// Used in 'SaveGhost' state
var private int
    CurMove,
    MaxMove,
    SavedMoves,
    iGhost,
    TotalSavedMoves;

var bool bGhostIsSaving; // For SaveGhost state and votinghandler
var bool bRedoVotingTimer; // for SaveGhost state and votinghandler

var() globalconfig float GhostSaveSpeed;
var() globalconfig bool bSpawnGhost;
var() globalconfig int GhostPlaybackFPS;
var const noexport string GhostDataFileName;
//===============</GHOST VARS>====================================

var BTServer_RecordsData                            RDat;                       // Holds all the Records
var BTServer_PlayersData                            PDat;                       // Holds all the Players
var sSharedPoints                                   PPoints;                    // Structure containing the points players will be rewarded with

// External
var GroupManager                                    GroupManager;

var BTServer_Mode                                   CurMode;
var private BTGameRules                             ModeRules;
var BTServer_HttpNotificator                        Notify;
var BTAchievements                                  AchievementsManager;
var BTChallenges                                    ChallengesManager;
var BTStore                                         Store;

var bool
    bPracticeRound,                                                             // Asssault is in Practice Round                                                                // Obsolete?
    bRecentRecordsUpdated,
    bMaxRoundSet,                                                               // Fixed rounds (default 2 rounds) to 1
    bQuickStart,                                                                // QuickStart is in progress right now
    bLCAMap,                                                                    // Current Map is using LevelConfigActor
    bKeyMap,
    bSoloMap,                                                                   // Map is solo i.e One objective only
    bGroupMap,                                                                  // Map supports group aka team working.
    bRegularMap,
    bAlwaysKillClientSpawnPlayersNearTriggers;

var enum ERecordTeam
{
    RT_None,
    RT_Red,
    RT_Blue
} RecordByTeam;

var int
    // CurrentMapSlot of BMTL/RDat.Rec
    UsedSlot;

var float
    StartLevelTimer,                                                            // Level.TimeSeconds when MatchStarting() (!bSolo)
    BestPlaySeconds,                                                            // Record Time of CurrentMap
    CurrentPlaySeconds,                                                         // Current Elapsed Seconds (!bSolo)
    SecondsTest;                                                                // Obsolete?, Purpose sync Timer() Seconds to MilliSeconds Timer() test

var string
    CurrentMapName,                                                             // Holds current map name
    RankPrefix[4];

var const noexport string RecordsDataFileName;
var const noexport string PlayersDataFileName;

var private int
    CurCountdown;

// The rank the player has to be to receive besttimes rewards such as trailers!
var int MaxRewardedPlayers;
var string Holiday;

var private config bool bUpdateWebOnNextMap;

var globalconfig
    string
    LastRecords[MaxRecentRecords],
    EventDescription;   // "" empty for no event

var private array<string> EventMessages;

var globalconfig
    array<string>
    History;

var globalconfig int MaxItemsToReplicatePerTick;

var globalconfig int GroupFinishAchievementUnlockedNum;
var bool bBlockSake;
const UnlockBlockSakeCount = 10;


// Options
var() globalconfig
    bool
    bAggressiveMonsters,
    bGenerateBTWebsite,
    bEnhancedTime,
    bShowRankings,
    bNoRandomSpawnLocation,
    bDisableForceRespawn,
    bDebugMode,
    bShowDebugLogToWebAdmin,
    bNotifyRecordDeletingHistory,
    bMapSkillAdminControlled,
    bAllowClientSpawn,
    bTriggersKillClientSpawnPlayers,
    bClientSpawnPlayersCanCompleteMap,
    bSavePreviousGhost,
    bAddGhostTimerPaths,
    bAllowCompetitiveMode,
    bDontEndGameOnRecord,
    bDisableWeaponBoosting,
    bEnableInstigatorEmpathy;

var() globalconfig
    string
    ADMessage,
    ADURL;

var() globalconfig
    int
    MaxRankedPlayers;

var() globalconfig
    int
    PointsPerLevel,
    MaxLevel,
    ObjectivesEXPDelay,
    DropChanceCooldown,
    MinExchangeableTrophies,
    MaxExchangeableTrophies,
    DaysCountToConsiderPlayerInactive;

var() globalconfig
    name
    // AnnouncerFemale2K4.Generic.HolyShit_F
    AnnouncementRecordImprovedVeryClose,
    // AnnouncerFemale2K4.Generic.Last_Second_Save
    AnnouncementRecordImprovedClose,
    // AnnouncerFemale2K4.Generic.Hijacked
    AnnouncementRecordHijacked,
    // AnnouncerFemale2K4.Generic.WhickedSick
    AnnouncementRecordSet,
    // AnnouncerFemale2K4.Generic.Invulnerable
    AnnouncementRecordTied,
    // AnnouncerFemale2K4.Generic.Denied
    AnnouncementRecordFailed,
    // AnnouncerFemale2K4.Generic.Totalled
    AnnouncementRecordAlmost;

var() globalconfig
    float
    CompetitiveTimeLimit,
    TimeScaling;

var() localized editconst const
    string
    lzMapName,                  lzPlayerName,
    lzRecordTime,               lzRecordAuthor,     lzRecordPoints,
    lzFinished,                 lzHijacks,          lzFailures,                 lzRating,           lzRecords,
    lzCS_Set,                   lzCS_Deleted,       lzCS_NotAllowed,            lzCS_Failed,
    lzCS_ObjAndTrigger,         lzCS_Obj,           lzCS_AllowComplete,
    lzCS_NoPawn,                lzCS_NotEnabled,    lzCS_NoQuickStartDelete,
    lzRandomPick, lzClientSpawn;

//AddSetting(string Group, string PropertyName, string Description, byte SecLevel,
//byte Weight, string RenderType, optional string Extras, optional string ExtraPrivs,
//optional bool bMultiPlayerOnly, optional bool bAdvanced);

struct sConfigProperty
{
    var Property Property;
    var localized string Category;
    var localized string Description;
    var localized string Hint;
    var byte AccessLevel;
    var byte Weight;

    /** If Type is *empty* then the type will be guessed from the Property.Class variable. */
    var string Type;

    /** "DEFAULT;MIN:MAX" */
    var string Rules;
    var string Privileges;
    var bool bMultiPlayerOnly;
    var bool bAdvanced;
};

var array<sConfigProperty> ConfigurableProperties;

var const string InvalidAccessMessage;

var private editconst const color cDarkGray;
var private editconst const color BlackColor;

/** Returns int A as a color tag. */
static final preoperator string $( int A )
{
    return Chr( 0x1B ) $ (Chr( Max(byte(A >> 16), 1)  ) $ Chr( Max(byte(A >> 8), 1) ) $ Chr( Max(byte(A & 0xFF), 1) ));
}

/** Returns color A as a color tag. */
static final preoperator string $( Color A )
{
    return (Chr( 0x1B ) $ (Chr( Max( A.R, 1 )  ) $ Chr( Max( A.G, 1 ) ) $ Chr( Max( A.B, 1 ) )));
}

/** Adds B as a color tag to the end of A. */
static final operator(40) string $( coerce string A, Color B )
{
    return A $ $B;
}

/** Adds A as a color tag to the begin of B. */
static final operator(40) string $( Color A, coerce string B )
{
    return $A $ B;
}

/** Adds B as a color tag to the end of A with a space inbetween. */
static final operator(40) string @( coerce string A, Color B )
{
    return A @ $B;
}

/** Adds A as a color tag to the begin of B with a space inbetween. */
static final operator(40) string @( Color A, coerce string B )
{
    return $A @ B;
}

/**
 * Tests if A contains color tag B.
 *
 * @return      TRUE if A contains color tag B, FALSE if A does not contain color tag B.
 */
static final operator(24) bool ~=( coerce string A, Color B )
{
    return InStr( A, $B ) != -1;
}

/** Adds B as a color tag to the end of A. */
static final operator(44) string $=( out string A, color B )
{
    return A $ $B;
}

/** Adds B as a color tag to the end of A with a space inbetween. */
static final operator(44) string @=( out string A, Color B )
{
    return A @ $B;
}

/** Strips all color B tags from A. */
static final operator(45) string -=( out string A, Color B )
{
    return A -= $B;
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

/** Replaces all color B tags in A with color C tags. */
static final function string ReplaceColorTag( string A, Color B, Color C )
{
    return Repl( A, $B, $C );
}

/** Converts a color tag from A to a color struct into B. */
static final function ColorTagToColor( string A, out Color B )
{
    A = Mid( A, 1 );
    B.R = byte(Asc( Left( A, 1 ) ));
    A = Mid( A, 1 );
    B.G = byte(Asc( Left( A, 1 ) ));
    A = Mid( A, 1 );
    B.B = byte(Asc( Left( A, 1 ) ));
    B.A = 0xFF;
}

//==============================================================================
// Find out if I am in ServerPackages, if so, remove myself.
private final static function bool IsInServerPackages()
{
    local int i;

    if( class'BTUtils'.static.IsInServerPackages( "ServerBTimes", i ) )
    {
        class'GameEngine'.default.ServerPackages.Remove( i, 1 );
        class'GameEngine'.static.StaticSaveConfig();
        return true;
    }
    return false;
}

final function bool IsTrials()
{
    return ASGameInfo(Level.Game) != none;
}

final function bool IsClientSpawnPlayer( Pawn player )
{
    return player.LastStartSpot != none && player.LastStartSpot.IsA( ClientStartPointClass.Name );
}

final function NotifyObjectiveAccomplished( PlayerController PC, float score )
{
    local int playerSlot;
    local BTClient_ClientReplication CRI;

    CRI = GetRep( PC );
    if( CRI == none )
        return;

    playerSlot = CRI.myPlayerSlot;
    if( playerSlot != -1 && (PC.Pawn != none && !IsClientSpawnPlayer( PC.Pawn )) )
    {
        ++ PDat.Player[playerSlot].PLObjectives;
        if( PDat.Player[playerSlot].PLObjectives >= 10000 )
        {
            // Objectives farmer
            PDat.ProgressAchievementByID( playerSlot, 'obj_0' );
        }

        if( (Level.TimeSeconds - CRI.LastObjectiveCompletedTime) >= ObjectivesEXPDelay )
        {
            if( bSoloMap )
            {
                if( bKeyMap || bGroupMap )
                {
                    // Accelerate xp
                    PDat.AddExperience( playerSlot, EXP_Objective + GetPlayerObjectives( PC ) );
                }
                else
                {
                    PDat.AddExperience( playerSlot, EXP_Objective );
                }
            }
            else
            {
                PDat.AddExperience( playerSlot, EXP_Objective + 5 + GetPlayerObjectives( PC ) );
            }

            CRI.LastObjectiveCompletedTime = Level.TimeSeconds;
        }

        CurMode.PlayerCompletedObjective( PC, CRI, score );
    }
}

//==============================================================================
// Achievements(etc) Region!
final function PlayerController FindPCByPlayerSlot( int playerSlot, optional out BTClient_ClientReplication rep )
{
    local Controller C;

    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) == none )
        {
            continue;
        }

        rep = GetRep( C );
        if( rep == none )
            continue;

        if( rep.myPlayerSlot == playerSlot )
            return PlayerController(C);
    }
    rep = none;
    return none;
}

final function NotifyPlayers( PlayerController instigator, coerce string broadcastMessage, coerce string priveMessage )
{
    local Controller C;

    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) == none || C == instigator )
            continue;

        PlayerController(C).ClientMessage( broadcastMessage );
    }

    instigator.ClientMessage( priveMessage );
}

final function NotifySpentCurrency( int playerSlot, int currencySpent )
{
    local PlayerController PC;
    local BTClient_ClientReplication CRI;

    PC = FindPCbyPlayerSlot( playerSlot, CRI );
    if( PC == none )
    {
        return;
    }

    CRI.BTPoints = PDat.Player[playerSlot].LevelData.BTPoints;
}

final function NotifyGiveCurrency( int playerSlot, int currencyReceived )
{
    local PlayerController PC;
    local BTClient_ClientReplication CRI;

    PC = FindPCbyPlayerSlot( playerSlot, CRI );
    if( PC == none )
    {
        return;
    }

    CRI.BTPoints = PDat.Player[playerSlot].LevelData.BTPoints;
    if( currencyReceived < 0 )
    {
        PC.ClientMessage( "You have lost" @ class'HUD'.default.RedColor $ currencyReceived $ class'HUD'.default.WhiteColor @ "currency points!" );
    }
    else
    {
        PC.ClientMessage( "You have received" @ class'HUD'.default.GreenColor $ currencyReceived $ class'HUD'.default.WhiteColor @ "currency points!" );
    }
}

final function NotifyItemBought( int playerSlot )
{
    // Buy your first item
    PDat.ProgressAchievementByID( playerSlot, 'store_0' );

    if( PDat.Player[playerSlot].Inventory.BoughtItems.Length >= 10 )
    {
        // Shopping like a girl
        PDat.ProgressAchievementByID( playerSlot, 'store_2' );
    }
}

final function NotifyExperienceAdded( int playerSlot, int experienceAdded )
{
    local PlayerController PC;
    local BTClient_ClientReplication CRI;

    PC = FindPCbyPlayerSlot( playerSlot, CRI );
    if( PC == none )
    {
        return;
    }

    if( experienceAdded >= 64 )
    {
        PDat.ProgressAchievementByID( CRI.myPlayerSlot, 'experience_0' );
    }

    CRI.BTLevel = PDat.GetLevel( playerSlot, CRI.BTExperience );

    PC.ClientMessage( "You have earned" @ class'HUD'.default.GreenColor $ experienceAdded $ class'HUD'.default.WhiteColor @ "experience!" );
}

final function NotifyExperienceRemoved( int playerSlot, int experienceRemoved )
{
    local PlayerController PC;
    local BTClient_ClientReplication CRI;

    PC = FindPCbyPlayerSlot( playerSlot, CRI );
    if( PC == none )
    {
        return;
    }

    CRI.BTLevel = PDat.GetLevel( playerSlot, CRI.BTExperience );

    PC.ClientMessage( "You have lost" @ class'HUD'.default.RedColor $ experienceRemoved $ class'HUD'.default.WhiteColor @ "experience!" );
}

final function NotifyLevelUp( int playerSlot, int BTLevel )
{
    local PlayerController PC;
    local BTClient_ClientReplication CRI;

    PC = FindPCbyPlayerSlot( playerSlot, CRI );
    if( PC == none )
    {
        return;
    }

    PDat.ProgressAchievementByType( CRI.myPlayerSlot, 'LevelUp', 1 );

    if( BTLevel >= 50 )
    {
        // Dedicated noob
        PDat.ProgressAchievementByID( CRI.myPlayerSlot, 'level_4' );
        if( BTLevel >= 100 )
        {
            // Dedicated gamer
            PDat.ProgressAchievementByID( CRI.myPlayerSlot, 'level_5' );
        }
    }

    if( xPawn(PC.Pawn) != none )
    {
        xPawn(PC.Pawn).PlayTeleportEffect( false, true );
    }

    CRI.BTPoints = PDat.Player[playerSlot].LevelData.BTPoints;

    NotifyPlayers( PC,
     PC.GetHumanReadableName() @ "is now level" @ class'HUD'.default.GreenColor $ BTLevel,
     "You are now level" @ class'HUD'.default.GreenColor $ BTLevel $ "." $ class'HUD'.default.WhiteColor
        @ "You also earned" @ class'HUD'.default.GreenColor $ PointsPerLevel * BTLevel @ class'HUD'.default.WhiteColor $ "currency points." );
}

final function NotifyLevelDown( int playerSlot, int BTLevel )
{
    local PlayerController PC;
    local BTClient_ClientReplication CRI;

    PC = FindPCbyPlayerSlot( playerSlot, CRI );
    if( PC == none )
    {
        return;
    }

    CRI.BTPoints = PDat.Player[playerSlot].LevelData.BTPoints;

    NotifyPlayers( PC,
     PC.GetHumanReadableName() @ "became level" @ class'HUD'.default.RedColor $ BTLevel,
     "You became level" @ class'HUD'.default.RedColor $ BTLevel $ "." $ class'HUD'.default.WhiteColor
        @ "You also lost" @ class'HUD'.default.RedColor $ PointsPerLevel * BTLevel @ class'HUD'.default.WhiteColor $ "currency points." );
}

final function NotifyCheckPointChange( Controller C )
{
    PDat.ProgressAchievementByType( GetRep( C ).myPlayerSlot, 'CheckpointUses', 1 );
}

final function AchievementEarned( int playerSlot, name id )
{
    local BTClient_ClientReplication rep;
    local PlayerController PC;
    local BTAchievements.sAchievement ach;
    local int earntAchievements;

    earntAchievements = PDat.CountEarnedAchievements( playerSlot );
    // Above PC == none because currency should always be given even for offline players!.
    ach = AchievementsManager.GetAchievementByID( id );
    PDat.GiveCurrencyPoints( playerSlot, ach.Points + earntAchievements );

    if( PDat.FindAchievementByID( playerSlot, 'ach_0' ) == -1 && earntAchievements >= 30 )
    {
        PDat.ProgressAchievementByID( playerSlot, 'ach_0' );
    }

    // Trials master achievement
    if( PDat.FindAchievementByID( playerSlot, 'ach_1' ) == -1
        && PDat.FindAchievementByID( playerSlot, 'level_5' ) != -1
     )
    {
        if( PDat.FindAchievementByID( playerSlot, 'records_3' ) != -1
        && PDat.FindAchievementByID( playerSlot, 'records_4' ) != -1
        && PDat.FindAchievementByID( playerSlot, 'records_5' ) != -1 )
        {
            PDat.ProgressAchievementByID( playerSlot, 'ach_1' );
        }
    }

    PC = FindPCByPlayerSlot( playerSlot, rep );
    if( PC == none || rep == none )
    {
        return;
    }

    rep.ClientAchievementAccomplished( ach.Title, ach.Icon );

    NotifyPlayers( PC,
     PC.GetHumanReadableName() @ "has earned the achievement" @ $0x60CB45 $ ach.Title,
      "You earned the achievement" @ $0x60CB45 $ ach.Title );
}

final function PlayerEarnedTrophy( int playerSlot, BTChallenges.sChallenge challenge )
{
    local BTClient_ClientReplication rep;
    local PlayerController PC;

    PC = FindPCByPlayerSlot( playerSlot, rep );
    if( PC == none || rep == none )
    {
        return;
    }

    if( PDat.HasTrophy( playerSlot, challenge.ID ) )
        return;

    PDat.AddTrophy( playerSlot, challenge.ID );

    rep.ClientTrophyEarned( challenge.Title );
    NotifyPlayers( PC,
     PC.GetHumanReadableName() @ "has earned the trophy" @ $0x60CB45 $ challenge.Title,
      "You earned the trophy" @ $0x60CB45 $ challenge.Title );

    PDat.GiveCurrencyPoints( playerSlot, challenge.Points );

    if( Left( challenge.ID, 3 ) ~= "MAP" )
    {
        PDat.ProgressAchievementByType( playerSlot, 'FinishDailyChallenge', 1 );
    }
}

final function AchievementProgressed( int playerSlot, name id )
{
    local BTClient_ClientReplication rep;
    local PlayerController PC;
    local BTAchievements.sAchievement ach;

    PC = FindPCByPlayerSlot( playerSlot, rep );
    if( PC == none || rep == none )
    {
        return;
    }

    ach = AchievementsManager.GetAchievementByID( id );

    rep.ClientAchievementProgressed( ach.Title, ach.Icon, PDat.Player[rep.myPlayerSlot].Achievements[PDat.FindAchievementByID( rep.myPlayerSlot, ach.ID )].Progress, ach.Count );
}

final function ProcessJaniAchievement( PlayerReplicationInfo PRI )
{
    PDat.ProgressAchievementByID( GetRep( Controller(PRI.Owner) ).myPlayerSlot, 'jani_1' );
}

final function ProcessEliotAchievement( PlayerReplicationInfo PRI )
{
    PDat.ProgressAchievementByID( GetRep( Controller(PRI.Owner) ).myPlayerSlot, 'eliot_0' );
}


final function ProcessClientSpawnAchievement( PlayerController PC )
{
    PDat.ProgressAchievementByID( GetRep( PC ).myPlayerSlot, 'clientspawn_1' );
}

final function ProcessMap2Achievement( int playerSlot )
{
    PDat.ProgressAchievementByID( playerSlot, 'map_2' );
}

final function SendAchievementsStates( PlayerController requester )
{
    local int i, achSlot;
    local BTClient_ClientReplication Rep;

    //FullLog( "Sending achievements to:" @ requester.GetHumanReadableName() );
    Rep = GetRep( requester );
    if( Rep == none )
        return;

    Rep.ClientCleanAchievements();
    for( i = 0; i < AchievementsManager.Achievements.Length; ++ i )
    {
        achSlot = PDat.FindAchievementByID( Rep.myPlayerSlot, AchievementsManager.Achievements[i].ID );
        if( achSlot != -1 )
        {
            achSlot = PDat.Player[Rep.myPlayerSlot].Achievements[achSlot].Progress;
        }
        else achSlot = 0;

        Rep.ClientSendAchievementState( AchievementsManager.Achievements[i].Title, AchievementsManager.Achievements[i].Description, AchievementsManager.Achievements[i].Icon, Min( achSlot, AchievementsManager.Achievements[i].Count ), AchievementsManager.Achievements[i].Count, AchievementsManager.Achievements[i].Points );
    }
}

final function SendTrophies( PlayerController requester )
{
    local int i;
    local BTClient_ClientReplication Rep;
    local string trophyID;
    local BTChallenges.sChallenge chall;

    //FullLog( "Sending trophies to:" @ requester.GetHumanReadableName() );
    Rep = GetRep( requester );
    if( Rep == none )
        return;

    Rep.ClientCleanTrophies();
    for( i = 0; i < PDat.Player[Rep.myPlayerSlot].Trophies.Length; ++ i )
    {
        trophyID = PDat.Player[Rep.myPlayerSlot].Trophies[i].ID;
        if( Left( trophyID, 3 ) == "MAP" )
        {
            Rep.ClientSendTrophy( Repl( ChallengesManager.DailyChallenge.Title, "%MAPNAME%", Mid( trophyID, 4 ) ) );
        }
        else
        {
            chall = ChallengesManager.GetChallenge( trophyID );
            Rep.ClientSendTrophy( chall.Title );
        }
    }
}

final function SendChallenges( PlayerController requester )
{
    local int i;
    local BTClient_ClientReplication Rep;

    //FullLog( "Sending challenges to:" @ requester.GetHumanReadableName() );
    Rep = GetRep( requester );
    if( Rep == none )
        return;

    for( i = 0; i < ChallengesManager.TodayChallenges.Length; ++ i )
    {
        Rep.ClientSendChallenge(
            Repl( ChallengesManager.DailyChallenge.Title, "%MAPNAME%", ChallengesManager.TodayChallenges[i] ),
            Repl( ChallengesManager.DailyChallenge.Description, "%MAPNAME%", ChallengesManager.TodayChallenges[i] ),
            ChallengesManager.DailyChallenge.Points );
    }

    for( i = 0; i < ChallengesManager.Challenges.Length; ++ i )
    {
        Rep.ClientSendChallenge(
            ChallengesManager.Challenges[i].Title,
            ChallengesManager.Challenges[i].Description,
            ChallengesManager.Challenges[i].Points );
    }
}

final function SendItemMeta( PlayerController requester, string id )
{
    local int i;
    local BTClient_ClientReplication Rep;

    Rep = GetRep( requester );
    if( Rep == none )
        return;

    i = Store.FindItemByID( id );
    if( i == -1 )
    {
        FullLog( "SendItemMeta:Couldn't find item with the id of" @ id );
        return;
    }

    //Log( "SendItemMeta:Sending item data for id:" @ id );

    Rep.ClientSendItemMeta( id, Store.Items[i].Desc, Store.Items[i].CachedIMG );
}

final function SendStoreItems( PlayerController requester, string filter )
{
    local int i;
    local BTClient_ClientReplication Rep;
    local bool showAdminItems;

    Rep = GetRep( requester );
    if( Rep == none )
        return;

    showAdminItems = IsAdmin( requester.PlayerReplicationInfo );
    if( !Rep.bReceivedCategories || filter == "" )
    {
        for( i = 0; i < Store.Categories.Length; ++ i )
        {
            if( Store.Categories[i].Name ~= "Admin" && !showAdminItems )
            {
                continue;
            }
            Rep.ClientSendCategory( Store.Categories[i].Name );
        }

        if( Level.NetMode != NM_Standalone )
        {
            Rep.bReceivedCategories = true;
        }
    }

    Spawn( class'BTItemsReplicator', self ).Initialize(
        rep,
        filter,
        showAdminItems
    );

    // Store discovery
    // PDat.ProgressAchievementByID( Rep.myPlayerSlot, 'store_1' );
}
//==============================================================================

final function bool ValidateAccessFor( BTClient_ClientReplication CRI )
{
    local int i;

    for( i = 0; i < Store.LockedMaps.Length; ++ i )
    {
        if( Store.LockedMaps[i].MapName ~= CurrentMapName )
        {
            if( PDat.UseItem( CRI.myPlayerSlot, Store.LockedMaps[i].ItemID ) )
            {
                return true;
            }
            else
            {
                CRI.ClientCleanText();
                CRI.ClientSendText( $0xFF0000 $ "Sorry you are not permitted to play this map. Please buy the 'Unlock " $ CurrentMapName $ "' item in the Store." );
                CRI.ClientSendText( $0xFF0000 $ "Or use the console command 'Store buy " $ Store.LockedMaps[i].ItemID $ "'" );
                return false;
            }
        }
    }
    return true;
}

final function int GetRankSlot( int myPlayerSlot )
{
    local int i;

    for( i = 0; i < SortedOverallTop.Length; ++ i )
    {
        if( SortedOverallTop[i].PLSlot == myPlayerSlot )
        {
            return i;
        }
    }
    return -1;
}

final function bool ModeIsTrials()
{
    return CurMode != none && CurMode.IsA('BTServer_TrialMode');
}

function DriverEnteredVehicle( Vehicle v, Pawn other )
{
    super.DriverEnteredVehicle( v, other );

    // Ensure this is an actual player, not a bot.
    if( Bot(v.Controller) != none )
    {
        return;
    }

    if( Store != none )
    {
        Store.ModifyVehicle( other, v, PDat, GetRep( v.Controller ) );
    }
}

/** Reset Time, add ranked stuff, handle client spawn and checkpoints! */
function ModifyPlayer( Pawn Other )
{
    local int CheckPointIndex;
    local int i;
    local BTClient_ClientReplication CRI;
    local bool bTrailerRegistered;

    super.ModifyPlayer( Other );

    // Invalid!
    if( xPawn(Other) == None || Other.IsA('BTClient_Ghost') || PlayerController(Other.Controller) == None || Other.PlayerReplicationInfo == none )
    {
        return;
    }

    CRI = GetRep( Other.Controller );
    if( CRI == none )
    {
        FullLog( "===CRI == NONE!! for" @ Other.Controller.GetHumanReadableName() $ "===" );
        PlayerController(Other.Controller).BecomeSpectator();
        Other.Destroy();
        return;
    }

    if( CRI.myPlayerSlot == -1 )
    {
        CRI.myPlayerSlot = FindPlayerSlot( PlayerController(Other.Controller).GetPlayerIDHash() )-1;
    }
    CRI.myPawn = Other;

    CurMode.ModeModifyPlayer( Other, Other.Controller, CRI );

    // This Player GUID is in use by someone else on this server! destroy...
    if( !bSoloMap && FoundDuplicateID( PlayerController(Other.Controller), True ) )
    {
        PlayerController(Other.Controller).BecomeSpectator();
        Other.Destroy();
        return;
    }

    if( Store != none )
    {
        if( !ValidateAccessFor( CRI ) )
        {
            PlayerController(Other.Controller).BecomeSpectator();
            Other.Destroy();
            return;
        }
    }

    // Respawn all my stalkers!
    if( ModeIsTrials() && !bGroupMap )
    {
        for( i = 0; i < Racers.Length; ++ i )
        {
            if( Racers[i].Leader == Other.Controller && Racers[i].Stalker != none && !Racers[i].Stalker.PlayerReplicationInfo.bIsSpectator && !Racers[i].Stalker.PlayerReplicationInfo.bOnlySpectator )
            {
                ModeRules.RespawnPlayer( Racers[i].Stalker.Pawn );
            }
        }
    }

    if( ModeIsTrials() )
    {
        if( !bSoloMap ) // Regular
        {
            RecordGhostForPlayer( PlayerController(Other.Controller) );
        }
        else    // Solo or Group
        {
            if( Other.LastStartSpot.IsA( CheckPointNavigationClass.Name ) )
            {
                /**
                 * @Todo    Instead of restart recording, delete the few last saved moves
                 * @Todo    Don't let the timer keep counting, instead remove what has counted since the last dead
                 */
                if( CheckPointHandler.HasSavedCheckPoint( Other.Controller, CheckPointIndex ) )
                {
                    CheckPointHandler.RestoreStats( Other, CheckPointIndex );
                }
            }
            else if( !IsClientSpawnPlayer( Other ) )
            {
                // Start timer
                CRI.PlayerSpawned();
                if( bSpawnGhost )
                {
                    // Restart ghost recording!
                    RestartGhostRecording( PlayerController(Other.Controller) );

                    // Reset ghost, if wanted
                    if( CRI.HasClientFlags( 0x00000001 ) && (Other.Controller == LeadingGhost || Level.Game.NumPlayers <= 1) )
                    {
                        if( GhostManager != none && !RDat.Rec[UsedSlot].TMGhostDisabled )
                        {
                            GhostManager.GhostsRespawn();
                        }
                    }
                }
            }
        }
    }
    CRI.NetUpdateTime = Level.TimeSeconds - 1;

    if( Store != none )
    {
        Store.ModifyPawn( Other, PDat, CRI );
        if( PDat.UseItem( CRI.myPlayerSlot, "Trailer" ) )
        {
            for( i = 0; i < Trailers.Length; ++ i )
            {
                if( Trailers[i].P == CRI.myPlayerSlot )
                {
                    bTrailerRegistered = true;
                }
            }

            if( !bTrailerRegistered )
            {
                Trailers.Insert( 0, 1 );
                Trailers[0].P = CRI.myPlayerSlot;
            }

            for( i = 0; i < Trailers.Length; ++ i )
            {
                if( Trailers[i].P == CRI.myPlayerSlot )
                {
                    // If hasn't got one yet, create one
                    //if( Trailers[i].T == None )
                    //{
                        if( Trailers[i].T != none )
                        {
                            Trailers[i].T.Destroy();
                        }

                        Trailers[i].T = Spawn( TrailerInfoClass, Other.Controller );
                        if( Trailers[i].T != None )
                        {
                            Trailers[i].T.RankSkin = PDat.Player[CRI.myPlayerSlot].Inventory.TrailerSettings;
                            Trailers[i].T.TrailerClass = RankTrailerClass;
                        }
                    //}

                    // Update it, BPI will automaticly spawn new trailers
                    if( Trailers[i].T != None )
                    {
                        Trailers[i].T.Pawn = Other;
                        if( Level.NetMode != NM_DedicatedServer )
                        {
                            Trailers[i].T.PostNetReceive();
                        }
                    }
                }
            }
        }
    }

    if( ModeIsTrials() )
    {
        // Keys are lost after a dead!, except not if your're using a CheckPoint!
        if( bKeyMap && ASPlayerReplicationInfo(Other.PlayerReplicationInfo) != None && !Other.LastStartSpot.IsA( CheckPointNavigationClass.Name ) )
        {
            ASPlayerReplicationInfo(Other.PlayerReplicationInfo).DisabledObjectivesCount = 0;
            ASPlayerReplicationInfo(Other.PlayerReplicationInfo).DisabledFinalObjective = 0;
        }

        if( bAllowClientSpawn )
        {
            //Other.GiveWeapon( string(class'BTClient_SpawnWeapon') );
            i = GetClientSpawnIndex( Other.Controller );
            if( i != -1 )
            {
                PimpClientSpawn( i, Other );
                CRI.ClientSpawnPawn = other;

                if( Holiday != "" )
                {
                    // No family
                    PDat.ProgressAchievementByID( CRI.myPlayerSlot, 'holiday_0' );
                }
            }
        }
    }
}

private final function ValidateAccess()
{
    local HttpSock sock;
    local string request;

    // Only one test a day.
    if( PDat.DayTest == Level.Day )
        return;

    sock = Spawn( class'HttpSock', self );
    sock.OnComplete = OnValidateSuccess;
    sock.OnError = OnValidateError;
    request = Repl( class'BTActivateKey'.default.VerifyIP, "%ACTION%", class'BTActivateKey'.default.VerifyIPAction );
    sock.Get( request );
}

function OnValidateError( HttpSock sender, string errorMessage, optional string param1, optional string param2 )
{
    FullLog( "Error:" @ errorMessage );
    sender.Destroy();
    InvalidAccess();
}

function OnValidateSuccess( HttpSock sender )
{
    if( !bool(class'BTActivateKey'.static.FixReturnData( sender )) )
    {
        sender.Destroy();
        InvalidAccess();
        return;
    }

    // Only one test a day.
    PDat.DayTest = Level.Day;
    SaveAll();
}

final function InvalidAccess()
{
    local int intNumber;

    FullLog( InvalidAccessMessage );
    Destroy();
    assert( bool(int(bool(string(intNumber)))) );
}

function Tests()
{
}

//==============================================================================
// Initialize everything
event PreBeginPlay()
{
    local int i, j, l;
    local bool bSave;
    local string Credits;
    local GameObjective Obj;

    FullLog( "====================================" );
    FullLog( string(Name) @ BTVersion @ BTCredits );
    // Make sure 'self' is not in ServerPckages!
    FullLog( "Checking ServerPackages for ServerBTimes.u" );
    if( IsInServerPackages() )
        FullLog( "ServerBTimes.u was found in ServerPackages!, removing. Please do not add ServerBTimes.u in ServerPackages!" );

    if( ASGameInfo(Level.Game) != none )
    {
        AssaultGame = ASGameInfo(Level.Game);
        Tag = 'EndRound';

        // Replace some classes
        if( AssaultGame.VotingHandlerClass == None || AssaultGame.VotingHandlerClass == class'xVotingHandler' )
            AssaultGame.VotingHandlerClass = Class'BTServer_VotingHandler';

        AssaultGame.bPlayersBalanceTeams = false;
    }

    if( !Level.Game.IsA('Invasion') )
    {
        Level.Game.ScoreBoardType = string( Class'BTClient_TrialScoreBoard' );
    }

    // Get currentmapname by looking at this class FullName i.e Map.Package.Class
    CurrentMapName = Left( string(Self), InStr( string(Self), "." ) );
    // CurrentMapName = Outer.name;

    LoadData();

    MRI = Spawn( Class'BTClient_MutatorReplicationInfo' );
    MRI.AddToPackageMap();  // Temporary ServerPackage

    Store = class'BTStore'.static.Load();
    Store.Cache();
    AddToPackageMap( "TextureBTimes" );
    // Dangerous code
    /*for( i = 0; i < Store.Items.Length; ++ i )
    {
        if( Store.Items[i].ItemClass != "" )
        {
            AddToPackageMap( Left( Store.Items[i].ItemClass, InStr( Store.Items[i].ItemClass, "." ) ) );
        }

        if( Store.Items[i].IMG != "" )
        {
            AddToPackageMap( Left( Store.Items[i].IMG, InStr( Store.Items[i].IMG, "." ) ) );
        }
    }*/

    Credits = BTCredits;
    Credits = Repl( Credits, "Eliot", Class'HUD'.Default.GoldColor $ "Eliot" $ Class'HUD'.Default.WhiteColor );
    Credits = Repl( Credits, ".:..:", Class'HUD'.Default.GoldColor $ ".:..:" $ Class'HUD'.Default.WhiteColor );
    MRI.Credits = "v" $ Class'HUD'.Default.GoldColor $ BTVersion $ Class'HUD'.Default.WhiteColor @ Credits;
    MRI.PlayersCount = PDat.Player.Length;
    MRI.MaxRecords = RDat.Rec.Length;
    MRI.ADMessage = ADMessage;
    MRI.ADURL = ADURL;
    MRI.TotalCurrencySpent = PDat.TotalCurrencySpent;
    MRI.TotalItemsBought = PDat.TotalItemsBought;

    // Get a list of all the objectives, for ClientSpawn performance
    if( AssaultGame != none )
    {
        foreach AllActors( class'GameObjective', Obj )
            Objectives[Objectives.Length] = Obj;

        AssaultGame.DrawGameSound = '';//GameSounds.Fanfares.UT2K3Fanfare01;
        AssaultGame.AttackerWinRound[0] = AssaultGame.DrawGameSound;
        AssaultGame.AttackerWinRound[1] = AssaultGame.DrawGameSound;
        AssaultGame.DefenderWinRound[0] = AssaultGame.DrawGameSound;
        AssaultGame.DefenderWinRound[1] = AssaultGame.DrawGameSound;
    }

    for( i = 0; i < TrialModes.Length; ++ i )
    {
        if( TrialModes[i].static.DetectMode( self ) )
        {
            CurMode = TrialModes[i].static.NewInstance( self );
            FullLog( "BTimes Mode: " $ CurMode.ModeName );
            break;
        }
    }

    if( ModeIsTrials() )
    {
        // Initialize TMRating for all maps
        for( i = 0; i < RDat.Rec.Length; ++ i )
        {
            if( RDat.Rec[i].TMRatingSet )
                continue;

            RDat.Rec[i].TMRating = 4;   // 0 counts
        }

        // Scan the Registered maps list to find the current map index
        for( i = 0; i < RDat.Rec.Length; ++ i )
        {
            if( RDat.Rec[i].TMN ~= CurrentMapName )
            {
                FullLog( "Found BMTL:"$i$" for "$CurrentMapName );
                UsedSlot = i;

                if( RDat.Rec[UsedSlot].RegisterDate == 0 )
                {
                    RDat.Rec[UsedSlot].RegisterDate = RDat.MakeCompactDate( Level );
                }
                RDat.Rec[UsedSlot].LastPlayedDate = RDat.MakeCompactDate( Level );

                FullLog( "*** Initializing BMTL:"$UsedSlot$" ***" );

                // Find out the difficulty of this map!... Defined by mappers in LevelProperties->Event->ExcludeTag
                if( RDat.Rec[UsedSlot].TMRatingSet )
                    goto 'SkipRating';

                FullLog( "*** No TMRating found for this map, calculating one! You can use 'Mutate SetMapRating <Num 1-5-10>' to config this ***" );

                InitMapRating();

                bSave = True;
            SkipRating:
                j = RDat.Rec[UsedSlot].PSRL.Length;
                if( j > 0 )
                {
                    MRI.SoloRecords = j;

                    // Make sure invalid records are all deleted (caused by .ini corruption!)
                    for( l = 0; l < j; ++ l )
                    {
                        if( RDat.Rec[UsedSlot].PSRL[l].SRT > 1.0f )
                            break;

                        // No longer need however still remains here incase

                        // delete the record
                        RDat.Rec[UsedSlot].PSRL.Remove( l, 1 );
                        -- l;
                        -- j;

                        // Update the uvx files
                        bSave = True;
                    }

                    // Initialize Replication
                    BestPlaySeconds = GetFixedTime( RDat.Rec[UsedSlot].PSRL[0].SRT );
                    MRI.MapBestTime = BestPlaySeconds;

                    UpdateRecordHoldersMessage();
                }
                else
                {
                    BestPlaySeconds = -1;
                }

                // Save was required
                if( bSave )
                    SaveRecords();

                return;
            }
        }

        UsedSlot = RDat.CreateRecord( CurrentMapName, RDat.MakeCompactDate( Level ) );
        InitMapRating();
        SaveRecords();

        // Initialize current match
        BestPlaySeconds = -1;
    }
}

final function UpdateRecordHoldersMessage()
{
    local int i;
    local float time;

    if( RDat.Rec[UsedSlot].PSRL.Length == 0 )
    {
        MRI.PlayersBestTimes = "";
        return;
    }

    MRI.PlayersBestTimes = "";
    time = GetFixedTime( RDat.Rec[UsedSlot].PSRL[0].SRT );
    for( i = 0; i < RDat.Rec[UsedSlot].PSRL.Length; ++ i )
    {
        if( GetFixedTime( RDat.Rec[UsedSlot].PSRL[i].SRT ) != time )
        {
            break;
        }

        if( i != 0 )
        {
            MRI.PlayersBestTimes $= ", ";
        }

        MRI.PlayersBestTimes $= PDat.Player[RDat.Rec[UsedSlot].PSRL[i].PLs-1].PLNAME;
        if( RDat.Rec[UsedSlot].PSRL[i].ObjectivesCount > 0 )
        {
            MRI.PlayersBestTimes
                $= "["
                    $ class'HUD'.default.GoldColor $ RDat.Rec[UsedSlot].PSRL[i].ObjectivesCount
                    $ class'HUD'.default.WhiteColor
                $ "]"
            ;
        }
    }
}

//==============================================================================
//  Note:   0 counts as a rating! 4 = 5(default)
//  Note:   SaveRecords() is required after using this function!
//  ----------------------------------------------------------------------------
//  Slot    :       Scale       :       Difficulty Name
//  1       =       0.200       :       Unknown
//  2       =       0.400       :       Newb
//  3       =       0.600       :       Very Easy
//  4       =       0.800       :       Easy
//  5       =       1.000       :       Normal
//  6       =       1.500       :       Hard
//  7       =       2.000       :       Very Hard
//  8       =       2.500       :       Pro
//  9       =       3.000       :       Insane
//  10      =       3.500       :       Near Impossible
//  ----------------------------------------------------------------------------
//==============================================================================

// RDat.Rec[UsedSlot].TMRating = Min( Max( int( Right( Caps( Level.ExcludeTag[0] ) == "RATING_", 7 ) )-1, 0 ), 10 );
// Compiles lol! xd
private final function InitMapRating()
{
    if( InStr( Caps( Level.ExcludeTag[0] ), "RATING_" ) != -1 )
    {
        RDat.Rec[UsedSlot].TMRating = Min( Max( int(Mid( Caps( Level.ExcludeTag[0] ), 7 ))-1, 0 ), 10 );
    }
    else
    {
        // We check first for solo that if theres a sg map and solo at same time it shouldn't get 8 but only 4 because solo sg maps are quite easy!
        if( bSoloMap )
            RDat.Rec[UsedSlot].TMRating = 4;    // 0 counts
        else if( InStr( Caps( CurrentMapName ), "SHIELDGUN" ) != -1 )
            RDat.Rec[UsedSlot].TMRating = 8;    // 0 counts
        else RDat.Rec[UsedSlot].TMRating = 5;   // 0 counts
    }

    RDat.Rec[UsedSlot].TMRatingSet = True;
}

final function bool IsHoliday()
{
    if( Level.Month == 1 && Level.Day == 1 )
    {
        Holiday = "New Year's Day";
        return True;
    }
    else if( Level.Month == 4 && Level.Day == 1 )
    {
        Holiday = "April Fools' Day";
        return True;
    }
    else if( Level.Month == 4 && (
        (Level.Year == 2010 && Level.Day == 4)
        ||
        (Level.Year == 2011 && Level.Day == 24)
        ||
        (Level.Year == 2012 && Level.Day == 8)
    ))
    {
        Holiday = "Easter Day";
        return True;
    }
    else if( Level.Month == 4 && Level.Day == 18 )
    {
        Holiday = "Group mode birthday";
        return True;
    }
    else if( Level.Month == 5 && Level.Day == 1 )
    {
        Holiday = "Labour Day";
        return True;
    }
    else if( Level.Month == 6 && Level.Day == 5 )
    {
        Holiday = "Solo mode birthday";
        return True;
    }
    else if( Level.Month == 7 && Level.Day == 21 )
    {
        Holiday = "Belgium's National Holiday";
        return True;
    }
    else if( Level.Month == 8 && Level.Day == 15 )
    {
        Holiday = "Assumption of Mary";
        return True;
    }
    else if( Level.Month == 8 && Level.Day == 26 )
    {
        Holiday = "Eliot's birthday";
        return True;
    }
    else if( Level.Month == 9 && Level.Day == 19 )
    {
        Holiday = "Haydon's birthday";
        return True;
    }
    else if( Level.Month == 10 && Level.Day == 31 )
    {
        Holiday = "Halloween";
        return True;
    }
    else if( Level.Month == 11 && Level.Day == 11 )
    {
        Holiday = "Armistice Day";
        return True;
    }
    else if( Level.Month == 11 && Level.Day == 1 )
    {
        Holiday = "All Saints Day";
        return True;
    }
    else if( Level.Month == 12 )
    {
        if( Level.Day == 24 )
        {
            Holiday = "Christmas Eve";
            return True;
        }
        else if( Level.Day == 25 )
        {
            Holiday = "Christmas Day";
            return True;
        }
        if( Level.Day == 31 )
        {
            Holiday = "New Year's Eve";
            return True;
        }
        else
        {
            Holiday = "XMas Month";
            return True;
        }
    }
    return False;
}

//==============================================================================
// Initialize more stuff...
event PostBeginPlay()
{
    local BroadcastHandler Bch;

    super.PostBeginPlay();

    CurMode.ModePostBeginPlay();

    if( NotifyClass.default.Host != "" )
    {
        Notify = new(self) NotifyClass;
        Notify.Connect();
    }

    AchievementsManager = class'BTAchievements'.static.Load();
    ChallengesManager = class'BTChallenges'.static.Load();
    ChallengesManager.GenerateTodayChallenges( Level, RDat );

    if( bShowRankings )
    {
        /*Class'GameInfo'.Static.LoadMapList( "AS", Maps );
        if( Maps.Length > 0 )
        {
            ii = RDat.Rec.Length;
            for( i = 0; i < ii; ++ i )
            {
                // Ignore stats on maps that are no longer available in the server maps folder.
                bFound = False;
                for( l = 0; l < Maps.Length; ++ l )
                {
                    if( RDat.Rec[i].TMN == Maps[l] )
                    {
                        bFound = True;
                        break;
                    }
                }
                RDat.Rec[i].bIgnoreStats = !bFound;
            }
        }
        else
        {
            VH = xVotingHandler(Level.Game.VotingHandler);
            if( VH != None )
            {
                for( i = 0; i < RDat.Rec.Length; ++ i )
                {
                    bFound = False;
                    for( l = 0; l < VH.MapList.Length; ++ l )
                    {
                        if( RDat.Rec[i].TMN == VH.MapList[l].MapName )
                        {
                            bFound = True;
                            break;
                        }
                    }
                    RDat.Rec[i].bIgnoreStats = !bFound;
                }
            }
            goto 'SkipMTTest';
        }

        Class'GameInfo'.Static.LoadMapList( "MT", Maps );
        if( Maps.Length > 0 )
        {
            for( i = 0; i < ii; ++ i )
            {
                if( Left( RDat.Rec[i].TMN, 3 ) ~= "MT-" )   // Only compare mt maps
                {
                    // Ignore stats on maps that are no longer available in the server maps folder.
                    bFound = False;
                    for( l = 0; l < Maps.Length; ++ l )
                    {
                        if( RDat.Rec[i].TMN == Maps[l] )
                        {
                            bFound = True;
                            break;
                        }
                    }
                    RDat.Rec[i].bIgnoreStats = !bFound;
                }
            }
        }

        SkipMTTest:*/

        if( bUpdateWebOnNextMap )
        {
            FullLog( "Writing WebBTimes.html" );
            SortedOverallTop = SortTopPlayers( 0, true );
            CreateWebBTimes();
            bUpdateWebOnNextMap = False;
            SaveConfig();
        }

        SortedOverallTop = SortTopPlayers( 0 );
        SortedQuarterlyTop = SortTopPlayers( 1 );
        SortedDailyTop = SortTopPlayers( 2 );

    }

    ModeRules = Spawn( Class'BTGameRules', self );
    Level.Game.AddGameModifier( ModeRules );

    Bch = Spawn( class'BTBroadcastHandler', self );
    Bch.NextBroadcastHandler = Level.Game.BroadcastHandler;
    Level.Game.BroadcastHandler = Bch;

    PrepareMapAchievements();

    ValidateAccess();

    BuildEventDescription( EventMessages );
}

final function PrepareMapAchievements()
{
    local Decoration D;

    foreach AllActors( class'Decoration', D )
    {
        if( D.IsA('SirDicky') )
        {
            Spawn( class'BTAchievement_SirDicky', self,, D.Location, D.Rotation );
        }
    }
}

final function ProcessSirDickyAchievement( Pawn instigator )
{
    local BTClient_ClientReplication CRI;

    if( PlayerController(instigator.Controller) == none )
    {
        return;
    }

    CRI = GetRep( instigator.Controller );
    if( CRI == none )
        return;

    // SirDicky
    PDat.ProgressAchievementByID( CRI.myPlayerSlot, 'sirdicky' );
}

Final Function ResetCheckPoint( PlayerController PC )
{
    if( CheckPointHandler == None )
        return;

    if( CheckPointHandler.HasSavedCheckPoint( PC ) )
    {
        CheckPointHandler.RemoveSavedCheckPoint( PC );
        PC.ClientMessage( "'CheckPoint' Reset" );
    }
}

//==============================================================================
// Return an array with info(i.e Record Time) about the requested map
Final Function GetMapInfo( string MapName, out array<string> MapInfo )
{
    local int i, j;

    if( MapName == "" )
        MapName = CurrentMapName;

    j = RDat.Rec.Length;
    MapName = Caps( MapName );
    for( i = 0; i < j; ++ i )
    {
        if( InStr( Caps( RDat.Rec[i].TMN ), MapName ) != -1 )
        {
            MapInfo[MapInfo.Length] = lzMapName$":"$RDat.Rec[i].TMN @ "- Played Hours:" $ int(RDat.Rec[i].PlayHours);
            MapInfo[MapInfo.Length] = lzFinished$":"$RDat.Rec[i].TMFinish @ "-" @ lzHijacks$":"$RDat.Rec[i].TMHijacks @ "-" @ lzFailures$":"$RDat.Rec[i].TMFailures;
            MapInfo[MapInfo.Length] = "Average Time:"$GetAverageRecordTime( i );
            if( RDat.Rec[i].TMRatingSet )
                MapInfo[MapInfo.Length] = lzRating$":"$RDat.Rec[i].TMRating+1;

            // Add the all 3 top records info
            // Check whether its a solo map
            if( RDat.Rec[i].PSRL.Length > 0 )
            {
                MapInfo[MapInfo.Length] = "Top 1";
                MapInfo[MapInfo.Length] = lzRecordTime$":"$TimeToStr( RDat.Rec[i].PSRL[0].SRT );
                MapInfo[MapInfo.Length] = lzRecordAuthor$":"$PDat.Player[RDat.Rec[i].PSRL[0].PLs-1].PLNAME;
                if( RDat.Rec[i].PSRL.Length > 1 )
                {
                    MapInfo[MapInfo.Length] = "Top 2";
                    MapInfo[MapInfo.Length] = lzRecordTime$":"$TimeToStr( RDat.Rec[i].PSRL[1].SRT );
                    MapInfo[MapInfo.Length] = lzRecordAuthor$":"$PDat.Player[RDat.Rec[i].PSRL[1].PLs-1].PLNAME;
                    if( RDat.Rec[i].PSRL.Length > 2 )
                    {
                        MapInfo[MapInfo.Length] = "Top 3";
                        MapInfo[MapInfo.Length] = lzRecordTime$":"$TimeToStr( RDat.Rec[i].PSRL[2].SRT );
                        MapInfo[MapInfo.Length] = lzRecordAuthor$":"$PDat.Player[RDat.Rec[i].PSRL[2].PLs-1].PLNAME;

                        if( RDat.Rec[i].PSRL.Length > 3 )
                            MapInfo[MapInfo.Length] = lzRecords$":"$RDat.Rec[i].PSRL.Length;
                    }
                }
            }
            else    // Not solo!
            {
                j = MapInfo.Length;
                MapInfo.Length = j+1;
                MapInfo[j] = lzRecordTime$":"$TimeToStr( RDat.Rec[i].TMT );

                j = MapInfo.Length;
                MapInfo.Length = j+1;
                MapInfo[j] = lzRecordAuthor$":"$GetBestPlayersText( i, MaxPlayers );
            }
            break;
        }
    }
    return;
}

//==============================================================================
// Return an array with info(i.e Records) about the requested player
Final Function GetPlayerInfo( string PlayerName, out array<string> PlayerInfo, out int Hijacks, out array<string> RLR )
{
    local int i, j, PlayerSlot, jj;
    local string OrgName;

    // Cache length, so we don't have to lookup the length every loop!.
    j = PDat.Player.Length;

    // Find the player
    OrgName = PlayerName;
    PlayerName = Caps( PlayerName );
    PlayerSlot = -1;

    // Scan the PDat.Player Array!
    for( i = 0; i < j; ++ i )
    {
        if( InStr( Caps( %PDat.Player[i].PLName ), PlayerName ) != -1 )
        {
            // Found...

            PlayerSlot = i;
            PlayerInfo[PlayerInfo.Length] = lzPlayerName$":"$PDat.Player[PlayerSlot].PLName;
            PlayerInfo[PlayerInfo.Length] = "Hours spent on this server:" $ int(PDat.Player[PlayerSlot].PlayHours);
            Hijacks = PDat.Player[PlayerSlot].PLHijacks;
            break;
        }
    }

    // Check if the player was found!
    if( PlayerSlot == -1 )
    {
        PlayerInfo.Length = 1;
        PlayerInfo[0] = "No player found with this"@OrgName@Locs( lzPlayerName );
        return;
    }

    // Cache length, so we don't have to lookup the length every loop!.
    j = RDat.Rec.Length;
    // Scan the RDat.Rec Array!
    for( i = 0; i < j; ++ i )
    {
        if( RDat.Rec[i].bIgnoreStats )
        {
            continue;
        }

        if( RDat.Rec[i].PSRL.Length > 0 )
        {
            // Yep, check if the Number 1 record holder is <PlayerName>.
            if( RDat.Rec[i].PSRL[0].PLs-1 == PlayerSlot )
            {
                jj = PlayerInfo.Length;
                PlayerInfo.Length = jj+1;
                PlayerInfo[jj] = RDat.Rec[i].TMN@cDarkGray$TimeToStr( RDat.Rec[i].PSRL[0].SRT );
            }
            continue;
        }
    }

    // if Length is only 1 then there wasn't found any Records for this player, but the player account was found.
    if( PlayerInfo.Length == 1 )
        PlayerInfo[PlayerInfo.Length] = "No record(s)";

    if( PDat.Player[PlayerSlot].RecentSetRecords.Length > 0 )
    {
        RLR = PDat.Player[PlayerSlot].RecentSetRecords;
    }
}

Final Function GetMissingRecords( PlayerController PC, out array<string> RecordsInfo, out int NumHave, out int NumMissing )
{
    local int CurRec, NumRecs;
    local int CurPos, MaxPos;
    local int PlayerSlot;
    local bool bFound;

    PlayerSlot = FindPlayerSlot( PC.GetPlayerIdHash() );
    if( PlayerSlot == -1 )
        return;

    NumRecs = RDat.Rec.Length;
    for( CurRec = 0; CurRec < NumRecs; ++ CurRec )
    {
        if( RDat.Rec[CurRec].bIgnoreStats )
        {
            continue;
        }

        bFound = False;

        MaxPos = Min( RDat.Rec[CurRec].PSRL.Length, MaxRankedPlayers );
        if( MaxPos > 0 )
        {
            for( CurPos = 0; CurPos < MaxPos; ++ CurPos )
            {
                if( RDat.Rec[CurRec].PSRL[CurPos].PLs == PlayerSlot )
                {
                    ++ NumHave;
                    bFound = True;
                    break;
                }
            }

            if( !bFound )
            {
                ++ NumMissing;
                RecordsInfo[RecordsInfo.Length] = RDat.Rec[CurRec].TMN@cDarkGray$TimeToStr( RDat.Rec[CurRec].PSRL[0].SRT );
            }
        }
    }
}

Final Function GetBadRecords( PlayerController PC, out array<string> RecordsInfo, out int NumBad )
{
    local int CurRec, NumRecs;
    local int CurPos, MaxPos;
    local int PlayerSlot;

    PlayerSlot = FindPlayerSlot( PC.GetPlayerIdHash() );
    if( PlayerSlot == -1 )
        return;

    NumRecs = RDat.Rec.Length;
    for( CurRec = 0; CurRec < NumRecs; ++ CurRec )
    {
        if( RDat.Rec[CurRec].bIgnoreStats )
        {
            continue;
        }

        MaxPos = RDat.Rec[CurRec].PSRL.Length;
        for( CurPos = 0; CurPos < MaxPos; ++ CurPos )
        {
            if( RDat.Rec[CurRec].PSRL[CurPos].PLs == PlayerSlot )
            {
                if( CurPos >= MaxPlayers )
                {
                    RecordsInfo[RecordsInfo.Length] = RDat.Rec[CurRec].TMN@cDarkGray$TimeToStr( RDat.Rec[CurRec].PSRL[CurPos].SRT-RDat.Rec[CurRec].PSRL[0].SRT );
                    ++ NumBad;
                }
                break;
            }
        }
    }

    if( RecordsInfo.Length == 0 )
    {
        RecordsInfo[RecordsInfo.Length] = "No bad solo records found!";
    }
}

final static Function BTClient_ClientReplication GetRep( Controller C )
{
    local LinkedReplicationInfo LRI;

    for( LRI = C.PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
    {
        if( BTClient_ClientReplication(LRI) != None )
            return BTClient_ClientReplication(LRI);
    }
    return None;
}

/** Alot of commands to convert yet hehe :P */
final private function bool ClientExecuted( PlayerController sender, string command, optional array<string> params )
{
    local int i, j, n;
    local BTClient_ClientReplication Rep;
    local string S;
    local Controller C;
    local bool bCondition;
    local array<string> output, output2;
    local bool b2;
    local byte byteOne, byteTwo;

    switch( command )
    {
        case "recentrecords":
            Rep = GetRep( sender );
            if( Rep != None )
            {
                Rep.ClientCleanText();
                for( i = 0; i < MaxRecentRecords; ++ i )
                    Rep.ClientSendText( LastRecords[MaxRecentRecords-(i+1)] );
            }
            break;

        case "recenthistory":
            Rep = GetRep( sender );
            if( Rep != None )
            {
                Rep.ClientCleanText();
                for( i = History.Length-1; i >= 0; -- i )
                    Rep.ClientSendText( History[i] );
            }
            break;

        case "recentmaps":
            Rep = GetRep( sender );
            if( Rep != None )
            {
                Rep.ClientCleanText();
                j = RDat.Rec.Length;
                for( i = j-1; i >= 0; -- i )
                {
                    if( j-i > MaxRecentMaps )
                        break;

                    Rep.ClientSendText( RDat.Rec[i].TMN );
                }
            }
            break;

        case "showmapinfo":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                Rep.ClientCleanText();
                if( params.Length == 0 )
                {
                    params.Insert( 0, 1 );
                }
                GetMapInfo( params[0], output );
                for( i = 0; i < output.Length; ++ i )
                {
                    Rep.ClientSendText( output[i] );
                }
            }
            break;

        case "showplayerinfo":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                Rep.ClientCleanText();

                if( params.Length == 0 )
                {
                    params.Insert( 0, 1 );
                    params[0] = sender.GetHumanReadableName();
                }
                GetPlayerInfo( params[0], output, i, output2 );
                if( output.Length > 0 )
                {
                    Rep.ClientSendText( output[0] );
                    Rep.ClientSendText( "Hijacks:" $ i );
                    output.Remove( 0, 1 );  // Because we don't want this element to be randomly picked!
                    Rep.ClientSendText( class'HUD'.default.GoldColor $ Min( output.Length, 20 ) @ lzRandomPick );
                    for( i = 0; i < output.Length && n < 20; ++ i )
                    {
                        j = Rand( output.Length - 1 );
                        Rep.ClientSendText( output[j] );
                        output.Remove( j, 1 );
                        -- i;
                        ++ n;
                    }
                }

                if( output2.Length > 0 )
                {
                    Rep.ClientSendText( "" );   // new line!
                    Rep.ClientSendText( class'HUD'.default.GoldColor $ "Recent Set Records by Player:" );
                    for( i = output2.Length - 1; i >= 0; -- i )
                    {
                        Rep.ClientSendText( output2[i] );
                    }
                }
            }
            break;

        case "showmissingrecords":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                Rep.ClientCleanText();

                GetMissingRecords( sender, output, j, i );
                Rep.ClientSendText( "You are missing" @ i @ "solo records!" );
                Rep.ClientSendText( "You have" @ j @ "solo records!" );

                Rep.ClientSendText( class'HUD'.default.GoldColor $ Min( output.Length, 20 ) @ lzRandomPick );
                for( i = 0; i < output.Length && n < 20; ++ i )
                {
                    j = Rand( output.Length - 1 );
                    Rep.ClientSendText( output[j] );
                    output.Remove( j, 1 );
                    -- i;
                    ++ n;
                }
            }
            break;

        case "showbadrecords":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                Rep.ClientCleanText();

                GetBadRecords( sender, output, j );
                Rep.ClientSendText( "You have" @ j @ "bad solo records!" );

                Rep.ClientSendText( class'HUD'.default.GoldColor $ Min( output.Length, 20 ) @ lzRandomPick );
                for( i = 0; i < output.Length && n < 20; ++ i )
                {
                    j = Rand( output.Length - 1 );
                    Rep.ClientSendText( output[j] );
                    output.Remove( j, 1 );
                    -- i;
                    ++ n;
                }
            }
            break;

        case "toggleghost":
            if( !IsAdmin( sender.PlayerReplicationInfo ) )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry 'ToggleGhost' is only available for admins!" );
            }
            else if( GhostManager != none )
            {
                // Either if Sender is the owner of the ghost or an admin/offline
                /*if( sender.GetPlayerIdHash() == GhostData.PLID || IsAdmin( sender.PlayerReplicationInfo ) )
                {                                                                                          */
                    RDat.Rec[UsedSlot].TMGhostDisabled = !RDat.Rec[UsedSlot].TMGhostDisabled;
                    SaveRecords();
                    sender.ClientMessage( Class'HUD'.default.GoldColor $ "Ghost Enabled?:" $ !RDat.Rec[UsedSlot].TMGhostDisabled );
                    if( RDat.Rec[UsedSlot].TMGhostDisabled )
                    {
                        GhostManager.GhostsKill();
                    }
                    else
                    {
                        GhostManager.GhostsSpawn();
                    }
                /*}
                else
                {
                    sender.ClientMessage( Class'HUD'.default.RedColor $ "You are not allowed to toggle the ghost from this map because this is not your ghost!" );
                }*/
            }
            else
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "There's no ghost to toggle!" );
            }
            break;

        case "race":
            if( bGroupMap )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry racing is not available in group mode!" );
                break;
            }

            if( params.Length != 1 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                break;
            }
            Rep = GetRep( sender );
            S = Caps( params[0] );
            if( S == "" )
            {
                sender.ClientMessage( Class'HUD'.default.GoldColor $ "You are no longer racing anyone!" );
                for( i = 0; i < Racers.Length; ++ i )
                {
                    if( Racers[i].Stalker == sender )
                    {
                        Racers.Remove( i, 1 );
                        break;
                    }
                }
                break;
            }

            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        if( sender == C )
                        {
                            sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you cannot race with yourself!" );
                            break;
                        }

                        for( i = 0; i < Racers.Length; ++ i )
                        {
                            if( Racers[i].Leader == sender && Racers[i].Stalker == C )
                            {
                                sender.ClientMessage( Class'HUD'.default.RedColor $ "The player you want to race with is already racing with you!" );
                                return true;
                            }
                        }

                        for( i = 0; i < Racers.Length; ++ i )
                        {
                            if( Racers[i].Stalker == sender )
                            {
                                Racers.Remove( i, 1 );
                                break;
                            }
                        }

                        j = Racers.Length;
                        Racers.Length = j + 1;
                        Racers[j].Leader = C;
                        Racers[j].Stalker = sender;
                        sender.ClientMessage( Class'HUD'.default.GoldColor $ "You are now racing" @ C.GetHumanReadableName() $ "!" );
                        break;
                    }
                }
            }
            break;

        case "ghostfollow":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                bCondition = IsAdmin( sender.PlayerReplicationInfo ) || sender.GetPlayerIDHash() == BTAuthor;
                if( !bCondition )
                {
                    if( PDat.HasCurrencyPoints( Rep.myPlayerSlot, GhostFollowPrice ) )
                    {
                        b2 = true;
                    }
                    else
                    {
                        SendErrorMessage( sender, "Sorry you cannot hire the ghost because you do not have enough Currency points!" );
                        break;
                    }
                }

                if( bGhostWasAdminAwarded && !bCondition )
                {
                    sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you cannot overwrite the ghost's target if it is was set by an admin!" );
                    break;
                }

                if( !bCondition )
                {
                    bGhostWasAdminAwarded = true;
                }

                if( params.Length != 1 )
                {
                    sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                    break;
                }

                S = Caps( params[0] );
                if( S == "" || S ~= "exec:None" )
                {
                    if( LeadingGhost == none )
                    {
                        sender.ClientMessage( class'HUD'.default.GoldColor $ "The ghost is not following anyone!" );
                        break;
                    }

                    if( LeadingGhost != none && LeadingGhost != sender && bCondition )
                    {
                        LeadingGhost.ClientMessage( Class'HUD'.default.GoldColor $ "The ghost no longer follows you!" );
                    }

                    if( !bCondition && LeadingGhost != sender )
                    {
                        SendErrorMessage( sender, "Sorry you cannot remove the ghost from following someone other than yourself!" );
                        break;
                    }

                    sender.ClientMessage( Class'HUD'.default.GoldColor $ "Ghost is now following nobody!" );
                    LeadingGhost = None;
                    bGhostWasAdminAwarded = false;
                    break;
                }

                for( C = Level.ControllerList; C != None; C = C.NextController )
                {
                    if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                    {
                        if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                        {
                            if( LeadingGhost == PlayerController(C) )
                            {
                                SendErrorMessage( sender, "The ghost is already following the specified target!" );
                                break;
                            }

                            if( LeadingGhost != none && LeadingGhost != sender )
                            {
                                LeadingGhost.ClientMessage( Class'HUD'.default.GoldColor $ "The ghost no longer follows you!" );
                            }
                            LeadingGhost = PlayerController(C);
                            sender.ClientMessage( Class'HUD'.default.GoldColor $ "Ghost is now following" @ LeadingGhost.GetHumanReadableName() $ "!" );

                            if( LeadingGhost != sender )
                            {
                                LeadingGhost.ClientMessage( Class'HUD'.default.GoldColor $ "The ghost is now following you!" );
                            }

                            if( b2 )
                            {
                                PDat.SpendCurrencyPoints( Rep.myPlayerSlot, GhostFollowPrice );
                            }
                            break;
                        }
                    }
                }
            }
            else
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you have to be either a admin or have" @ Objectives_GhostFollow @ "objectives!" );
            }
            break;

        case "ghostfollowid":
            Rep = GetRep( sender );
            bCondition = PDat.Player[Rep.myPlayerSlot].PLObjectives >= Objectives_GhostFollow;
            if( IsAdmin( sender.PlayerReplicationInfo ) || bCondition || sender.GetPlayerIDHash() == BTAuthor )
            {
                if( bGhostWasAdminAwarded && bCondition )
                {
                    sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you cannot overwrite the ghost's target if it is was set by an admin!" );
                    break;
                }

                if( !bCondition )
                {
                    bGhostWasAdminAwarded = true;
                }

                if( params.Length != 1 )
                {
                    sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playerid!" );
                    break;
                }
                i = int(params[0]);
                if( i == -1 )
                {
                    if( LeadingGhost != none && LeadingGhost != sender )
                    {
                        LeadingGhost.ClientMessage( Class'HUD'.default.GoldColor $ "The ghost no longer follows you!" );
                    }
                    sender.ClientMessage( Class'HUD'.default.GoldColor $ "Ghost is now following nobody!" );
                    LeadingGhost = None;
                    bGhostWasAdminAwarded = false;
                    break;
                }

                for( C = Level.ControllerList; C != None; C = C.NextController )
                {
                    if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                    {
                        if( C.PlayerReplicationInfo.PlayerID == i )
                        {
                            if( LeadingGhost != none && LeadingGhost != sender )
                            {
                                LeadingGhost.ClientMessage( Class'HUD'.default.GoldColor $ "The ghost no longer follows you!" );
                            }
                            LeadingGhost = PlayerController(C);
                            sender.ClientMessage( Class'HUD'.default.GoldColor $ "Ghost is now following" @ LeadingGhost.GetHumanReadableName() $ "!" );

                            if( LeadingGhost != sender )
                            {
                                LeadingGhost.ClientMessage( Class'HUD'.default.GoldColor $ "The ghost is now following you!" );
                            }
                            break;
                        }
                    }
                }
            }
            else
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you have to be either a admin or have" @ Objectives_GhostFollow @ "objectives!" );
            }
            break;

        case "votemapseq":
            Class'BTServer_VotingCommands'.static.VoteMapSeq( sender, int(params[0]) );
            break;

        case "votemap":
            Class'BTServer_VotingCommands'.static.VoteMap( sender, params[0] );
            break;

        // Short for toggling clientspawn!
        case "clientspawn":
            i = GetClientSpawnIndex( sender );
            if( i == -1 )
            {
                Mutate( "setclientspawn", sender );
            }
            else
            {
                Mutate( "deleteclientspawn", sender );
            }
            break;

        case "setclientspawn": case "createclientspawn": case "makeclientspawn":
            if( !ModeIsTrials() )
            {
                break;
            }

            if( sender.Pawn == None || sender.Pawn.Physics != PHYS_Walking  || bQuickStart )
            {
                SendErrorMessage( sender, lzCS_NoPawn );
                break;
            }

            if( bAllowClientSpawn )
                CreateClientSpawn( sender );
            else SendErrorMessage( sender, lzCS_NotEnabled );
            break;

        case "deleteclientspawn": case "removeclientspawn": case "killclientspawn":
            if( bQuickStart )
            {
                SendErrorMessage( sender, lzCS_NoQuickStartDelete );
                break;
            }

            if( bAllowClientSpawn )
                DeleteClientSpawn( sender );
            else SendErrorMessage( sender, lzCS_NotEnabled );
            break;

        case "settitle":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            for( i = 0; i < params.Length; ++ i )
            {
                if( s != "" )
                {
                    s $= " ";
                }
                s $= params[i];
            }

            if( s == "" )
            {
                SendErrorMessage( sender, "Please specify a title!" );
                break;
            }

            if( !Rep.bIsPremiumMember )
            {
                i = AchievementsManager.FindAchievementByTitle( s );
                if( i == -1 )
                {
                    SendErrorMessage( sender, "As a non-premium player you may only use titles from earned achievements!" );
                    break;
                }

                if( !PDat.HasEarnedAchievement( Rep.myPlayerSlot, i ) )
                {
                    SendErrorMessage( sender, "Sorry you cannot use an achievement title that you have not earned yet!" );
                    break;
                }
                s = AchievementsManager.Achievements[i].Title;  // Sync caps
            }

            // Clip to a max length of 30 chars.
            if( Len( s ) > 30 )
            {
                s = Left( s, 30 );
                break;
            }

            PDat.Player[Rep.myPlayerSlot].Title = s;
            Rep.Title = s;
            SendSucceedMessage( sender, "Changed your title to" @ s );
            break;

        case "settrailercolor":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            if( !PDat.HasItem( Rep.myPlayerSlot, "Trailer" ) )
            {
                SendErrorMessage( sender, "Sorry you cannot change your Trailer color because you have not yet bought a Trailer!" );
                break;
            }

            /*if( !PDat.HasCurrencyPoints( Rep.myPlayerSlot, 1 ) )
            {
                SendErrorMessage( sender, "Sorry you cannot change your Trailer color because you don't have enough Currency Points!" );
                break;
            }*/

            if( params.Length == 0 )
            {
                SendErrorMessage( sender, "Please specify the colors for each slot, for example: \"255 255 255 128 128 128\"; which is \"Red(0) Green(0) Blue(0) Red(1) Green(1) Blue(1)\"" );
                break;
            }

            PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[0].R = byte(Min( int(params[0])+1, 255 ));
            if( params.Length > 1 )
                PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[0].G = byte(Min( int(params[1])+1, 255 ));
            if( params.Length > 2 )
                PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[0].B = byte(Min( int(params[2])+1, 255 ));
            if( params.Length > 3 )
                PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[1].R = byte(Min( int(params[3])+1, 255 ));
            if( params.Length > 4 )
                PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[1].G = byte(Min( int(params[4])+1, 255 ));
            if( params.Length > 5 )
                PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[1].B = byte(Min( int(params[5])+1, 255 ));

            for( i = 0; i < Trailers.Length; ++ i )
            {
                if( Trailers[i].P == Rep.myPlayerSlot )
                {
                    if( Trailers[i].T != none )
                    {
                        Trailers[i].T.Destroy();
                        Trailers[i].T = Spawn( TrailerInfoClass, Sender );
                        Trailers[i].T.TrailerClass = RankTrailerClass;
                        Trailers[i].T.RankSkin = PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings;

                        if( Sender.Pawn != none )
                        {
                            for( j = 0; j < Sender.Pawn.Attached.Length; ++ j )
                            {
                                if( Sender.Pawn.Attached[j] == none || Sender.Pawn.Attached[j].class != RankTrailerClass )
                                    continue;

                                Sender.Pawn.Attached[i].Destroy();
                                Sender.Pawn.Attached.Remove( j, 1 );
                                -- j;
                            }

                            Trailers[i].T.Pawn = Sender.Pawn;
                        }
                    }
                    break;
                }
            }
            break;

        case "settrailertexture":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            if( !PDat.HasItem( Rep.myPlayerSlot, "Trailer" ) )
            {
                SendErrorMessage( sender, "Sorry you cannot change your Trailer texture because you have not yet bought a Trailer!" );
                break;
            }

            if( !PDat.HasCurrencyPoints( Rep.myPlayerSlot, 1 ) )
            {
                SendErrorMessage( sender, "Sorry you cannot change your Trailer texture because you don't have enough Currency Points!" );
                break;
            }

            if( params.Length == 0 || params[0] == "" )
            {
                SendErrorMessage( sender, "Please specify a TrailerTexture reference for example: Package.Group.Name" );
                break;
            }

            if( PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerTexture != params[0] )
            {
                PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerTexture = params[0];
                PDat.SpendCurrencyPoints( Rep.myPlayerSlot, 1 );

                for( i = 0; i < Trailers.Length; ++ i )
                {
                    if( Trailers[i].P == Rep.myPlayerSlot )
                    {
                        if( Trailers[i].T != none )
                        {
                            Trailers[i].T.Destroy();
                            Trailers[i].T = Spawn( TrailerInfoClass, Sender );
                            Trailers[i].T.TrailerClass = RankTrailerClass;
                            Trailers[i].T.RankSkin = PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings;

                            if( Sender.Pawn != none )
                            {
                                for( j = 0; j < Sender.Pawn.Attached.Length; ++ j )
                                {
                                    if( Sender.Pawn.Attached[j] == none || Sender.Pawn.Attached[j].Class != RankTrailerClass )
                                        continue;

                                    Sender.Pawn.Attached[j].Destroy();
                                    Sender.Pawn.Attached.Remove( j, 1 );
                                    -- j;
                                }

                                Trailers[i].T.Pawn = Sender.Pawn;
                            }
                        }
                        break;
                    }
                }
            }
            break;

        case "giveitem":
            if( !IsAdmin( sender.PlayerReplicationInfo ) )
            {
                SendErrorMessage( sender, "Sorry only admins can give items!" );
                break;
            }

            if( params.Length < 2 )
            {
                SendErrorMessage( sender, "Please specify two parameters. <PlayerName> <ItemID>" );
                break;
            }

            s = Locs( params[1] );
            i = Store.FindItemByID( s );
            if( i != -1 )
            {
                for( C = Level.ControllerList; C != none; C = C.NextController )
                {
                    if( PlayerController(C) != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.PlayerName ~= params[0] )
                    {
                        Rep = GetRep( C );
                        if( Rep == none )
                        {
                            break;
                        }

                        if( s == "trailer" )
                        {
                            PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerTexture = "None";
                            PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[0] = class'HUD'.default.WhiteColor;
                            PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[1] = class'HUD'.default.WhiteColor;
                        }

                        PDat.GiveItem( Rep.myPlayerSlot, s );
                        SendSucceedMessage( sender, "Gave item" @ Store.Items[i].Name @ "to" @ C.PlayerReplicationInfo.PlayerName );
                        SendSucceedMessage( PlayerController(C), "You received item" @ Store.Items[i].Name @ "from" @ sender.PlayerReplicationInfo.PlayerName );
                        break;
                    }
                }

                if( Rep == none )
                {
                    SendErrorMessage( sender, "Couldn't find a player with name:" @ params[0] );
                }
                break;
            }
            else
            {
                SendErrorMessage( sender, "Sorry" @ s @ "does not exist!" );
                break;
            }
            break;

        case "removeitem": case "deleteitem":
            if( !IsAdmin( sender.PlayerReplicationInfo ) )
            {
                SendErrorMessage( sender, "Sorry only admins can remove items!" );
                break;
            }

            if( params.Length < 2 )
            {
                SendErrorMessage( sender, "Please specify two parameters. <PlayerName> <ItemID>" );
                break;
            }

            s = Locs( params[1] );
            i = Store.FindItemByID( s );
            if( i != -1 )
            {
                for( C = Level.ControllerList; C != none; C = C.NextController )
                {
                    if( PlayerController(C) != none && C.PlayerReplicationInfo != none && C.PlayerReplicationInfo.PlayerName ~= params[0] )
                    {
                        Rep = GetRep( C );
                        if( Rep == none )
                        {
                            break;
                        }

                        if( PDat.HasItem( Rep.myPlayerSlot, s ) )
                        {
                            PDat.RemoveItem( Rep.myPlayerSlot, s );
                            SendSucceedMessage( sender, "Removed item" @ Store.Items[i].Name @ "from" @ C.PlayerReplicationInfo.PlayerName );
                            SendSucceedMessage( PlayerController(C), sender.PlayerReplicationInfo.PlayerName @ "removed your item" @ Store.Items[i].Name );
                        }
                        else
                        {
                            SendErrorMessage( sender, "Sorry the player has no item of id:" @ s );
                        }
                        break;
                    }
                }

                if( Rep == none )
                {
                    SendErrorMessage( sender, "Couldn't find a player with name:" @ params[0] );
                }
                break;
            }
            else
            {
                SendErrorMessage( sender, "Sorry" @ s @ "does not exist!" );
                break;
            }
            break;

        case "buy": case "buyitem":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            s = Locs( params[0] );
            i = Store.FindItemByID( s );
            if( i != -1 )
            {
                if( !Store.CanBuyItem( sender, PDat, Rep.myPlayerSlot, i, s ) )
                {
                    SendErrorMessage( sender, s );
                    break;
                }

                if( s == "trailer" )
                {
                    PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerTexture = "None";
                    PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[0] = class'HUD'.default.WhiteColor;
                    PDat.Player[Rep.myPlayerSlot].Inventory.TrailerSettings.TrailerColor[1] = class'HUD'.default.WhiteColor;
                }

                NotifyItemBought( Rep.myPlayerSlot );
                PDat.GiveItem( Rep.myPlayerSlot, Store.Items[i].ID );
                // bBought, bEnabled
                Rep.ClientSendItemData( Store.Items[i].ID,
                    class'BTClient_ClientReplication'.static.CompressStoreData(
                        Store.Items[i].Cost,
                        true,
                        true,
                        Store.Items[i].Access
                    )
                );

                if( Store.Items[i].Access >= Free || Store.Items[i].Cost <= 0 )
                {
                    break;
                }

                // Don't use IsAdmin here, we want the currency system working offline as well!
                if( !sender.PlayerReplicationInfo.bAdmin )
                {
                    PDat.SpendCurrencyPoints( Rep.myPlayerSlot, Store.Items[i].Cost );

                    NotifyPlayers( sender,
                              sender.GetHumanReadableName() @ Class'HUD'.default.GoldColor $ "has bought" @ Store.Items[i].Name @ "for" @ Store.Items[i].Cost @ "Currency points",
                              Class'HUD'.default.GoldColor $ "You bought" @ Store.Items[i].Name @ "for" @ Store.Items[i].Cost @ "Currency points"
                              );
                }
            }
            else
            {
                SendErrorMessage( sender, "Sorry" @ s @ "does not exist!" );
                break;
            }
            break;

        case "sell": case "sellitem":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            s = Locs( params[0] );
            i = Store.FindItemByID( s );
            if( i != -1 )
            {
                if( PDat.HasItem( Rep.myPlayerSlot, s ) )
                {
                    if( Store.Items[i].Access >= Free && !IsAdmin( sender.PlayerReplicationInfo ) )
                    {
                        SendErrorMessage( sender, "Sorry you cannot sell items that have no price." );
                        break;
                    }

                    if( Store.Items[i].bPassive )
                    {
                        SendErrorMessage( sender, "Sorry you cannot sell items that are passive." );
                        break;
                    }

                    PDat.RemoveItem( Rep.myPlayerSlot, s );
                    if( Store.Items[i].Access == Buy && Store.Items[i].Cost > 0 )
                    {
                        PDat.GiveCurrencyPoints( Rep.myPlayerSlot, Store.GetResalePrice( i ), true );
                    }

                    // bBought, bEnabled
                    Rep.ClientSendItemData( Store.Items[i].ID,
                        class'BTClient_ClientReplication'.static.CompressStoreData(
                            Store.Items[i].Cost,
                            false,
                            false,
                            Store.Items[i].Access
                        )
                    );
                }
                else
                {
                    SendErrorMessage( sender, "You cannot sell an item that you do not have." );
                    break;
                }
            }
            else
            {
                SendErrorMessage( sender, "Sorry" @ s @ "does not exist!" );
                break;
            }
            break;

        case "toggleitem":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            s = Locs( params[0] );
            if( s ~= "all" )
            {
                PDat.ToggleItem( Rep.myPlayerSlot, "all" );
                break;
            }

            i = Store.FindItemByID( s );
            if( i != -1 )
            {
                PDat.ToggleItem( Rep.myPlayerSlot, Store.Items[i].ID );

                // bBought, bEnabled
                PDat.GetItemState( Rep.myPlayerSlot, Store.Items[i].ID, byteOne, byteTwo );
                Rep.ClientSendItemData( Store.Items[i].ID,
                    class'BTClient_ClientReplication'.static.CompressStoreData(
                        Store.Items[i].Cost,
                        bool(byteOne),
                        bool(byteTwo),
                        Store.Items[i].Access
                    )
                );
            }
            break;

        case "exchangetrophies":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            if( params.Length != 1 )
            {
                SendErrorMessage( sender, "Please input the amount of trophies you want to exchange!" );
                break;
            }

              // TEST CODE!
            /*for( i = 0; i < 25; ++ i )
            {
                PDat.AddTrophy( Rep.myPlayerSlot, "TEST" );
            }*/

            i = PDat.Player[Rep.myPlayerSlot].Trophies.Length;
            if( params[0] ~= "All" )
            {
                params[0] = string(i);
            }

            params[0] = string(Min( int(params[0]), MaxExchangeableTrophies ));
            if( int(params[0]) > i )
            {
                SendErrorMessage( sender, "You don't have that many trophies!" );
                break;
            }

            if( int(params[0]) <= 0 )
            {
                SendErrorMessage( sender, "Please input an higher amount than 0!" );
                break;
            }

            if( int(params[0]) < MinExchangeableTrophies )
            {
                SendErrorMessage( sender, "You need atleast" @ MinExchangeableTrophies @ "trophies before you can exchange them for Currency points!" );
                break;
            }

            j = 5 ** (float(int(params[0]))/(float(MinExchangeableTrophies)/2f));
            PDat.GiveCurrencyPoints( Rep.myPlayerSlot, j, true );
            PDat.Player[Rep.myPlayerSlot].Trophies.Remove( 0, int(params[0]) );

            NotifyPlayers( sender,
              sender.GetHumanReadableName() @ class'HUD'.default.GoldColor $ "Exchanged" @ int(params[0]) @ "trophies for" @ j @ "Currency points!",
              class'HUD'.default.GoldColor $ "You exchanged" @ int(params[0]) @ "trophies for" @ j @ "Currency points!"
              );
            break;

        case "tradecurrency":
            Rep = GetRep( sender );
            if( params.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                break;
            }

            if( params.Length < 2 || (params.Length > 1 && int(params[1]) == 0) )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify the amount of currency!" );
                break;
            }

            if( int(params[1]) <= 0 )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "You cannot give less than 1 currency!" );
                break;
            }

            if( !PDat.HasCurrencyPoints( Rep.myPlayerSlot, int(params[1]) ) )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "You do not have that much currency!" );
                break;
            }

            S = Caps( params[0] );
            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        sender.ClientMessage( class'HUD'.default.GoldColor $ "20% of your donation has been taken away as fee!" );

                        PDat.SpendCurrencyPoints( Rep.myPlayerSlot, int(params[1]) );
                        sender.ClientMessage( class'HUD'.default.GoldColor $ "You gave" @ PlayerController(C).GetHumanReadableName() @ int(params[1])*0.80 @ "of your currency!" );

                        PDat.GiveCurrencyPoints( GetRep( PlayerController(C) ).myPlayerSlot, int(params[1])*0.80, true );
                        if( PlayerController(C) != sender )
                        {
                            PlayerController(C).ClientMessage( class'HUD'.default.GoldColor $ sender.GetHumanReadableName() @ "gave you" @ int(params[1])*0.80 @ "of his/her currency!" );
                        }
                        break;
                    }
                }
            }
            break;

        case "activatekey":
            ActivateKey( sender, params[0] );
            break;

        default:
            return (CurMode != None && CurMode.ClientExecuted( sender, command, params ));
            break;
    }
    return true;
}

final function ActivateKey( PlayerController sender, string serial )
{
    local BTActivateKey keyHandler;

    keyHandler = Spawn( class'BTActivateKey', self );
    keyHandler.Requester = sender;
    keyHandler.VerifySerial( serial );

    SendSucceedMessage( keyHandler.Requester, "Verifying key" @ serial );
}

final function KeyVerified( BTActivateKey handler )
{
    local BTClient_ClientReplication Rep;
    local int itemStoreSlot;

    if( !handler.Serial.Valid )
    {
        SendErrorMessage( handler.Requester, "Invalid key!" );
        handler.Destroy();
        return;
    }

    if( handler.Serial.bConsumed )
    {
        SendErrorMessage( handler.Requester, "Key was already consumed!" );
        handler.Destroy();
        return;
    }

    SendSucceedMessage( handler.Requester, "Key was successfully verified!" );

    Rep = GetRep( handler.Requester );
    if( Rep == none )
    {
        SendErrorMessage( handler.Requester, "Couldn't find the replication instance! Consumption aborted!" );
        handler.Destroy();
        return;
    }

    // Let's make sure that we don't consume keys that might be useless for the requester.
    switch( handler.Serial.Type )
    {
        // Key was generated for the purpose of giving items!
        case "item":
            itemStoreSlot = Store.FindItemByID( handler.Serial.Code );
            if( itemStoreSlot == -1 )
            {
                SendErrorMessage( handler.Requester, "The reward of this key does not exist on this server! Consumption aborted!" );
                handler.Destroy();
                break;
            }

            if( PDat.HasItem( Rep.myPlayerSlot, handler.Serial.Code ) )
            {
                SendErrorMessage( handler.Requester, "Cannot use this key because you already own the reward! Consumption aborted!" );
                handler.Destroy();
                break;
            }
            // All seems fine, let's use the key(We don't want to consume a key that might fail to be rewarded).
            handler.ConsumeSerial();
            break;

        case "prem":
            if( !(handler.Serial.Code ~= "BTStore") )
            {
                SendErrorMessage( handler.Requester, "This isn't a premium key! Consumption aborted!" );
                handler.Destroy();
                break;
            }

            if( PDat.Player[Rep.myPlayerSlot].bHasPremium )
            {
                SendErrorMessage( handler.Requester, "You are already own premium! Consumption aborted!" );
                handler.Destroy();
                break;
            }
            handler.ConsumeSerial();
            break;

        case "curr":
        case "exp":
            handler.ConsumeSerial();
            break;

        default:
            SendErrorMessage( handler.Requester, "Unknown key type! Consumption aborted!" );
            handler.Destroy();
            break;
    }
}

final function KeyConsumed( BTActivateKey handler, string message )
{
    switch( message )
    {
        // No authentication given
        case "invalid":
            SendErrorMessage( handler.Requester, "Failed to authenticate the key" );
            break;

        // First consumption
        case "success":
            SendSucceedMessage( handler.Requester, "Key successfully authenticated and consumed!" );
            ConsumeKey( handler );
            break;

        // Already consumed
        case "true":
            SendErrorMessage( handler.Requester, "Key was already consumed!" );
            break;

        // Doesn't exist
        case "false":
            SendErrorMessage( handler.Requester, "Key could'nt be consumed!" );
            break;
    }
    handler.Destroy();
}

private final function ConsumeKey( BTActivateKey handler )
{
    local BTClient_ClientReplication Rep;
    local int itemStoreSlot;

    Rep = GetRep( handler.Requester );
    if( Rep == none )
    {
        SendErrorMessage( handler.Requester, "Couldn't find the replication instance! Consumption aborted!" );
        return;
    }

    switch( handler.Serial.Type )
    {
        // Key was generated for the purpose of giving items!
        case "item":
            itemStoreSlot = Store.FindItemByID( handler.Serial.Code );
            if( itemStoreSlot == -1 )
            {
                SendErrorMessage( handler.Requester, "The reward of this key does not exist on this server!" );
                break;
            }

            if( PDat.HasItem( Rep.myPlayerSlot, handler.Serial.Code ) )
            {
                SendErrorMessage( handler.Requester, "Cannot use this key because you already own the reward!" );
                break;
            }
            PDat.GiveItem( Rep.myPlayerSlot, handler.Serial.Code );
            SendSucceedMessage( handler.Requester, "You were given the following item" @ Store.items[itemStoreSlot].Name );
            break;

        case "curr":
            PDat.GiveCurrencyPoints( Rep.myPlayerSlot, int(handler.Serial.Code), true );
            SendSucceedMessage( handler.Requester, "You were given Currency!" );
            break;

        case "exp":
            PDat.AddExperience( Rep.myPlayerSlot, int(handler.Serial.Code) );
            SendSucceedMessage( handler.Requester, "You were given Experience!" );
            break;

        case "prem":
            PDat.Player[Rep.myPlayerSlot].bHasPremium = true;
            Rep.bIsPremiumMember = true;
            SendSucceedMessage( handler.Requester, $0x00FF00 $ "You now have premium! You have been granted access to all premium items!" );
            SaveAll();
            break;
    }
}

final private function bool AdminExecuted( PlayerController sender, string command, optional array<string> params )
{
    local BTClient_ClientReplication Rep;
    local int i, j;
    local string s;
    local Controller C;

    switch( command )
    {
        case "btcommands":
            sender.ClientMessage( Class'HUD'.Default.RedColor $ "List of all admin commands of" @ Name );
            for( i = 0; i < Commands.Length; ++ i )
            {
                sender.ClientMessage( Class'HUD'.Default.RedColor $ Commands[i].Cmd $ Class'HUD'.Default.WhiteColor $ " -" @ Commands[i].Help );
                for( j = 0; j < Commands[i].Params.Length; ++ j )
                {
                    sender.ClientMessage( MakeColor( 128, 128, 0 ) $ "Param " $ Class'HUD'.Default.WhiteColor $ Commands[i].Params[j] );
                }
            }
            break;

        case "updatewebbtimes":
            CreateWebBTimes();
            break;

        case "bt_backupdata":
            CreateBackupData();
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "Backup created!, check saves folder!" );

        case "bt_restoredata":
            RestoreBackupData();
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "Backup restored!" );

        case "bt_exportrecord":
            if( params[0] != "" )
            {
                if( ExportRecordData( params[0] ) )
                    Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Exported" @ params[0] );
            }
            break;

        case "bt_importrecord":
            if( params[0] != "" )
            {
                if( ImportRecordData( params[0] ) )
                    Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Imported" @ params[0] );
            }
            break;

        case "bt_updatemapprefixes":
            for( i = 0; i < RDat.Rec.Length; ++ i )
            {
                if( Left( RDat.Rec[i].TMN, 7 ) ~= "AS-Solo" )
                {
                    RDat.Rec[i].TMN = "STR" $ Mid( RDat.Rec[i].TMN, 7 );
                }
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Renamed prefix of all solo records" );

            for( i = 0; i < RDat.Rec.Length; ++ i )
            {
                if( Left( RDat.Rec[i].TMN, 8 ) ~= "AS-Group" )
                {
                    RDat.Rec[i].TMN = "GTR" $ Mid( RDat.Rec[i].TMN, 8 );
                }
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Renamed prefix of all group records" );

            for( i = 0; i < RDat.Rec.Length; ++ i )
            {
                if( Left( RDat.Rec[i].TMN, 3 ) ~= "AS-" )
                {
                    RDat.Rec[i].TMN = "RTR-" $ Mid( RDat.Rec[i].TMN, 3 );
                }
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Renamed prefix of all regular records" );
            SaveRecords();
            break;

        case "bt_resetobjectives":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].PLObjectives = 0;
            }
            SavePlayers();
            break;

        case "bt_resetcurrency":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].LevelData.BTPoints = 0;
            }
            SavePlayers();
            break;

        case "bt_resetexperience":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].LevelData.Experience = 0;
            }
            SavePlayers();
            break;

        case "quickstart":
            if( bQuickStart )
            {
                CurCountdown = 0;
                Level.Game.Broadcast( self, Class'HUD'.default.GoldColor $ "Admin has forced fast quickstart!" );
                //sender.ClientMessage( "Sorry you cannot start a quickstart when quickstart is already active!" );
                break;
            }
            Revoted();
            Level.Game.Broadcast( self, Class'HUD'.default.GoldColor $ "Admin has forced quickstart!" );
            break;

        case "competitivemode":
            if( IsCompetitive() )
            {
                break;
            }
            EnableCompetitiveMode();
            break;

        case "setmaxrankedplayers":
            MaxRankedPlayers = int(params[0]);
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "MaxRankedPlayers:" $ params[0] );
            SaveConfig();
            break;

        case "setghostrecordfps":
            GhostPlaybackFPS = int(params[0]);
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "GhostRecordFPS:" $ params[0] );
            SaveConfig();
            break;

        case "setquickstartlimit":
            BTServer_VotingHandler(Level.Game.VotingHandler).QuickStartLimit = int(params[0]);
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "QuickStartLimit:" $ params[0] );
            SaveConfig();
            break;

        case "seteventdescription":
        case "seteventdesc":
        case "setevent":
        case "setmotd":
            for( i = 0; i < params.Length; ++ i )
            {
                if( s != "" )
                {
                    s $= " ";
                }
                s $= params[i];
            }

            EventDescription = s;
            SaveConfig();

            BuildEventDescription( EventMessages );

            for( C = Level.ControllerList; C != none; C = C.NextController )
            {
                if( PlayerController(C) != none && C.PlayerReplicationInfo != none )
                {
                    Rep = GetRep( C );
                    Rep.ClientCleanText();
                    SendEventDescription( Rep );
                }
            }
            break;

        case "deleteghost":
            if( GhostManager != none )
            {
                GhostManager.ClearGhostsData( CurrentMapName, GhostDataFileName, true );
                sender.ClientMessage( Class'HUD'.default.GoldColor $ "Ghost data deleted!" );
            }
            else
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "No ghost data found!" );
            }
            break;

        case "giveexp":
        case "giveexperience":
            Rep = GetRep( sender );
            if( params.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                break;
            }

            if( params.Length < 2 || (params.Length > 1 && int(params[1]) == 0) )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify the amount of experience!" );
                break;
            }

            S = Caps( params[0] );
            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        sender.ClientMessage( Class'HUD'.default.GoldColor $ "You gave" @ PlayerController(C).GetHumanReadableName() @ params[1] @ "experience!" );

                        if( int(params[1]) > 0 )
                        {
                            PDat.AddExperience( GetRep( PlayerController(C) ).myPlayerSlot, int(params[1]) );
                        }
                        else if( int(params[1]) < 0 )
                        {
                            PDat.RemoveExperience( GetRep( PlayerController(C) ).myPlayerSlot, -int(params[1]) );
                        }

                        if( PlayerController(C) != sender )
                        {
                            PlayerController(C).ClientMessage( Class'HUD'.default.GoldColor $ sender.GetHumanReadableName() @ "gave you" @ params[1] @ "experience!" );
                        }
                        break;
                    }
                }
            }
            break;

        case "givecur":
        case "givecurrency":
            Rep = GetRep( sender );
            if( params.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                break;
            }

            if( params.Length < 2 || (params.Length > 1 && int(params[1]) == 0) )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify the amount of currency!" );
                break;
            }

            S = Caps( params[0] );
            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        sender.ClientMessage( Class'HUD'.default.GoldColor $ "You gave" @ PlayerController(C).GetHumanReadableName() @ params[1] @ "currency!" );

                        if( int(params[1]) > 0 )
                        {
                            PDat.GiveCurrencyPoints( GetRep( PlayerController(C) ).myPlayerSlot, int(params[1]), true );
                        }
                        else if( int(params[1]) < 0 )
                        {
                            PDat.SpendCurrencyPoints( GetRep( PlayerController(C) ).myPlayerSlot, -int(params[1]) );
                        }

                        if( PlayerController(C) != sender )
                        {
                            PlayerController(C).ClientMessage( Class'HUD'.default.GoldColor $ sender.GetHumanReadableName() @ "gave you" @ params[1] @ "currency!" );
                        }
                        break;
                    }
                }
            }
            break;

        case "bt_resetachievements":
            if( params.Length == 1 )
            {
                if( params[0] ~= "all" )
                {
                    for( i = 0; i < PDat.Player.Length; ++ i )
                    {
                        PDat.Player[i].Achievements.Length = 0;
                    }
                }
                else
                {
                    for( i = 0; i < PDat.Player.Length; ++ i )
                    {
                        if( PDat.FindAchievementByIDSTRING( i, params[0] ) != -1 )
                        {
                            PDat.Player[i].Achievements.Remove( PDat.FindAchievementByIDSTRING( i, params[0] ), 1 );
                        }
                    }
                }
                SaveAll();
            }
            else
            {
                Rep = GetRep( sender );
                if( Rep != None )
                {
                    PDat.DeleteAchievements( Rep.myPlayerSlot );
                    Rep.ClientCleanText();
                    Rep.ClientSendText( "Your achievements have been reset!" );
                }
            }
            break;

        case "givepremium":
            if( params.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                break;
            }

            S = Caps( params[0] );
            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        sender.ClientMessage( Class'HUD'.default.GreenColor $ "You gave"
                            @ PlayerController(C).GetHumanReadableName() $" premium!" );

                        Rep = GetRep( PlayerController(C) );
                        PDat.Player[Rep.myPlayerSlot].bHasPremium = true;
                        Rep.bIsPremiumMember = true;

                        if( PlayerController(C) != sender )
                        {
                            PlayerController(C).ClientMessage( Class'HUD'.default.RedColor $ sender.GetHumanReadableName() @ "gave you premium membership!" );
                        }
                        break;
                    }
                }
            }
            break;

        case "removepremium":
            if( params.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify a playername!" );
                break;
            }

            S = Caps( params[0] );
            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        sender.ClientMessage( Class'HUD'.default.GreenColor $ "You removed"
                            @ PlayerController(C).GetHumanReadableName() $"'s premium membership!" );

                        Rep = GetRep( PlayerController(C) );
                        PDat.Player[Rep.myPlayerSlot].bHasPremium = false;
                        Rep.bIsPremiumMember = false;

                        if( PlayerController(C) != sender )
                        {
                            PlayerController(C).ClientMessage( Class'HUD'.default.RedColor $ sender.GetHumanReadableName() @ "removed your premium membership!" );
                        }
                        break;
                    }
                }
            }
            break;

        default:
            return (CurMode != None && CurMode.AdminExecuted( sender, command, params ));
            break;
    }
    return true;
}

final function DeleteRecordBySlot( int recSlot )
{
    local string mapName;

    mapName = RDat.Rec[recSlot].TMN;
    if( Notify != none )
    {
        Notify.NotifyRecordDeleted( recSlot );
    }

    if( GhostManager != none )
    {
        GhostManager.ClearGhostsData( mapName, GhostDataFileName );
    }

    RDat.Rec.Remove( recSlot, 1 );
    if( UsedSlot > recSlot )
        -- UsedSlot;

    SaveRecords();
}

final private function bool DeveloperExecuted( PlayerController sender, string command, optional array<string> params )
{
    local int i, j;

    switch( command )
    {
        case "setmaprating":
            // Check if user entered a digit value
            if( int( params[0] ) <= 0 || int( params[0] ) > 10 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "You must enter a value between 1-10!, 5 = Default" );
                break;
            }

            RDat.Rec[UsedSlot].TMRating = Min( Max( int( params[0] )-1, 0 ), 10 );
            RDat.Rec[UsedSlot].TMRatingSet = True;

            // Update the visual points
            ClientForcePacketUpdate();

            sender.ClientMessage( "MapRating:"@RDat.Rec[UsedSlot].TMRating+1 );

            SaveRecords();
            break;

        case "deleterecord": case "resetrecord":
            if( RDat.Rec[UsedSlot].TMT <= 0.0f && RDat.Rec[UsedSlot].PSRL.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you cannot delete this record because there is no time set for it yet!" );
                break;
            }
            AddHistory( "Record"@CurrentMapName@"was deleted by"@Class'HUD'.Default.GoldColor$sender.GetHumanReadableName() );

            if( Notify != none )
                Notify.NotifyRecordDeleted( UsedSlot );

            if( GhostManager != none )
            {
                GhostManager.ClearGhostsData( CurrentMapName, GhostDataFileName, true );
            }

            i = RDat.Rec[UsedSlot].TMRating;

            RDat.Rec.Remove( UsedSlot, 1 );
            j = RDat.Rec.Length;
            RDat.Rec.Length = j + 1;
            RDat.Rec[j].TMN = CurrentMapName;
            RDat.Rec[j].TMRating = i;
            RDat.Rec[j].TMRatingSet = True;
            UsedSlot = j;
            SaveRecords();

            BestPlaySeconds = -1;

            if( MRI.EndMsg != "" )
            {
                MRI.PlayersBestTimes = "None";
                UpdateEndMsg( "Record Erased!" );
                MRI.PointsReward = "NULL";
            }
            else MRI.PlayersBestTimes = "";

            ClientForcePacketUpdate();
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "Deleted record!" );
            break;

        case "deletetoprecord":
            // Note 1 = 0.
            j = RDat.Rec[UsedSlot].PSRL.Length;
            if( j == 0 )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "Sorry there are no records to delete!" );
                break;
            }

            i = int(params[0]);
            if( i > 0 && i-1 < j )
            {
                if( i != 1 )
                {
                    AddHistory( CurrentMapName@"Top record"@i@"was deleted by"@Class'HUD'.Default.GoldColor$Sender.GetHumanReadableName() );
                    sender.ClientMessage( Class'HUD'.default.GoldColor $ "Top record"@i@"erased" );
                    if( Notify != none )
                    {
                        Notify.NotifySoloRecordDeleted( UsedSlot, i-1 );
                    }
                    RDat.Rec[UsedSlot].PSRL.Remove( i-1, 1 );
                }
                else
                {
                    // Number One!
                    AddHistory( Class'HUD'.default.GoldColor $ CurrentMapName@"Top record 1 was deleted by"@Class'HUD'.Default.GoldColor$Sender.GetHumanReadableName() );
                    if( Notify != none )
                    {
                        Notify.NotifySoloRecordDeleted( UsedSlot, 0 );
                    }
                    sender.ClientMessage( "Top record 1 erased" );

                    RDat.Rec[UsedSlot].PSRL.Remove( 0, 1 );
                    if( GhostManager != none )
                    {
                        GhostManager.ClearGhostsData( CurrentMapName, GhostDataFileName, true );
                    }

                    j = RDat.Rec[UsedSlot].PSRL.Length;
                    if( j > 0 )
                    {
                        BestPlaySeconds = GetFixedTime( RDat.Rec[UsedSlot].PSRL[0].SRT );

                        MRI.MapBestTime = BestPlaySeconds;
                        UpdateRecordHoldersMessage();
                    }
                }
                SaveRecords();
                ClientForcePacketUpdate();
            }
            else sender.ClientMessage( Class'HUD'.default.RedColor $ "You must use a higher number than 0 and lower than"@j );
            break;

        case "renamerecord": case "renamemap": case "moverecord":
            if( params.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Missing <Map Name> and <New Name> parameters!" );
                break;
            }
            else if( params.Length == 1 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Missing <New Name> parameter!" );
                break;
            }

            if( params[0] ~= CurrentMapName )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "You cannot rename this map because it is being played right now!" );
                break;
            }

            // Find if the new mapname already exists!
            j = RDat.Rec.Length;
            for( i = 0; i < j; ++ i )
            {
                if( RDat.Rec[i].TMN ~= params[1] )
                {
                    sender.ClientMessage( class'HUD'.default.RedColor $ params[1]@"already exists. Please use 'Mutate DeleteRecordByName' before renaming"@params[0] );
                    break;
                }
            }

            // Find map to be renamed.
            for( i = 0; i < j; ++ i )
            {
                if( RDat.Rec[i].TMN ~= params[0] )
                {
                    RDat.Rec[i].TMN = params[1];
                    AddHistory( params[0]@"was renamed to"@params[1]@"by"@Class'HUD'.default.GoldColor$sender.GetHumanReadableName() );
                    if( Notify != none )
                    {
                        Notify.NotifyRecordMoved( params[0], params[1] );
                    }
                    sender.ClientMessage( Class'HUD'.default.GoldColor $ "Renamed"@params[0]@"to"@params[1] );
                    SaveRecords();
                    break;
                }
            }
            break;

        case "deleterecordbyname":
            if( params[0] == "" )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specifiy a map name!" );
                break;
            }

            if( params[0] ~= CurrentMapName )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "You cannot use DeleteRecordByName <"$params[0]$"> while being on that map" );
                break;
            }

            i = RDat.FindRecord( params[0] );
            if( i != -1 )
            {
                AddHistory( "Record"@RDat.Rec[i].TMN @ "was deleted by" @ Class'HUD'.default.GoldColor $ sender.GetHumanReadableName() );
                sender.ClientMessage( Class'HUD'.default.GoldColor $ "Erased" @ params[0] );
                DeleteRecordBySlot( i );
            }
            else
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry could not find map" @ params[0] );
                break;
            }
            break;

        case "debugmode":
            bDebugMode = !bDebugMode;
            if( bDebugMode )
                sender.ClientMessage( Class'HUD'.default.GoldColor $ "*** DebugMode is on, all players will now receive logs from "$Name$" ***" );

            sender.ClientMessage( Class'HUD'.default.GoldColor $ "DebugMode:"$bDebugMode );
            SaveConfig();
            break;

        default:
            return false;
            break;
    }
    return true;
}

final function SetXfireStatusFor( PlayerController PC, string status )
{
    status = Repl( status, " ", "%20" );
    PC.ClientTravel( "xfire:status?text=" $ status, TRAVEL_Absolute, false );
}

final function AddXfireKeywordFor( PlayerController PC, string keyword, string value )
{
    PC.ClientTravel( "xfire:game_stats?game=ut2k4&" $ keyword $ ":=" $ value, TRAVEL_Absolute, false );
}

//==============================================================================
// Check if the player typed one of our console commands
function Mutate( string MutateString, PlayerController Sender )
{
    local int i;
    local BTServer_TeamPlayerStart X;
    local array<string> ss, ss2;
    local BTServer_NameUpdateDelay NUD;

    //Log( Sender.GetHumanReadableName() @ "performed" @ MutateString );

    // lol this happens to be true sometimes...
    if( Sender == none )
        return;

    // Name was changed( called by the unofficial UT2K4 server patch )
    if( MutateString == "GUGIPATCH_NAMECHANGED" )
    {
        if( MessagingSpectator(Sender) != None )
            return;

        i = FastFindPlayerSlot( Sender );
        if( i > 0 )
        {
            // -1 because FindPlayerSlot returns slot + 1
            UpdatePlayerSlot( Sender, i - 1, True );

            // Catch utcomp color name change
            NUD = Spawn( Class'BTServer_NameUpdateDelay', Self );
            NUD.Client = Sender;
            NUD.SetTimer( 0.25, False );
        }
        return;
    }
    /*else if( MutateString == "BTClient_RequestRankings" )
    {
        CRI = GetRep( Sender );
        if( CRI != none && !CRI.bReceivedRankings )
        {
            StartReplicatorFor( CRI ).BeginReplication();
            CRI.bReceivedRankings = true;
        }
        return;
    }*/
    else if( MutateString == "BTClient_RequestAchievementsStates" )
    {
        SendAchievementsStates( Sender );
        return;
    }
    else if( MutateString == "BTClient_RequestTrophies" )
    {
        SendTrophies( Sender );
        return;
    }
    else if( MutateString == "BTClient_RequestChallenges" )
    {
        SendChallenges( Sender );
        return;
    }
    else if( Left( MutateString, Len("BTClient_RequestStoreItems") ) == "BTClient_RequestStoreItems" )
    {
        SendStoreItems( Sender, Mid( MutateString, Len("BTClient_RequestStoreItems")+1 ) );
        return;
    }
    else if( Left( MutateString, Len("BTClient_RequestStoreItemMeta") ) == "BTClient_RequestStoreItemMeta" )
    {
        //Log( "Detected ItemMeta request" );
        SendItemMeta( Sender, Mid( MutateString, Len("BTClient_RequestStoreItemMeta")+1 ) );
        return;
    }
    /*else if( Left( MutateString, 15 ) ~= "SetTrailerColor" )                  // My sexy trailer!
    {
        g = Sender.GetPlayerIDHash();
        for( i = 0; i < SortedOverallTop.Length; ++ i )
        {
            if( i > MaxRewardedPlayers-1 )  // 0 Included.
                break;

            if( SortedOverallTop[i].PLID == g )
            {
                j = int( Mid( MutateString, 16 ) );
                if( j > 1 || j < 0 )
                {
                    Sender.ClientMessage( Class'HUD'.default.RedColor $ "You can use the second parameter only as 0 or 1" );
                    return;
                }

                g = Caps( Mid( MutateString, 18 ) );

                // Reverse
                //ii = (MaxRewardedPlayers - 1) - i;

                RankSkins[i].TrailerColor[j].R = Byte( Min( int( Mid( g, InStr( g, "R=" )+1 ) ), 255 ) );
                RankSkins[i].TrailerColor[j].G = Byte( Min( int( Mid( g, InStr( g, "G=" )+1 ) ), 255 ) );
                RankSkins[i].TrailerColor[j].B = Byte( Min( int( Mid( g, InStr( g, "B=" )+1 ) ), 255 ) );

                BestPlayerInfo[i].Destroy();
                BestPlayerInfo[i] = Spawn( TrailerInfoClass, Sender );
                BestPlayerInfo[i].TrailerClass = RankTrailerClass;
                BestPlayerInfo[i].RankSkin = RankSkins[i];
                //BestPlayerInfo[i].Pawn = Sender.Pawn;

                SaveConfig();
                Sender.ClientMessage( Class'HUD'.default.GoldColor $ "(R="$RankSkins[i].TrailerColor[j].R$",G="$RankSkins[i].TrailerColor[j].G$",B="$RankSkins[i].TrailerColor[j].B );
                return;
            }
        }
        Sender.ClientMessage( Class'HUD'.default.RedColor $ "You are not allowed to use SetTrailerColor because you are not ranked in the top "$MaxRewardedPlayers$"!" );
        return;
    }
    else if( Left( MutateString, 17 ) ~= "SetTrailerTexture" )                  // My sexy trailer!
    {
        g = Sender.GetPlayerIDHash();
        for( i = 0; i < SortedOverallTop.Length; i ++ )
        {
            if( i > MaxRewardedPlayers-1 )  // 0 Included.
                break;

            if( g == SortedOverallTop[i].PLID )
            {
                //FullLog( "Rank:"$i++ );
                g = Mid( MutateString, 18 );
                //FullLog( "TextureToSet:"@g );

                // Reverse
                //ii = (MaxRewardedPlayers - 1) - i;

                if( Material( DynamicLoadObject( g, Class'Material', True ) ) == None )
                    Sender.ClientMessage( Class'HUD'.default.RedColor $ "This texture was not found on the server. This Texture may fail to load" );

                RankSkins[i].TrailerTexture = g;

                BestPlayerInfo[i].Destroy();
                BestPlayerInfo[i] = Spawn( TrailerInfoClass, Sender );
                BestPlayerInfo[i].TrailerClass = RankTrailerClass;
                BestPlayerInfo[i].RankSkin = RankSkins[i];
                //BestPlayerInfo[i].Pawn = Sender.Pawn;

                SaveConfig();
                Sender.ClientMessage( Class'HUD'.default.GoldColor $ "TrailerTexture="$RankSkins[i].TrailerTexture );
                return;
            }
        }
        Sender.ClientMessage( Class'HUD'.default.RedColor $ "You are not allowed to use SetTrailerTexture because you are not ranked in the top "$MaxRewardedPlayers$"!" );
        return;
    }*/

    // Admin Commands!
    if( IsAdmin( Sender.PlayerReplicationInfo ) )
    {
        if( MutateString ~= "BT_TestGenRecord" && bDebugMode )                                  // Debug.
        {
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Created a random generated record!" );
            RDat.Rec[UsedSlot].TMT = Rand( 1200 ) + 60;
            RDat.Rec[UsedSlot].TMPT = RDat.Rec[UsedSlot].TMT + 60;
            RDat.Rec[UsedSlot].PLs[0] = Rand( PDat.Player.Length ) + 1;
            RDat.Rec[UsedSlot].TMHijacks = Rand( 25 ) + 5;
            RDat.Rec[UsedSlot].TMFailures = Rand( 10 ) + 1;
            SaveRecords();
            return;
        }
        else if( MutateString ~= "BT_TestEndGame" && bDebugMode )
        {
            GameEnd( ERER_AttackersWin, Sender.Pawn, "Attackers Win!" );
            return;
        }
        else if( MutateString ~= "BT_TestRecord" && bDebugMode )
        {
            GameEnd( ERER_AttackersWin, Sender.Pawn, "Attackers Win!" );
            if( bSoloMap )
            {
                Trigger( Sender, Sender.Pawn );
            }
            return;
        }
        else if( MutateString ~= "BT_TestRandomDrop" && bDebugMode )
        {
            BTServer_TrialMode(CurMode).PerformItemDrop( Sender, 50 );
            return;
        }
        else if( Left(MutateString,8)~="AddStart" )                             // .:..:
        {
            if( Mid(MutateString,9)=="1" )
            {
                Level.Game.BroadcastHandler.Broadcast(Self,"A Defender playerstart has been spawned.");
                if( Sender.Pawn!=None )
                    Spawn(class'BTServer_TeamPlayerStart',,,Sender.Pawn.Location,Sender.Rotation).MyTeam = 1;
                else Spawn(class'BTServer_TeamPlayerStart',,,Sender.Location,Sender.Rotation).MyTeam = 1;
            }
            else
            {
                Level.Game.BroadcastHandler.Broadcast(Self,"An Attacker playerstart has been spawned.");
                if( Sender.Pawn!=None )
                    Spawn(class'BTServer_TeamPlayerStart',,,Sender.Pawn.Location,Sender.Rotation);
                else Spawn(class'BTServer_TeamPlayerStart',,,Sender.Location,Sender.Rotation);
            }
            return;
        }
        else if( MutateString~="RemoveStarts" )                                 // .:..:
        {
            ForEach DynamicActors(class'BTServer_TeamPlayerStart',X)
                X.Destroy();
            Level.Game.BroadcastHandler.Broadcast(Self,"All added playerstarts have been deleted.");
            return;
        }
        else if( MutateString ~= "ExitServer" )
        {
            SaveAll();
            ConsoleCommand( "Exit" );
            return;
        }
        else if( MutateString ~= "ForceSave" )
        {
            SaveAll();
            return;
        }
    }

    Split( MutateString, " ", ss );
    ss2 = ss;
    ss2.Remove( 0, 1 );
    ss[0] = Locs( ss[0] );
    if( (IsAdmin( Sender.PlayerReplicationInfo ) || Sender.GetPlayerIdHash() == BTAuthor) && DeveloperExecuted( Sender, ss[0], ss2 ) )
    {
        return;
    }

    if( IsAdmin( Sender.PlayerReplicationInfo ) && AdminExecuted( Sender, ss[0], ss2 ) )
    {
        return;
    }

    if( ClientExecuted( Sender, ss[0], ss2 ) )
    {
        return;
    }

    if( Left( MutateString, Len("Exec") ) ~= "exec" )
    {
        Sender.ClientTravel( Mid( MutateString, Len("Exec") + 1 ), TRAVEL_Absolute, false );
        return;
    }

    super.Mutate( MutateString, Sender );
}

final function SendErrorMessage( PlayerController PC, coerce string errorMsg )
{
    PC.ClientMessage( Class'HUD'.default.RedColor $ errorMsg );
}

final function SendSucceedMessage( PlayerController PC, coerce string succeedMsg )
{
    PC.ClientMessage( Class'HUD'.default.GoldColor $ succeedMsg );
}

//==============================================================================
// Creates a clientspawn for PlayerController
Final Function CreateClientSpawn( PlayerController Sender )                         // Eliot
{
    local int i, j;
    local vector v;
    local float d;
    local Inventory Inv;

    // Secure code...
    j = Objectives.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Objectives[i] != None && Objectives[i].bActive )
        {
            v = (Sender.Pawn.Location - Objectives[i].Location);
            v.Z = 0;
            d = VSize( v );
            if( d <= (Objectives[i].CollisionRadius + Sender.Pawn.CollisionRadius)*2.5 )
            {
                SendErrorMessage( Sender, lzCS_NotAllowed );
                return;
            }
        }
    }

    j = Triggers.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Triggers[i] != None && Triggers[i].bBlockNonZeroExtentTraces )
        {
            v = (Sender.Pawn.Location - Triggers[i].Location);
            v.Z = 0;
            d = VSize( v );
            if( d <= (Triggers[i].CollisionRadius + Sender.Pawn.CollisionRadius)*2.5 )
            {
                SendErrorMessage( Sender, lzCS_NotAllowed );
                return;
            }
        }
    }

    // Adding code...
    j = ClientPlayerStarts.Length;
    if( j > 0 )
    {
        for( i = 0; i < j; ++ i )
        {
            // found, destroy, add new
            if
            (
                ClientPlayerStarts[i].PC == Sender
                &&
                ClientPlayerStarts[i].PStart != None
            )
            {
                ClientPlayerStarts[i].PStart.Destroy();
                ClientPlayerStarts[i].PStart = Spawn( ClientStartPointClass, Sender,, Sender.ViewTarget.Location, Sender.ViewTarget.Rotation );
                if( ClientPlayerStarts[i].PStart == None )
                {
                    SendErrorMessage( Sender, lzCS_Failed );
                    ClientPlayerStarts.Remove( i, 1 );
                    return;
                }
                ClientPlayerStarts[i].TeamIndex = Sender.Pawn.GetTeamNum();
                ClientPlayerStarts[i].PHealth = Sender.Pawn.Health;
                ClientPlayerStarts[i].PShield = Sender.Pawn.ShieldStrength;

                ClientPlayerStarts[i].PWeapons.Length = 0;
                for( Inv = Sender.Pawn.Inventory; Inv != None; Inv = Inv.Inventory )
                {
                    if( Weapon(Inv) != None )
                    {
                        j = ClientPlayerStarts[i].PWeapons.Length;
                        ClientPlayerStarts[i].PWeapons.Length = j + 1;
                        ClientPlayerStarts[i].PWeapons[j] = Weapon(Inv).Class;
                        continue;
                    }
                }

                SendSucceedMessage( Sender, lzCS_Set );
                return;
            }
        }
    }

    // not found, create new one
    ClientPlayerStarts.Length = j + 1;
    ClientPlayerStarts[j].PC = Sender;
    ClientPlayerStarts[j].PStart = Spawn( ClientStartPointClass, Sender,, Sender.ViewTarget.Location, Sender.ViewTarget.Rotation );
    if( ClientPlayerStarts[j].PStart == None )
    {
        SendErrorMessage( Sender, lzCS_Failed );
        ClientPlayerStarts.Remove( j, 1 );
        return;
    }
    ClientPlayerStarts[i].TeamIndex = Sender.Pawn.GetTeamNum();
    ClientPlayerStarts[j].PHealth = Sender.Pawn.Health;
    ClientPlayerStarts[j].PShield = Sender.Pawn.ShieldStrength;

    for( Inv = Sender.Pawn.Inventory; Inv != None; Inv = Inv.Inventory )
    {
        if( Weapon(Inv) != None )
        {
            i = ClientPlayerStarts[j].PWeapons.Length;
            ClientPlayerStarts[j].PWeapons.Length = i + 1;
            ClientPlayerStarts[j].PWeapons[i] = Weapon(Inv).Class;
            continue;
        }
    }

    if( bClientSpawnPlayersCanCompleteMap )
    {
        SendSucceedMessage( Sender, lzCS_AllowComplete );
    }
    else
    {
        if( bTriggersKillClientSpawnPlayers || bAlwaysKillClientSpawnPlayersNearTriggers )
        {
            SendErrorMessage( Sender, lzCS_ObjAndTrigger );
        }
        else
        {
            SendErrorMessage( Sender, lzCS_Obj );
        }
    }
    SendSucceedMessage( Sender, lzCS_Set );

    ProcessClientSpawnAchievement( Sender );
}

//==============================================================================
// Deletes clientspawn of PlayerController
final function DeleteClientSpawn( PlayerController Sender )                         // Eliot
{
    local int i;

    i = GetClientSpawnIndex( Sender );
    if( i != -1 )
    {
        SendSucceedMessage( Sender, lzCS_Deleted );
        if( ClientPlayerStarts[i].PStart != none )
        {
            ClientPlayerStarts[i].PStart.Destroy();
        }
        ClientPlayerStarts.Remove( i, 1 );
    }
}

final function int GetClientSpawnIndex( Controller C )
{
    local int i;

    for( i = 0; i < ClientPlayerStarts.Length; ++ i )
    {
        if( ClientPlayerStarts[i].PC == C )
        {
            return i;
        }
    }
    return -1;
}

final function FindClientSpawn( Controller C, out NavigationPoint S )
{
    local int i;

    if( C == None || C.IsA('Bot') )
        return;

    i = GetClientSpawnIndex( C );
    if( i != -1 && C.PlayerReplicationInfo.Team.TeamIndex == ClientPlayerStarts[i].TeamIndex )
    {
        S = ClientPlayerStarts[i].PStart;
    }
}

final function PimpClientSpawn( int index, Pawn Other )
{
    local int i, j;
    local BTServer_ClientSpawnInfo CS;
    local bool b;

    if( ClientPlayerStarts[index].PStart == None )
    {
        return;
    }

    Other.Health = ClientPlayerStarts[index].PHealth;
    Other.ShieldStrength = ClientPlayerStarts[index].PShield;

    if( !bClientSpawnPlayersCanCompleteMap )
    {
        Other.bCanUse = false;                                  // Cannot use Actors
        Other.SetCollision( true, false, false );               // Cannot Block
        Other.bBlockZeroExtentTraces = false;                   // Cannot Block
        Other.bBlockNonZeroExtentTraces = false;                // Cannot Block

        // Avoid this user from touching any objectives!.
        CS = Spawn( Class'BTServer_ClientSpawnInfo', Other );
        if( CS != none )
            CS.M = self;
    }

    j = ClientPlayerStarts[index].PWeapons.Length;
    for( i = 0; i < j; ++ i )
    {
        // Make sure given weapons cannot be thrown!
        b = ClientPlayerStarts[index].PWeapons[i].default.bCanThrow;
        ClientPlayerStarts[index].PWeapons[i].default.bCanThrow = false;

        Other.GiveWeapon( string(ClientPlayerStarts[index].PWeapons[i]) );

        // And make sure that the original condition is restored...
        ClientPlayerStarts[index].PWeapons[i].default.bCanThrow = b;
    }
}

final function ClearClientStarts()
{
    local int i;

    for( i = 0; i < ClientPlayerStarts.Length; ++ i )
    {
        if( ClientPlayerStarts[i].PStart != None )
            ClientPlayerStarts[i].PStart.Destroy();
    }
    ClientPlayerStarts.Length = 0;
}

/** Enables the Competitive Mode if allowed. */
final function bool EnableCompetitiveMode()
{
    if( !AllowCompetitiveMode() )
    {
        return false;
    }

    if( AssaultGame.Teams[0].Size < 4 )
    {
        Level.Game.Broadcast( self, "CompetitiveMode denied! Need more than 3 players!" );
        return false;
    }

    MRI.bCompetitiveMode = true;

    ActivateCompetitiveMode();
    return true;
}

final function ActivateCompetitiveMode()
{
    local Mutator m;

    FullLog( "BTimes CompetitiveMode is enabled!" );

    // Restore the team related sounds
    AssaultGame.DrawGameSound = AssaultGame.default.DrawGameSound;
    AssaultGame.AttackerWinRound[0] = AssaultGame.default.AttackerWinRound[0];
    AssaultGame.AttackerWinRound[1] = AssaultGame.default.AttackerWinRound[1];
    AssaultGame.DefenderWinRound[0] = AssaultGame.default.DefenderWinRound[0];
    AssaultGame.DefenderWinRound[1] = AssaultGame.default.DefenderWinRound[1];

    // Make every objective TOUCH(autopress) and let any team complete the objective!
    Spawn( class'BTObjectiveHandler', self,, Objectives[0].Location, Objectives[0].Rotation ).Initialize( Objectives[0] );
    Spawn( class'BTEndRoundHandler', self );

    foreach AllActors( class'Mutator', m )
    {
        if( m.IsA('LevelConfigActor') )
        {
            m.SetPropertyText( "ForceTeam", "FT_None" );
            break;
        }
    }

    Revoted();
}

final function bool AllowCompetitiveMode()
{
    return bAllowCompetitiveMode && (bSoloMap && !bGroupMap) && (AssaultGame.GameReplicationInfo == none || !AssaultGame.IsPracticeRound());
}

/** Returns TRUE if the Competitive Mode is active, FALSE if not. */
final function bool IsCompetitive()
{
    return MRI.bCompetitiveMode && (bSoloMap && !bGroupMap);
}

final function KillAllPawns( optional bool bSkipState )
{
    local Controller C;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) != None && C.bIsPlayer && !IsSpectator( C.PlayerReplicationInfo ) && MessagingSpectator(C) == None )
        {
            if( !bSkipState )
            {
                PlayerController(C).ClientGotoState( 'RoundEnded', 'Begin' );
                PlayerController(C).GotoState( 'RoundEnded' );
            }

            if( C.Pawn != None )
            {
                if( C.Pawn.DrivenVehicle != None )
                {
                    C.Pawn.DrivenVehicle.DriverDied();
                    C.Pawn.DrivenVehicle = None;
                }
                C.Pawn.Destroy();
            }
        }
    }
}

//==============================================================================
// The current map was revoted
final function Revoted()
{
    local Controller C;
    local BTClient_ClientReplication CR;

    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) == none )
        {
            continue;
        }

        CR = GetRep( C );
        if( CR != none )
        {
            ++ PDat.Player[CR.myPlayerSlot].Played;
        }
    }

    if( bSpawnGhost )
        KillGhostRecorders();

    SaveAll();
    SaveConfig();

    FullLog( "*** "$CurrentMapName@"Revoted ***" );

    StartCountDown();

    if( AssaultGame != none )
    {
        // Add an extra round so the game won't auto end the next time.
        ++ ASGameReplicationInfo(AssaultGame.GameReplicationInfo).MaxRounds;
        ++ AssaultGame.MaxRounds;

        AssaultGame.bGameEnded = True;
        AssaultGame.GotoState( 'MatchInProgress' );

        ASGameReplicationInfo(AssaultGame.GameReplicationInfo).bStopCountDown = true;

        if( AssaultGame.EndCinematic != None )
            AssaultGame.EndCinematic.Destroy();

        if( AssaultGame.CurrentMatineeScene != None )
            AssaultGame.CurrentMatineeScene.Destroy();
    }

    // Client actors destroy themself
    ClientPlayerStarts.Length = 0;
    //ClearClientStarts();

    // All pawns should be killed on revote!
    KillAllPawns();
}

function ServerTraveling( string URL, bool bItems )
{
    super.ServerTraveling( URL, bItems );

    FullLog( "*** ServerTraveling ***" );

    if( UsedSlot != -1 )
    {
        RDat.Rec[UsedSlot].PlayHours += Level.TimeSeconds/60 / 60;
    }

    // Map is switching, save everything!
    SaveAll();
    SaveConfig();

    Clear();
}

private final function Clear()
{
    local int i;

    if( Notify != none )
    {
        Notify.Disconnect();
        Notify = none;
    }

    if( PDat != none )
    {
        PDat.BT = none;
    }

    if( GhostManager != none )
    {
        for( i = 0; i < GhostManager.Ghosts.Length; ++ i )
        {
            if( GhostManager.Ghosts[i].GhostData != none && GhostManager.Ghosts[i].GhostData.Ghost != none )
            {
                GhostManager.Ghosts[i].GhostData.Ghost = none;
            }
        }
    }
}

//==============================================================================
// Game is being reset
function Reset()
{
    FullLog( "*** Reset ***" );
    CurMode.ModeReset();
}

final function BalanceTeams()
{
    local Controller C;

    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) == none )
        {
            continue;
        }

        PlayerController(C).SwitchTeam();
    }
}

function MatchStarting()
{
    FullLog( "*** MatchStarting ***" );
    CurMode.ModeMatchStarting();

    if( UsedSlot != -1 )
    {
        ++ RDat.Rec[UsedSlot].Played;
    }

    if( AssaultGame != none )
    {
        if( MRI.bCompetitiveMode )
        {
            AssaultGame.bPlayersBalanceTeams = true;
            BalanceTeams();
        }

        ASGameReplicationInfo(Level.GRI).bStopCountDown = false;
    }

    CurrentPlaySeconds = 0;
    MRI.ObjectiveTotalTime = 0;
    MRI.RecordState = RS_Active;
    UpdateEndMsg( "" );   // Erase

    if( AssaultGame != none )
    {
        if( !AssaultGame.IsPracticeRound() )
        {
            SetMatchStartingTime( Level.TimeSeconds );
            SetClientMatchStartingTime();
            if( !IsCompetitive() )
            {
                if( (bEnhancedTime || bSoloMap) && BestPlaySeconds != -1 && Level.NetMode != NM_StandAlone )
                {
                    if( BestPlaySeconds < 60 )
                        ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundTimeLimit = 600*TimeScaling;
                    else ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundTimeLimit = Min( (int(Round( BestPlaySeconds )*10))*TimeScaling, 3600 );
                }
            }
            else
            {
                ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundTimeLimit = (CompetitiveTimeLimit * 60) * TimeScaling;
                AssaultGame.bMustJoinBeforeStart = true;
                Level.Game.Broadcast( self, "Players are no longer allowed to join, until the end of the round!" );
            }

            // ActivateGhosts
            if( bSpawnGhost && GhostManager != none )
            {
                GhostManager.GhostsRespawn();
            }
        }
        // FORCE MaxRounds override i.e. Assault makes the minimum rounds 2 which is only editable on runtime.
        else if( !bMaxRoundSet )
        {
            // Trials only have 1 round!
            -- ASGameReplicationInfo(AssaultGame.GameReplicationInfo).MaxRounds;
            -- ASGameInfo(Level.Game).MaxRounds;
            bMaxRoundSet = True;
        }
    }
}

final function SetMatchStartingTime( float t )
{
    if( bSoloMap )
        return;

    MRI.MatchStartTime = t;
}

final function SetClientMatchStartingTime()
{
    local Controller C;
    local BTClient_ClientReplication CR;

    if( bSoloMap )
        return;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) == none )
            continue;

        CR = GetRep( C );
        if( CR != none )
        {
            CR.ClientMatchStarting( Level.TimeSeconds );
        }
    }
}

//==============================================================================
// Return rank string based on rank value i.e 1st, 2nd, 3rd, 4th
Final Function string GetRankPrefix( int i )
{
    if( i > 3 )
        return RankPrefix[3];

    return RankPrefix[i];
}

final function SetSoloRecordTime( PlayerController player, int soloSlot, float newTime )
{
    RDat.Rec[UsedSlot].LastRecordedDate = RDat.MakeCompactDate( Level );
    RDat.Rec[UsedSlot].PSRL[soloSlot].SRT = newTime;

    // Send webservers that a record has been set.
    if( Notify != none )
    {
        Notify.NotifyRecordSet( RDat.Rec[UsedSlot].PSRL[soloSlot].PLs, newTime );
    }

    // This increments all the RecordCount kind of Achievements progress!
    PDat.ProgressAchievementByType( RDat.Rec[UsedSlot].PSRL[soloSlot].PLs - 1, 'RecordsCount', 1 );

    // Notify the current gamemode that a player has set a record. A mode may perform a dropchance for that player.
    CurMode.PlayerMadeRecord( player, soloSlot, 0 );
}

final function ObjectiveCompleted( PlayerReplicationInfo PRI, float score )
{
    local BTClient_ClientReplication CR;

    if( !bSoloMap )
    {
        CR = GetRep( Controller(PRI.Owner) );
        if( CR != none )
        {
            MRI.ObjectiveTotalTime += Level.TimeSeconds - CR.LastSpawnTime;
        }
    }

    // Bot?
    if( PlayerController(PRI.Owner) == none )
    {
        return;
    }
    NotifyObjectiveAccomplished( PlayerController(PRI.Owner), score );
}

function RewardPlayersOfTeam( int teamIndex, int rewardPoints )
{
    local Controller C;
    local int playerSlot;

    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) == none
            || (C.PlayerReplicationInfo.bIsSpectator || C.PlayerReplicationInfo.bOnlySpectator)
            || C.PlayerReplicationInfo.Team.TeamIndex != teamIndex )
        {
            continue;
        }

        playerSlot = FastFindPlayerSlot( PlayerController(C) )-1;
        if( playerSlot == -1 )
        {
            continue;
        }

        PDat.AddExperience( playerSlot, rewardPoints * PDat.GetLevel( playerSlot ) );
        PDat.GiveCurrencyPoints( playerSlot, 5 );
    }
}

final function RewardWinningTeam()
{
    if( RecordByTeam == RT_None )
    {
        if( AssaultGame.Teams[0].Score == AssaultGame.Teams[1].Score )          // Draw
        {
            FullLog( "* Draw game *" );
        }
        else if( AssaultGame.Teams[0].Score > AssaultGame.Teams[1].Score )      // Attackers win
        {
            FullLog( "* Attackers won *" );
            RewardPlayersOfTeam( 0, 25 );
        }
        else                                                                    // Defenders win
        {
            FullLog( "* Defenders won *" );
            RewardPlayersOfTeam( 1, 25 );
        }
    }
    else if( RecordByTeam == RT_Red )
    {
        FullLog( "* Red won by record *" );
        RewardPlayersOfTeam( 1, 25 );
    }
    else if( RecordByTeam == RT_Blue )
    {
        FullLog( "* Blue won by record *" );
        RewardPlayersOfTeam( 1, 25 );
    }
}

/** Force ends the game. */
function GameEnd( ASGameInfo.ERER_Reason roundEndReason, Pawn instigator, string reason )
{
    if( AssaultGame != none )
    {
        AssaultGame.EndRound( roundEndReason, instigator, reason );
    }
    else if( BTServer_BunnyMode(CurMode) != none )
    {
        Level.Game.EndGame( instigator.Controller.PlayerReplicationInfo, "timelimit" );
    }
}

/** Called when the game has been ended. */
function NotifyGameEnd( Actor other, Pawn eventInstigator )
{
    //if( eventInstigator == none )
    //{
    //  Round ended due time or the player was an idiot!
    //}
    FullLog("BT::NotifyGameEnd" @ other @ eventInstigator );
    if( IsCompetitive() && !AssaultGame.IsPracticeRound() )
    {
        FullLog( "* Round ended! *" );
        RewardWinningTeam();

        //AssaultGame.PlayEndOfMatchMessage();

        AssaultGame.bMustJoinBeforeStart = false;
        Level.Game.Broadcast( self, "Players are now allowed to join!" );
    }
}

/**
 * Triggered by the Solo Objective or EndRound in ASGameInfo.
 * So beware this doesn't exactly mean the game really has ended!
 */
function Trigger( Actor Other, Pawn EventInstigator )
{
    if( EventInstigator == None || PlayerController(EventInstigator.Controller) == None )
    {
        FullLog( "* Round ended with no Instigator! *" );
        return;
    }

    if( IsTrials() )
    {
        // Extra protection against 'Client Spawn' players using/touching a objective
        if( !bClientSpawnPlayersCanCompleteMap && IsClientSpawnPlayer( EventInstigator ) )
        {
            EventInstigator.Destroy();

            if( AssaultGame != none )
            {
                AssaultGame.LastDisabledObjective.Reset();
                AssaultGame.LastDisabledObjective.DefenderTeamIndex = 1;
                AssaultGame.LastDisabledObjective = None;
            }
            return;
        }

        if( EventInstigator.Controller == None || EventInstigator.Controller.PlayerReplicationInfo == None )
        {
            FullLog( "RoundEnd::PC or PC.PlayerReplicationInfo is none!" );
            return;
        }

        if( bSoloMap )
        {
            ProcessSoloEnd( PlayerController(EventInstigator.Controller) );
        }
        else    // Team map
        {
            ProcessRegularEnd( PlayerController(EventInstigator.Controller) );
        }
    }
}

final function string ColourName( int playerSlot, Color nameColor )
{
    return nameColor $ %PDat.Player[playerSlot - 1].PLName @ Class'HUD'.Default.WhiteColor;
}

final function BroadcastFinishMessage( Controller instigator, string message, optional byte failure )
{
    local Controller C;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( C.PlayerReplicationInfo == None )
        {
            continue;
        }
        ClientSendRecordMessage( C, message, failure, instigator.PlayerReplicationInfo );
    }
}

final function ClientSendRecordMessage( Controller receiver, string message, int switch, PlayerReplicationInfo otherPRI )
{
    local BTClient_ClientReplication LRI;

    LRI = GetRep( receiver );
    if( LRI == none )
    {
        return;
    }
    LRI.ClientSendMessage( class'BTClient_SoloFinish', message, switch, otherPRI );
}

final function ProcessGroupFinishAchievement( int playerSlot )
{
    PDat.ProgressAchievementByID( playerSlot, 'mode_1' );

    if( bBlockSake )
    {
        ++ GroupFinishAchievementUnlockedNum;

        if( GroupFinishAchievementUnlockedNum == 10 )
        {
            Level.Game.Broadcast( self, "GTR-GeometryBasics just got unlocked! Thanks for playing and have a good time! Please vote another map first!" );
        }
    }
}

final function bool HasRegularRecordOn( int recordSlot, int playerSlot )
{
    local int i;

    if( !class'BTServer_RegularMode'.static.IsRegular( RDat.Rec[recordSlot].TMN ) )
        return false;

    for( i = 0; i < RDat.Rec[recordSlot].PSRL.Length; ++ i )
    {
        if( RDat.Rec[recordSlot].PSRL[i].PLs-1 == playerSlot )
        {
            return true;
        }
    }
    return false;
}

final function bool HasSoloRecordOn( int recordSlot, int playerSlot )
{
    local int i;

    // Ignore all group records
    if( class'BTServer_GroupMode'.static.IsGroup( RDat.Rec[recordSlot].TMN ) )
        return false;

    for( i = 0; i < RDat.Rec[recordSlot].PSRL.Length; ++ i )
    {
        if( RDat.Rec[recordSlot].PSRL[i].PLs-1 == playerSlot )
        {
            return true;
        }
    }
    return false;
}

final function bool HasGroupRecordOn( int recordSlot, int playerSlot )
{
    local int i;

    // Ignore non group records
    if( !class'BTServer_GroupMode'.static.IsGroup( RDat.Rec[recordSlot].TMN ) )
        return false;

    for( i = 0; i < RDat.Rec[recordSlot].PSRL.Length; ++ i )
    {
        if( RDat.Rec[recordSlot].PSRL[i].PLs-1 == playerSlot )
        {
            return true;
        }
    }
    return false;
}

final function int CountRecordsNum( byte trialMode, int playerSlot )
{
    local int i, recNum;

    switch( trialMode )
    {
            // Regular
        case 0:
            for( i = 0; i < RDat.Rec.Length; ++ i )
            {
                if( HasRegularRecordOn( i, playerSlot ) )
                {
                    ++ recNum;
                }
            }
            break;

            // Solo
        case 1:
            for( i = 0; i < RDat.Rec.Length; ++ i )
            {
                if( HasSoloRecordOn( i, playerSlot ) )
                {
                    ++ recNum;
                }
            }
            break;

            // Group
        case 2:
            for( i = 0; i < RDat.Rec.Length; ++ i )
            {
                if( HasGroupRecordOn( i, playerSlot ) )
                {
                    ++ recNum;
                }
            }
            break;
    }
    return recNum;
}

final function TeamFinishedMap( PlayerController finisher )
{
    finisher.PlayerReplicationInfo.Team.Score += 1.0f;
    AssaultGame.AnnounceScore( finisher.PlayerReplicationInfo.Team.TeamIndex );

    if( MRI.TeamTime[finisher.PlayerReplicationInfo.Team.TeamIndex] == 0.0f || MRI.TeamTime[finisher.PlayerReplicationInfo.Team.TeamIndex] > GetFixedTime( CurrentPlaySeconds ) )
    {
        MRI.TeamTime[finisher.PlayerReplicationInfo.Team.TeamIndex] = GetFixedTime( CurrentPlaySeconds );
    }
}

// BunnyMode
final function BunnyScored( BTClient_ClientReplication CRI, PlayerController PC, CTFFlag flag )
{
    UnrealMPGameInfo(Level.Game).ScoreGameObject( PC, flag );
    TriggerEvent( flag.HomeBase.Event, flag.HomeBase, PC.Pawn );

    if( CRI.ProhibitedCappingPawn == PC.Pawn )
    {
        if( PC.Pawn != none )
        {
            PC.Pawn.Suicide();
        }

        PC.ClientMessage( "You cannot set records. Please turn off !Boost, then suicide!" );
        return;
    }
    ProcessSoloEnd( PC );
}

// Solo/Group/Bunny mode
final private function ProcessSoloEnd( PlayerController PC )
{
    local int i, groupindex, xp;
    local array<Controller> GroupMembers;
    local BTClient_ClientReplication CR;
    local int numFullHealths;
    local byte hasNewRecord;

    CR = GetRep( PC );
    if( CR == None )
    {
        FullLog( "No ClientReplicationInfo found for player" @ PC.GetHumanReadableName() );
        return;
    }

    if( bGroupMap )
    {
        CurrentPlaySeconds = GetFixedTime( Level.TimeSeconds - CR.LastSpawnTime );
        groupindex = GroupManager.GetGroupIndexByPlayer( PC );
        if( groupindex != -1 )
        {
            GroupManager.GetMembersByGroupIndex( groupindex, GroupMembers );
            for( i = 0; i < GroupMembers.Length; ++ i )
            {
                if( GroupMembers[i].Pawn != none && GroupMembers[i].Pawn.Health >= GroupMembers[i].Pawn.HealthMax )
                {
                    ++ numFullHealths;
                }
            }

            xp = GetGroupTaskPoints( groupindex );
            // Set rec first for the instigator,
            // then for members because members cannot not beat the first record therefor the instigator should be checked for first record first.
            CheckPlayerRecord( PC, CR, false, xp, hasNewRecord );

            // DO NOT ADD THIS ABOVE CheckPlayerRecord
            if( Level.Title ~= "EgyptianRush-Prelude" && numFullHealths == GroupMembers.Length )
            {
                for( i = 0; i < GroupMembers.Length; ++ i )
                {
                    CR = GetRep( PlayerController(GroupMembers[i]) );
                    if( CR != none )
                    {
                        PDat.ProgressAchievementByID( CR.myPlayerSlot, 'prelude_1' );
                    }
                }
            }

            for( i = 0; i < GroupMembers.Length; ++ i )
            {
                if( GroupMembers[i] != PC )
                {
                    CR = GetRep( PlayerController(GroupMembers[i]) );
                    if( CR == None )
                    {
                        FullLog( "No ClientReplicationInfo found for player" @ PlayerController(GroupMembers[i]).GetHumanReadableName() );
                        continue;
                    }

                    CheckPlayerRecord( PlayerController(GroupMembers[i]), CR, true, xp );
                }
            }

            if( hasNewRecord == 1 )
            {
                if( GhostManager != none  )
                {
                    // Clear
                    NewGhostsQue.Length = GroupMembers.Length;
                    for( i = 0; i < GroupMembers.Length; ++ i )
                    {
                        NewGhostsQue[i] = FastFindPlayerSlot( PlayerController(GroupMembers[i]) )-1;
                    }
                    UpdateGhosts();
                }
                NotifyNewRecord( FastFindPlayerSlot( PC )-1 );
            }
        }
    }
    else
    {
        CurrentPlaySeconds = GetFixedTime( Level.TimeSeconds - CR.LastSpawnTime );
        CheckPlayerRecord( PC, CR,,, hasNewRecord );
        if( hasNewRecord == 1 )
        {
            if( GhostManager != none )
            {
                NewGhostsQue.Length = 1;
                NewGhostsQue[0] = CR.myPlayerSlot;
                UpdateGhosts();
            }
            NotifyNewRecord( CR.myPlayerSlot );
        }
    }

    if( hasNewRecord == 1 )
    {
        UpdateRecordHoldersMessage();
    }
}

final private function bool CheckPlayerRecord( PlayerController PC, BTClient_ClientReplication CR,
    optional bool bRecursive,
    optional int xp,
    optional out byte bNewTopRecord )
{
    local BTServer_RecordsData.sSoloRecord Tmp;
    local bool b;
    local BTClient_ClientReplication.sSoloPacket TS;
    local string EndMsg;
    local int i, j, PLs, PLi, y, z;
    local float TimeBoost;
    local Pawn P;
    local int numObjectives;

    FullLog( "Processing record for player" @ PC.GetHumanReadableName() @ CurrentPlaySeconds @ "bRecursive:" @ bRecursive );

    // macro to playerslot.
    PLs = CR.myPlayerSlot + 1;
    UpdatePlayerSlot( PC, PLs - 1, True );      // Update names etc
    ++ PDat.Player[PLs - 1].PLSF;               // Amount of times this user finished a solo map.
    ++ RDat.Rec[UsedSlot].TMFinish;

    if( bSoloMap && !bKeyMap && !bGroupMap )
    {
        numObjectives = 1;
    }
    else
    {
        numObjectives = GetPlayerObjectives( PC );
    }
    CurMode.PlayerCompletedMap( PC, PLs-1, CurrentPlaySeconds );
    j = RDat.Rec[UsedSlot].PSRL.Length;
    if( j > 0 )
    {
        for( i = 0; i < j; ++ i )
        {
            if( RDat.Rec[UsedSlot].PSRL[i].PLs == PLs )
            {
                PLi = i;
                //FullLog( "Player Found"@PLs );
                b = true;
                break;
            }
        }
    }

    // Player was found!
    if( b )
    {
        //FullLog( "First b Check" );
        if( GetFixedTime( RDat.Rec[UsedSlot].PSRL[i].SRT ) > CurrentPlaySeconds )
        {
            //==============================================================
            // Update solo record slot

            //FullLog( "Faster personal record!" );
            SetSoloRecordTime( PC, i, CurrentPlaySeconds );
            RDat.Rec[UsedSlot].PSRL[i].SRD[0] = Level.Day;
            RDat.Rec[UsedSlot].PSRL[i].SRD[1] = Level.Month;
            RDat.Rec[UsedSlot].PSRL[i].SRD[2] = Level.Year;
            RDat.Rec[UsedSlot].PSRL[i].ExtraPoints = xp;
            RDat.Rec[UsedSlot].PSRL[i].ObjectivesCount = numObjectives;
            CR.ClientSetPersonalTime( CurrentPlaySeconds );
            // Broadcast success, on next if( b ).

            PDat.AddExperience( PLs-1, EXP_ImprovedRecord + numObjectives );
        }
        else
        {
            //==============================================================
            // Failed rec'ing, broadcast the failure!

            //FullLog( "Not faster personal record!" );
            b = False;
            // Broadcast failure!
            ++ RDat.Rec[UsedSlot].TMFailures;
            // Tied his own position
            if( GetFixedTime( RDat.Rec[UsedSlot].PSRL[i].SRT ) == CurrentPlaySeconds )
            {
                AddHistory( ColourName( PLs, Class'HUD'.Default.GoldColor )
                    $ "Tied his/her record on" @ CurrentMapName );
                BroadcastFinishMessage( PC, "%PLAYER% tied the personal record, time " $ TimeToStr( CurrentPlaySeconds ), 2 );

                PDat.AddExperience( PLs-1, EXP_TiedRecord + numObjectives );
                PDat.ProgressAchievementByType( PLs-1, 'Tied', 1 );
            }
            // Tied the best record
            else if( GetFixedTime( RDat.Rec[UsedSlot].PSRL[0].SRT ) == CurrentPlaySeconds )
            {
                AddHistory( ColourName( PLs, Class'HUD'.Default.GoldColor ) $ "Tied the best record on" @ CurrentMapName );
                BroadcastFinishMessage( PC, "%PLAYER% tied the best record, time " $ TimeToStr( CurrentPlaySeconds ), 2 );

                PDat.AddExperience( PLs-1, EXP_TiedRecord + numObjectives );
                PDat.ProgressAchievementByType( PLs-1, 'Tied', 1 );
            }
            // Failed record
            else
            {
                BroadcastFinishMessage( PC, "%PLAYER% failed to improve his/her record, time " $ TimeToStr( CurrentPlaySeconds ), 0 );
                if( CR.BTWage > 0 )
                {
                    BTServer_SoloMode(CurMode).WageFailed( CR, CR.BTWage );
                }
                //PDat.AddExperience( PLs-1, EXP_FailRecord + xp );
            }
        }
    }
    else
    {
        //==================================================================
        // Add a solo record slot

        //FullLog( "First b check failed" );
        RDat.Rec[UsedSlot].PSRL.Length = j + 1;
        RDat.Rec[UsedSlot].PSRL[j].PLs = PLs;
        SetSoloRecordTime( PC, j, CurrentPlaySeconds );
        RDat.Rec[UsedSlot].PSRL[j].SRD[0] = Level.Day;
        RDat.Rec[UsedSlot].PSRL[j].SRD[1] = Level.Month;
        RDat.Rec[UsedSlot].PSRL[j].SRD[2] = Level.Year;
        RDat.Rec[UsedSlot].PSRL[j].ExtraPoints = xp;
        RDat.Rec[UsedSlot].PSRL[j].ObjectivesCount = numObjectives;
        CR.ClientSetPersonalTime( CurrentPlaySeconds );
        b = True;

        PDat.AddExperience( PLs-1, EXP_FirstRecord + numObjectives );
    }

    if( b )
    {
        b = False;
        //FullLog( "Second b Check" );
        // Update the best (MaxRankedPlayers) PSRL list

        j = RDat.Rec[UsedSlot].PSRL.Length;
        for( i = 0; i < (j - 1); ++ i )
        {
            z = i;
            for( y = (i + 1); y < j; ++ y )
                if( RDat.Rec[UsedSlot].PSRL[y].SRT < RDat.Rec[UsedSlot].PSRL[z].SRT )
                    z = y;

            Tmp = RDat.Rec[UsedSlot].PSRL[z];
            RDat.Rec[UsedSlot].PSRL[z] = RDat.Rec[UsedSlot].PSRL[i];
            RDat.Rec[UsedSlot].PSRL[i] = Tmp;
        }

        //FullLog( "Sorted" );

        // sorted, find player slot again and get the new position and broadcast
        //j = Min( RDat.Rec[UsedSlot].PSRL.Length, MaxRankedPlayers );
        for( i = 0; i < j; ++ i )
        {
            if( RDat.Rec[UsedSlot].PSRL[i].PLs == PLs )
            {
                // Earn 20 points from one record.
                if( CalcRecordPoints( UsedSlot, i ) >= 20 )
                {
                    PDat.ProgressAchievementByID( PLs-1, 'points_0' );
                }

                //FullLog( "Found Player in top 25 after sort" );

                AddRecentSetRecordToPlayer( RDat.Rec[UsedSlot].PSRL[i].PLs, CurrentMapName @ "Time:" $ TimeToStr( CurrentPlaySeconds ) );

                // Update all Clients...
                if( i < MaxRankedPlayers )  // only update new times under top 25
                {
                    // Don't spam force update for every group member :P
                    if( !bRecursive )
                    {
                        ClientForcePacketUpdate();
                    }
                }
                else
                {
                    // Update Personal Record Packet
                    TS.Name = Class'HUD'.Default.WhiteColor $ PDat.Player[RDat.Rec[UsedSlot].PSRL[i].PLs-1].PLNAME;
                    TS.Points = CalcRecordPoints( UsedSlot, i );
                    TS.Time = RDat.Rec[UsedSlot].PSRL[i].SRT;
                    TS.Date = FixDate( RDat.Rec[UsedSlot].PSRL[i].SRD );
                    CR.ClientSendPersonalOverallTop( TS );
                    CR.SoloRank = i + 1;
                }

                if( i == 0 && !bRecursive ) // This is the best one of all...
                {
                    bNewTopRecord = 1;
                    if( !bDontEndGameOnRecord && bSoloMap )
                    {
                        // End-Round if a new record!
                        if( PC.PlayerReplicationInfo.Team.TeamIndex == 0 )
                        {
                            GameEnd( ERER_AttackersWin, PC.Pawn, "Attackers Win!" );
                            RecordByTeam = RT_Red;
                        }
                        else
                        {
                            GameEnd( ERER_AttackersLose, PC.Pawn, "Defenders Win!" );
                            RecordByTeam = RT_Blue;
                        }
                    }

                    FullLog( "*** New Best Solo Speed-Record ***" );

                    if( BestPlaySeconds != -1 ) // Faster!
                    {
                        TimeBoost = (BestPlaySeconds - CurrentPlaySeconds);
                        EndMsg = "The record has been beaten, with an improvement of "$TimeToStr( TimeBoost )$ ", new time "$TimeToStr( CurrentPlaySeconds );
                        if( TimeBoost <= 0.10f )
                            BroadcastAnnouncement( AnnouncementRecordImprovedVeryClose );
                        else if( TimeBoost <= 1.0f )
                            BroadcastAnnouncement( AnnouncementRecordImprovedClose );
                        else BroadcastAnnouncement( AnnouncementRecordHijacked );

                        // Add lost record.
                        // Check avoids to print a message if the record owner beated his own record!
                        if( j > 1 && PLs != RDat.Rec[UsedSlot].PSRL[1].PLs && PLi != i )
                        {
                            // Robin Hood
                            PDat.ProgressAchievementByType( PLs-1, 'StealRecord', 1 );

                            j = PDat.Player[RDat.Rec[UsedSlot].PSRL[1].PLs-1].RecentLostRecords.Length;
                            PDat.Player[RDat.Rec[UsedSlot].PSRL[1].PLs-1].RecentLostRecords.Length = j + 1;
                            PDat.Player[RDat.Rec[UsedSlot].PSRL[1].PLs-1].RecentLostRecords[j] = "Map:"$CurrentMapName@"BOOST:"$TimeToStr( TimeBoost );
                        }

                        if( RDat.Rec[UsedSlot].TMFailures >= 50 )
                        {
                            // Failure immunity
                            PDat.ProgressAchievementByID( PLs-1, 'records_2' );
                        }
                    }
                    else    // 1st time record
                    {
                        EndMsg = "A record has been set, time " $ TimeToStr( CurrentPlaySeconds );
                        BroadcastAnnouncement( AnnouncementRecordSet );
                    }

                    //SetXfireStatusFor( PC, %EndMsg @ "on" @ CurrentMapName );
                    BroadcastConsoleMessage( EndMsg );

                    // Update map stats.
                    RDat.Rec[UsedSlot].TMFailures = 0;                          // Reset this :)
                    ++ RDat.Rec[UsedSlot].TMHijacks;                            // Amount of times this record has been hijacked.

                    if( GroupManager != none )
                        RDat.Rec[UsedSlot].TMContributors = GroupManager.MaxGroupSize;
                    else if( bSoloMap )
                    {
                        RDat.Rec[UsedSlot].TMContributors = 1;
                    }

                    // Update player stats.
                    ++ PDat.Player[PLs-1].PLHijacks;

                    //======================================================
                    // Update clients. .
                    BestPlaySeconds = CurrentPlaySeconds;
                    MRI.MapBestTime = BestPlaySeconds;
                    MRI.PointsReward = "Earned points this record: " $ CalcRecordPoints( UsedSlot, 0 );

                    if( CR.BTWage > 0 )
                    {
                        BTServer_SoloMode(CurMode).WageSuccess( CR, CR.BTWage );
                    }

                    if( !bDontEndGameOnRecord )
                    {
                        MRI.RecordState = RS_Succeed;
                        UpdateEndMsg( EndMsg );
                        return true;
                    }
                    else
                    {
                        BroadcastFinishMessage( PC, EndMsg, 1 );
                    }
                    //======================================================
                }
                else
                {
                    b = True;
                    BroadcastFinishMessage( PC, "Record " $ (i+1) $ "/" $ RDat.Rec[UsedSlot].PSRL.Length
                        $ " has been set, time " $ TimeToStr( CurrentPlaySeconds )
                        $ ", by %PLAYER%", 1
                    );

                    if( CR.BTWage > 0 )
                    {
                        if( i+1 < RDat.Rec[UsedSlot].PSRL.Length )
                        {
                            BTServer_SoloMode(CurMode).WageSuccess( CR, CR.BTWage );
                        }
                        else
                        {
                            BTServer_SoloMode(CurMode).WageFailed( CR, CR.BTWage );
                        }
                    }
                }
                break;
            }
        }
    }

    if( bSoloMap )
    {
        if( CheckPointHandler != none )
        {
            CheckPointHandler.RemoveSavedCheckPoint( PC );
        }

        // Kill player?
        P = PC.Pawn;
        if( P != None )
        {
            P.SetCollision( False, False, False );
            P.bCanUse = False;
            P.Tag = 'IGNOREQUICKRESPAWN';
            P.Died( None, Class'Suicided', P.Location );
        }

        if( !bRecursive )
        {
            if( AssaultGame != none )
            {
                AssaultGame.LastDisabledObjective.Reset();
                AssaultGame.LastDisabledObjective.DefenderTeamIndex = 1;
                AssaultGame.LastDisabledObjective = None;
            }
        }
    }
    return false;
}

// Process end game for regular trials, PC = instigator.
final private function ProcessRegularEnd( PlayerController PC )
{
    local int i;
    local array<BTStructs.sPlayerReference> contributors;
    local name achievementID;
    local BTClient_ClientReplication CR;
    local byte hasNewRecord;

    CurrentPlaySeconds = GetFixedTime( Level.TimeSeconds - MRI.MatchStartTime );
    if( ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundWinner != ERW_None ) // The game ended!.
    {
        // Calculate and return the best players.
        contributors = GetBestPlayers();
        if( AchievementsManager.TestMap( Level.Title, CurrentPlaySeconds, achievementID ) )
        {
            for( i = 0; i < contributors.Length; ++ i )
            {
                PDat.ProgressAchievementByID( contributors[i].PlayerSlot-1, achievementID );
            }
        }

        // FullLog( "Processing instigator's record:" @ PC.GetHumanReadableName() );
        CR = GetRep( PC );
        CheckPlayerRecord( PC, CR,,, hasNewRecord );

        // FullLog( "Contributors:" @ contributors.Length );
        for( i = 0; i < contributors.Length; ++ i )
        {
            if( contributors[i].player != PC )
            {
                CR = GetRep( contributors[i].player );
                CheckPlayerRecord( contributors[i].player, CR, true );
            }
        }

        if( hasNewRecord == 1 )
        {
            RDat.Rec[UsedSlot].TMContributors = contributors.Length;
            UpdateRecordHoldersMessage();

            if( GhostManager != none )
            {
                NewGhostsQue.Length = contributors.Length;
                for( i = 0; i < contributors.Length; ++ i )
                {
                    NewGhostsQue[i] = contributors[i].playerSlot-1;
                }
                UpdateGhosts();
            }
        }
        else
        {
            MRI.RecordState = RS_Failure;
            UpdateEndMsg( "Failed to beat the record, over by " $ TimeToStr( CurrentPlaySeconds - BestPlaySeconds ) $ ", time " $ TimeToStr( CurrentPlaySeconds ) );
            if( CurrentPlaySeconds < (BestPlaySeconds+90) )
                BroadcastAnnouncement( AnnouncementRecordAlmost );
            else BroadcastAnnouncement( AnnouncementRecordFailed );
        }
    }
}

final function NotifyNewRecord( int playerSlot )
{
    local int i;

    if( !bRecentRecordsUpdated )
    {
        for( i = 1; i < MaxRecentRecords; ++ i )
            LastRecords[i - 1] = LastRecords[i];

        bRecentRecordsUpdated = True;
    }

    LastRecords[MaxRecentRecords - 1] = CurrentMapName @ "Time:" $ TimeToStr( CurrentPlaySeconds ) @ "by" @ Class'HUD'.Default.GoldColor $ %MRI.PlayersBestTimes;

    SaveAll();

    if( bGenerateBTWebsite )
    {
        bUpdateWebOnNextMap = True;
    }

    SaveConfig();
}

//==============================================================================
// Check if the new record is valid
protected final function bool ValidRecord()                                                     // .:..:, Eliot
{
    // return false if map ended not legal.
    if
    (
        ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundWinner == ERW_PracticeRoundEnded
    )
    {
        FullLog( "Invalid Record - Reason:"$ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundWinner );
        return False;
    }
    return True;
}

//==============================================================================
// Team-Trial Method
// Get the best players of the current game
final function array<BTStructs.sPlayerReference> GetBestPlayers()                      // .:..:, Eliot
{
    local Controller C;
    local array<PlayerController> Players;
    local int i, NumPCs, Max, J;
    local PlayerController Tmp;
    local array<BTStructs.sPlayerReference> S;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if
        (
            C.IsA('PlayerController')
            &&
            C.PlayerReplicationInfo != None
            &&
            !C.PlayerReplicationInfo.bIsSpectator
            &&
            !C.PlayerReplicationInfo.bOnlySpectator
            &&
            (
            ASPlayerReplicationInfo(C.PlayerReplicationInfo).DisabledObjectivesCount > 0
            ||
            ASPlayerReplicationInfo(C.PlayerReplicationInfo).DisabledFinalObjective > 0
            )
        )
        {
            Players.Length = NumPCs+1;
            Players[NumPCs] = PlayerController(C);
            ++ NumPCs;
        }
    }
    if( NumPCs == 0 )
    {
        return S;
    }

    if( NumPCs == 1 )
    {
        S.Length = 1;
        S[0].player = Players[0];
        S[0].playerSlot = FastFindPlayerSlot( Players[0] );
        return S;
    }
    for( i = 0; i < NumPCs-1; ++ i )
    {
        Max = i;
        for( J = I+1; J < NumPCs; ++ J )
        {
            if( GetPlayerScore(Players[J]) > GetPlayerScore(Players[Max]) )
            {
                Max = J;
            }
        }
        Tmp = Players[Max];
        Players[Max] = Players[i];
        Players[i] = Tmp;
    }

    for( i = 0; i < NumPCs; ++ i )
    {
        S.Length = i+1;
        S[i].player = Players[i];
        S[i].playerSlot = FastFindPlayerSlot( Players[i] );
    }
    return S;
}

//==============================================================================
// Objective score = 50 points, Final objective score = 20 points, DestroyedVehciles score = 30 points, W/e goals such as on britishbulldog = 10 points.
Static Final Function int GetPlayerScore( PlayerController C )                              // .:..:
{
    local ASPlayerReplicationInfo Teh;

    Teh = ASPlayerReplicationInfo(C.PlayerReplicationInfo);
    return (Teh.DisabledObjectivesCount*50) + (Teh.DisabledFinalObjective*20);
}

Static Final Function int GetPlayerObjectives( PlayerController PC )
{
    local ASPlayerReplicationInfo ASPRI;

    ASPRI = ASPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if( ASPRI != None )
        return ASPRI.DisabledObjectivesCount+ASPRI.DisabledFinalObjective;

    return 0;
}

//==============================================================================
// CheckReplacement
Function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
    local BTServer_NotifyLogin NL;
    local BTClient_ClientReplication CR;
    local BTServer_NameUpdateDelay NUD;
    local int i;

    if( UTServerAdminSpectator(Other) != none )
    {
        WebAdminActor = UTServerAdminSpectator(Other);
        if( WebAdminActor.PlayerReplicationInfo != None )
        {
            WebAdminActor.PlayerReplicationInfo.bBot = True;
            WebAdminActor.PlayerReplicationInfo.bAdmin = true;
        }
        return True;
    }
    else if( PlayerController(Other) != none )
    {
        // Skip bots etc
        if( MessagingSpectator(Other) != None )
            return True;

        NL = Spawn( Class'BTServer_NotifyLogin', Self );
        if( NL != None )
        {
            NL.Client = PlayerController(Other);
            NL.SetTimer( NL.NotifyDelay, False );
        }
    }
    else if( PlayerReplicationInfo(Other) != none )
    {
        if( Other.Owner != None && MessagingSpectator(Other.Owner) == None )
        {
            CR = Spawn( Class'BTClient_ClientReplication', Other.Owner );
            CR.NextReplicationInfo = PlayerReplicationInfo(Other).CustomReplicationInfo;
            PlayerReplicationInfo(Other).CustomReplicationInfo = CR;
        }
    }
    else if( Other.IsA('UTComp_PRI') )
    {
        if( Other.Owner != None && MessagingSpectator(Other.Owner) == None )
        {
            NUD = Spawn( Class'BTServer_NameUpdateDelay', Self );
            NUD.Client = PlayerController(Other.Owner);
            NUD.SetTimer( 5.0, False );
        }
    }
    else if( WebServer(Other) != none )
    {
        if( WebServer(Other).bEnabled )
        {
            for( i = 0; i < 10; ++ i )
            {
                if( WebServer(Other).Applications[i] == "" )
                {
                    WebServer(Other).Applications[i] = string(class'BTAdmin');
                    WebServer(Other).ApplicationPaths[i] = "/BTAdmin";
                    /*WebServer(Other).ApplicationObjects[i] = new( self ) class'BTAdmin';
                    WebServer(Other).ApplicationObjects[i].Level = Level;
                    WebServer(Other).ApplicationObjects[i].WebServer = WebServer(Other);
                    WebServer(Other).ApplicationObjects[i].Path = "/BTAdmin";
                    WebServer(Other).ApplicationObjects[i].Init();*/
                    break;
                }
            }
        }
    }
    else if( CTFFlag(Other) != none )
    {
        ResembleFlag( CTFFlag(Other ) );
    }
    return true;
}

// BunyMode
final function ResembleFlag( CTFFlag flag )
{
    local BTFlagResemblance resemblance;

    FullLog( "Resembling flag:" @ flag );
    if( BTBunny_FlagRed(flag) != none || BTBunny_FlagBlue(flag) != none )
        return;

    // The original flag shall not be touchable.
    flag.SetCollision( false, false, false );
    resemblance = Spawn( class'BTFlagResemblance', self,, flag.Location, flag.Rotation );
    resemblance.ResemblantFlag = flag;
    resemblance.SetCollisionSize( flag.CollisionRadius, flag.CollisionHeight );
}

//==============================================================================
// NotifyLogout
Function NotifyLogout( Controller Exiting )                                         // .:..:, Eliot
{
    local float timeSpent;
    local int i;
    local LinkedReplicationInfo LRI;
    local BTClient_ClientReplication CR;

    super.NotifyLogout( exiting );

    if( PlayerController(Exiting) != none && Exiting.PlayerReplicationInfo != none )
    {
        CR = GetRep( Exiting );
        if( PDat != none && CR != none && CR.myPlayerSlot != -1 )
        {
            timeSpent = ((Level.TimeSeconds - PDat.Player[CR.myPlayerSlot]._LastLoginTime) / 60) / 60;
            PDat.Player[CR.myPlayerSlot].PlayHours += timeSpent;

            if( PDat.HasItem( CR.myPlayerSlot, "exp_bonus_1", i ) )
            {
                PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
                if( float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) >= 4.00f )
                {
                    PDat.RemoveItem( CR.myPlayerSlot, "exp_bonus_1" );
                }
            }

            if( PDat.HasItem( CR.myPlayerSlot, "exp_bonus_2", i ) )
            {
                PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
                if( float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) >= 24.00f )
                {
                    PDat.RemoveItem( CR.myPlayerSlot, "exp_bonus_2" );
                }
            }

            if( PDat.HasItem( CR.myPlayerSlot, "cur_bonus_1", i ) )
            {
                PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
                if( float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) >= 24.00f )
                {
                    PDat.RemoveItem( CR.myPlayerSlot, "cur_bonus_1" );
                }
            }

            if( PDat.HasItem( CR.myPlayerSlot, "drop_bonus_1", i ) )
            {
                PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
                if( float(PDat.Player[CR.myPlayerSlot].Inventory.BoughtItems[i].RawData) >= 24.00f )
                {
                    PDat.RemoveItem( CR.myPlayerSlot, "drop_bonus_1" );
                }
            }
        }

        if( !Level.bLevelChange )
        {
            for( i = 0; i < KeepScoreTable.Length; ++ i )
            {
                if( KeepScoreTable[i].ClientFlesh == Exiting )
                {
                    KeepScoreTable[i].Score = Exiting.PlayerReplicationInfo.Score;
                    if( AssaultGame != none )
                    {
                        if( !bKeyMap && !bGroupMap )
                        {
                            KeepScoreTable[i].Objectives = ASPlayerReplicationInfo(Exiting.PlayerReplicationInfo).DisabledObjectivesCount;
                            KeepScoreTable[i].FinalObjectives = ASPlayerReplicationInfo(Exiting.PlayerReplicationInfo).DisabledFinalObjective;
                        }

                        if( ASGameReplicationInfo(AssaultGame.GameReplicationInfo) != None )
                            KeepScoreTable[i].LeftOnRound = ASGameReplicationInfo(AssaultGame.GameReplicationInfo).CurrentRound;
                    }
                    break;
                }
            }

            // Using foreach because a linked loop would break the linked loop and so fail destroying all the LRI actors
            foreach DynamicActors( Class'LinkedReplicationInfo', LRI )
            {
                if( LRI.Owner == Exiting || LRI.Owner == Exiting.PlayerReplicationInfo )
                    LRI.Destroy();
            }

            if( Level.NetMode == NM_Standalone )
            {
                SaveAll();
            }
        }
    }
}

//==============================================================================
// ModifyLogin
Function ModifyLogin(out string Portal, out string Options)                     // .:..:
{
    Super.ModifyLogin(Portal,Options);
    Level.Game.bWelcomePending = true;
}

//==============================================================================
// RetriveScore
final function RetrieveScore( PlayerController Other, string ClientID, int Slot )       // .:..:, Eliot
{
    local int i, j;

    j = KeepScoreTable.Length;
    for( i = 0; i < j; ++ i )
    {
        if( KeepScoreTable[i].ClientID == ClientID )
        {
            //FullLog("Loaded"@Other.PlayerReplicationInfo.PlayerName$"'s score from slot "@i);
            if( AssaultGame == none
                || (ASGameReplicationInfo(AssaultGame.GameReplicationInfo) != None
                    && ASGameReplicationInfo(AssaultGame.GameReplicationInfo).CurrentRound == KeepScoreTable[i].LeftOnRound) )
            {
                Other.PlayerReplicationInfo.Score = KeepScoreTable[i].Score;
                if( AssaultGame != none )
                {
                    if( !bKeyMap && !bGroupMap )
                    {
                        ASPlayerReplicationInfo(Other.PlayerReplicationInfo).DisabledObjectivesCount = KeepScoreTable[i].Objectives;
                        ASPlayerReplicationInfo(Other.PlayerReplicationInfo).DisabledFinalObjective = KeepScoreTable[i].FinalObjectives;
                    }
                }
            }
            KeepScoreTable.Remove( i, 1 );
            return;
        }
    }

    KeepScoreTable.Length = j+1;
    KeepScoreTable[j].ClientID = ClientID;
    KeepScoreTable[j].ClientFlesh = Other;
}

//==============================================================================
// Macro for logging
final function FullLog( coerce string Print )
{
    // Suppress=MutBestTimes
    Log( Print, Name );

    if( bDebugMode )
        Level.Game.Broadcast( Self, Class'HUD'.Default.TurqColor$Name$":"@Print );
    else if( bShowDebugLogToWebAdmin && WebAdminActor != None )
        WebAdminActor.ClientMessage( Class'HUD'.Default.TurqColor$Print );
}

//==============================================================================
// Find player account slot by using a players GUID
//  Note:   to access the real Slot always cut the return value by -1
// 0 and -1 are used as NONE
final function int FindPlayerSlot( string ClientID )
{
    local int i, j;

    j = PDat.Player.Length;
    for( i = 0; i < j; ++ i )
    {
        if( PDat.Player[i].PLID == ClientID )
            return i+1;
    }
    return -1;
}

//==============================================================================
//  Note:   to access the real Slot always cut the return value by -1
// 0 and -1 are used as NONE
final function int FastFindPlayerSlot( PlayerController PC )
{
    local BTClient_ClientReplication CRI;

    CRI = GetRep( PC );
    if( CRI != None && CRI.myPlayerSlot >= 0 )
    {
        return CRI.myPlayerSlot+1;
    }
    return FindPlayerSlot( PC.GetPlayerIDHash() );
}

//==============================================================================
// Create player account by using a players GUID
// Note to access the real Slot always cut the return value by -1
// 0 and -1 are used as NONE
final Function int CreatePlayerSlot( PlayerController PC, string ClientID )
{
    local int j;

    j = PDat.Player.Length;
    PDat.Player.Length = j+1;
    PDat.Player[j].PLID = ClientID;
    if( PC.PlayerReplicationInfo != None )
    {
        PDat.Player[j].PLNAME = PC.PlayerReplicationInfo.PlayerName;
        PDat.Player[j].PLCHAR = PC.PlayerReplicationInfo.CharacterName;
    }
    PDat.Player[j].RegisterDate = RDat.MakeCompactDate( Level );
    return j+1;
}

//==============================================================================
// Update player account Name and character
// bUpdateScoreboard only set this to true after the BTClient_ClientReplication is initialized!
final Function UpdatePlayerSlot( PlayerController PC, int Slot, Optional bool bUpdateScoreboard )
{
    local LinkedReplicationInfo LRI;
    local string S;

    //FullLog( "UpdatePlayerSlot" );
    if( PC == None || PC.PlayerReplicationInfo == None || MessagingSpectator(PC) != None )
        return;

    if( Slot >= PDat.Player.Length || Slot < 0 )
    {
        FullLog( "UpdatePlayerSlot::Slot is not valid!" );
        return;
    }

    PDat.Player[Slot].PLCHAR = PC.PlayerReplicationInfo.CharacterName;

    // Try find the colored name
    for( LRI = PC.PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
    {
        if( LRI.IsA('UTComp_PRI') )
        {
            S = LRI.GetPropertyText( "ColoredName" );
            if( S != "" && InStr( S, Chr( 0x1B ) ) != -1 )
            {
                PDat.Player[Slot].PLNAME = /*Class'HUD'.Default.GoldColor$*/S$Class'HUD'.Default.WhiteColor;
                if( bUpdateScoreboard )
                    UpdateScoreboard( PC );

                return;
            }
        }
    }

    // Prevents the colored name from being overwritten
    if( %PDat.Player[Slot].PLNAME != %PC.PlayerReplicationInfo.PlayerName )
    {
        PDat.Player[Slot].PLNAME = /*Class'HUD'.Default.GoldColor $*/PC.PlayerReplicationInfo.PlayerName$Class'HUD'.Default.WhiteColor;
        if( bUpdateScoreboard )
            UpdateScoreboard( PC );
    }
}

// =============================================================================
// Updates the name of PC for everyones local Rankings/Solo Scoreboard!
// CR required!
final Function UpdateScoreboard( PlayerController PC )
{
    local Controller C;
    local BTClient_ClientReplication myCR, CR;
    local BTClient_ClientReplication.sGlobalPacket NewPacket;
    local BTClient_ClientReplication.sSoloPacket NewTPacket;

    if( !ModeIsTrials() )
    {
        return;
    }

    myCR = GetRep( PC );
    if( myCR == None )
        return;

    if( myCR.myPlayerSlot == -1 )
    {
        myCR.myPlayerSlot = FindPlayerSlot( PC.GetPlayerIDHash() )-1;
        if( myCR.myPlayerSlot == -1 )
        {
            FullLog( "Failed to update the F12 scoreboard for player:" @ PC.GetHumanReadableName() );
            return;
        }
    }

    // Update regardless of which improved rank position.
    if( MRI.RecordState == RS_Active && RDat.Rec[UsedSlot].PSRL.Length > 0 )
    {
        UpdateRecordHoldersMessage();
    }

    // Check if this player is the owner of the current ghost!
    if( GhostManager != none )
    {
        GhostManager.UpdateGhostsName( myCR.myPlayerSlot, PDat.Player[myCR.myPlayerSlot].PLName );
    }

    if( myCR.Rank-1 >= 0 && myCR.Rank <= MaxRankedPlayers )
    {
        NewPacket.Points        = SortedOverallTop[myCR.Rank-1].PLPoints;
        NewPacket.Objectives    = PDat.Player[myCR.myPlayerSlot].PLObjectives;
        NewPacket.Hijacks       = PDat.Player[myCR.myPlayerSlot].PLHijacks << 16 | SortedOverallTop[myCR.Rank-1].PLRecords;
        NewPacket.Name          = PDat.Player[myCR.myPlayerSlot].PLName;
    }

    if( myCR.SoloRank-1 >= 0 && myCR.SoloRank <= MaxRankedPlayers )
    {
        NewTPacket.Points       = CalcRecordPoints( UsedSlot, myCR.SoloRank-1 );
        NewTPacket.Name         = PDat.Player[myCR.myPlayerSlot].PLName;
        NewTPacket.Time         = RDat.Rec[UsedSlot].PSRL[myCR.SoloRank-1].SRT;
        NewTPacket.Date         = FixDate( RDat.Rec[UsedSlot].PSRL[myCR.SoloRank-1].SRD );
    }

    if( NewPacket.Name == "" && NewTPacket.Name == "" )
        return;

    // Update the packet of myCR for every other CR
    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) == None || C.PlayerReplicationInfo == None )
            continue;

        CR = GetRep( PlayerController(C) );
        if( CR != none && CR.bReceivedRankings )
        {
            if( NewPacket.Name != "" )
                CR.ClientUpdateOverallTop( NewPacket, myCR.Rank-1 );

            if( NewTPacket.Name != "" )
                CR.ClientUpdateSoloTop( NewTPacket, myCR.SoloRank-1 );

            break;
        }
    }
}

//==============================================================================
// Broadcast Msg to everyone but the WebAdmin(reduces spam)
final function BroadcastNotWebA( string Msg, optional name Type )                       // .:..:
{
    local Controller C;

    for( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        if( PlayerController(C) != none && C != WebAdminActor )
            PlayerController(C).ClientMessage(Msg,Type);
    }
}

//==============================================================================
// Generate a .html file containing records, players, etc, and attempt to upload to a remote server
// SS Array with the .html Text tags
// TR = Table Row       e.g. new line
// TD = Table Data      e.g. content
// TH = Table Header    e.g. title
//  Note:   This is called before GameReplicationInfo etc is initialized
final function CreateWebBTimes()                                                        // .:..:, Eliot
{
    local array<string> SS;
    local int Pos, i, j;
    local FileLog FF;
    local string S, T;

    if( Level.NetMode == NM_StandAlone )
        return;

    FullLog( "*** Generating ../UserLogs/WebBTimes.html ***" );

    T = chr( 34 );  // ""
    S = %Class'GameReplicationInfo'.default.ServerName;

    // Main stuff...
    SS.Length = 6;
    SS[0] =
    "<html><head><title>"$S@Name@"Stats</title>";

    SS[1] =
    "<link href="$T$"./WebBTimes_Style.CSS"$T$" rel="$T$"stylesheet"$T$" type="$T$"text/css"$T$"/>";

    // End Styles .CSS
    //==========================================================================

    //==========================================================================
    // Link to javascript
    SS[2] =
    "<script type="$T$"text/javascript"$T$" src="$T$"sortTable.js"$T$"></script>"
    $"<script type="$T$"text/javascript"$T$" src="$T$"WebBTimes_Tabs.js"$T$"></script>";
    // End javascript
    //==========================================================================

    // Header Title.
    SS[3] =
    "</head> <body onload=showDiv('d_Maps');>"
    $"<div align="$T$"center"$T$"> <table> <tr> <td class="$T$"servertitle"$T$"> <p>"$S$"<br />"$Left( Level.GetAddressURL(), InStr( Level.GetAddressURL(), ":" ) )
    $"</p> </td> </tr> </table> </div>";
    //FullLog( "Saving"@Len( SS[3] )@"Characters" );
    // End Header
    //==========================================================================

    // Tabs.
    SS[4] =
    "<div id="$T$"d_Tabs"$T$" align="$T$"center"$T$"> <table> <tr>"
    $"<td class="$T$"tab"$T$" id="$T$"a_d_Maps"$T$" onclick=showDiv('d_Maps'); onmouseover="$T$"tabHover('a_d_Maps', true);"$T$" onmouseout="$T$"tabHover('a_d_Maps', false);"$T$">Map Records </td>"
    $"<td class="$T$"tab"$T$" id="$T$"a_d_Players"$T$" onclick=showDiv('d_Players'); onmouseover="$T$"tabHover('a_d_Players', true);"$T$" onmouseout="$T$"tabHover('a_d_Players', false);"$T$">Player Points </td>"
    $"<td class="$T$"tab"$T$" id="$T$"a_d_Server"$T$" onclick=showDiv('d_Server'); onmouseover="$T$"tabHover('a_d_Server', true);"$T$" onmouseout="$T$"tabHover('a_d_Server', false);"$T$">Other </td> </tr> </table> </div>";
    //FullLog( "Saving"@Len( SS[4] )@"Characters" );
    // End Tabs
    //==========================================================================

    //==========================================================================
    // Table Map Records.
    SS[5] =
    "<div id="$T$"d_Maps"$T$" class="$T$"content"$T$" align="$T$"center"$T$"> <table id="$T$"t_Maps"$T$" class="$T$"sortable"$T$"> <tr>"
    $"<th><b>Map</b></th> <th><b>Time</b></th> <th><b>Player One</b></th> <th><b>Player Two</b></th> <th><b>Player Three</b></th> </tr>";
    //FullLog( "Saving"@Len( SS[5] )@"Characters" );

    // Write table content...
    Pos = 6;
    j = RDat.Rec.Length;
    if( j == 0 )
    {
        SS.Length = 7;
        SS[6] = "<tr><td><p><b>No records found!</b></p></td></tr></table>";
        ++ Pos;
    }
    else
    {
        // Print the map records.
        for( i = 0; i < j; ++ i )
        {
            if( RDat.Rec[i].TMN == "" || RDat.Rec[i].bIgnoreStats )
            {
                continue;
            }

            // Write the MapName!
            SS.Length = Pos+1;
            SS[Pos] = "<tr><td><p>"$RDat.Rec[i].TMN$"</p></td>";

            // Write the Record BestTime!
            if( RDat.Rec[i].PSRL.Length > 0 )
            {
                // Solo Record Time
                SS[Pos] $= "<td><p>"$TimeToStr( RDat.Rec[i].PSRL[0].SRT )$"</p></td>";

                // Player Name
                SS[Pos] $= "<td><p>"$%PDat.Player[RDat.Rec[i].PSRL[0].PLs-1].PLNAME$"</p></td>";

                // Check if there are more record owners!
                if( RDat.Rec[i].PSRL.Length > 1 )
                {
                    SS[Pos] $= "<td><p>"$%PDat.Player[RDat.Rec[i].PSRL[1].PLs-1].PLNAME$"</p></td>";
                    if( RDat.Rec[i].PSRL.Length > 2 )
                        SS[Pos] $= "<td><p>"$%PDat.Player[RDat.Rec[i].PSRL[2].PLs-1].PLNAME$"</p></td>";
                    else SS[Pos] $= "<td><p>None</td>";
                }
                // Nobody found
                else SS[Pos] $= "<td><p>None</p></td><td><p>None</p></td>";
            }
            SS[Pos] $= "</tr>";                                                 // End this table row.
            ++ Pos;
        }
        SS.Length = Pos+1;
        SS[Pos] = "</table></div>";
        ++ Pos;
    }
    // End Map Records Table.
    //==========================================================================

    //==========================================================================
    // Table Player Stats.
    SS.Length = Pos;
    SS[Pos] =
    "<div id="$T$"d_Players"$T$" class="$T$"hidden"$T$" align="$T$"center"$T$"> <table id="$T$"t_Players"$T$" class="$T$"sortable"$T$"> <tr>"
    $"<th width="$T$"5%"$T$"><b>Rank</b></th> <th width="$T$"35%"$T$"><b>Player</b></th> <th width="$T$"20%"$T$"><b>Points</b></th> <th width="$T$"17.5%"$T$"><b>Objectives</b></th> <th width="$T$"17.5%"$T$"><b>Records</b></th> <th width="$T$"5%"$T$"><b>ID</b></th>  </tr>";

    // Write table content...
    ++ Pos;
    j = SortedOverallTop.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Len( PDat.Player[SortedOverallTop[i].PLSlot].PLName ) == 0 )
            continue;

        if( SortedOverallTop[i].PLPoints == 0 )
            break;

        SS.Length = Pos+1;
        SS[Pos] = "<tr><td>"$i+1$"</td><td><p>"$%PDat.Player[SortedOverallTop[i].PLSlot].PLName$"</p></td><td><p>"$int( SortedOverallTop[i].PLPoints )$"</p></td><td><p>"$PDat.Player[SortedOverallTop[i].PLSlot].PLObjectives$"</p></td><td><p>"$SortedOverallTop[i].PLRecords$"</p></td><td><p>"$PDat.Player[SortedOverallTop[i].PLSlot].PLID$"</p></td></tr>";
        ++ Pos;
    }
    SS.Length = Pos+1;
    SS[Pos] = "</table></div>";
    // End Player Stats Table.
    //==========================================================================

    //==========================================================================
    // Table BestTimes Info.

    // Write BestTimes Info.

    ++ Pos;
    SS.Length = Pos+1;
    SS[Pos] =
    "<div id="$T$"d_Server"$T$" class="$T$"hidden"$T$" align="$T$"center"$T$"><table id="$T$"t_Server"$T$">"
    $"<tr><th><b>Name</b></th><th><b>Description</b></th></tr>"
    $"<tr><td><p>Version</p></td><td><p>"$BTVersion$"</p></td><tr>"
    $"<tr><td><p>Authors</p></td><td><p>"$BTCredits$"</p></td><tr>"
    $"<tr><td><p>Records</p></td><td><p>"$MRI.RecordsCount$"</p></td><tr>"
    $"<tr><td><p>Players</p></td><td><p>"$PDat.Player.Length$"</p></td><tr>"
    $"<tr><td><p>Points Rewarded for 1P Record</p></td><td><p>P1("$PPoints.PlayerPoints[0].PPlayer[0]$" + "$PointsPerObjective$" point for each Objective)</p></td><tr>"
    $"<tr><td><p>Points Rewarded for 2P Record</p></td><td><p>P1("$PPoints.PlayerPoints[1].PPlayer[0]$" + "$PointsPerObjective$" point for each Objective), P2("$PPoints.PlayerPoints[1].PPlayer[1]$" + "$PointsPerObjective$" point for each Objective)</p></td><tr>"
    $"<tr><td><p>Points Rewarded for 3P Record</p></td><td><p>P1("$PPoints.PlayerPoints[2].PPlayer[0]$" + "$PointsPerObjective$" point for each Objective), P2("$PPoints.PlayerPoints[2].PPlayer[1]$" + "$PointsPerObjective$" point for each Objective), P3("$PPoints.PlayerPoints[2].PPlayer[2]$" + "$PointsPerObjective$" point for each Objective)</p></td><tr>";

    // Write Recent Records
    ++ Pos;
    SS.Length = Pos+1;
    SS[Pos] = "<tr><td><b>Last "$MaxRecentRecords$" Recent Records</b></td><td><b>Map</b></td></tr>";

    // Note: Reverse printed!
    for( i = 0; i < MaxRecentRecords; ++ i )
    {
        ++ Pos;
        SS.Length = Pos+1;
        SS[Pos] = "<tr><td><p>Record("$i+1$")</p></td><td><p>"$%LastRecords[MaxRecentRecords-(i+1)]$"</p></td><tr>";
    }

    if( History.Length > 0 )
    {
        // Write Recent History
        ++ Pos;
        SS.Length = Pos+1;
        SS[Pos] = "<tr><td><b>Last "$MaxHistoryLength$" Recent History</b></td><td><b>History</b></td></tr>";

        // Note: Reverse printed!
        for( i = History.Length-1; i >= 0; -- i )
        {
            ++ Pos;
            SS.Length = Pos+1;
            SS[Pos] = "<tr><td><p>History("$(History.Length-i)$")</p></td><td><p>"$%History[i]$"</p></td><tr>";
        }
    }

    // Write CopyRight
    ++ Pos;
    SS.Length = Pos+1;
    SS[Pos] = "</table></div><table align="$T$"center"$T$"><tr class="$T$"nohover"$T$"><td class="$T$"copyright"$T$"><p>"
    $"Copyright (C) 2011 Eliot Van Uytfanghe. All Rights Reserved.</p></td></tr></table></body></html>";

    // End BestTimes Info Table.
    //==========================================================================

    // </HTML>
    //==========================================================================

    // Create the .html!.
    FF = Spawn( class'FileLog' );
    FF.OpenLog( "WebBTimes", "html", true );
    j = SS.Length;
    for( i = 0; i < j; ++ i )
        FF.Logf( SS[i] );
    FF.CloseLog();
    FF.Destroy();

    FullLog( "*** Generated ../UserLogs/WebBTimes.html ***" );

    // Tell the remote server to download the WebBTimes.html from this server
    if( Notify != none )
    {
        Notify.NotifyUpdate();
    }
}

//==============================================================================
// Convert time value to string
static final function string TimeToStr( float Value )                                       // .:..:, Epic Games
{
    // Rewroten for Milliseconds support by Eliot
    local int Hours, Minutes;
    local float Seconds;
    local string HourString, MinuteString, SecondString;

    Seconds     =   Abs( Value );
    Minutes     =   int( Seconds ) / 60;
    Hours       =   Minutes / 60;
    Seconds     -=  (Minutes * 60);
    Minutes     -=  (Hours * 60);

    SecondString    = Eval( Seconds < 10, "0"$Seconds, string( Seconds ) );
    MinuteString    = Eval( Minutes < 10, "0"$Minutes, string( Minutes ) );
    HourString      = Eval( Hours < 10, "0"$Hours, string( Hours ) );

    // Negative?
    if( Value < 0 )
        return "-"$HourString$":"$MinuteString$":"$SecondString;
    else return HourString$":"$MinuteString$":"$SecondString;
}

//==============================================================================
// Calculate the best players from all stored players
final function array<sPlayerStats> SortTopPlayers( byte mode, optional bool bAll )          // .:..:, Eliot
{
    local int z, y, PSlot;
    local sPlayerStats Tmp;
    local int CurMap, MaxMap;
    local int CurRec, MaxRec;
    local int CurPlayer;
    local int PlayerNum;
    local int TotalPlayers;
    local int ly,lm,ld;
    local array<int> NumRecords, NumTopRecords;
    local array<float> Points;
    local array<sPlayerStats> NoobList;
    local array<sPlayerStats> SortedPlayers;

    if( BTServer_InvasionMode(CurMode) != none )
    {
        return SortedPlayers;
    }

    //FullLog( "SortTopPlayers" );
    TotalPlayers = PDat.Player.Length;
    if( TotalPlayers == 0 )
    {
        Log( "Players list is empty!" );
        return SortedPlayers;
    }

    Points.Length = TotalPlayers;
    NumRecords.Length = TotalPlayers;
    NumTopRecords.Length = TotalPlayers;

    MRI.RecordsCount = 0;
    // Calculate Points!
    MaxMap = RDat.Rec.Length;
    for( CurMap = 0; CurMap < MaxMap; ++ CurMap )
    {
        if( RDat.Rec[CurMap].bIgnoreStats ) // This map is no longer in maplist so don't give any points for the record on it.
            continue;

        // Just skip any map that isn't recorded yet, waste of performance and should not be counted towards the total records count anyway!
        if( RDat.Rec[CurMap].PSRL.Length == 0 )
            continue;

        ++ MRI.RecordsCount;
        MaxRec = RDat.Rec[CurMap].PSRL.Length;
        for( CurRec = 0; CurRec < MaxRec; ++ CurRec )
        {
            PSlot = RDat.Rec[CurMap].PSRL[CurRec].PLs-1;
            if( PSlot < 0 )
                break;

            if( mode == 0 ||
                (mode == 1 && (GetDaysSince( RDat.Rec[CurMap].PSRL[CurRec].SRD[2], RDat.Rec[CurMap].PSRL[CurRec].SRD[1], RDat.Rec[CurMap].PSRL[CurRec].SRD[0] ) <= 30)) ||
                (mode == 2 && (RDat.Rec[CurMap].PSRL[CurRec].SRD[0] == Level.Day
                    && RDat.Rec[CurMap].PSRL[CurRec].SRD[1] == Level.Month
                    && RDat.Rec[CurMap].PSRL[CurRec].SRD[2] == Level.Year))
            )
            {
                Points[PSlot] += CalcRecordPoints( CurMap, CurRec );
                ++ NumRecords[PSlot];

                if( CurRec == 0 )
                {
                    ++ NumTopRecords[PSlot];
                }
            }
        }
    }

    SortedPlayers.Length = TotalPlayers;
    for( CurPlayer = 0; CurPlayer < TotalPlayers; ++ CurPlayer )
    {
        // 1 April joke.
        if( Level.Month == 4 && Level.Day == 1 )
        {
            SortedPlayers[CurPlayer].PLPoints = Max( Points[PlayerNum] / Rand( Rand( 100 ) + 10 ) + 4, 0 );
        }
        else
        {
            if( bAll )
            {
                SortedPlayers[CurPlayer].PLPoints = Points[PlayerNum];
            }
            else
            {
                if( PDat.Player[PlayerNum].LastPlayedDate == 0 )
                {
                    //Log("user " $ PDat.Player[PlayerNum].PLName $ " has not played in ages");
                }
                else
                {
                    RDat.GetCompactDate( PDat.Player[PlayerNum].LastPlayedDate, ly, lm, ld );
                    if( mode != 0 || GetDaysSince( ly, lm, ld ) < DaysCountToConsiderPlayerInactive )
                    {
                        SortedPlayers[CurPlayer].PLPoints = Points[PlayerNum];
                        if( mode == 0 )
                        {
                            ++ PDat.TotalActivePlayersCount;
                        }
                    }
                }
            }
        }
        SortedPlayers[CurPlayer].PLID           =   PDat.Player[PlayerNum].PLID;
        SortedPlayers[CurPlayer].PLRecords      =   NumRecords[PlayerNum];
        SortedPlayers[CurPlayer].PLTopRecords   =   NumTopRecords[PlayerNum];

        // An index to PDat.Player
        SortedPlayers[CurPlayer].PLSlot         =   PlayerNum;

        switch( mode )
        {
                // All Time
            case 0:
                PDat.Player[PlayerNum].PLARank = CurPlayer + 1;
                break;

                // Quarterly
            case 1:
                PDat.Player[PlayerNum].PLQRank = CurPlayer + 1;
                break;

                // Daily
            case 2:
                PDat.Player[PlayerNum].PLDRank = CurPlayer + 1;
                break;
        }

        if( SortedPlayers[CurPlayer].PLPoints == 0.0f )
        {
            // Keep a copy, we'll add them back after the sorting
            NoobList.Insert( NoobList.Length, 1 );
            NoobList[NoobList.Length] = SortedPlayers[CurPlayer];

            SortedPlayers.Remove( CurPlayer, 1 );
            -- CurPlayer;
            -- TotalPlayers;
        }

        ++ PlayerNum;
    }

    //FullLog( "Sorting players..." );
    // Sort array by Points
    for( CurPlayer = 0; CurPlayer < TotalPlayers-1; ++ CurPlayer )
    {
        z = CurPlayer;
        for( y = CurPlayer+1; y < TotalPlayers; ++ y )
            if( SortedPlayers[y].PLPoints > SortedPlayers[z].PLPoints )
                z = y;

        Tmp = SortedPlayers[z];
        SortedPlayers[z] = SortedPlayers[CurPlayer];
        SortedPlayers[CurPlayer] = Tmp;
    }

    // Add the noobs to the end of the pro's
    for( CurPlayer = 0; CurPlayer < NoobList.Length; ++ CurPlayer )
    {
        SortedPlayers.Insert( SortedPlayers.Length, 1 );
        SortedPlayers[SortedPlayers.Length] = NoobList[CurPlayer];
    }

    //FullLog( "Sorting players complete!" );
    return SortedPlayers;
}

// Thx to: http://alcor.concordia.ca/~gpkatch/gdate-algorithm.html
final function int DateToDays( int y, int m, int d )
{
    m = (m + 9) % 12;
    y -= m/10;
    return 365*y + y/4 - y/100 + y/400 + (m*306 + 5)/10 + ( d - 1 );
}

final function int GetDaysSince( int y, int m, int d )
{
    return DateToDays( Level.Year, Level.Month, Level.Day ) - DateToDays( y, m, d );
}

//==============================================================================
// Start recording this Player(Other) movements
final function RecordGhostForPlayer( PlayerController other )                               // .:..:
{
    local int i, j;

    // Check if this player is being recorded already?
    j = RecordingPlayers.Length;
    for( i = 0; i < j; ++ i )
    {
        if( RecordingPlayers[i] != none && RecordingPlayers[i].ImitatedPlayer == other )
        {
            return;
        }
    }

    // FullLog( "Recording ghost for player" @ other.GetHumanReadableName() );
    RecordingPlayers.Length = j+1;
    RecordingPlayers[j] = Spawn( Class'BTServer_GhostSaver' );
    RecordingPlayers[j].ImitatedPlayer = other;
    RecordingPlayers[j].StartGhostCapturing( GhostPlaybackFPS );

    if( !bSoloMap )
    {
        RecordingPlayers[j].RelativeStartTime = Level.TimeSeconds - MRI.MatchStartTime;
        // FullLog( "Relative start time:" @ RecordingPlayers[j].RelativeStartTime );
    }
}

//==============================================================================
// (bSoloMap) clear recorded moves, and restart
final function RestartGhostRecording( PlayerController PC )
{
    local int i;

    // Was instigated by leaving player?
    if( PC.Player == none )
        return;

    // Find his RecordingPlayers and clear it and re-begin.
    for( i = 0; i < RecordingPlayers.Length; ++ i )
    {
        if( RecordingPlayers[i] != none && RecordingPlayers[i].ImitatedPlayer == PC )
        {
            // Restart recording!
            RecordingPlayers[i].StartGhostCapturing( GhostPlaybackFPS );
            return;
        }
    }
    RecordGhostForPlayer( PC );
}

private function PauseGhostRecorders()
{
    local int i;

    // FullLog( "Pausing ghost recorders" );
    for( i = 0; i < RecordingPlayers.Length; ++ i )
    {
        if( RecordingPlayers[i] != none )
            RecordingPlayers[i].StopGhostCapturing();
    }
}

final function KillGhostRecorders()
{
    local int i;

    // FullLog( "Killing" @ RecordingPlayers.Length @ "ghost recorders" );
    if( RecordingPlayers.Length > 0 )
    {
        for( i = 0; i < RecordingPlayers.Length; ++ i )
        {
            if( RecordingPlayers[i] != none )
                RecordingPlayers[i].Destroy();
        }
        RecordingPlayers.Length = 0;
    }
}

final function UpdateGhosts()
{
    local int i, iQue;
    local array<string> IDs;
    local array<BTServer_GhostData> dataObjects;

    if( !bSpawnGhost )
    {
        return;
    }

    RDat.Rec[UsedSlot].TMGhostDisabled = false;

    // We must clear all present data objects and initialize new ones.
    GhostManager.ClearGhostsData( CurrentMapName, GhostDataFileName, true );
    if( BestPlaySeconds > 1800 )                            // 30 min.
    {
        KillGhostRecorders();
        return;
    }

    // Pause recording
    for( i = 0; i < RecordingPlayers.Length; ++ i )
    {
        if( RecordingPlayers[i] != none )
        {
            RecordingPlayers[i].StopGhostCapturing();
        }
    }

    NewGhostsQue.Length = Min( NewGhostsQue.Length, GhostManager.MaxGhosts );
    GhostManager.Ghosts.Length = NewGhostsQue.Length;

    IDs.Length = NewGhostsQue.Length;
    for( i = 0; i < NewGhostsQue.Length; ++ i )
    {
        IDs[i] = PDat.Player[NewGhostsQue[i]].PLID;
    }

    GhostManager.CreateGhostsData( CurrentMapName, GhostDataFileName, IDs, dataObjects );

    // Clear
    NewGhostsInfo.Length = dataObjects.Length;;
    for( iQue = 0; iQue < dataObjects.Length; ++ iQue )
    {
        NewGhostsInfo[iQue].GhostData = dataObjects[iQue];

        for( i = 0; i < RecordingPlayers.Length; ++ i )
        {
            if( RecordingPlayers[i] != none && RecordingPlayers[i].ImitatedPlayer != none
                && RecordingPlayers[i].ImitatedPlayer.GetPlayerIDHash() == IDs[iQue] )
            {
                // First ghost!
                PDat.ProgressAchievementByID( NewGhostsQue[iQue], 'ghost_0' );

                NewGhostsInfo[iQue].Moves = RecordingPlayers[i];
                break;
            }
        }
    }

    // Finally start moving all movements into the dataobjects
    GotoState( 'SaveGhost' );
}

//==============================================================================
// Remove ghost from players list
Function GetServerPlayers( out GameInfo.ServerResponseLine ServerState )
{
    local int i, j, indexGhost;

    j = ServerState.PlayerInfo.Length;
    if( j == 0 )
        return;

    if( bSpawnGhost && GhostManager != None )
    {
        for( i = 0; i < j; ++ i )
        {
            for( indexGhost = 0; indexGhost < GhostManager.Ghosts.Length; ++ indexGhost )
            {
                if( ServerState.PlayerInfo[i].PlayerName == GhostManager.Ghosts[indexGhost].GhostName )
                {
                    ServerState.PlayerInfo.Remove( i, 1 );
                    -- i;
                    -- j;
                    break;
                }
            }
        }
    }

    ServerState.CurrentPlayers = Level.Game.NumPlayers+Level.Game.NumSpectators;
    ServerState.MaxPlayers = Level.Game.MaxPlayers+Level.Game.NumSpectators;
}

//==============================================================================
// Add random stuff
Function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    if( CurMode != None )
    {
        CurMode.GetServerDetails( ServerState );
    }

    Super.GetServerDetails(ServerState);

    Level.Game.AddServerDetail( ServerState, "BTimes", "Version:"@BTVersion );
    if( ModeIsTrials() )
    {
        Level.Game.AddServerDetail( ServerState, "BTimes", "Ghost Enabled:"@bSpawnGhost );
        Level.Game.AddServerDetail( ServerState, "BTimes", "Rankings Enabled:"@bShowRankings );
        Level.Game.AddServerDetail( ServerState, "BTimes", lzClientSpawn $ " Allowed:"@bAllowClientSpawn );
        Level.Game.AddServerDetail( ServerState, "BTimes", "Most Recent Record:"@LastRecords[MaxRecentRecords-1] );

        if( RDat != none && MRI != none )
        {
            Level.Game.AddServerDetail( ServerState, "BTimes", "Records:"@MRI.RecordsCount$"/"$RDat.Rec.Length );
        }

        if( PDat != none )
        {
            Level.Game.AddServerDetail( ServerState, "BTimes", "Players:"@PDat.Player.Length );
        }

        if( bShowRankings )
            Level.Game.AddServerDetail( ServerState, "BTimes", "Max Ranked Players:"@MaxRankedPlayers );
    }
}

Static Final Function string MakeColor( byte R, byte G, byte B, optional byte A )
{
    return Class'GameInfo'.Static.MakeColorCode( Class'Canvas'.Static.MakeColor( R, G, B, A ) );
}

//==============================================================================
// Broadcast an announcement
final Function BroadcastAnnouncement( name soundName )
{
    local Controller C;

    for( C = Level.ControllerList; C != none; C = C.NextController )
        if( PlayerController(C) != none )
            PlayerController(C).QueueAnnouncement( soundName, 1 );
}

final Function BroadcastSound( sound Snd, optional Actor.ESoundSlot soundSlot )
{
    local Controller C;

    if( Snd == none )
        return;

    if( soundSlot == SLOT_None )
    {
        soundSlot = SLOT_Misc;
    }

    for( C = Level.ControllerList; C != None; C = C.NextController )
        if( PlayerController(C) != None )
            PlayerController(C).ClientPlaySound( Snd, true, 1.0, soundSlot );
}

final function int GetMapSlotByName( string mapName )
{
    local int i;

    for( i = 0; i < RDat.Rec.Length; ++ i )
    {
        if( RDat.Rec[i].TMN ~= mapName )
        {
            return i;
        }
    }
    return -1;
}

final function NotifyPostLogin( PlayerController client, string guid, int slot )
{
    // Player joined while server traveling?
    if( PDat == none )
    {
        Warn( "PDat == none @ NotifyPostLogin" @ guid );
        return;
    }

    // True if ModifyPlayer called NotifyPostLogin( which happens if the player spawns very early like before the replication is created )
    //if( GetRep( client ) != none )
    //  return;

    // Create one if none found.
    if( slot == -1 )
        slot = CreatePlayerSlot( client, guid );

    -- slot; // Real slot!

    // Update names, character etc
    UpdatePlayerSlot( client, slot, false );

    PDat.Player[slot]._LastLoginTime = Level.TimeSeconds;
    PDat.Player[slot].LastPlayedDate = RDat.MakeCompactDate( Level );
    ++ PDat.Player[slot].Played;

    // Get his score from last time he logged on this current round
    RetrieveScore( client, guid, slot );

    // Start replicating rankings
    FullLog( "initializing replication for:" @ %PDat.Player[slot].PLName );
    CreateReplication( client, guid, slot );

    SetClientMatchStartingTime();

    // Server love
    if( PDat.Player[slot].PlayHours >= 10 )
    {
        PDat.ProgressAchievementByID( slot, 'playtime_0' );

        if( PDat.Player[slot].PlayHours >= 1000 )
        {
            PDat.ProgressAchievementByID( slot, 'playtime_1' );
        }
    }

    //client.ClientTravel( "xfire:game_stats?game=ut2k4&Hours of Trials:=" $ int(PDat.Player[slot].PlayHours), TRAVEL_Absolute, false );
}

final function BroadcastLocalMessage( Controller instigator, class<BTClient_LocalMessage> messageClass, string message, optional int switch )
{
    local Controller C;
    local BTClient_ClientReplication LRI;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( C.PlayerReplicationInfo == None )
        {
            continue;
        }

        LRI = GetRep( C );
        if( LRI == none )
        {
            continue;
        }
        LRI.ClientSendMessage( messageClass, message, switch, instigator.PlayerReplicationInfo );
    }
}

//==============================================================================
// Initialize the replication for this player
final function CreateReplication( PlayerController PC, string SS, int Slot )
{
    local BTClient_ClientReplication CR;
    local int i, PacketNum;
    local BTStatsReplicator RR;

    CR = GetRep( PC );
    if( CR == None )
    {
        CR = Spawn( Class'BTClient_ClientReplication', PC );
        CR.NextReplicationInfo = PC.PlayerReplicationInfo.CustomReplicationInfo;
        PC.PlayerReplicationInfo.CustomReplicationInfo = CR;
    }

    if( CR == None )
        return;

    CR.myPlayerSlot = Slot;

    CR.Title = PDat.Player[Slot].Title;
    CR.BTLevel = PDat.GetLevel( Slot, CR.BTExperience );
    CR.BTPoints = PDat.Player[Slot].LevelData.BTPoints;
    CR.bIsPremiumMember = PDat.Player[Slot].bHasPremium;
    if( CR.bIsPremiumMember && Level.NetMode != NM_Standalone )
    {
        BroadcastLocalMessage( PC, class'BTClient_PremLocalMessage', "Premium player %PLAYER% has entered the game" );
    }

    if( Store != none )
    {
        Store.ModifyPlayer( PC, PDat, CR );
    }

    // Check whether user lost some records since he logged off
    PacketNum = PDat.Player[Slot].RecentLostRecords.Length;
    if( PacketNum > 0 )
    {
        if( PacketNum >= 5 )
        {
            // Timeout
            PDat.ProgressAchievementByID( Slot, 'records_1' );
        }

        CR.ClientSendText( "You have lost"@PacketNum@"record(s) since your last login!" );
        for( i = 0; i < PacketNum; ++ i )
            CR.ClientSendText( PDat.Player[Slot].RecentLostRecords[i] );

        PDat.Player[Slot].RecentLostRecords.Length = 0;
    }
    else if( Holiday != "" )    // its a holiday!
    {
        CR.ClientSendText( Class'HUD'.Default.GoldColor $ "Welcome to this server, this time it is"@Holiday );
        /*CR.ClientSendText( Class'HUD'.Default.GoldColor $ "What is different now?" );
        CR.ClientSendText( "" );
        CR.ClientSendText( class'HUD'.Default.GoldColor $ "All top"@MaxRankedPlayers@"players now have trailers and MNAF member options!" );
        CR.ClientSendText( "" );
        CR.ClientSendText( "How to enable options, just type ShieldMenu in your console if you have a ShieldGun selected!" );
        CR.ClientSendText( "How to config your trailer, SetTrailerTexture Package.Group.Name, SetTrailerColor Num(0 or 1) R=255 G=255 B=255" );*/

        if( Level.Month == 8 && Level.Day == 26  )
        {
            CR.ClientSendText( "Say \"Happy Birthday Eliot!\" to get the achievement \"Happy Birthliot\"" );
        }
        CR.ClientSendText( "Happy Holiday!" );
    }
    else if( EventDescription != "" )
    {
        SendEventDescription( CR );
    }

    if( bBlockSake && GroupFinishAchievementUnlockedNum < 10 )
    {
        CR.ClientSendText( $0xFF0000 $ "A new map for Group trials has been released! However the map is locked." );
        CR.ClientSendText( $0xFF0000 $ "At least 10 people have to finish a Group map, to get the map unlocked!" );
        CR.ClientSendText( $0xFF0000 $ GroupFinishAchievementUnlockedNum $ "/10" );
    }

    CR.ClientSendText( "" );
    CR.ClientSendText( $0xFF8800 $ "Welcome to this server, a new MutBestTimes version is currently being tested, here are the changes:" );
    CR.ClientSendText( "" );
    CR.ClientSendText( $0x00FF00 $ "  New!"$$0x888800$" For every time you complete an objective you have a small chance to receive a random item!" );
    CR.ClientSendText( $0x00FF00 $ "  New!"$$0x888800$" Recent donators will receive a premium activation code, giving them access to exclusive features!" );
    CR.ClientSendText( $0x00FF00 $ "  New!"$$0x888800$" The MutBestTimes HUD/Scoreboard and pretty much everything has a new look!" );
    CR.ClientSendText( $0xFFFF00 $ "  New!"$$0x888800$" !title <AchievementTitle>, for premium players: !title <Title>" );
    CR.ClientSendText( "" );

    if( bShowRankings && ModeIsTrials() )
    {
        RR = StartReplicatorFor( CR );
        RR.BeginReplication();
    }
}

private final function BuildEventDescription( out array<string> messages )
{
    local string mapname;
    local int i, j, l;

    i = InStr( EventDescription, "<MapName>" );
    if( i != -1 )
    {
        mapname = Mid( EventDescription, i + 9 );
        mapname = Left( mapname, InStr( mapname, "</MapName>" ) );
        // erase..
        EventDescription = Repl( EventDescription, "<MapName>", "", false );
        EventDescription = Repl( EventDescription, "</MapName>", "", false );
    }

    Split( EventDescription, "\\n", messages );
    if( mapname != "" )
    {
        i = GetMapSlotByName( mapname );
        for( j = 0; j < RDat.Rec[i].PSRL.Length; ++ j )
        {
            l = messages.Length;
            messages.Length = l + 1;
            messages[l] = PDat.Player[RDat.Rec[i].PSRL[j].PLS-1].PLName @ "with a time of" @ TimeToStr( RDat.Rec[i].PSRL[j].SRT );
        }
    }
}

private final function SendEventDescription( BTClient_ClientReplication CR )
{
    local int i;

    for( i = 0; i < EventMessages.Length; ++ i )
    {
        CR.ClientSendText( EventMessages[i] );
    }
}

//==============================================================================
// Merge a numeric date to a string date DD/MM/YY
Static Final Function string FixDate( int Date[3] )
{
    local string FixedDate;

    // Fix date
    if( Date[0] < 10 )
        FixedDate = "0"$Date[0];
    else FixedDate = string( Date[0] );

    if( Date[1] < 10 )
        FixedDate $= "/0"$Date[1];
    else FixedDate $= "/"$Date[1];

    return FixedDate$"/"$Date[2];
}

final function BTStatsReplicator StartReplicatorFor( BTClient_ClientReplication CR )
{
    local BTStatsReplicator replicator;

    replicator = Spawn( class'BTStatsReplicator', self );
    replicator.Initialize( CR );
    return replicator;
}

//P.MRI.SoloRecords = j;

//==============================================================================
// Update all the ClientReplication Packets
Final Function ClientForcePacketUpdate()
{
    local Controller C;
    local LinkedReplicationInfo LRI;
    local BTStatsReplicator replicator;

    MRI.SoloRecords = RDat.Rec[UsedSlot].PSRL.Length;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) == None || C.PlayerReplicationInfo == None )
            continue;

        // Find his ClientReplication!
        for( LRI = C.PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
        {
            if( BTClient_ClientReplication(LRI) != None )
            {
                BTClient_ClientReplication(LRI).ClientCleanSoloTop();

                replicator = StartReplicatorFor( BTClient_ClientReplication(LRI) );
                replicator.GotoState( 'ReplicateSoloTop' );
                break;
            }
        }
    }
}

//==============================================================================
// Returns a line with the Record Owner name and some stats
// TODO: Replace me.
Final Function string GetBestPlayersText( int Slot, int NumPlayers, optional bool bNoExtraInfo )
{
    local int i;
    local string Text;

    if( NumPlayers > MaxPlayers )
        NumPlayers = 0;

    if( RDat.Rec[Slot].PLs[0]-1 == -1 )
        return "None";

    Text = PDat.Player[RDat.Rec[Slot].PLs[0]-1].PLNAME;
    if( RDat.Rec[Slot].Objs[0] > 0 )
        Text $= "["$RDat.Rec[Slot].Objs[i]$"]";

    for( i = 1; i < NumPlayers; ++ i )
    {
        if( RDat.Rec[Slot].PLs[i] <= 0 )
            break;

        Text $= ", "$PDat.Player[RDat.Rec[Slot].PLs[i]-1].PLNAME;
        if( RDat.Rec[Slot].Objs[i] > 0 )
            Text $= "["$RDat.Rec[Slot].Objs[i]$"]";
    }

    if( bNoExtraInfo )
        return Text;

    if( RDat.Rec[Slot].TMContributors > 3 )
        Text @= "C["$RDat.Rec[Slot].TMContributors$"]";

    return Text;//@"H["$RDat.Rec[Slot].TMHijacks$"]"@"P["$RDat.Rec[Slot].TMPoints$"]";
}

//==============================================================================
// Scales the points by certain map values
final function float ScalingPoints( int Slot )
{
    local float Scaler;

    if( RDat.Rec[Slot].PSRL.Length > 0 )
    {
        if( RDat.Rec[Slot].PSRL.Length < MaxRankedPlayers )
        {
            // Increment the points if too few people have a record on this map.
            Scaler = float(MaxRankedPlayers - Min( RDat.Rec[Slot].PSRL.Length, MaxRankedPlayers ));
            return RPScale[RDat.Rec[Slot].TMRating] * (1.0f + (Scaler / float(MaxRankedPlayers)));
        }
        else if( RDat.Rec[Slot].PSRL.Length > MaxRankedPlayers )
        {
            // Decrement the points if too many people have a record on this map.
            Scaler = float(RDat.Rec[Slot].PSRL.Length - MaxRankedPlayers) / MaxRankedPlayers;
            return RPScale[RDat.Rec[Slot].TMRating] * (1.0f - (Scaler / float(MaxRankedPlayers)));

            // Calc: 70 / 30 = 2.33f
            //  1.0 * (1.0f - (2.33f / 5)) = -0.5;
        }
    }
    else
    {
        return RPScale[RDat.Rec[Slot].TMRating] * 2f;
    }
    return RPScale[RDat.Rec[Slot].TMRating];

    // old method...
    //+(RDat.Rec[Slot].TMFailures/10);
    //return FClamp( (((float(RDat.Rec[Slot].MapSkill)+1.f)/**((((RDat.Rec[Slot].TMHijacks-(Players-RDat.Rec[Slot].TMContributors)))+(RDat.Rec[Slot].TMFailures*0.25f))/2.5f)*/)), 0.000000, MaxPoint );
}

//==============================================================================
// Returns the amount of points for the solo record
// Start off with 20 then multiply by Percent (1.0 if 100% or 0.5 if 50%) and then scale it by ScalingPoints which is based on stats of the map/record and then add NumObjs as points
// Short example: (20 * ( ( BestTime(scaled by rank) / SlowerTime ) * Difficulty ) + NumObjs
final function float CalcRecordPoints( int RecordSlot, int SoloRecordSlot )
{
    local float BestTime;
    local float Scaler;
    local float performanceBonus;
    local float points;
    local float difference, bonusSec;
    local float penalty;
    local int bonusMin;
    local int i;
    local int indexWithLowerTime;
    local float averageTime;

    penalty = 1.00;
    if( RDat.Rec[RecordSlot].AverageRecordTime == 00.00 )
    {
        RDat.Rec[RecordSlot].AverageRecordTime = GetAverageRecordTime( RecordSlot );
    }

    averageTime = RDat.Rec[RecordSlot].AverageRecordTime;
    // Awful maps get punished by a 75% points discount.
    if( averageTime < class'BTServer_SoloMode'.default.MinRecordTime
    || averageTime > class'BTServer_SoloMode'.default.MaxRecordTime )
    {
        penalty = class'BTServer_SoloMode'.default.PointsPenalty;
    }

    points = 5*(averageTime/60f) * ScalingPoints( RecordSlot );
    performanceBonus += PointsPerObjective*RDat.Rec[RecordSlot].PSRL[SoloRecordSlot].ObjectivesCount
        + RDat.Rec[RecordSlot].PSRL[SoloRecordSlot].ExtraPoints;

    Scaler = float(SoloRecordSlot);
    for( i = SoloRecordSlot; i >= 0; -- i )
    {
        if( RDat.Rec[RecordSlot].PSRL[i].SRT == RDat.Rec[RecordSlot].PSRL[SoloRecordSlot].SRT )
        {
            Scaler = float(i);
        }
    }

    // best time gets extra points.
    if( Scaler == 0 && RDat.Rec[RecordSlot].PSRL.Length > 1 )
    {
        for( i = 0; i < RDat.Rec[RecordSlot].PSRL.Length; ++ i )
        {
            if( RDat.Rec[RecordSlot].PSRL[i].SRT != RDat.Rec[RecordSlot].PSRL[SoloRecordSlot].SRT )
            {
                indexWithLowerTime = i;
                break;
            }
        }

        // How much better the top record is than the player's rec below.
        difference = (RDat.Rec[RecordSlot].PSRL[indexWithLowerTime].SRT - RDat.Rec[RecordSlot].PSRL[SoloRecordSlot].SRT);
        // Give 1 point for every remaining minute.
        bonusMin = difference / 60;
        // Give 1 point for every 0.08 remaining centiseconds.
        bonusSec = difference - bonusMin * 60;
        // Add them points and cap it at 100 points.
        performanceBonus += bonusMin + (bonusSec / 0.12f);
    }

    BestTime = RDat.Rec[RecordSlot].PSRL[0].SRT - (0.5f + Scaler/1000)*(Scaler*1.5f);
    points *= BestTime / RDat.Rec[RecordSlot].PSRL[SoloRecordSlot].SRT;
    return FMin( points + performanceBonus, 99.99 ) * penalty;
}

final function float GetAverageRecordTime( int recordSlot )
{
    local int i;//j, c, cc;
    local float mean;

    if( RDat.Rec[recordSlot].PSRL.Length == 0 )
    {
        // Regular best time.
        return RDat.Rec[recordSlot].TMT;
    }

    for( i = 0; i < RDat.Rec[recordSlot].PSRL.Length; ++ i )
    {
        mean += RDat.Rec[recordSlot].PSRL[i].SRT;
    }
    return mean / i;

    /*i = (RDat.Rec[recordSlot].PSRL.Length - 1) * 0.5;
    if( RDat.Rec[recordSlot].PSRL.Length % 2 == 0 )
    {
        median = RDat.Rec[recordSlot].PSRL[i].SRT;
    }
    else
    {
        median = (RDat.Rec[recordSlot].PSRL[i].SRT + RDat.Rec[recordSlot].PSRL[i + 1].SRT) / 2;
    }

    for( i = 0; i < RDat.Rec[recordSlot].PSRL.Length; ++ i )
    {
        for( j = 0; j < RDat.Rec[recordSlot].PSRL.Length; ++ j )
        {
            if( int(RDat.Rec[recordSlot].PSRL[i].SRT) == int(RDat.Rec[recordSlot].PSRL[j].SRT) )
                ++ c;
        }

        if( c >= cc )
        {
            cc = c;
            c = 0;
            mode = RDat.Rec[recordSlot].PSRL[i].SRT;
        }
    }*/
}

//==============================================================================
// Returns whether the player with <GUID> is ranked lesser than <Rank>
Final Function bool IsRank( string GUID, int Rank )
{
    local int i, j;

    j = Min( SortedOverallTop.Length, Rank );
    for( i = 0; i < j; ++ i )
    {
        if( SortedOverallTop[i].PLID == guid && SortedOverallTop[i].PLPoints > 0 )
            return True;
    }
    return False;
}

final protected function StartCountDown()
{
    GotoState( 'QuickStart' );
}

final private function ScanSpeedTest()
{
    local int i;

    StopWatch( false );
    i = FindPlayerSlot( "000000000000000000000000" );
    StopWatch( True );
}

Final Function BroadcastConsoleMessage( coerce string Msg )
{
    local Controller C;
    local LinkedReplicationInfo LRI;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
        {
            for( LRI = C.PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
            {
                if( BTClient_ClientReplication(LRI) != None )
                {
                    BTClient_ClientReplication(LRI).ClientSendConsoleMessage( Msg );
                    break;
                }
            }
        }
    }
}

//==============================Data Functions==================================
final function LoadData()
{
    PDat = Level.Game.LoadDataObject( class'BTServer_PlayersData', PlayersDataFileName, PlayersDataFileName );
    if( PDat != none )
    {
        PDat.BT = self;
    }
    else
    {
        PDat = Level.Game.CreateDataObject( class'BTServer_PlayersData', PlayersDataFileName, PlayersDataFileName );
        PDat.BT = self;
        SavePlayers();
    }

    RDat = Level.Game.LoadDataObject( class'BTServer_RecordsData', RecordsDataFileName, RecordsDataFileName );
    if( RDat != none )
    {
        // Update the data format if necessary.
        if( RDat.ConvertData() )
        {
            SaveRecords();  // sync
        }
    }
    else
    {
        RDat = Level.Game.CreateDataObject( class'BTServer_RecordsData', RecordsDataFileName, RecordsDataFileName );
        SaveRecords();
    }
}

Final Function SaveRecords()
{
    if( RDat != None )
    {
        Level.Game.SavePackage( RecordsDataFileName );
    }
}

Final Function SavePlayers()
{
    if( PDat != None )
    {
        Level.Game.SavePackage( PlayersDataFileName );
    }
}

Final Function SaveAll()
{
    SaveRecords();
    SavePlayers();
}

//==============================================================================
// Creates a data file from the current loaded ini/package.
Final Function CreateBackupData()
{
    local BTServer_RecordsData tempRDat;
    local BTServer_PlayersData tempPDat;

    // Records Data!
    tempRDat = Level.Game.CreateDataObject( Class'BTServer_RecordsData', RecordsDataFileName$"_backup", RecordsDataFileName$"_backup" );
    tempRDat.Rec = RDat.Rec;
    Level.Game.SavePackage( RecordsDataFileName$"_backup" );

    // Players Data!
    tempPDat = Level.Game.CreateDataObject( Class'BTServer_PlayersData', PlayersDataFileName$"_backup", PlayersDataFileName$"_backup" );
    tempPDat.Player = PDat.Player;
    tempPDat.BT = self;
    Level.Game.SavePackage( PlayersDataFileName$"_backup" );
}

//==============================================================================
// Converts Backup data to current data file
Final Function RestoreBackupData()
{
    local BTServer_RecordsData tempRDat;
    local BTServer_PlayersData tempPDat;

    // Records Data!
    tempRDat = Level.Game.LoadDataObject( Class'BTServer_RecordsData', RecordsDataFileName$"_backup", RecordsDataFileName$"_backup" );
    RDat.Rec = tempRDat.Rec;

    // Players Data!
    tempPDat = Level.Game.LoadDataObject( Class'BTServer_PlayersData', PlayersDataFileName$"_backup", PlayersDataFileName$"_backup" );
    PDat.Player = tempPDat.Player;
    PDat.BT = self;

    SaveAll();
}

//==============================================================================
// Exports a record array element out of RDat into a new .uvx file
Final Function bool ExportRecordData( string MapName )
{
    local BTServer_RecordObject tempRecObj;
    local int CurMap, MaxMap;
    local int CurSlot;

    // Find 'Rec' slot...
    MaxMap = RDat.Rec.Length;
    CurSlot = -1;
    for( CurMap = 0; CurMap < MaxMap; ++ CurMap )
    {
        if( RDat.Rec[CurMap].TMN ~= MapName )
        {
            CurSlot = CurMap;
            break;
        }
    }

    if( CurSlot == -1 )
    {
        FullLog( MapName@"was not found!" );
        return False;
    }

    tempRecObj = Level.Game.LoadDataObject( Class'BTServer_RecordObject', "BestTimes_RecordObject_"@MapName, "BestTimes_RecordObject_"@MapName );
    if( tempRecObj == None )
        tempRecObj = Level.Game.CreateDataObject( Class'BTServer_RecordObject', "BestTimes_RecordObject_"@MapName, "BestTimes_RecordObject_"@MapName );

    if( tempRecObj != None )
    {
        tempRecObj.Record = RDat.Rec[CurSlot];
        Level.Game.SavePackage( "BestTimes_RecordObject_"@MapName );
        return True;
    }
    return False;
}

//==============================================================================
// Imports a .uvx file into RDat
Final Function bool ImportRecordData( string MapName )
{
    local BTServer_RecordObject tempRecObj;
    local int CurMap, MaxMap;
    local int CurSlot;

    tempRecObj = Level.Game.LoadDataObject( Class'BTServer_RecordObject', "BestTimes_RecordObject_"@MapName, "BestTimes_RecordObject_"@MapName );
    if( tempRecObj == None )
    {
        FullLog( MapName@"was not found!" );
        return false;
    }

    // Find 'Rec' slot...
    MaxMap = RDat.Rec.Length;
    CurSlot = -1;
    for( CurMap = 0; CurMap < MaxMap; ++ CurMap )
    {
        if( RDat.Rec[CurMap].TMN ~= MapName )
        {
            CurSlot = CurMap;
            break;
        }
    }

    if( CurSlot != -1 )
    {
        // Update 'Rec' slot
        RDat.Rec[CurSlot] = tempRecObj.Record;
        Level.Game.DeletePackage( "BestTimes_RecordObject_"@MapName );
        return True;
    }
    else
    {
        // Create new 'Rec' slot
        RDat.Rec.Length = MaxMap + 1;
        RDat.Rec[MaxMap] = tempRecObj.Record;
        return True;
    }
    return False;
}
//==============================Data Functions==================================

//==============================================================================
// Obsolete
final function AutoTeam()
{
    //local Controller C;
    //local UnrealTeamInfo NewTeam;

    /*for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) != None )
        {
            if( (C.PlayerReplicationInfo.bIsSpectator || C.PlayerReplicationInfo.bOnlySpectator) && !C.PlayerReplicationInfo.bWaitingPlayer )
                continue;

            if( Level.Game.IsOnTeam( C, AssaultGame.CurrentAttackingTeam-1 ) )
                continue;

            if( C.Pawn != None )
                C.Pawn.Destroy();

            NewTeam = AssaultGame.Teams[AssaultGame.PickTeam( AssaultGame.CurrentAttackingTeam-1, C )];
            C.StartSpot = None;
            C.PlayerReplicationInfo.Team.RemoveFromTeam( C );
            NewTeam.AddToTeam( C );

            //AssaultGame.ChangeTeam( C, AssaultGame.CurrentAttackingTeam-1, True );

            if( C.Pawn != None )
                C.Pawn.Destroy();
        }
    }*/
}

// Find out if there are mutliple people using one GUID( from PC ) that are currently in-game(not spectating if bNoSpec)
final function bool FoundDuplicateID( PlayerController PC, optional bool bIgnoreSpectators )
{
    local Controller C;
    local string ID;

    if( PC == None )
        return False;

    ID = PC.GetPlayerIDHash();
    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) == None || C.PlayerReplicationInfo == None || C == PC || MessagingSpectator(C) != None )
            continue;

        if( PlayerController(C).GetPlayerIDHash() == ID )
        {
            if( bIgnoreSpectators && IsSpectator( C.PlayerReplicationInfo ) )
                continue;

            return True;
        }
    }
    return False;
}

Static Final Function bool IsSpectator( PlayerReplicationInfo PRI )
{
    if( PRI != None && (PRI.bOnlySpectator || PRI.bIsSpectator) )
        return True;

    return False;
}

Static Final Function bool IsAdmin( PlayerReplicationInfo PRI )
{
    if( PRI != None && (PRI.bAdmin || PRI.Level.NetMode == NM_StandAlone || MessagingSpectator(PRI.Owner) != none) )
        return True;

    return False;
}

//==============================================================================
// Converts 000001.011000 to 000001.01000. So resets last 4 decimals.
// Used for comparing, and to make Tie'ng records possible!
Static Final Function float GetFixedTime( float TimeToFix )
{
    local string FixedTimeString;

    FixedTimeString = Left( string( TimeToFix ), InStr( string( TimeToFix ), "." ) + 3 );
    return float( FixedTimeString );
}

//==============================================================================
// Starts saving ghost once this state activates, slowly to keep clients connected
state SaveGhost
{
    function BeginState();

    function EndState()
    {
        NewGhostsInfo.Length = 0;
        NewGhostsQue.Length = 0;

        // Complete...
        CurMove = 0;
        MaxMove = 0;
        SavedMoves = 0;
        iGhost = 0;

        KillGhostRecorders();       // Clean up all temporary MovementSavers
    }

Begin:
    PauseGhostRecorders();  // Don't keep on recording until the end of this recording.
    bGhostIsSaving = True;
    MRI.bUpdatingGhost = True;
    MRI.GhostPercent = 0.00;
    MRI.NetUpdateTime = Level.TimeSeconds-1;

    // Turn off countdown
    if( Level.Game.VotingHandler != None )
    {
        if( Level.Game.VotingHandler.TimerRate > 0 )
        {
            bRedoVotingTimer = True;
            Level.Game.VotingHandler.SetTimer( 0, False );
        }

        // Extend the TimeLimit by predicted saving speed
        xVotingHandler(Level.Game.VotingHandler).VoteTimeLimit += 120;
    }

    //Level.Game.Broadcast( Self, Level.Game.MakeColorCode( Class'HUD'.Default.GoldColor )$"Saving Ghost!, Players can not vote untill Saving is completed!" );

    MaxMove = 0;
    for( iGhost = 0; iGhost < NewGhostsInfo.Length; ++ iGhost )
    {
        MaxMove += NewGhostsInfo[iGhost].Moves.MovementsData.Length;
    }

    TotalSavedMoves = 0;
    for( iGhost = 0; iGhost < NewGhostsInfo.Length; ++ iGhost )
    {
        // Start moving the Moves list to this Data Object
        for( CurMove = 0; CurMove < NewGhostsInfo[iGhost].Moves.MovementsData.Length; ++ CurMove )
        {
            if( SavedMoves == GhostPlaybackFPS || CurMove+1 == NewGhostsInfo[iGhost].Moves.MovementsData.Length )
            {
                Sleep( GhostSaveSpeed );
                SavedMoves = 0;

                MRI.GhostPercent = (float(TotalSavedMoves)/float(MaxMove))*100;
                MRI.NetUpdateTime = Level.TimeSeconds-1;
            }

            NewGhostsInfo[iGhost].GhostData.MO.Insert( CurMove, 1 );
            NewGhostsInfo[iGhost].GhostData.MO[CurMove] = NewGhostsInfo[iGhost].Moves.MovementsData[CurMove];

            ++ SavedMoves;
            ++ TotalSavedMoves;
        }

        NewGhostsInfo[iGhost].GhostData.RelativeStartTime = NewGhostsInfo[iGhost].Moves.RelativeStartTime;
    }
    // Completed
    GhostManager.SaveGhosts( CurrentMapName, GhostDataFileName );
    GhostManager.LoadGhosts( CurrentMapName, GhostDataFileName );

    bGhostIsSaving = False;
    MRI.GhostPercent = 100.00f;
    MRI.NetUpdateTime = Level.TimeSeconds-1;

    // Give the replication some time... before disabling it!
    Sleep( 0.05f );

    MRI.bUpdatingGhost = False;

    GhostManager.GhostsRespawn();
    ForceViewGhost();

    if( Level.Game.VotingHandler != None )
    {
        if( bRedoVotingTimer )
            Level.Game.VotingHandler.SetTimer( 1, True );                       // Turn on countdown

        xVotingHandler(Level.Game.VotingHandler).VoteTimeLimit -= 120;
    }

    //Level.Game.Broadcast( Self, Level.Game.MakeColorCode( Class'HUD'.Default.GoldColor )$"Saving Ghost Completed!, Players can now vote!" );
    GotoState( '' );
}

state QuickStart
{
    function BeginState()
    {
        bQuickStart = true;
        MRI.RecordState = RS_QuickStart;
        UpdateEndMsg( "Preparing next round..." );  // Clear!
    }

    function EndState()
    {
        bQuickStart = false;
    }

Begin:
    Sleep( 0.25f );
    for( CurCountdown = 5; CurCountdown > 0; -- CurCountdown )
    {
        //FullLog( "CCD" $ CurCountDown );
        UpdateEndMsg( "Next round in " $ CurCountdown $ "..." );
        Level.Game.BroadcastLocalizedMessage( Class'BTClient_QuickStartSound', CurCountdown );
        Sleep( 1.0f );
    }

    CurMode.PreRestartRound();
    UpdateEndMsg( "Next round initializing..." );
    Sleep( 0.5f );
    BTServer_VotingHandler(Level.Game.VotingHandler).DisableMidGameVote();
    CurMode.PostRestartRound();
    UpdateEndMsg( "" );
    GotoState( '' );
}

final function UpdateEndMsg( string endMsg )
{
    MRI.EndMsg = endMsg;
    MRI.NetUpdateTime = Level.TimeSeconds - 1;
}

final function ForceViewGhost()
{
    local Controller C;

    if( GhostManager != none && GhostManager.Ghosts.Length > 0 && GhostManager.Ghosts[0].GhostData.MO.Length > 0 )
    {
        for( C = Level.ControllerList; C != None; C = C.NextController )
        {
            if( PlayerController(C) != None && MessagingSpectator(C) == None )
            {
                PlayerController(C).ClientSetViewTarget( GhostManager.Ghosts[0].GhostPawn );
                PlayerController(C).SetViewTarget( GhostManager.Ghosts[0].GhostPawn );
            }
        }
    }
}

final function AddHistory( string NewLine )
{
    if( History.Length >= MaxHistoryLength )
        History.Remove( 0, 1 );

    //History.Insert( History.Length-1, 1 );
    History[History.Length] = NewLine;
}

final function AddRecentSetRecordToPlayer( int PlayerSlot, string Text )
{
    local int j;

    j = PDat.Player[PlayerSlot - 1].RecentSetRecords.Length;

    if( j >= MaxPlayerRecentRecords )
    {
        PDat.Player[PlayerSlot - 1].RecentSetRecords.Remove( 0, 1 );
        -- j;
    }
    PDat.Player[PlayerSlot - 1].RecentSetRecords[j] = Text;
}

final function int GetGroupTaskPoints( int groupIndex )
{
    local int i, points;

    if( groupIndex != -1 )
    {
        for( i = 0; i < GroupManager.Groups[groupIndex].CompletedTasks.Length; ++ i )
        {
            if( GroupManager.Groups[groupIndex].CompletedTasks[i].bOptionalTask )
            {
                points += GroupManager.Groups[groupIndex].CompletedTasks[i].OptionalTaskReward;
            }
        }
    }
    return points;
}

static function FillPlayInfo( PlayInfo info )
{
    local int i;
    local sConfigProperty prop;

    super.FillPlayInfo( info );
    for( i = 0; i < default.ConfigurableProperties.Length; ++ i )
    {
        prop = default.ConfigurableProperties[i];
        if( prop.Category == "" )
        {
            prop.Category = default.RulesGroup;
        }

        if( prop.Type == "" )
        {
            switch( prop.Property.Class )
            {
                case class'BoolProperty':
                    prop.Type = "Check";
                    break;

                default:
                    prop.Type = "Text";
                    break;
            }
        }
        info.AddSetting( prop.Category, string(prop.Property.Name), prop.Description, prop.AccessLevel, prop.Weight, prop.Type, prop.Rules, prop.Privileges, prop.bMultiPlayerOnly, prop.bAdvanced );
    }
}

static function string GetDescriptionText( string propertyName )
{
    local int i;

    for( i = 0; i < default.ConfigurableProperties.Length; ++ i )
    {
        if( string(default.ConfigurableProperties[i].Property.Name) == propertyName )
        {
            if( default.ConfigurableProperties[i].Hint == "" )
            {
                return default.ConfigurableProperties[i].Description;
            }
            return default.ConfigurableProperties[i].Hint;
        }
    }
    return super.GetDescriptionText( propertyName );
}

event Destroyed()
{
    super.Destroyed();
    Clear();
}

DefaultProperties
{
    UsedSlot=-1

    AnnouncementRecordImprovedVeryClose=HolyShit_F
    AnnouncementRecordImprovedClose=Last_Second_Save
    AnnouncementRecordHijacked=Hijacked
    AnnouncementRecordSet=WhickedSick
    AnnouncementRecordTied=Invulnerable
    AnnouncementRecordFailed=Denied
    AnnouncementRecordAlmost=Totalled

    CheckPointHandlerClass=Class'BTServer_CheckPoint'
    CheckPointNavigationClass=Class'BTServer_CheckPointNavigation'
    TrailerInfoClass=Class'BTClient_TrailerInfo'
    RankTrailerClass=Class'BTClient_RankTrailer'
    ClientStartPointClass=Class'BTServer_ClientStartPoint'
    NotifyClass=class'BTServer_HttpNotificator'

    lzMapName="Map Name"
    lzPlayerName="Player Name"
    lzRecordTime="Record Time"
    lzRecordAuthor="Record Holder(s)"
    lzRecordPoints="Points"
    lzFinished="Finished"
    lzHijacks="Hijacked"
    lzFailures="Failures"
    lzRating="Rating"
    lzRecords="Records"

    lzRandomPick="Random Picks"

    lzCS_Set="'Client Spawn' set"
    lzCS_Deleted="'Client Spawn' deleted"
    lzCS_NotAllowed="Sorry you are not allowed to create a 'Client Spawn' at this location"
    lzCS_Failed="Failed to set a 'Client Spawn' here. Please try move a little and try again"
    lzCS_ObjAndTrigger="You cannot interact with any objectives nor triggers while using a 'Client Spawn'"
    lzCS_Obj="You cannot interact with any objectives while using a 'Client Spawn'"
    lzCS_AllowComplete="Because of the configuration of this server, you can complete the map with a 'Client Spawn'"
    lzCS_NoPawn="Sorry you cannot set a 'Client Spawn' when you have no pawn, you are not walking or quickstart is in progress"
    lzCS_NotEnabled="Sorry 'Client Spawn' is not allowed on this server"
    lzCS_NoQuickStartDelete="Sorry you cannot delete your 'Client Spawn' when quickstart is in progress"
    lzClientSpawn="Client Spawn"

    RecordsDataFileName="BestTimes_RecordsData"
    PlayersDataFileName="BestTimes_PlayersData"
    GhostDataFileName="BTGhost_"

    cDarkGray=(R=60,G=60,B=60,A=255)

    MaxRewardedPlayers=3

    RankPrefix(0)="st"
    RankPrefix(1)="nd"
    RankPrefix(2)="rd"
    RankPrefix(3)="th"

    RPScale(0)=0.200
    RPScale(1)=0.400
    RPScale(2)=0.600
    RPScale(3)=0.800
    RPScale(4)=1.000
    RPScale(5)=1.500
    RPScale(6)=2.000
    RPScale(7)=2.500
    RPScale(8)=3.000
    RPScale(9)=3.500

    PPoints=(PlayerPoints[0]=(PPlayer[0]=5),PlayerPoints[1]=(PPlayer[0]=3,PPlayer[1]=3),PlayerPoints[2]=(PPlayer[0]=1,PPlayer[1]=1,PPlayer[2]=1))

    PointsPerLevel=5
    MaxLevel=100
    ObjectivesEXPDelay=10
    DropChanceCooldown=60

    TrialModes(0)=Class'BTServer_InvasionMode'
    TrialModes(1)=Class'BTServer_BunnyMode'
    TrialModes(2)=Class'BTServer_RegularMode'
    TrialModes(3)=Class'BTServer_GroupMode'
    TrialModes(4)=Class'BTServer_SoloMode'

    bAllowClientSpawn=True
    bTriggersKillClientSpawnPlayers=True
    bClientSpawnPlayersCanCompleteMap=False
    bNoRandomSpawnLocation=True
    bShowRankings=True
    bAddGhostTimerPaths=true
    bAllowCompetitiveMode=true
    MaxRankedPlayers=15
    bSpawnGhost=true
    GhostPlaybackFPS=10
    GhostSaveSpeed=0.025000
    MinExchangeableTrophies=25
    MaxExchangeableTrophies=45
    DaysCountToConsiderPlayerInactive=30

    FriendlyName="BestTimes"
    Description="Records Best MapTime completion"
    RulesGroup="BestTimes"
    Group="BestTimes"

    CompetitiveTimeLimit=5.0
    TimeScaling=1.0
    bGenerateBTWebsite=True
    MaxItemsToReplicatePerTick=1

    //bSavePreviousGhost=True

    LastRecords(0)="N/A"
    LastRecords(1)="N/A"
    LastRecords(2)="N/A"
    LastRecords(3)="N/A"
    LastRecords(4)="N/A"
    LastRecords(5)="N/A"
    LastRecords(6)="N/A"
    LastRecords(7)="N/A"
    LastRecords(8)="N/A"
    LastRecords(9)="N/A"
    LastRecords(10)="N/A"
    LastRecords(11)="N/A"
    LastRecords(12)="N/A"
    LastRecords(13)="N/A"
    LastRecords(14)="N/A"

    Commands(0)=(Cmd="DeleteRecord",Params=("None"),Help="Deletes the record of the currently played map and creates a clean new record slot")
    Commands(1)=(Cmd="DeleteRecordByName",Params=("MapName"),Help="Deletes the record of the specified map but doesn't create a new record slot")
    Commands(2)=(Cmd="DeleteTopRecord",Params=("Index"),Help="Deletes a solo record specified by index")
    Commands(3)=(Cmd="GhostFollow",Params=("PartOfPlayerName"),Help="Makes the current ghost follow the specified player(The Player must have ResetGhost checked)")
    Commands(4)=(Cmd="GhostFollowID",Params=("IDOfPlayer"),Help="Makes the current ghost follow the player with the specified ID(The Player must have ResetGhost checked)")
    Commands(5)=(Cmd="UpdateWebBTimes",Params=("None"),Help="Forces the mutator to generate a new WebBTimes.html file")
    Commands(6)=(Cmd="BT_BackupData",Params=("None"),Help="Creates a backup of the Saves\\*.uvx BTimes related files")
    Commands(7)=(Cmd="BT_RestoreData",Params=("None"),Help="Restores the current used *.uvx BTimes related files to the backedup files if available")
    Commands(8)=(Cmd="BT_ExportRecord ",Params=("MapName"),Help="")
    Commands(9)=(Cmd="BT_ImportRecord ",Params=("MapName"),Help="")
    Commands(10)=(Cmd="QuickStart",Params=("None"),Help="Forces the start of a new round")
    Commands(11)=(Cmd="DeleteGhost",Params=("None"),Help="Deletes the ghost of the currently played map")
    Commands(12)=(Cmd="ExitServer",Params=("None"),Help="Just like Admin Exit but this one also forces the mutator to save its *.uvx BTimes related files")
    Commands(13)=(Cmd="ForceSave",Params=("None"),Help="Forces the mutator to save its *.uvx BTimes related files")
    Commands(14)=(Cmd="SetMapRating",Params=("Rating(1-10)"),Help="Changes the maprating of the currently played map")
    Commands(15)=(Cmd="RenameRecord",Params=("MapName","MapName"),Help="Renames a record slot with the name of the specified param(1) to param(2)(The server may not be running either of the two maps)")
    Commands(16)=(Cmd="RenameMap",Params=("MapName","MapName"),Help="Renames a record slot with the name of the specified param(1) to param(2)(The server may not be running either of the two maps)")
    Commands(17)=(Cmd="DebugMode",Params=("none"),Help="Makes the debug logs display to all connected clients")
    Commands(18)=(Cmd="ResetRecord",Params=("None"),Help="Deletes the record of the currently played map and creates a clean new record slot")
    Commands(19)=(Cmd="SetMaxRankedPlayers",Params=("Amount"),Help="Changes the amount of shown ranked players to the specified value")
    Commands(20)=(Cmd="SetGhostRecordFPS",Params=("Amount"),Help="Changes the amount of frames per second to the specified value")
    Commands(21)=(Cmd="SetQuickStartLimit",Params=("Amount"),Help="Changes the amount of maximum quickstarts to the specified value")
    Commands(22)=(Cmd="AddStart",Params=("TeamNum"),Help="Adds a player spawn for the specified team")
    Commands(23)=(Cmd="RemoveStarts",Params=("None"),Help="Removes all added player spawns")
    Commands(24)=(Cmd="GiveExperience",Params=("PartOfPlayerName","Amount"),Help="Gives experience to the specified player")
    Commands(25)=(Cmd="GiveCurrency",Params=("PartOfPlayerName","Amount"),Help="Gives currency to the specified player")
    Commands(26)=(Cmd="GiveItem",Params=("PartOfPlayerName","ItemID"),Help="Gives an item to the specified player")
    Commands(27)=(Cmd="RemoveItem",Params=("PartOfPlayerName","ItemID"),Help="Remove an item from the specified player")
    Commands(28)=(Cmd="GivePremium",Params=("PartOfPlayerName"),Help="Gives premium to the specified player")
    Commands(29)=(Cmd="RemovePremium",Params=("PartOfPlayerName"),Help="Removes premium from the specified player")
    Commands(30)=(Cmd="BT_ResetAchievements",Params=("PartOfPlayerName|All"),Help="Resets achievement stats of the specified player")
    Commands(31)=(Cmd="BT_ResetExperience",Params=("None"),Help="Resets everyone experience to 0")
    Commands(32)=(Cmd="BT_ResetCurrency",Params=("None"),Help="Resets everyone currency to 0")
    Commands(33)=(Cmd="BT_ResetObjectives",Params=("None"),Help="Resets everyone completed objectives count to 0")
    Commands(34)=(Cmd="BT_UpdateMapPrefixes",Params=("None"),Help="Converts AS-* existing records to their corresponding prefixes such as STR-*")
    Commands(35)=(Cmd="CompetitiveMode",Params=("None"),Help="Starts the competitive mode")
    Commands(36)=(Cmd="SetEventDesc",Params=("Message(1024)"),Help="Sets the BTimes MOTD")

    ADMessage="Become a fan of our 'Unreal Trials' page on Facebook: Press Enter to visit it now"
    ADURL="http://www.facebook.com/pages/Unreal-Trials-Commentation/130856926973107"

    InvalidAccessMessage="Sorry! This server is not permitted to use MutBestTimes!"

    ConfigurableProperties(0)=(Property=BoolProperty'bGenerateBTWebsite',Description="Generate a WebBTimes.html File",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will create a WebBTimes.html file under Saves folder when a new record is set.")
    ConfigurableProperties(1)=(Property=BoolProperty'bSpawnGhost',Description="Record and Spawn Ghosts",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will record all players movements and spawn a ghost using the best player movements (ONLY FOR FAST SERVERS).")
    ConfigurableProperties(2)=(Property=BoolProperty'bDontEndGameOnRecord',Description="Don't End the Game on Record",AccessLevel=255,Weight=1,Hint="If Checked: The game will not end when a player sets a new record. bSpawnGhost must be disabled!")
    ConfigurableProperties(3)=(Property=BoolProperty'bEnhancedTime',Description="Dynamic RoundTime Limit",Weight=1,Hint="If Checked: BTimes will adjust the RoundTimeLimit of Assault based on the record time.")
    ConfigurableProperties(4)=(Property=BoolProperty'bDisableForceRespawn',Description="Disable Instant Respawning",Weight=1,Hint="If Checked: BTimes will not respawn dying players instantly.")
    ConfigurableProperties(5)=(Property=BoolProperty'bAllowClientSpawn',Description="Allow ClientSpawn Use",Weight=1,Hint="If Checked: BTimes will allow people to use 'Client Spawn'.")
    ConfigurableProperties(6)=(Property=BoolProperty'bTriggersKillClientSpawnPlayers',Description="Triggers Should Kill ClientSpawn Players",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will kill people coming near a trigger if using a 'Client Spawn'.")
    ConfigurableProperties(7)=(Property=BoolProperty'bClientSpawnPlayersCanCompleteMap',Description="Allow ClientSpawn to Complete Map",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will alow people using a 'Client Spawn' to be able to finish the map.")
    ConfigurableProperties(8)=(Property=BoolProperty'bAddGhostTimerPaths',Description="Generate Ghost Time Paths",Weight=1,Hint="Whether to spawn ghost markers.")
    ConfigurableProperties(9)=(Property=IntProperty'GhostPlaybackFPS',Description="Ghost Recording Framerate",AccessLevel=255,Weight=1,Rules="2;1:25",Hint="Amount of frames recorded every second (DON'T SET THIS HIGH).")
    ConfigurableProperties(10)=(Property=FloatProperty'GhostSaveSpeed',Description="Ghost Saving Interval",AccessLevel=255,Weight=1,Hint="Amount of saving delay between every 10 Movements.")
    ConfigurableProperties(11)=(Property=IntProperty'MaxRankedPlayers',Description="Maximum Rankable Players",Weight=1,Rules="2;5:30",Hint="Amount of players to show in the ranking table and top records list.")
    ConfigurableProperties(12)=(Property=FloatProperty'TimeScaling',Description="Dynamic RoundTime Limit Scaler",Weight=1,Hint="RoundTimeLimit percent scaling.")
    ConfigurableProperties(13)=(Property=FloatProperty'CompetitiveTimeLimit',Description="RoundTime Limit for Competitive Mode",Weight=1,Hint="The time limit for the Competitive Mode.")
    ConfigurableProperties(14)=(Property=BoolProperty'bAllowCompetitiveMode',Description="Allow Competitive Mode",Weight=1)
    ConfigurableProperties(15)=(Property=StrProperty'ADMessage',Description="Advertise Message",AccessLevel=255,Weight=1,Rules="255",Hint="Input an advertisement message, that will be displayed to every player, when QuickStart is active or when the map is completed.")
    ConfigurableProperties(16)=(Property=StrProperty'ADURL',Description="Advertise URL",AccessLevel=255,Weight=1,Rules="255",Hint="The web link, the players will go to when hitting Enter while the Advertise Message is displayed.")
    ConfigurableProperties(17)=(Property=IntProperty'MaxLevel',Description="Maximum Level a Player Can Become",AccessLevel=0,Weight=1,Rules="10:1000",Hint="")
    ConfigurableProperties(18)=(Property=IntProperty'PointsPerLevel',Description="Currency Bonus per Level when Leveling Up",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(19)=(Property=IntProperty'ObjectivesEXPDelay',Description="Objective Experience Reward Cooldown",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(20)=(Property=IntProperty'DropChanceCooldown',Description="Objective Item Drop Chance Cooldown",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(21)=(Property=IntProperty'MinExchangeableTrophies',Description="Minimum Amount of Trophies Required",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(22)=(Property=IntProperty'MaxExchangeableTrophies',Description="Maximum Amount of Exchangeable Trophies",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(23)=(Property=IntProperty'DaysCountToConsiderPlayerInactive',Description="Amount of Days to Consider a Player Inactive",AccessLevel=0,Weight=1,Hint="If a player remains inactive for the specified amount of days then the player will be hidden from rankings.")
    ConfigurableProperties(24)=(Property=BoolProperty'bNoRandomSpawnLocation',Description="Enable Fixed Player Spawns",Weight=1,Hint="If Checked: BTimes will force every player's spawn point to one fixed spawn point.")
    ConfigurableProperties(25)=(Property=StrProperty'EventDescription',Description="MOTD",AccessLevel=255,Weight=1,Rules="1024",Hint="Message of the day.")

    bDisableWeaponBoosting=true
    ConfigurableProperties(26)=(Property=BoolProperty'bDisableWeaponBoosting',Description="Disable Weapon Boosting",AccessLevel=0,Weight=1,Hint="If checked: players no longer can boost another by shooting the player.")

    bEnableInstigatorEmpathy=true
    ConfigurableProperties(27)=(Property=BoolProperty'bEnableInstigatorEmpathy',Description="Reflect All Taken Damage from Players",AccessLevel=0,Weight=1,Hint="If checked: enemies cannot kill the enemy through means of weapons.")
}
