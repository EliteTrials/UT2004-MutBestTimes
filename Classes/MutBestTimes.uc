//=============================================================================
// Copyright 2005-2016 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class MutBestTimes extends Mutator
    config(MutBestTimes)
    dependson(BTStructs)
    dependson(BTServer_PlayersData)
    dependson(BTServer_RecordsData)
    dependson(BTAchievements)
    dependson(BTChallenges)
    dependson(BTActivateKey)
    dependson(BTServer_CheckPoint);

#exec obj load file="TrialGroup.u"

//==============================================================================
// Macros
//  Major Version // Major modification
//  Minor Version  // minor new features
//  Build Number // compile/test count, resets??
//  Revision // quick fix
const BTVersion                         = "4.0.1.0";
const CREDITS                           = "Copyright 2005-2016 Eliot van Uytfanghe and .:..:";
const MaxRecentRecords                  = 15;                                   // The max recent records that is saved.
const MaxPlayerRecentRecords            = 5;                                    // The max recent records that are saved per player.
const MaxHistoryLength                  = 25;
const MaxRecentMaps                     = 20;
const BTAuthor                          = "2e216ede3cf7a275764b04b5ccdd005d";   // Author guid, gives access to some admin commands...

const EXP_ImprovedRecord                = 25;
const EXP_FirstRecord                   = 40;
const EXP_TiedRecord                    = 30;
const EXP_FailRecord                    = 3;
const EXP_Objective                     = 4;

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
    var BTServer_ClientStartPoint
        PStart;

    var int TeamIndex;
    var PlayerController
        PC;

    var BTServer_CheckPoint.sPawnStats SavedStats;
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

var BTRanks                                         Ranks;
var private array<KeepScoreSE>                      KeepScoreTable;             // Backed up score from leaving players.

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

var BTGhostManager                                  GhostManager;               // Currently used ghost data loader.
var PlayerController                                LeadingGhost;               // PlayerController the ghost should reset CurrentMove for
// "GhostFollow <PlayerName>" was used on a player by an Admin.
var bool                                            bGhostWasAdminAwarded;

var() globalconfig float GhostSaveSpeed;
var() globalconfig bool bSpawnGhost;
var() globalconfig int GhostPlaybackFPS;
//===============</GHOST VARS>====================================

var BTServer_RecordsData                            RDat;                       // Holds all the Records
var BTServer_PlayersData                            PDat;                       // Holds all the Players
var sSharedPoints                                   PPoints;                    // Structure containing the points players will be rewarded with

// External
var GroupManager                                    GroupManager;

var BTServer_Mode                                   CurMode;
var BTGameRules                                     ModeRules;
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
    bTriggersKillClientSpawnPlayers,
    bClientSpawnPlayersCanCompleteMap,
    bSavePreviousGhost,
    bAddGhostTimerPaths,
    bAllowCompetitiveMode,
    bDontEndGameOnRecord,
    bEnableInstigatorEmpathy;

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
    float
    PointsPerObjective;

var() globalconfig
    name
    // AnnouncerFemale2K4.Generic.HolyShit_F
    AnnouncementRecordImprovedVeryClose,
    // AnnouncerFemale2K4.Generic.Unstoppable
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
    lzFinished,                 lzHijacks,          lzFailures,           lzRecords,
    lzCS_Set,                   lzCS_Deleted,       lzCS_NotAllowed,            lzCS_Failed,
    lzCS_ObjAndTrigger,         lzCS_Obj,           lzCS_AllowComplete,
    lzCS_NoPawn,                lzCS_NotEnabled,    lzCS_NoQuickStartDelete,
    lzRandomPick, lzClientSpawn;

//AddSetting(string Group, string PropertyName, string Description, byte SecLevel,
//byte Weight, string RenderType, optional string Extras, optional string ExtraPrivs,
//optional bool bMultiPlayerOnly, optional bool bAdvanced);

var array<BTStructs.sConfigProperty> ConfigurableProperties;
var const string InvalidAccessMessage;
var private editconst const color cDarkGray, cLight, cGold, cWhite, cRed, cGreen;
var private const string cEnd;

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

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

final function bool IsClientSpawnPlayer( Pawn other )
{
    local BTClient_ClientReplication CRI;

    CRI = GetRep( other.Controller );
    return other != none && CRI != none && CRI.ClientSpawnPawn == other
        // Checkpoint players use the same system, so make sure we don't consider them as ClientSpawn users.
        && !(other.LastStartSpot != none && other.LastStartSpot.IsA( CheckPointNavigationClass.Name ));
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
        PC.ClientMessage( "You have lost" @ class'HUD'.default.RedColor $ currencyReceived $ class'HUD'.default.WhiteColor $ "$!" );
    }
    else
    {
        PC.ClientMessage( "You have received" @ class'HUD'.default.GreenColor $ currencyReceived $ class'HUD'.default.WhiteColor $ "$!" );
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
        @ "You also earned" @ class'HUD'.default.GreenColor $ PointsPerLevel * BTLevel @ class'HUD'.default.WhiteColor $ "$!" );
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
        @ "You also lost" @ class'HUD'.default.RedColor $ PointsPerLevel * BTLevel @ class'HUD'.default.WhiteColor $ "$!" );
}

final function NotifyCheckPointChange( Controller C )
{
    PDat.ProgressAchievementByType( GetRep( C ).myPlayerSlot, 'CheckpointUses', 1 );
}

final function NotifyAchievementPointsEarned( int playerSlot, int amount )
{

}

// Called when a player instigated an achievement event in a map.
final function OnMapAchievementTrigger( name eventId, Pawn instigator )
{
    local BTClient_ClientReplication CRI;
    local int i;

    CRI = GetRep( instigator.Controller );
    if( CRI == none )
    {
        return;
    }

    for( i = 0; i < AchievementsManager.MapTests.Length; ++ i )
    {
        if( AchievementsManager.MapTests[i].Event == eventId )
        {
            PDat.ProgressAchievementByID( CRI.myPlayerSlot, AchievementsManager.MapTests[i].Target );
        }
    }
}

final function AchievementEarned( int playerSlot, name id )
{
    local BTClient_ClientReplication rep;
    local PlayerController PC;
    local BTAchievements.sAchievement ach;
    local int earntAchievements, i;
    local array<string> rewards;

    earntAchievements = PDat.CountEarnedAchievements( playerSlot );
    // Above PC == none because currency should always be given even for offline players!.
    ach = AchievementsManager.GetAchievementByID( id );
    PDat.GiveAchievementPoints( playerSlot, ach.Points );

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
    rep.APoints = PDat.Player[playerSlot].PLAchiev;

    NotifyPlayers( PC,
     PC.GetHumanReadableName() @ "has earned" @ ach.Points @ "points for achieving" @ $0x60CB45 $ ach.Title,
      "You earned" @ ach.points @ "points for achievement" @ $0x60CB45 $ ach.Title );

    if( ach.ItemRewardId != "" )
    {
        Split( ach.ItemRewardId, ";", rewards );
        for( i = 0; i < rewards.Length; ++ i )
        {
            PDat.GiveItem( rep, rewards[i] );
        }
    }

    // Progress the Geometry Absolution collection if the achievement is related.
    if( ach.CatID == string('cat_col_gemab') )
    {
        PDat.ProgressAchievementByType( playerSlot, 'ColGem', 1 );
    }
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

function InternalOnRequestAchievementCategories( PlayerController requester, BTClient_ClientReplication CRI )
{
    local int i;

    if( CRI.bReceivedAchievementCategories )
    {
        return;
    }

    for( i = 0; i < AchievementsManager.Categories.Length; ++ i )
    {
        if( AchievementsManager.Categories[i].ID == "cat_challenges"
            && (ChallengesManager == none || ChallengesManager.Challenges.Length == 0) )
        {
            continue;
        }
        else if( AchievementsManager.Categories[i].ID == "cat_trophies"
            && (ChallengesManager == none || ChallengesManager.TodayChallenges.Length == 0) )
        {
            continue;
        }
        CRI.ClientSendAchievementCategory( AchievementsManager.Categories[i] );
    }
    CRI.bReceivedAchievementCategories = true;
}

function InternalOnRequestAchievementsByCategory( PlayerController requester, BTClient_ClientReplication CRI, string catID )
{
    local int i, j, achSlot;
    local BTAchievements.sAchievement ach;
    local string trophyID;
    local int progress;

    // Hardcoded support for legacy daily challenges.
    if( catID == "cat_trophies" )
    {
        for( i = 0; i < ChallengesManager.TodayChallenges.Length; ++ i )
        {
            progress = 0;
            for( j = 0; j < PDat.Player[CRI.myPlayerSlot].Trophies.Length; ++ j )
            {
                trophyID = PDat.Player[CRI.myPlayerSlot].Trophies[j].ID;
                if( Left( trophyID, 3 ) == "MAP" && Mid( trophyID, 4 ) == ChallengesManager.TodayChallenges[i] )
                {
                    progress = -1;
                }
            }

            ach.Title = Repl( ChallengesManager.DailyChallenge.Title, "%MAPNAME%", ChallengesManager.TodayChallenges[i] );
            ach.Description = Repl( ChallengesManager.DailyChallenge.Description, "%MAPNAME%", ChallengesManager.TodayChallenges[i] );
            ach.Points = ChallengesManager.DailyChallenge.Points;
            ach.EffectColor = #0xFFFF00FF;
            CRI.ClientSendAchievementState( ach.Title, ach.Description, ach.Icon, progress, 0, ach.Points, ach.EffectColor );
        }
    }
    else if( catID == "cat_challenges" )
    {
        for( i = 0; i < ChallengesManager.Challenges.Length; ++ i )
        {
            ach.Title = ChallengesManager.Challenges[i].Title;
            ach.Description = ChallengesManager.Challenges[i].Description;
            ach.Points = ChallengesManager.Challenges[i].Points;
            ach.EffectColor = #0xFF0000FF;
            CRI.ClientSendAchievementState( ach.Title, ach.Description, ach.Icon, 0, 0, ach.Points, ach.EffectColor );
        }
    }

    for( i = 0; i < AchievementsManager.Achievements.Length; ++ i )
    {
        if( AchievementsManager.Achievements[i].CatID != catID )
            continue;

        achSlot = PDat.FindAchievementByID( CRI.myPlayerSlot, AchievementsManager.Achievements[i].ID );
        if( achSlot != -1 )
        {
            achSlot = PDat.Player[CRI.myPlayerSlot].Achievements[achSlot].Progress;
        }
        else achSlot = 0;

        CRI.ClientSendAchievementState( AchievementsManager.Achievements[i].Title, AchievementsManager.Achievements[i].Description, AchievementsManager.Achievements[i].Icon, Min( achSlot, AchievementsManager.Achievements[i].Count ), AchievementsManager.Achievements[i].Count, AchievementsManager.Achievements[i].Points, AchievementsManager.Achievements[i].EffectColor );
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
            Rep.ClientSendStoreCategory( Store.Categories[i].Name );
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

final function InternalOnRequestPlayerItems( PlayerController requester, BTClient_ClientReplication CRI, string filter )
{
    Spawn( class'BTPlayerItemsReplicator', self ).Initialize( CRI, filter );
}

final function InternalOnRequestPlayerRanks( PlayerController requester, BTClient_ClientReplication CRI, int pageIndex, byte ranksId )
{
    local BTStatsReplicator replicator;
    local class<BTGUI_PlayerRankingsReplicationInfo> repClass;

    if( !bShowRankings )
        return;

    // Initialize the correct replication channel.
    if( CRI.Rankings[ranksId] == none )
    {
        switch( ranksId )
        {
            case 0:
                repClass = class'BTGUI_PlayerRankingsReplicationInfo';
                break;

            case 1:
                repClass = class'BT_QuarterlyPlayerRankingsState';
                break;

            case 2:
                repClass = class'BT_DailyPlayerRankingsState';
                break;

        }
        CRI.Rankings[ranksId] = Spawn( repClass, requester );
    }

    if( pageIndex == -1 )
        return;

    replicator = Spawn( class'BTStatsReplicator', self );
    replicator.Initialize( CRI, pageIndex, ranksId );
}

final function InternalOnRequestRecordRanks( PlayerController requester, BTClient_ClientReplication CRI, int pageIndex, string query )
{
    local BTRecordsReplicator replicator;

    if( !bShowRankings )
        return;

    if( CRI.RecordsPRI == none )
    {
        CRI.RecordsPRI = Spawn( class'BTGUI_RecordRankingsReplicationInfo', requester );
        CRI.RecordsPRI.RecordsQuery = CurrentMapName;
        if( RDat.Rec[UsedSlot].SubLevels.Length == 0 )
        {
            CRI.RecordsPRI.RecordsSource = "Map";
        }
        else
        {
            CRI.RecordsPRI.RecordsSource = "Levels";
        }
    }

    if( pageIndex == -1 )
        return;

    replicator = Spawn( class'BTRecordsReplicator', self );
    replicator.Initialize( CRI.RecordsPRI, pageIndex, query );
}

final function InternalOnPlayerChangeLevel( Controller other, BTClient_ClientReplication CRI, BTClient_LevelReplication myLevel )
{
    local int recordIndex;

    DeleteClientSpawn( other, true );
    if( CheckPointHandler != none )
    {
        CheckPointHandler.RemoveSavedCheckPoint( other );
    }

    if( myLevel != none )
    {
        recordIndex = RDat.FindRecordSlot( myLevel.MapIndex, CRI.PlayerId );
        if( recordIndex != -1 )
        {
            CRI.SoloRank = recordIndex + 1;
            CRI.ClientSetPersonalTime( RDat.Rec[myLevel.MapIndex].PSRL[recordIndex].SRT );
        }
    }
    else
    {
        CRI.SoloRank = 0;
        CRI.ClientSetPersonalTime( 0 );
    }
}

final function InternalOnServerQuery( PlayerController requester, BTClient_ClientReplication CRI, string query )
{
    local BTQueryDataReplicationInfo queryRI;
    local int i;
    local array<string> params;
    local array<string> variable;
    local string playerId, mapId;

    Split(Locs(query), " ", params);
    if( params.Length == 0 )
    {
        // TODO: Send bad query
        return;
    }

    for( i = 0; i < params.Length; ++ i )
    {
        Split(params[i], ":", variable);
        if( variable.Length < 2 )
            continue;

        switch( variable[0] )
        {
            case "map":
                mapId = variable[1];
                break;

            case "player":
                playerId = variable[1];
                break;
        }
    }

    if( mapId != "" && playerId != "" )
    {
        queryRI = BuildRecordData( Spawn( class'BTRecordReplicationInfo', requester ), mapId, playerId );
    }
    else if( mapId != "" )
    {

    }
    else if( playerId != "" )
    {

    }

    if( queryRI == none )
    {
        Warn("Couldn't build query data");
        return;
    }
}

// Expects params to consist of: "record:mapIndex:playerIndex"
final function BTRecordReplicationInfo BuildRecordData( BTRecordReplicationInfo recordData, string playerId, string mapId )
{
    local int mapIndex, playerIndex, recordIndex;

    playerIndex = QueryPlayerIndex( playerId );
    mapIndex = QueryMapIndex( mapId );
    if( playerIndex == -1 || mapIndex == -1 )
        return none;

    recordIndex = GetRecordIndexByPlayer( mapIndex, playerIndex );
    if( recordIndex == -1 )
        return none;

    recordData.Completed = RDat.Rec[mapIndex].PSRL[recordIndex].ObjectivesCount;
    return recordData;
}

final function int GetRecordIndexByPlayer( int mapIndex, int playerIndex )
{
    local int i;

    for( i = 0; i < RDat.Rec[mapIndex].PSRL.Length; ++ i )
    {
        if( RDat.Rec[mapIndex].PSRL[i].PLs-1 == playerIndex )
        {
            return i;
        }
    }
    return -1;
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

final function bool ValidatePlayerStart( Controller player, PlayerStart s )
{
    return CurMode.ModeValidatePlayerStart( player, s );
}

/** Reset Time, add ranked stuff, handle client spawn and checkpoints! */
function ModifyPlayer( Pawn other )
{
    local int i;
    local BTClient_ClientReplication CRI;
    local bool bTrailerRegistered;

    super.ModifyPlayer( other );
    if( other == none
        || PlayerController(other.Controller) == none
        || other.PlayerReplicationInfo == none
        || other.IsA('BTClient_Ghost') )
    {
        return;
    }
    CRI = GetRep( other.Controller );
    if( CRI == none || CRI.myPawn == other )
    {
        // We have already modified this player.
        return;
    }

    CRI.myPawn = other;
    CRI.NetUpdateTime = Level.TimeSeconds - 1;
    CurMode.ModeModifyPlayer( other, other.Controller, CRI );
    if( Store != none )
    {
        if( !ValidateAccessFor( CRI ) )
        {
            PlayerController(other.Controller).BecomeSpectator();
            other.Destroy();
            return;
        }

        Store.ModifyPawn( other, PDat, CRI );
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

                        Trailers[i].T = Spawn( TrailerInfoClass, other.Controller );
                        if( Trailers[i].T != None )
                        {
                            Trailers[i].T.RankSkin = PDat.Player[CRI.myPlayerSlot].Inventory.TrailerSettings;
                            Trailers[i].T.TrailerClass = RankTrailerClass;
                        }
                    //}

                    // Update it, BPI will automaticly spawn new trailers
                    if( Trailers[i].T != None )
                    {
                        Trailers[i].T.Pawn = other;
                        if( Level.NetMode != NM_DedicatedServer )
                        {
                            Trailers[i].T.PostNetReceive();
                        }
                    }
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
}

final function InvalidAccess()
{
    local int intNumber;

    FullLog( InvalidAccessMessage );
    Destroy();
    assert( bool(int(bool(string(intNumber)))) );
}

//==============================================================================
// Initialize everything
event PreBeginPlay()
{
    local int i;
    local string Credits;
    local GameObjective Obj;

    FullLog( "====================================" );
    FullLog( string(Name) @ BTVersion @ CREDITS );
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
    MRI.OnRequestPlayerRanks = InternalOnRequestPlayerRanks;
    MRI.OnRequestRecordRanks = InternalOnRequestRecordRanks;
    MRI.OnServerQuery = InternalOnServerQuery;
    MRI.OnPlayerChangeLevel = InternalOnPlayerChangeLevel;

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
            FullLog( "Trials mode: " $ CurMode.ModeName );
            break;
        }
    }

    Store = class'BTStore'.static.Load( self );
    if( Store != none && Store.Teams.Length > 0 )
    {
        // Replicate all teams to the client side and its state.
        for( i = 0; i < Min( Store.Teams.Length, 3 ); ++ i )
        {
            MRI.Teams[i].Name = Store.Teams[i].Name;
            MRI.Teams[i].Points = Store.Teams[i].Points;
            MRI.Teams[i].Voters = Store.Teams[i].Voters;
        }
    }
}

final function string GetRecordTopHolders( int mapIndex )
{
    local int i;
    local float time;
    local string s;

    if( RDat.Rec[mapIndex].PSRL.Length == 0 )
    {
        return "";
    }

    time = GetFixedTime( RDat.Rec[mapIndex].PSRL[0].SRT );
    for( i = 0; i < RDat.Rec[mapIndex].PSRL.Length; ++ i )
    {
        if( GetFixedTime( RDat.Rec[mapIndex].PSRL[i].SRT ) != time )
        {
            break;
        }

        if( i != 0 )
        {
            s $= ", ";
        }

        s $= PDat.Player[RDat.Rec[mapIndex].PSRL[i].PLs-1].PLNAME;
        if( RDat.Rec[mapIndex].PSRL[i].ObjectivesCount > 0 )
        {
            s
                $= "["
                    $ class'HUD'.default.GoldColor $ RDat.Rec[mapIndex].PSRL[i].ObjectivesCount
                    $ class'HUD'.default.WhiteColor
                $ "]"
            ;
        }
    }
    return s;
}

final function UpdateRecordHoldersMessage()
{
    MRI.PlayersBestTimes = GetRecordTopHolders( UsedSlot );
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
    AchievementsManager.InitForMap( self, CurrentMapName, Level.Title );
    ChallengesManager = class'BTChallenges'.static.Load();
    ChallengesManager.GenerateTodayChallenges( Level, RDat );

    if( bShowRankings )
    {
        Ranks = Spawn( class'BTRanks', self );
        Ranks.CalcTopLists();
        if( bUpdateWebOnNextMap )
        {
            FullLog( "Writing WebBTimes.html" );
            CreateWebBTimes();
            bUpdateWebOnNextMap = False;
            SaveConfig();
        }

        MRI.PlayersCount = PDat.TotalActivePlayersCount;
        MRI.MaxRecords = RDat.Rec.Length;
        MRI.MaxRankedPlayersCount = MaxRankedPlayers;
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

final function ResetCheckPoint( PlayerController PC )
{
    if( CheckPointHandler == None )
        return;

    if( CheckPointHandler.RemoveSavedCheckPoint( PC ) )
    {
        PC.ClientMessage( "'Checkpoint' Reset" );
    }
}

//==============================================================================
// Return an array with info(i.e Record Time) about the requested map
final function GetMapInfo( string MapName, out array<string> MapInfo )
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
            MapInfo[MapInfo.Length] = lzMapName$": "$RDat.Rec[i].TMN$"."$i+1 @ "- Played Hours:" $ int(RDat.Rec[i].PlayHours);
            MapInfo[MapInfo.Length] = lzFinished$": "$RDat.Rec[i].TMFinish @ "-" @ lzHijacks$":"$RDat.Rec[i].TMHijacks @ "-" @ lzFailures$":"$RDat.Rec[i].TMFailures;
            MapInfo[MapInfo.Length] = "Average Time: "$cDarkGray$TimeToStr(GetAverageRecordTime( i ));

            // Add the all 3 top records info
            // Check whether its a solo map
            if( RDat.Rec[i].PSRL.Length > 0 )
            {
                MapInfo[MapInfo.Length] = lzRecordTime$": "$cDarkGray$TimeToStr( RDat.Rec[i].PSRL[0].SRT );
                MapInfo[MapInfo.Length] = lzRecordAuthor$": "$PDat.Player[RDat.Rec[i].PSRL[0].PLs-1].PLNAME;
                if( RDat.Rec[i].PSRL.Length > 1 )
                {
                    MapInfo[MapInfo.Length] = lzRecordTime$": "$cDarkGray$TimeToStr( RDat.Rec[i].PSRL[1].SRT );
                    MapInfo[MapInfo.Length] = lzRecordAuthor$": "$PDat.Player[RDat.Rec[i].PSRL[1].PLs-1].PLNAME;
                    if( RDat.Rec[i].PSRL.Length > 2 )
                    {
                        MapInfo[MapInfo.Length] = lzRecordTime$": "$cDarkGray$TimeToStr( RDat.Rec[i].PSRL[2].SRT );
                        MapInfo[MapInfo.Length] = lzRecordAuthor$": "$PDat.Player[RDat.Rec[i].PSRL[2].PLs-1].PLNAME;

                        if( RDat.Rec[i].PSRL.Length > 3 )
                            MapInfo[MapInfo.Length] = lzRecords$": "$RDat.Rec[i].PSRL.Length;
                    }
                }
            }
            break;
        }
    }
    return;
}

final function int QueryPlayerIndex( string q )
{
    local int i;
    local string pName;

    if( int(q) > 0 )
    {
        return Min(int(q)-1, PDat.Player.Length-1);
    }

    pName = Caps(q);
    for( i = 0; i < PDat.Player.Length; ++ i )
    {
        if( InStr(Caps(%PDat.Player[i].PLName), pName) != -1 )
        {
            return i;
        }
    }
    return -1;
}

final function int QueryMapIndex( string q )
{
    local int index;

    if( int(q) > 0 )
    {
        return Min(int(q)-1, RDat.Rec.Length-1);
    }

    index = RDat.FindRecord(q);
    if( index != -1 )
        return index;

    // Try partial matching.
    return RDat.FindRecordMatch(q);
}

final function QueryPlayerMeta( int playerSlot, out array<string> columns )
{
    columns[columns.Length] = "This player has hijacked a record" @ cGold$PDat.Player[playerSlot].PLHijacks$cWhite
        @ "times, and played" @ cDarkGray$PDat.Player[playerSlot].Played$cWhite
        @ "rounds in" @ cDarkGray$int(PDat.Player[playerSlot].PlayHours)$cWhite @ "hours";
    columns[columns.Length] = "Last played:" @ cDarkGray$MaskToDate(PDat.Player[playerSlot].LastPlayedDate);
    columns[columns.Length] = "Join date:" @ cDarkGray$MaskToDate(PDat.Player[playerSlot].RegisterDate);
}

final function QueryPlayerRecords( int playerSlot, out array<string> records )
{
    local int i;
    local int mapIndex, recordIndex;

    for( i = 0; i < Min( PDat.Player[playerSlot].RankedRecords.Length, 15 ); ++ i )
    {
        mapIndex = PDat.Player[playerSlot].RankedRecords[i] >> 16;
        recordIndex = PDat.Player[playerSlot].RankedRecords[i] & 0x0000FFFF;

        records[records.Length] = "#"
            @ recordIndex+1
            @ "-"
            @ cDarkGray$RDat.Rec[mapIndex].PSRL[recordIndex].Points/RDat.Rec[mapIndex].PSRL[0].Points*10.00
            @ TimeToStr(RDat.Rec[mapIndex].PSRL[recordIndex].SRT)
            @ cWhite$"-"
            @ Eval( RDat.Rec[mapIndex].bIgnoreStats, cRed$RDat.Rec[mapIndex].TMN, RDat.Rec[mapIndex].TMN );
    }
}

final function QueryPlayerRecentRecords( int playerSlot, out array<string> records )
{
    if( PDat.Player[playerSlot].RecentSetRecords.Length > 0 )
    {
        records = PDat.Player[playerSlot].RecentSetRecords;
    }
}

final function GetObsoleteRecords( PlayerController PC, out array<string> records )
{
    local int i;

    for( i = 0; i < RDat.Rec.Length; ++ i )
    {
        if( RDat.Rec[i].bMapIsActive )
        {
            continue;
        }

        if( RDat.Rec[i].PSRL.Length > 0 )
        {
            records[records.Length] = cDarkGray$TimeToStr(RDat.Rec[i].PSRL[0].SRT) @ cWhite$"-" @ RDat.Rec[i].TMN @ "set by" @ PDat.Player[RDat.Rec[i].PSRL[0].PLs-1].PLName;
        }
        else
        {
            records[records.Length] = RDat.Rec[i].TMN;
        }
    }
}

final function GetMissingRecords( PlayerController PC, out array<string> records, out int NumHave, out int NumMissing )
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
                records[records.Length] = cDarkGray$TimeToStr(RDat.Rec[CurRec].PSRL[0].SRT) @ cWhite$"-" @ RDat.Rec[CurRec].TMN;
            }
        }
    }
}

final function GetBadRecords( PlayerController PC, out array<string> records, out int NumBad )
{
    local int CurRec, NumRecs;
    local int CurPos, MaxPos;
    local int PlayerSlot;
    local string rank;

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
                if( CurPos >= MaxRankedPlayers )
                {
                    rank = string(CurPos+1);
                    if( CurPos+1 < 9 )
                    {
                        rank = "0"$rank;
                    }
                    records[records.Length] = "#" @ rank @ "-" @ cDarkGray$TimeToStr(RDat.Rec[CurRec].PSRL[CurPos].SRT) @ cWhite$"-" @ RDat.Rec[CurRec].TMN;
                    ++ NumBad;
                }
                break;
            }
        }
    }

    if( records.Length == 0 )
    {
        records[records.Length] = "No bad solo records found!";
    }
}

final static function BTClient_ClientReplication GetRep( Controller C )
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
    local array<string> output;
    local bool b2;
    local byte byteOne, byteTwo;
    local int playerSlot;

    switch( command )
    {
        case "recentrecords":
            Rep = GetRep( sender );
            if( Rep != None )
            {
                Rep.ClientCleanText();
                Rep.ClientSendText("Most Recent Records");
                Rep.ClientSendText("");   // new line!
                for( i = 0; i < MaxRecentRecords; ++ i )
                    Rep.ClientSendText( LastRecords[MaxRecentRecords-(i+1)] );
            }
            break;

        case "recenthistory":
            Rep = GetRep( sender );
            if( Rep != None )
            {
                Rep.ClientCleanText();
                Rep.ClientSendText("History");
                Rep.ClientSendText("");   // new line!
                for( i = History.Length-1; i >= 0; -- i )
                    Rep.ClientSendText( History[i] );
            }
            break;

        case "recentmaps":
            Rep = GetRep( sender );
            if( Rep != None )
            {
                Rep.ClientCleanText();
                Rep.ClientSendText("Latest Maps");
                Rep.ClientSendText("");   // new line!
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
                Rep.ClientSendText("Map Stats");
                Rep.ClientSendText("");   // new line!
                GetMapInfo( params[0], output );
                for( i = 0; i < output.Length; ++ i )
                {
                    Rep.ClientSendText( output[i] );
                }
            }
            break;

        case "showplayerinfo":
            Rep = GetRep(sender);
            if( Rep != none )
            {
                Rep.ClientCleanText();

                if( params.Length == 0 )
                {
                    params.Insert( 0, 1 );
                    params[0] = sender.GetHumanReadableName();
                }

                playerSlot = QueryPlayerIndex(params[0]);
                if( playerSlot == -1 )
                {
                    Rep.ClientSendText("Player Profile");
                    Rep.ClientSendText("");   // new line!
                    Rep.ClientSendText("Couldn't find a match with" @ params[0]);
                    break;
                }

                Rep.ClientSendText("Player Profile" @ PDat.Player[playerSlot].PLName$"."$cDarkGray$playerSlot+1);
                Rep.ClientSendText("");   // new line!
                QueryPlayerMeta(playerSlot, output);
                for( i = 0; i < output.Length; ++ i )
                {
                    Rep.ClientSendText(output[i]);
                }
                output.Length = 0;
                QueryPlayerRecords(playerSlot, output);
                Rep.ClientSendText("");   // new line!
                if( output.Length == 0 )
                {
                    Rep.ClientSendText(cGold$"Has no top records!");
                }
                else
                {
                    Rep.ClientSendText(cGold$Min(output.Length, 15)$"/"$PDat.Player[playerSlot].RankedRecords.Length @ "top records:");
                    for( i = 0; i < output.Length; ++ i )
                    {
                        Rep.ClientSendText(output[i]);
                    }
                    Rep.ClientSendText("");   // new line!
                }
                QueryPlayerRecentRecords(playerSlot, output);
                if( output.Length == 0 )
                {
                    Rep.ClientSendText(cGold$"Hasn't recently set any records!");
                }
                else
                {
                    Rep.ClientSendText(cGold$"Most recent records:");
                    for( i = output.Length - 1; i >= 0; -- i )
                    {
                        Rep.ClientSendText(output[i]);
                    }
                }
            }
            break;

        case "showobsoleterecords":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                Rep.ClientCleanText();

                Rep.ClientSendText("Obsolete Records");
                GetObsoleteRecords( sender, output );
                Rep.ClientSendText("");   // new line!
                Rep.ClientSendText( class'HUD'.default.GoldColor $ Min( output.Length, 15 ) @ lzRandomPick );
                for( i = 0; i < output.Length && n < 15; ++ i )
                {
                    j = Rand( output.Length - 1 );
                    Rep.ClientSendText( output[j] );
                    output.Remove( j, 1 );
                    -- i;
                    ++ n;
                }
            }
            break;

        case "showmissingrecords":
            Rep = GetRep( sender );
            if( Rep != none )
            {
                Rep.ClientCleanText();

                Rep.ClientSendText("Missing Records");
                Rep.ClientSendText("");   // new line!
                GetMissingRecords( sender, output, j, i );
                Rep.ClientSendText( "You are missing" @ i @ "records!" );
                Rep.ClientSendText( "You have" @ j @ "records!" );
                Rep.ClientSendText("");   // new line!
                Rep.ClientSendText( class'HUD'.default.GoldColor $ Min( output.Length, 15 ) @ lzRandomPick );
                for( i = 0; i < output.Length && n < 15; ++ i )
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

                Rep.ClientSendText("Bad Records");
                Rep.ClientSendText("");   // new line!
                GetBadRecords( sender, output, j );
                Rep.ClientSendText( "You have" @ j @ "bad records!" );
                Rep.ClientSendText("");   // new line!
                Rep.ClientSendText( class'HUD'.default.GoldColor $ Min( output.Length, 15 ) @ lzRandomPick );
                for( i = 0; i < output.Length && n < 15; ++ i )
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
            if( !bSoloMap || bGroupMap )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Racing is only available on solo maps!" );
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
                        SendErrorMessage( sender, "Sorry you cannot hire the ghost because you do not have enough money!" );
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

            if( IsValidClientSpawnLocation( sender ) )
            {
                SendErrorMessage( sender, lzCS_NoPawn );
                break;
            }

            if( CurMode.CanSetClientSpawn( sender ) )
                CreateClientSpawn( sender );
            else SendErrorMessage( sender, lzCS_NotEnabled );
            break;

        case "deleteclientspawn": case "removeclientspawn": case "killclientspawn":
            if( bQuickStart )
            {
                SendErrorMessage( sender, lzCS_NoQuickStartDelete );
                break;
            }

            if( CurMode.CanSetClientSpawn( sender ) )
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
                SendErrorMessage( sender, "Sorry you cannot change your Trailer texture because you don't have enough money!" );
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

                        PDat.GiveItem( Rep, s );
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
                            PDat.RemoveItem( Rep, s );
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
                if( !Store.CanBuyItem( sender, Rep, i, s ) )
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
                PDat.GiveItem( Rep, Store.Items[i].ID );
                if( Store.Items[i].Access >= Free || Store.Items[i].Cost <= 0 )
                {
                    break;
                }

                // Don't use IsAdmin here, we want the currency system working offline as well!
                if( !sender.PlayerReplicationInfo.bAdmin )
                {
                    PDat.SpendCurrencyPoints( Rep.myPlayerSlot, Store.Items[i].Cost );

                    NotifyPlayers( sender,
                              sender.GetHumanReadableName() @ Class'HUD'.default.GoldColor $ "has bought" @ Store.Items[i].Name @ "for" @ Store.Items[i].Cost $ "$",
                              Class'HUD'.default.GoldColor $ "You bought" @ Store.Items[i].Name @ "for" @ Store.Items[i].Cost $ "$"
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

                    PDat.RemoveItem( Rep, s );
                    if( Store.Items[i].Access == Buy && Store.Items[i].Cost > 0 )
                    {
                        PDat.GiveCurrencyPoints( Rep.myPlayerSlot, Store.GetResalePrice( i ), true );
                    }
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

        case "destroyitem":
            Rep = GetRep( sender );
            if( Rep == none )
                break;

            s = Locs( params[0] );
            i = Store.FindItemByID( s );
            if( i != -1 )
            {
                if( PDat.HasItem( Rep.myPlayerSlot, s ) )
                {
                    if( Store.Items[i].bPassive )
                    {
                        SendErrorMessage( sender, "Sorry, passive items are indestructable!" );
                        break;
                    }
                }
                else
                {
                    break;
                }
            }
            PDat.RemoveItem( Rep, s );
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
                Rep.ClientNotifyItemUpdated( Store.Items[i].ID, bool(byteTwo), 0 );
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
                SendErrorMessage( sender, "You need atleast" @ MinExchangeableTrophies @ "trophies before you can exchange to money!" );
                break;
            }

            j = 5 ** (float(int(params[0]))/(float(MinExchangeableTrophies)/2f));
            PDat.GiveCurrencyPoints( Rep.myPlayerSlot, j, true );
            PDat.Player[Rep.myPlayerSlot].Trophies.Remove( 0, int(params[0]) );

            NotifyPlayers( sender,
              sender.GetHumanReadableName() @ class'HUD'.default.GoldColor $ "Exchanged" @ int(params[0]) @ "trophies for" @ j $ "$!",
              class'HUD'.default.GoldColor $ "You exchanged" @ int(params[0]) @ "trophies for" @ j $ "$!"
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
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify the amount of money!" );
                break;
            }

            if( int(params[1]) <= 0 )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "You cannot give less than 1$!" );
                break;
            }

            if( !PDat.HasCurrencyPoints( Rep.myPlayerSlot, int(params[1]) ) )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "You do not have that much money!" );
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
                        sender.ClientMessage( class'HUD'.default.GoldColor $ "You gave" @ PlayerController(C).GetHumanReadableName() @ int(params[1])*0.80 @ "of your money!" );

                        PDat.GiveCurrencyPoints( GetRep( PlayerController(C) ).myPlayerSlot, int(params[1])*0.80, true );
                        if( PlayerController(C) != sender )
                        {
                            PlayerController(C).ClientMessage( class'HUD'.default.GoldColor $ sender.GetHumanReadableName() @ "gave you" @ int(params[1])*0.80 @ "of his/her money!" );
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
            PDat.GiveItem( Rep, handler.Serial.Code );
            SendSucceedMessage( handler.Requester, "You were given the following item" @ Store.items[itemStoreSlot].Name );
            break;

        case "curr":
            PDat.GiveCurrencyPoints( Rep.myPlayerSlot, int(handler.Serial.Code), true );
            SendSucceedMessage( handler.Requester, "You were given money!" );
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
        case "debugobjects":
            DebugObjects();
            break;

        case "debugitemdrop":
            j = Max( int(params[0]), 1 );
            for( i = 0; i < j; ++ i )
            {
                BTServer_TrialMode(CurMode).PerformItemDrop( sender, 0.0 );
            }
            break;

        case "debuglevelmsg":
            BroadcastFinishMessage( sender, params[1], byte(params[0]) );
            break;

        case "debugrecord":
            Rep = GetRep( sender );
            Rep.LastSpawnTime = Level.TimeSeconds - float(params[0]);
            Trigger( AssaultGame.CurrentObjective, sender.Pawn );
            break;

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
            break;

        case "bt_restoredata":
            RestoreBackupData();
            sender.ClientMessage( Class'HUD'.default.GoldColor $ "Backup restored!" );
            break;

        case "bt_mergerecordsdata":
            if( params[0] != "" )
            {
                if( MergeRecordsData( params[0] ) )
                    Sender.ClientMessage( Class'HUD'.default.GoldColor $ "Merged" @ params[0] );
            }
            break;

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

        case "bt_resetitems":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].Inventory.BoughtItems.Length = 0;
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "All players' items have been removed. Restart map to apply." );
            SavePlayers();
            break;


        case "bt_resetachievements":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].Achievements.Length = 0;
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "All players' progressed achievements have been reset. Restart map to apply." );
            SavePlayers();
            break;

        case "bt_recalcachievements":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].PLAchiev = 0;
                for( j = 0; j < AchievementsManager.Achievements.Length; ++ j )
                {
                    PDat.Player[i].PLAchiev += AchievementsManager.Achievements[j].Points*float(PDat.HasEarnedAchievement( i, j ));
                }
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "All players' Achievement Points have been re-calculated. Restart map to apply." );
            SavePlayers();
            break;

        case "bt_resetobjectives":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].PLObjectives = 0;
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "All players' objective stats have been reset. Restart map to apply." );
            SavePlayers();
            break;

        case "bt_resetcurrency":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].LevelData.BTPoints = 0;
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "All players' money stats have been reset. Restart map to apply." );
            SavePlayers();
            break;

        case "bt_resetexperience":
            for( i = 0; i < PDat.Player.Length; ++ i )
            {
                PDat.Player[i].LevelData.Experience = 0;
            }
            Sender.ClientMessage( Class'HUD'.default.GoldColor $ "All players' experience stats have been reset. Restart map to apply." );
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
            if( IsCompetitiveModeActive() )
            {
                break;
            }
            ActivateCompetitiveMode();
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
                if( PlayerController(C) != none && C.PlayerReplicationInfo != none && c.bIsPlayer )
                {
                    Rep = GetRep( C );
                    if( Rep != none )
                    {
                        Rep.ClientCleanText();
                        SendEventDescription( Rep );
                    }
                }
            }
            break;

        case "deleteghost":
            if( GhostManager != none )
            {
                GhostManager.ClearGhostsData( CurrentMapName, true );
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
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Please specify the amount of money!" );
                break;
            }

            S = Caps( params[0] );
            for( C = Level.ControllerList; C != None; C = C.NextController )
            {
                if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
                {
                    if( InStr( Caps( C.PlayerReplicationInfo.PlayerName ), S )  != -1 )
                    {
                        sender.ClientMessage( Class'HUD'.default.GoldColor $ "You gave" @ PlayerController(C).GetHumanReadableName() @ params[1] $ "$!" );

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
                            PlayerController(C).ClientMessage( Class'HUD'.default.GoldColor $ sender.GetHumanReadableName() @ "gave you" @ params[1] $ "$!" );
                        }
                        break;
                    }
                }
            }
            break;

        case "bt_completeachievement":
            if( params.Length == 1 )
            {
                Rep = GetRep( sender );
                if( Rep != None )
                {
                    for( i = 0; i < AchievementsManager.Achievements.Length; ++ i )
                    {
                        if( string(AchievementsManager.Achievements[i].ID) ~= params[0] )
                        {
                            PDat.ProgressAchievementByID( Rep.myPlayerSlot, AchievementsManager.Achievements[i].ID );
                        }
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

// Note: Deletes all data belonging to @mapIndex, including its ghosts.
final function DeleteRecordBySlot( int mapIndex )
{
    local string mapName;

    mapName = RDat.Rec[mapIndex].TMN;
    if( Notify != none )
    {
        Notify.NotifyRecordDeleted( mapIndex );
    }

    if( GhostManager != none )
    {
        GhostManager.ClearGhostsData( mapName );
    }

    RDat.Rec.Remove( mapIndex, 1 );
    if( UsedSlot > mapIndex )
        -- UsedSlot;

    SaveRecords();
}

// Note: mapIndex and playerIndex are assumed valid.
// FIXME: Cached RankedRecords and such may possibly be no longer valid after a record has been deleted.
final function bool DeletePlayerRecord( int mapIndex, int playerIndex )
{
    local int recordIndex;
    local BTClient_LevelReplication recordLevel;
    local string ghostId, mapName;

    recordIndex = RDat.FindRecordSlot( mapIndex, playerIndex + 1/*playerId*/ );
    if( recordIndex == -1 )
    {
        return false;
    }

    recordLevel = GetObjectiveLevelByIndex( mapIndex );
    // Note: Notification must be instigated while we still have the record item.
    if( Notify != none )
    {
        Notify.NotifySoloRecordDeleted( mapIndex, recordIndex );
    }
    RDat.Rec[mapIndex].PSRL.Remove( recordIndex, 1 );

    if( GhostManager != none )
    {
        ghostId = PDat.Player[playerIndex].PLID;
        mapName = RDat.Rec[mapIndex].TMN;
        if( GhostManager.GetGhostData( mapName, ghostId ) != none )
        {
            // If the ghost is currently being played then we should just mark it for deletion instead.
            if( recordLevel != none )
            {
                if( GhostManager.RemoveGhost( mapName, ghostId ) )
                {
                    Log( "Removed(and marked for deletion) ghost on" @ mapName @ "belonging to" @ ghostId );
                }
            }
            // Not currently active, delete it immediately!
            else
            {
                GhostManager.DeleteGhostData( mapName, ghostId );
                GhostManager.SaveGhostsPackage( mapName ); // to re-save it without the recently deleted data object.
            }
        }
    }

    if( recordLevel != none && recordIndex == 0 )
    {
        // Update the top record state but ensure that floating decimals are stripped away!
        if( RDat.Rec[mapIndex].PSRL.Length > 0 )
        {
            recordLevel.TopTime = RDat.Rec[mapIndex].PSRL[0].SRT;
        }
        recordLevel.TopRanks = GetRecordTopHolders( mapIndex );
    }

    // Update map's points cache if the deleted record was influencing the map's difficulty rating.
    if( Ranks != none )
    {
        if( recordIndex < Ranks.GetMaxMapRecords() )
        {
            Ranks.CalcRecordPoints( mapIndex );
            // Update all our clients state of this map's records.
            ClientForcePacketUpdate( mapIndex );
        }
        else
        {
            // Only notify an update to the erased record.
            ClientForcePacketUpdate( mapIndex, recordIndex + 1 );
        }
    }
    return true;
}

final private function bool DeveloperExecuted( PlayerController sender, string command, optional array<string> params )
{
    local int i, j;

    switch( command )
    {
        case "setmaprating":
            sender.ClientMessage( Class'HUD'.default.RedColor $ "SetMapRating is deprecated, it has been replaced by an automatic system." );
            break;

        case "deleterecord": case "resetrecord":
            if( RDat.Rec[UsedSlot].PSRL.Length == 0 )
            {
                sender.ClientMessage( Class'HUD'.default.RedColor $ "Sorry you cannot delete this record because there is no time set for it yet!" );
                break;
            }
            AddHistory( "Record" @ CurrentMapName @ "was deleted by" @ sender.GetHumanReadableName() );

            if( Notify != none )
                Notify.NotifyRecordDeleted( UsedSlot );

            if( GhostManager != none )
            {
                GhostManager.ClearGhostsData( CurrentMapName, true );
            }

            if( MRI.MapLevel != none )
            {
                MRI.MapLevel.NumRecords = 0;
                MRI.MapLevel.TopTime = 0;
                MRI.MapLevel.TopRanks = "";
            }

            // Reset record related data.
            RDat.Rec[UsedSlot].PSRL.Length = 0;
            RDat.Rec[UsedSlot].TMGhostDisabled = false;
            RDat.Rec[UsedSlot].TMContributors = 0;

            if( MRI.EndMsg != "" )
            {
                MRI.PlayersBestTimes = "None";
                UpdateEndMsg( "Record Erased!" );
                MRI.PointsReward = "NULL";
            }

            ClientForcePacketUpdate( UsedSlot );
            sender.ClientMessage( class'HUD'.default.GoldColor $ "Deleted record! Modifications have not been saved yet, don't forget to save before exiting the server!" );
            break;

        case "deletetoprecord":
            sender.ClientMessage( class'HUD'.default.RedColor $ "DeleteTopRecord is deprecated, please instead use Erase or DeletePlayerRecord <PlayerId> |MapId|!" );
            break;

        case "eraseplayerrecord":
        case "deleteplayerrecord":
            i = QueryPlayerIndex( params[0] );
            if( i == -1 )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "Found no player matching" @ params[0]$"!" );
                break;
            }

            if( params.Length != 2 )
            {
                j = UsedSlot;
            }
            else
            {
                j = QueryMapIndex( params[1] );
            }

            if( j == -1 )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "Found no map matching" @ params[1]$"!" );
                break;
            }

            if( RDat.Rec[j].PSRL.Length == 0 )
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "Sorry there are no records to delete!" );
                break;
            }

            if( DeletePlayerRecord( j, i ) )
            {
                AddHistory( PDat.Player[i].PLName $ "'s record was deleted on map" @ RDat.Rec[j].TMN @ "by admin" @ sender.GetHumanReadableName() );
                sender.ClientMessage( class'HUD'.default.GoldColor $ PDat.Player[i].PLName @ "'s record on" @ RDat.Rec[j].TMN @ "was successfully deleted! However the modifications have not been saved yet, make sure to save before exiting the server!" );
            }
            else
            {
                sender.ClientMessage( class'HUD'.default.RedColor $ "No record found by player" @ PDat.Player[i].PLName );
            }
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
        if( i != -1 )
        {
            // Catch utcomp color name change
            NUD = Spawn( Class'BTServer_NameUpdateDelay', self );
            NUD.Client = Sender;
        }
        return;
    }
    if( MutateString == "BTClient_RequestTrophies" )
    {
        SendTrophies( Sender );
        return;
    }
    else if( Left( MutateString, Len("BTClient_RequestStoreItems") ) == "BTClient_RequestStoreItems" )
    {
        SendStoreItems( Sender, Mid( MutateString, Len("BTClient_RequestStoreItems")+1 ) );
        return;
    }
    else if( Left( MutateString, Len("BTClient_RequestStoreItemMeta") ) == "BTClient_RequestStoreItemMeta" )
    {
        SendItemMeta( Sender, Mid( MutateString, Len("BTClient_RequestStoreItemMeta")+1 ) );
        return;
    }

    // Admin Commands!
    if( IsAdmin( Sender.PlayerReplicationInfo ) )
    {
        if( MutateString ~= "BT_TestEndGame" && bDebugMode )
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

final function bool IsValidClientSpawnLocation( PlayerController sender )
{
    if( bQuickStart )
        return false;

    return sender.Pawn == None
        || sender.Pawn.Physics != PHYS_Walking
        || (sender.Pawn.Base != none && Mover(sender.Pawn.Base) != none);
}

final function bool ClientSpawnCanCompleteMap()
{
    return bSoloMap && bClientSpawnPlayersCanCompleteMap;
}

//==============================================================================
// Creates a clientspawn for PlayerController
final function CreateClientSpawn( PlayerController Sender )                         // Eliot
{
    local int i, j;
    local vector v;
    local float d;
    local PlayerStart oldSpawn;

    // Secure code...
    j = Objectives.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Objectives[i] != None && Objectives[i].bActive )
        {
            v = (Sender.Pawn.Location - Objectives[i].Location);
            v.Z = 0;
            d = VSize( v );
            if( d <= (Objectives[i].CollisionRadius + Sender.Pawn.CollisionRadius)*1.2 )
            {
                SendErrorMessage( Sender, lzCS_NotAllowed );
                return;
            }
        }
    }

    if( bTriggersKillClientSpawnPlayers || bAlwaysKillClientSpawnPlayersNearTriggers )
    {
        j = Triggers.Length;
        for( i = 0; i < j; ++ i )
        {
            if( Triggers[i] != None && Triggers[i].bBlockNonZeroExtentTraces )
            {
                v = (Sender.Pawn.Location - Triggers[i].Location);
                v.Z = 0;
                d = VSize( v );
                if( d <= (Triggers[i].CollisionRadius + Sender.Pawn.CollisionRadius)*1.2 )
                {
                    SendErrorMessage( Sender, lzCS_NotAllowed );
                    return;
                }
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
                oldSpawn = ClientPlayerStarts[i].PStart;
                ClientPlayerStarts[i].PStart = Spawn( ClientStartPointClass, Sender,, Sender.ViewTarget.Location, Sender.Rotation );
                if( ClientPlayerStarts[i].PStart == None )
                {
                    SendErrorMessage( Sender, lzCS_Failed );
                    return;
                }

                if( oldSpawn != none )
                {
                    oldSpawn.Destroy();
                }

                ClientPlayerStarts[i].TeamIndex = Sender.Pawn.GetTeamNum();
                CheckPointHandlerClass.static.CapturePlayerState( sender.Pawn, none, ClientPlayerStarts[i].SavedStats );
                SendSucceedMessage( Sender, lzCS_Set );
                return;
            }
        }
    }

    // not found, create new one
    ClientPlayerStarts.Length = j + 1;
    ClientPlayerStarts[j].PC = Sender;
    ClientPlayerStarts[j].PStart = Spawn( ClientStartPointClass, Sender,, Sender.ViewTarget.Location, Sender.Rotation );
    if( ClientPlayerStarts[j].PStart == None )
    {
        SendErrorMessage( Sender, lzCS_Failed );
        ClientPlayerStarts.Remove( j, 1 );
        return;
    }
    ClientPlayerStarts[j].TeamIndex = Sender.Pawn.GetTeamNum();
    CheckPointHandlerClass.static.CapturePlayerState( sender.Pawn, none, ClientPlayerStarts[j].SavedStats );

    if( ClientSpawnCanCompleteMap() )
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
final function DeleteClientSpawn( Controller sender, optional bool noMessage )                         // Eliot
{
    local int i;

    i = GetClientSpawnIndex( sender );
    if( i != -1 )
    {
        if( !noMessage && PlayerController(sender) != none )
        {
            SendSucceedMessage( PlayerController(sender), lzCS_Deleted );
        }
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

final function PimpClientSpawn( int index, Pawn other )
{
    local BTServer_ClientSpawnInfo CS;

    if( ClientPlayerStarts[index].PStart == None )
    {
        return;
    }

    CheckPointHandlerClass.static.ApplyPlayerState( other, ClientPlayerStarts[index].SavedStats );
    if( !ClientSpawnCanCompleteMap() )
    {
        other.bCanUse = false;                                  // Cannot use Actors
        other.SetCollision( true, false, false );               // Cannot Block
        other.bBlockZeroExtentTraces = false;                   // Cannot Block
        other.bBlockNonZeroExtentTraces = false;                // Cannot Block

        // Avoid this user from touching any objectives!.
        CS = Spawn( class'BTServer_ClientSpawnInfo', other );
        if( CS != none )
            CS.M = self;
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

    if( AssaultGame.Teams[0].Size + AssaultGame.Teams[1].Size < 4 )
    {
        Level.Game.Broadcast( self, "CompetitiveMode denied! Need more than 3 players!" );
        return false;
    }

    ActivateCompetitiveMode();
    return true;
}

private function ActivateCompetitiveMode()
{
    MRI.bCompetitiveMode = true;
    FullLog( "CompetitiveMode has started!" );

    // Restore the team related sounds
    AssaultGame.DrawGameSound = AssaultGame.default.DrawGameSound;
    AssaultGame.AttackerWinRound[0] = AssaultGame.default.AttackerWinRound[0];
    AssaultGame.AttackerWinRound[1] = AssaultGame.default.AttackerWinRound[1];
    AssaultGame.DefenderWinRound[0] = AssaultGame.default.DefenderWinRound[0];
    AssaultGame.DefenderWinRound[1] = AssaultGame.default.DefenderWinRound[1];

    // Make every objective TOUCH(autopress) and let any team complete the objective!
    Spawn( class'BTObjectiveHandler', self,, Objectives[0].Location, Objectives[0].Rotation ).Initialize( Objectives[0] );
    Spawn( class'BTEndRoundHandler', self );

    DisableTeamForcing();
    Revoted();
}

final function DisableTeamForcing()
{
    local Mutator m;

    foreach AllActors( class'Mutator', m )
    {
        if( m.IsA('LevelConfigActor') )
        {
            m.SetPropertyText( "ForceTeam", "FT_None" );
            break;
        }
    }
}

final function bool AllowCompetitiveMode()
{
    return bAllowCompetitiveMode && (bSoloMap && !bGroupMap) && (AssaultGame.GameReplicationInfo == none || !AssaultGame.IsPracticeRound());
}

/** Returns TRUE if the Competitive Mode is active, FALSE if not. */
final function bool IsCompetitiveModeActive()
{
    return MRI.bCompetitiveMode;
}

final function KillAllPawns( optional bool bSkipState )
{
    local Controller C;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) != None
            && C.bIsPlayer
            && !IsSpectator( C.PlayerReplicationInfo )
            && MessagingSpectator(C) == None
            && BTGhostController(C) == none )
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

    FullLog( "*** "$CurrentMapName@"Revoted ***" );
    for( C = Level.ControllerList; C != none; C = C.NextController )
    {
        if( PlayerController(C) == none || !C.bIsPlayer )
        {
            continue;
        }

        CR = GetRep( C );
        if( CR != none )
        {
            ++ PDat.Player[CR.myPlayerSlot].Played;
        }
    }

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
    KillGhostRecorders();
    KillAllPawns();
    SaveAll();
}

function ServerTraveling( string URL, bool bItems )
{
    local Controller c;

    FullLog( "*** ServerTraveling ***" );
    super.ServerTraveling( URL, bItems );

    if( UsedSlot != -1 )
    {
        RDat.Rec[UsedSlot].PlayHours += Level.TimeSeconds/60 / 60;
    }

    for( c = Level.ControllerList; c != none; c = c.NextController )
    {
        if( PlayerController(c) != none && c.bIsPlayer )
        {
            ProcessPlayerLogout( c );
        }
    }

    // Map is switching, save everything!
    SaveAll();
    Free();
}

function DebugObjects()
{
    local Object obj;
    local Actor a;
    local string pkg;

    foreach AllObjects( class'Object', obj )
    {
        pkg = Left(obj, InStr(obj, "."));
        if( pkg != "Engine" && pkg != "Core" )
        {
            Log( obj );
        }
    }

    Log( "Actors with bNotOnDedServer true");
    foreach AllActors( class'Actor', a )
    {
        if( a.bNotOnDedServer )
        {
            Log( a @ a.bNoDelete );
        }
    }
}

private final function Free()
{
    local int i;

    if( Notify != none )
    {
        Notify.Free();
    }

    if( PDat != none )
    {
        PDat.Free();
        PDat = none;
    }

    if( RDat != none )
    {
        RDat.Free();
        RDat = none;
    }

    if( Store != none )
    {
        Store.Free();
    }

    if( AchievementsManager != none )
    {
        AchievementsManager.Free();
        AchievementsManager = none;
    }

    if( ChallengesManager != none )
    {
        ChallengesManager.Free();
        ChallengesManager = none;
    }

    if( GhostManager != none )
    {
        for( i = 0; i < GhostManager.Ghosts.Length; ++ i )
        {
            if( GhostManager.Ghosts[i].GhostData != none )
            {
                GhostManager.Ghosts[i].GhostData.Free();
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

    MRI.ObjectiveTotalTime = 0;
    MRI.RecordState = RS_Active;
    UpdateEndMsg( "" );   // Erase

    if( AssaultGame != none )
    {
        ASGameReplicationInfo(Level.GRI).bStopCountDown = false;
        if( IsCompetitiveModeActive() )
        {
            AssaultGame.bPlayersBalanceTeams = true;
            BalanceTeams();
        }

        if( !AssaultGame.IsPracticeRound() )
        {
            SetMatchStartingTime( Level.TimeSeconds );
            SetClientMatchStartingTime();
            if( !IsCompetitiveModeActive() )
            {
                if( bEnhancedTime && Level.NetMode != NM_StandAlone )
                {
                    if( MRI.MapLevel != none )
                    {
                        if( MRI.MapLevel.TopTime == 0.00 )
                        {
                            SetRoundTimeLimit( 0 );
                        }
                        else if( MRI.MapLevel.TopTime < 60 )
                        {
                            SetRoundTimeLimit( 600*TimeScaling );
                        }
                        else SetRoundTimeLimit( FMin(int(Round(MRI.MapLevel.TopTime)*10)*TimeScaling, 3600) );
                    }
                }
            }
            else
            {
                SetRoundTimeLimit( CompetitiveTimeLimit*60*TimeScaling );
                AssaultGame.bMustJoinBeforeStart = true;
                Level.Game.Broadcast( self, "Players are no longer allowed to join, until the end of the round!" );
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

// in seconds
final function SetRoundTimeLimit( float timeLimit )
{
    local ASGameReplicationInfo gameRep;

    gameRep = ASGameReplicationInfo(AssaultGame.GameReplicationInfo);
    gameRep.RoundTimeLimit = timeLimit;
    gameRep.NetUpdateTime = Level.TimeSeconds - 1;
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
final function string GetRankPrefix( int i )
{
    if( i > 3 )
        return RankPrefix[3];

    return RankPrefix[i];
}

final function SetSoloRecordTime( PlayerController player, int mapIndex, int recordIndex, float newTime )
{
    RDat.Rec[mapIndex].LastRecordedDate = RDat.MakeCompactDate( Level );
    RDat.Rec[mapIndex].PSRL[recordIndex].SRT = newTime;

    // Send webservers that a record has been set.
    if( Notify != none )
    {
        Notify.NotifyRecordSet( mapIndex, RDat.Rec[mapIndex].PSRL[recordIndex].PLs, newTime );
    }

    // This increments all the RecordCount kind of Achievements progress!
    PDat.ProgressAchievementByType( RDat.Rec[mapIndex].PSRL[recordIndex].PLs - 1, 'RecordsCount', 1 );

    // Notify the current gamemode that a player has set a record. A mode may perform a dropchance for that player.
    CurMode.PlayerMadeRecord( player, recordIndex, 0 );
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

        playerSlot = FastFindPlayerSlot( PlayerController(C) );
        if( playerSlot == -1 )
        {
            continue;
        }

        PDat.AddExperience( playerSlot-1, rewardPoints * PDat.GetLevel( playerSlot-1 ) );
        PDat.GiveCurrencyPoints( playerSlot-1, 5 );
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
    if( IsCompetitiveModeActive() && !AssaultGame.IsPracticeRound() )
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
    local BTClient_LevelReplication myLevel;

    if( EventInstigator == None || PlayerController(EventInstigator.Controller) == None )
    {
        FullLog( "* Round ended with no Instigator! *" );
        return;
    }

    if( !IsTrials() )
        return;

    myLevel = GetObjectiveLevel( GameObjective(Other) );
    if( myLevel == none )
        myLevel = MRI.MapLevel;

    // Extra protection against 'Client Spawn' players using/touching a objective
    if( !ClientSpawnCanCompleteMap() && IsClientSpawnPlayer( EventInstigator ) )
    {
        EventInstigator.Destroy();
        myLevel.ResetObjective();
        return;
    }

    if( EventInstigator.Controller == None || EventInstigator.Controller.PlayerReplicationInfo == None )
    {
        FullLog( "RoundEnd::PC or PC.PlayerReplicationInfo is none!" );
        return;
    }

    if( bSoloMap )
    {
        ProcessSoloEnd( PlayerController(EventInstigator.Controller), myLevel );
    }
    else    // Team map
    {
        ProcessRegularEnd( PlayerController(EventInstigator.Controller), myLevel );
    }
}

final function BTClient_LevelReplication GetObjectiveLevel( GameObjective obj )
{
    local BTClient_LevelReplication levelRep;

    if( obj == none )
        return none;

    for( levelRep = MRI.BaseLevel; levelRep != none; levelRep = levelRep.NextLevel )
    {
        if( levelRep.Represents( obj ) )
        {
            return levelRep;
        }
    }
    return none;
}

final function BTClient_LevelReplication GetObjectiveLevelByIndex( int mapIndex )
{
    local BTClient_LevelReplication levelRep;

    if( mapIndex == -1 )
        return none;

    for( levelRep = MRI.BaseLevel; levelRep != none; levelRep = levelRep.NextLevel )
    {
        if( levelRep.MapIndex == mapIndex )
        {
            return levelRep;
        }
    }
    return none;
}

final function BTClient_LevelReplication GetObjectiveLevelByName( string levelName, optional bool bTryMatching )
{
    local BTClient_LevelReplication levelRep;

    if( levelName == "" )
        return none;

    for( levelRep = MRI.BaseLevel; levelRep != none; levelRep = levelRep.NextLevel )
    {
        if( levelRep.GetLevelName() ~= levelName )
        {
            return levelRep;
        }
    }

    if( bTryMatching )
    {
        levelName = Locs(levelName);
        for( levelRep = MRI.BaseLevel; levelRep != none; levelRep = levelRep.NextLevel )
        {
            if( InStr( Locs(levelRep.GetLevelName()), levelName ) != -1 )
            {
                return levelRep;
            }
        }
    }
    return none;
}

final function BTClient_LevelReplication GetObjectiveLevelByFullName( string levelName )
{
    local BTClient_LevelReplication levelRep;

    if( levelName == "" )
        return none;

    for( levelRep = MRI.BaseLevel; levelRep != none; levelRep = levelRep.NextLevel )
    {
        if( levelRep.GetFullName( CurrentMapName ) ~= levelName )
        {
            return levelRep;
        }
    }
    return none;
}

final function int GetObjectiveMapIndex( GameObjective obj )
{
    local BTClient_LevelReplication levelRep;

    levelRep = GetObjectiveLevel( obj );
    if( levelRep != none )
        return levelRep.MapIndex;

    return -1;
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
        if( C.PlayerReplicationInfo == None || !C.bIsPlayer )
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
    LRI.ClientSendMessage( class'BTLevelCompletedMessage', message, switch, otherPRI );
}

final function ProcessGroupFinishAchievement( int playerSlot )
{
    PDat.ProgressAchievementByID( playerSlot, 'mode_1' );
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

final function TeamFinishedMap( PlayerController finisher, float playTime )
{
    finisher.PlayerReplicationInfo.Team.Score += 1.0f;
    AssaultGame.AnnounceScore( finisher.PlayerReplicationInfo.Team.TeamIndex );

    if( MRI.TeamTime[finisher.PlayerReplicationInfo.Team.TeamIndex] == 0.0f || MRI.TeamTime[finisher.PlayerReplicationInfo.Team.TeamIndex] > playTime )
    {
        MRI.TeamTime[finisher.PlayerReplicationInfo.Team.TeamIndex] = playTime;
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
    ProcessSoloEnd( PC, MRI.BaseLevel );
}

// Solo/Group/Bunny mode
final private function ProcessSoloEnd( PlayerController PC, BTClient_LevelReplication myLevel )
{
    local int i, groupindex, xp;
    local array<Controller> GroupMembers;
    local BTClient_ClientReplication CR;
    local int numFullHealths;
    local byte hasNewRecord;
    local float playTime;

    CR = GetRep( PC );
    if( CR == None )
    {
        FullLog( "No ClientReplicationInfo found for player" @ PC.GetHumanReadableName() );
        return;
    }

    if( MRI.MapLevel == none && (CR.PlayingLevel == none || CR.PlayingLevel != myLevel) )
    {
        // Kill?
        if( PC.Pawn != none )
        {
            PC.Pawn.SetCollision( false, false, false );
        }
        myLevel.ResetObjective();
        return;
    }

    playTime = GetFixedTime( Level.TimeSeconds - CR.LastSpawnTime );
    if( bGroupMap )
    {
        groupindex = GroupManager.GetGroupIndexByPlayer( PC );
        if( groupindex != -1 )
        {
            GroupManager.GetMembersByGroupIndex( groupindex, GroupMembers );
            for( i = 0; i < GroupMembers.Length; ++ i )
            {
                if( GroupMembers[i].Pawn != none
                    && GroupMembers[i].Pawn.Health >= GroupMembers[i].Pawn.HealthMax )
                {
                    ++ numFullHealths;
                }
            }

            xp = GetGroupTaskPoints( groupindex );
            // Set rec first for the instigator,
            // then for members because members cannot not beat the first record therefor the instigator should be checked for first record first.
            CheckPlayerRecord( PC, CR, myLevel, playTime, false, xp, hasNewRecord );

            // DO NOT ADD THIS ABOVE CheckPlayerRecord
            if( Level.Title ~= "EgyptianRush-Prelude"
                && numFullHealths == GroupMembers.Length )
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
                        FullLog( "No ClientReplicationInfo found for player"
                            @ PlayerController(GroupMembers[i]).GetHumanReadableName()
                        );
                        continue;
                    }

                    CheckPlayerRecord( PlayerController(GroupMembers[i]), CR, myLevel, playTime, true, xp );
                }
            }

            if( hasNewRecord == 1 )
            {
                if( GhostManager != none && playTime <= 1800 )
                {
                    for( i = 0; i < GroupMembers.Length; ++ i )
                    {
                        GhostManager.Saver.QueueGhost(
                            PlayerController(GroupMembers[i]),
                            FastFindPlayerSlot( PlayerController(GroupMembers[i]) )-1,
                            myLevel.GetFullName( CurrentMapName )
                        );
                    }
                }
                NotifyNewRecord( FastFindPlayerSlot( PC )-1, myLevel.MapIndex, playTime );
            }
        }
    }
    else
    {
        if( CheckPlayerRecord( PC, CR, myLevel, playTime,,, hasNewRecord ) )
        {
            if( hasNewRecord == 1 )
            {
                NotifyNewRecord( CR.myPlayerSlot, myLevel.MapIndex, playTime );
            }

            if( GhostManager == none || CR.SoloRank > 3 || playTime > 1800 )
                return;

            GhostManager.Saver.QueueGhost(
                PC, // PC.GetPlayerIdHash(), // RETURNS a random GUID but the real guid other times WTF?
                CR.myPlayerSlot,
                myLevel.GetFullName( CurrentMapName )
            );
        }
    }
}

final private function bool CheckPlayerRecord(
    PlayerController PC,
    BTClient_ClientReplication CR,
    BTClient_LevelReplication myLevel,
    float playTime,
    optional bool bRecursive,
    optional int xp,
    optional out byte bNewTopRecord )
{
    local bool b, wasHijacked, hasImprovised;
    local string finishMsg, finishTime;
    local int i, j, PLs, oldPLi, PLi, l, tmpSlot;
    local float score, finishDiff;
    local Pawn P;
    local int numObjectives;
    local BTServer_RecordsData.sSoloRecord newSoloRecord;
    local int mapIndex;

    FullLog( "Processing record for player" @ PC.GetHumanReadableName() @ playTime @ "bRecursive:" @ bRecursive @ myLevel.GetFullName( CurrentMapName ) );

    // macro to playerslot.
    mapIndex = myLevel.MapIndex;
    finishTime = TimeToStr( playTime );
    finishMsg = "%PLAYER% completed" @ class'HUD_Assault'.static.GetTeamColor( 1 )$myLevel.GetLevelName()$cEnd;

    PLs = CR.myPlayerSlot + 1;
    UpdatePlayerSlot( PC, PLs - 1, True );      // Update names etc
    ++ PDat.Player[PLs - 1].PLSF;               // Amount of times this user finished a solo map.
    ++ RDat.Rec[mapIndex].TMFinish;

    if( bSoloMap && !bKeyMap && !bGroupMap )
    {
        numObjectives = 1;
    }
    else
    {
        numObjectives = GetPlayerObjectives( PC );
    }
    CurMode.PlayerCompletedMap( PC, PLs-1, playTime );
    PLi = RDat.FindRecordSlot( mapIndex, PLs );
    j = RDat.Rec[mapIndex].PSRL.Length;
    // Player was found!
    if( PLi != -1 )
    {
        // Player has improved his/her existing record's time.
        if( GetFixedTime( RDat.Rec[mapIndex].PSRL[PLi].SRT ) > playTime )
        {
            //==============================================================
            // Update solo record slot
            RDat.Rec[mapIndex].PSRL[PLi].SRD[0] = Level.Day;
            RDat.Rec[mapIndex].PSRL[PLi].SRD[1] = Level.Month;
            RDat.Rec[mapIndex].PSRL[PLi].SRD[2] = Level.Year;
            RDat.Rec[mapIndex].PSRL[PLi].ExtraPoints = xp;
            RDat.Rec[mapIndex].PSRL[PLi].ObjectivesCount = numObjectives;
            if( IsClientSpawnPlayer( PC.Pawn ) )
            {
                RDat.Rec[mapIndex].PSRL[PLi].Flags = RDat.Rec[mapIndex].PSRL[PLi].Flags | 0x01/**RFLAG_CP*/;
            }
            else
            {
                RDat.Rec[mapIndex].PSRL[PLi].Flags = RDat.Rec[mapIndex].PSRL[PLi].Flags & ~0x01/**RFLAG_CP*/;
            }
            finishDiff = RDat.Rec[mapIndex].PSRL[PLi].SRT - playTime;
            SetSoloRecordTime( PC, mapIndex, PLi, playTime );
            CR.ClientSetPersonalTime( playTime );
            // Broadcast success, on next if( b ).
            PDat.AddExperience( PLs-1, EXP_ImprovedRecord + numObjectives );
            b = true;
        }
        // Player has failed to improve his/her record time
        else
        {
            // Broadcast failure!
            ++ RDat.Rec[mapIndex].TMFailures;
            finishDiff = RDat.Rec[mapIndex].PSRL[PLi].SRT - playTime;
            // Tied his own position
            if( GetFixedTime( RDat.Rec[mapIndex].PSRL[PLi].SRT ) == playTime )
            {
                finishMsg @= "with a tie to" @ #0xFFFF00FF$finishTime;
                BroadcastFinishMessage( PC, finishMsg, 2 );

                PDat.AddExperience( PLs-1, EXP_TiedRecord + numObjectives );
                PDat.ProgressAchievementByType( PLs-1, 'Tied', 1 );
            }
            // Tied the best record
            else if( GetFixedTime( RDat.Rec[mapIndex].PSRL[0].SRT ) == playTime )
            {
                finishMsg @= "with a record tie to" @ #0xFFFF00FF$finishTime;
                BroadcastFinishMessage( PC, finishMsg, 2 );

                PDat.AddExperience( PLs-1, EXP_TiedRecord + numObjectives );
                PDat.ProgressAchievementByType( PLs-1, 'Tied', 1 );
            }
            // Failed record
            else
            {
                finishMsg @= "in" @ #0xFFFF00FF$finishTime$cEnd$", "$cRed$TimeToStr( finishDiff );
                BroadcastFinishMessage( PC, finishMsg, 0 );

                if( CR.BTWage > 0 )
                {
                    BTServer_SoloMode(CurMode).WageFailed( CR, CR.BTWage );
                }
            }
        }
    }
    // Player has set his/her first personal record.
    else
    {
        PLi = RDat.OpenRecordSlot( RDat.Rec[mapIndex].PSRL, playTime );
        RDat.Rec[mapIndex].PSRL[PLi].PLs = PLs;
        RDat.Rec[mapIndex].PSRL[PLi].SRD[0] = Level.Day;
        RDat.Rec[mapIndex].PSRL[PLi].SRD[1] = Level.Month;
        RDat.Rec[mapIndex].PSRL[PLi].SRD[2] = Level.Year;
        RDat.Rec[mapIndex].PSRL[PLi].ExtraPoints = xp;
        RDat.Rec[mapIndex].PSRL[PLi].ObjectivesCount = numObjectives;
        if( IsClientSpawnPlayer( PC.Pawn ) )
        {
            RDat.Rec[mapIndex].PSRL[PLi].Flags = RDat.Rec[mapIndex].PSRL[PLi].Flags | 0x01/**RFLAG_CP*/;
        }
        SetSoloRecordTime( PC, mapIndex, PLi, playTime );
        CR.ClientSetPersonalTime( playTime );
        PDat.AddExperience( PLs-1, EXP_FirstRecord + numObjectives );
        b = true;

        // Update the total set of solo records here because ClientForcePacketUpdate() is only called for visible records.
        myLevel.NumRecords = RDat.Rec[mapIndex].PSRL.Length;
    }

    // Somebody improved his or her time.
    if( b )
    {
        hasImprovised = true;
        b = false;

        // Remove player's old time.
        oldPLi = PLi;
        newSoloRecord = RDat.Rec[mapIndex].PSRL[PLi];
        RDat.Rec[mapIndex].PSRL.Remove( PLi, 1 );
        PLi = RDat.OpenRecordSlot( RDat.Rec[mapIndex].PSRL, playTime );
        RDat.Rec[mapIndex].PSRL[PLi] = newSoloRecord;
        if( Ranks != none )
        {
            // Re-calculate the points, because points are time and position based, all RECORDS must be calculated.
            Ranks.CalcRecordPoints( mapIndex );
            // Update our local copy to include the freshly calculated points.
            newSoloRecord.Points = RDat.Rec[mapIndex].PSRL[PLi].Points;

            CR.SoloRank = PLi + 1;
        }

        // Tie or new record
        if( (playTime == myLevel.TopTime || PLi == 0) && !bRecursive )
        {
            myLevel.TopRanks = GetRecordTopHolders( mapIndex );
        }

    	score = newSoloRecord.Points/RDat.Rec[mapIndex].PSRL[0].Points*10.00;
        if( Store != none && Store.Teams.Length > 0 )
        {
            l = Store.FindPlayerTeam( CR );
            if( l != -1 )
            {
                Store.AddPointsForTeam( CR, l, 1*(numObjectives*PointsPerObjective) );
                Level.Game.Broadcast( self, PC.GetHumanReadableName() @ "scored" @ 1*(numObjectives*PointsPerObjective) @ "points for team" @ Store.Teams[l].Name );
                PDat.GiveCurrencyPoints( CR.myPlayerSlot, 2 );
            }
            else
            {
                SendErrorMessage( PC, "You haven't voted for a team! Please vote a team to get extra rewards!" );
            }
        }

        // Earn 20 points from one record.
        if( score >= 20 )
        {
            PDat.ProgressAchievementByID( PLs-1, 'points_0' );
        }

        AddRecentSetRecordToPlayer( PLs, myLevel.GetFullName( CurrentMapName ) @ cDarkGray$finishTime );
        // Don't spam force update for every group member :P
        if( !bRecursive )
        {
            ClientForcePacketUpdate( mapIndex );
        }

        if( PLi == 0 && !bRecursive ) // This is the best one of all...
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
            if( myLevel.TopTime != 0 ) // Faster!
            {
                finishDiff = (myLevel.TopTime - playTime);
                finishMsg @= "with a new record time of" @ #0xFFFF00FF$finishTime$cEnd$", +" $ cGreen$TimeToStr( finishDiff );

                if( finishDiff <= 0.10f )
                    BroadcastAnnouncement( AnnouncementRecordImprovedVeryClose );
                else if( finishDiff <= 1.0f )
                    BroadcastAnnouncement( AnnouncementRecordImprovedClose );
                else BroadcastAnnouncement( AnnouncementRecordHijacked );

                // Check avoids to print a message if the record owner beated his own record!
                wasHijacked = j > 1 && PLs != RDat.Rec[mapIndex].PSRL[1].PLs && PLi != i;
                if( wasHijacked )
                {
                    BroadcastAnnouncement( AnnouncementRecordHijacked );

                    // Robin Hood
                    PDat.ProgressAchievementByType( PLs-1, 'StealRecord', 1 );

                    tmpSlot = RDat.Rec[mapIndex].PSRL[1].PLs-1;
                    PDat.Player[tmpSlot].RecentLostRecords[PDat.Player[tmpSlot].RecentLostRecords.Length] =
                        $cGold$TimeToStr( finishDiff )$cWhite
                        @ myLevel.GetFullName( CurrentMapName ) @ "by" @ PDat.Player[PLs-1].PLNAME;

                    RDat.Rec[mapIndex].TMFailures = 0;
                    ++ RDat.Rec[mapIndex].TMHijacks;    // Amount of times this record has been hijacked.
                    ++ PDat.Player[PLs-1].PLHijacks;    // Amount of records this player has hijacked in total.
                }
                else
                {
                    if( finishDiff <= 0.10f )
                        BroadcastAnnouncement( AnnouncementRecordImprovedVeryClose );
                    else if( finishDiff <= 1.0f )
                        BroadcastAnnouncement( AnnouncementRecordImprovedClose );
                }

                if( RDat.Rec[mapIndex].TMFailures >= 50 )
                {
                    // Failure immunity
                    PDat.ProgressAchievementByID( PLs-1, 'records_2' );
                }
            }
            else    // 1st time record
            {
                RDat.Rec[mapIndex].TMFailures = 0;
                finishMsg @= "setting a first time record of" @ #0xFFFF00FF$finishTime;
                BroadcastAnnouncement( AnnouncementRecordSet );
            }

            if( GroupManager != none )
                RDat.Rec[mapIndex].TMContributors = GroupManager.MaxGroupSize;
            else if( bSoloMap )
            {
                RDat.Rec[mapIndex].TMContributors = 1;
            }

            //======================================================
            // Update clients. .
            myLevel.TopTime = playTime;
            if( CR.BTWage > 0 )
            {
                BTServer_SoloMode(CurMode).WageSuccess( CR, CR.BTWage );
            }

            if( !bDontEndGameOnRecord )
            {
                MRI.PlayersBestTimes = myLevel.TopRanks;
                MRI.MapBestTime = myLevel.TopTime;
                MRI.RecordState = RS_Succeed;
                MRI.PointsReward = string(score);
                UpdateEndMsg( Repl( finishMsg, "%PLAYER% completed", "Completed" ) );
                return true;
            }
            else
            {
                BroadcastFinishMessage( PC, finishMsg, 1 );
            }
            //======================================================
        }
        else
        {
            // Improved
            if( finishDiff != 0 )
            {
                finishMsg @= "in" @ #0xFFFF00FF$finishTime$cEnd$", "$cGreen$"+"$TimeToStr( finishDiff )$cEnd @ "achieving best" @ #0xFFFF00FF$(PLi+1)$cEnd @ "out of" @ #0xFFFF00FF$RDat.Rec[mapIndex].PSRL.Length;
            }
            else
            {
                finishMsg @= "in" @ #0xFFFF00FF$finishTime$cEnd$", achieving best" @ #0xFFFF00FF$(PLi+1)$cEnd @ "out of" @ #0xFFFF00FF$RDat.Rec[mapIndex].PSRL.Length;
            }
            BroadcastFinishMessage( PC, finishMsg, 1 );

            if( CR.BTWage > 0 )
            {
                if( PLi+1 < RDat.Rec[mapIndex].PSRL.Length )
                {
                    BTServer_SoloMode(CurMode).WageSuccess( CR, CR.BTWage );
                }
                else
                {
                    BTServer_SoloMode(CurMode).WageFailed( CR, CR.BTWage );
                }
            }
        }
    }

    DeleteClientSpawn( PC, true );
    if( CheckPointHandler != none )
    {
        CheckPointHandler.RemoveSavedCheckPoint( PC );
    }

    if( bSoloMap )
    {
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
            myLevel.ResetObjective();
        }
    }
    return hasImprovised;
}

// Process end game for regular trials, PC = instigator.
final private function ProcessRegularEnd( PlayerController PC, BTClient_LevelReplication myLevel )
{
    local int i;
    local array<BTStructs.sPlayerReference> contributors;
    local name achievementID;
    local BTClient_ClientReplication CR;
    local byte hasNewRecord;
    local float playTime;

    playTime = GetFixedTime( Level.TimeSeconds - MRI.MatchStartTime );
    if( ASGameReplicationInfo(AssaultGame.GameReplicationInfo).RoundWinner != ERW_None ) // The game ended!.
    {
        // Calculate and return the best players.
        contributors = GetBestPlayers();
        if( AchievementsManager.TestMap( Level.Title, playTime, achievementID ) )
        {
            for( i = 0; i < contributors.Length; ++ i )
            {
                PDat.ProgressAchievementByID( contributors[i].PlayerSlot-1, achievementID );
            }
        }

        // FullLog( "Processing instigator's record:" @ PC.GetHumanReadableName() );
        CR = GetRep( PC );
        CheckPlayerRecord( PC, CR, myLevel, playTime,,, hasNewRecord );

        // FullLog( "Contributors:" @ contributors.Length );
        for( i = 0; i < contributors.Length; ++ i )
        {
            if( contributors[i].player != PC )
            {
                CR = GetRep( contributors[i].player );
                CheckPlayerRecord( contributors[i].player, CR, myLevel, playTime, true );
            }
        }

        if( hasNewRecord == 1 )
        {
            RDat.Rec[myLevel.MapIndex].TMContributors = contributors.Length;
            NotifyNewRecord( CR.myPlayerSlot, myLevel.MapIndex, playTime );

            if( GhostManager != none && playTime <= 1800 )
            {
                GhostManager.Saver.QueueGhost(
                    contributors[i].player,
                    contributors[i].playerSlot-1,
                    myLevel.GetFullName( CurrentMapName )
                );
            }
        }
        else
        {
            MRI.RecordState = RS_Failure;
            UpdateEndMsg( "Failed to beat the record, over by "
                $ TimeToStr( playTime - myLevel.TopTime )
                $ ", time " $ TimeToStr( playTime )
            );
            if( playTime < (myLevel.TopTime+90) )
                BroadcastAnnouncement( AnnouncementRecordAlmost );
            else BroadcastAnnouncement( AnnouncementRecordFailed );
        }
    }
}

final function NotifyNewRecord( int playerSlot, int mapIndex, float playTime )
{
    local int i;

    if( !bRecentRecordsUpdated )
    {
        for( i = 1; i < MaxRecentRecords; ++ i )
            LastRecords[i - 1] = LastRecords[i];

        bRecentRecordsUpdated = True;
    }
    LastRecords[MaxRecentRecords - 1] = RDat.Rec[mapIndex].TMN
        @ cDarkGray$TimeToStr( playTime )$cWhite
        @ "by" @ Class'HUD'.Default.GoldColor $ %MRI.PlayersBestTimes;
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
static final function int GetPlayerScore( PlayerController C )                              // .:..:
{
    local ASPlayerReplicationInfo Teh;

    Teh = ASPlayerReplicationInfo(C.PlayerReplicationInfo);
    return (Teh.DisabledObjectivesCount*50) + (Teh.DisabledFinalObjective*20);
}

static final function int GetPlayerObjectives( PlayerController PC )
{
    local ASPlayerReplicationInfo ASPRI;

    ASPRI = ASPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if( ASPRI != None )
        return ASPRI.DisabledObjectivesCount+ASPRI.DisabledFinalObjective;

    return 0;
}

//==============================================================================
// CheckReplacement
function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
    local BTServer_NotifyLogin NL;
    local BTClient_ClientReplication CR;
    local BTServer_NameUpdateDelay NUD;
    local int i;

    if( PlayerController(Other) != none )
    {
        // Skip bots etc
        if( !PlayerController(Other).bIsPlayer )
            return true;

        NL = Spawn( Class'BTServer_NotifyLogin', self );
        if( NL != none )
        {
            NL.Player = PlayerController(Other);
            NL.SetTimer( NL.NotifyDelay, false );
        }
        return true;
    }
    else if( UTServerAdminSpectator(Other) != none )
    {
        WebAdminActor = UTServerAdminSpectator(Other);
        if( WebAdminActor.PlayerReplicationInfo != none )
        {
            WebAdminActor.PlayerReplicationInfo.bBot = True;
            WebAdminActor.PlayerReplicationInfo.bOnlySpectator = false;
            WebAdminActor.PlayerReplicationInfo.bAdmin = true;
        }
        return true;
    }
    else if( PlayerReplicationInfo(Other) != none )
    {
        if( PlayerController(Other.Owner) != none && PlayerController(Other.Owner).bIsPlayer )
        {
            CR = Spawn( Class'BTClient_ClientReplication', Other.Owner );
            CR.MRI = MRI;

            CR.OnRequestAchievementCategories = InternalOnRequestAchievementCategories;
            CR.OnRequestAchievementsByCategory = InternalOnRequestAchievementsByCategory;
            CR.OnRequestPlayerItems = InternalOnRequestPlayerItems;
            CR.NextReplicationInfo = PlayerReplicationInfo(Other).CustomReplicationInfo;
            PlayerReplicationInfo(Other).CustomReplicationInfo = CR;
        }
        return true;
    }
    else if( Other.IsA('UTComp_PRI') )
    {
        if( PlayerController(Other.Owner) != none && PlayerController(Other.Owner).bIsPlayer )
        {
            NUD = Spawn( Class'BTServer_NameUpdateDelay', self );
            NUD.Client = PlayerController(Other.Owner);
            NUD.SetTimer( 5.0, false );
        }
        return true;
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
                    break;
                }
            }
        }
        return true;
    }
    else if( CTFFlag(Other) != none )
    {
        ResembleFlag( CTFFlag(Other ) );
        return true;
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

final function ProcessPlayerLogout( Controller player )
{
    local int playerSlot;
    local int i;
    local float timeSpent;

    // Use find by hash, because the PlayerReplicationInfos are destroyed on ServerTravel!
    playerSlot = FindPlayerSlot( PlayerController(player).GetPlayerIDHash() );
    if( playerSlot == -1 )
    {
        FullLog( "A player with no account, has left the server!! This shouldn't happen!" );
        return;
    }
    -- playerSlot;

    timeSpent = ((Level.TimeSeconds - PDat.Player[playerSlot]._LastLoginTime) / 60) / 60;
    PDat.Player[playerSlot].PlayHours += timeSpent;
    PDat.Player[playerSlot].LastKnownRank = PDat.Player[playerSlot].PLARank-1;
    PDat.Player[playerSlot].LastKnownPoints = PDat.Player[playerSlot].PLPoints[0]; // 0 = all time

    if( PDat.HasItem( playerSlot, "exp_bonus_1", i ) )
    {
        PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
        if( float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) >= 4.00f )
        {
            PDat.SilentRemoveItem( playerSlot, "exp_bonus_1" );
        }
    }

    if( PDat.HasItem( playerSlot, "exp_bonus_2", i ) )
    {
        PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
        if( float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) >= 24.00f )
        {
            PDat.SilentRemoveItem( playerSlot, "exp_bonus_2" );
        }
    }

    if( PDat.HasItem( playerSlot, "cur_bonus_1", i ) )
    {
        PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
        if( float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) >= 24.00f )
        {
            PDat.SilentRemoveItem( playerSlot, "cur_bonus_1" );
        }
    }

    if( PDat.HasItem( playerSlot, "drop_bonus_1", i ) )
    {
        PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData = string(float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) + timeSpent);
        if( float(PDat.Player[playerSlot].Inventory.BoughtItems[i].RawData) >= 24.00f )
        {
            PDat.SilentRemoveItem( playerSlot, "drop_bonus_1" );
        }
    }
}

//==============================================================================
// NotifyLogout
function NotifyLogout( Controller Exiting )                                         // .:..:, Eliot
{
    local int i;

    super.NotifyLogout( exiting );
    if( Exiting.PlayerReplicationInfo != none && !Level.bLevelChange
        && Exiting.bIsPlayer && !Exiting.PlayerReplicationInfo.bBot )
    {
        ProcessPlayerLogout( Exiting );
        // Because GameInfo does not broadcast a left game message for spectators.
        if( Exiting.PlayerReplicationInfo.bOnlySpectator && Level.NetMode != NM_Standalone )
        {
            Level.Game.BroadcastLocalizedMessage(Level.Game.GameMessageClass, 4, Exiting.PlayerReplicationInfo);
        }

        // Backup our disconnected player's stats, so we can restore it when he or she gets back!
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
    }

    if( Level.NetMode == NM_Standalone )
    {
        SaveAll();
    }
}

//==============================================================================
// ModifyLogin
function ModifyLogin(out string Portal, out string Options)                     // .:..:
{
    Super.ModifyLogin(Portal,Options);
    Level.Game.bWelcomePending = true;
}

//==============================================================================
// RetriveScore
final function RetrieveScore( PlayerController Other, string ClientID )       // .:..:, Eliot
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
final function int CreatePlayerSlot( PlayerController PC, string ClientID )
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
final function UpdatePlayerSlot( PlayerController PC, int playerIndex, Optional bool bUpdateScoreboard )
{
    local LinkedReplicationInfo LRI;
    local string s;

    if( PC == None || PC.PlayerReplicationInfo == None || MessagingSpectator(PC) != None )
        return;

    if( playerIndex >= PDat.Player.Length || playerIndex < 0 )
    {
        FullLog( "UpdatePlayerSlot::playerIndex is not valid!" );
        return;
    }

    PDat.Player[playerIndex].PLCHAR = PC.PlayerReplicationInfo.CharacterName;
    // Try find the colored name
    for( LRI = PC.PlayerReplicationInfo.CustomReplicationInfo; LRI != none; LRI = LRI.NextReplicationInfo )
    {
        if( LRI.IsA('UTComp_PRI') )
        {
            s = LRI.GetPropertyText( "ColoredName" );
            if( s != "" && InStr( s, Chr( 0x1B ) ) != -1 )
            {
                PDat.Player[playerIndex].PLNAME = /*Class'HUD'.Default.GoldColor$*/s$Class'HUD'.Default.WhiteColor;
                if( bUpdateScoreboard )
                    UpdateScoreboard( PC );

                return;
            }
        }
    }

    // Prevents the colored name from being overwritten
    if( %PDat.Player[playerIndex].PLNAME != %PC.PlayerReplicationInfo.PlayerName )
    {
        PDat.Player[playerIndex].PLNAME = /*Class'HUD'.Default.GoldColor $*/PC.PlayerReplicationInfo.PlayerName$Class'HUD'.Default.WhiteColor;
        if( bUpdateScoreboard )
            UpdateScoreboard( PC );
    }
}

final function QueryPlayerCountry( int playerIndex, string playerIp )
{
    local BTHttpIpToCountry ipToCountry;

    ipToCountry = Spawn( class'BTHttpIpToCountry', self );
    ipToCountry.OnCountryCodeReceived = InternalOnCountryCodeReceived;
    ipToCountry.GetCountryFromIp( playerIndex, playerIp );
}

function InternalOnCountryCodeReceived( BTHttpIpToCountry sender, string countryCode )
{
    local int playerIndex;

    playerIndex = sender.PlayerIndex;
    PDat.Player[playerIndex].LastIpAddress = sender.PlayerIp;
    PDat.Player[playerIndex].IpCountry = countryCode;
    // Log( "received IpToCountry data" @ PDat.Player[playerIndex].LastIpAddress @ PDat.Player[playerIndex].IpCountry);
}

// =============================================================================
// Updates the name of PC for everyones local Rankings/Solo Scoreboard!
// CR required!
final function UpdateScoreboard( PlayerController PC )
{
    // local Controller C;
    local BTClient_ClientReplication myCR;//, CR;
    // local BTClient_ClientReplication.sSoloPacket NewTPacket;

    if( !ModeIsTrials() )
    {
        return;
    }

    myCR = GetRep( PC );
    if( myCR == none || myCR.myPlayerSlot == -1 )
        return;

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

// FIXME: Reimplement solo packets updating.
    // if( myCR.SoloRank-1 >= 0 && myCR.SoloRank <= MaxRankedPlayers )
    // {
    //     NewTPacket.Points       = RDat.Rec[UsedSlot].PSRL[myCR.SoloRank-1].Points;
    //     NewTPacket.Name         = PDat.Player[myCR.myPlayerSlot].PLName;
    //     NewTPacket.Time         = RDat.Rec[UsedSlot].PSRL[myCR.SoloRank-1].SRT;
    //     NewTPacket.Date         = class'BTClient_Interaction'.static.FixDate( RDat.Rec[UsedSlot].PSRL[myCR.SoloRank-1].SRD );
    //     NewTPacket.Flags        = RDat.Rec[UsedSlot].PSRL[myCR.SoloRank-1].Flags;
    // }

    // if( NewTPacket.Name == "" )
    //     return;

    // // Update the packet of myCR for every other CR
    // for( C = Level.ControllerList; C != None; C = C.NextController )
    // {
    //     if( PlayerController(C) == None || C.PlayerReplicationInfo == None )
    //         continue;

    //     CR = GetRep( PlayerController(C) );
    //     if( CR != none && CR.bReceivedRankings )
    //     {
    //         if( NewTPacket.Name != "" )
    //             CR.ClientUpdateSoloTop( NewTPacket, myCR.SoloRank-1 );

    //         break;
    //     }
    // }
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
    j = Ranks.OverallTopList.Items.Length;
    for( i = 0; i < j; ++ i )
    {
        if( Len( PDat.Player[Ranks.OverallTopList.Items[i]].PLName ) == 0 )
            continue;

        if( PDat.Player[Ranks.OverallTopList.Items[i]].PLPoints[0] == 0 )
            break;

        SS.Length = Pos+1;
        SS[Pos] = "<tr><td>"$i+1$"</td><td><p>"$%PDat.Player[Ranks.OverallTopList.Items[i]].PLName$"</p></td><td><p>"$int( PDat.Player[Ranks.OverallTopList.Items[i]].PLPoints[0] )$"</p></td><td><p>"$PDat.Player[Ranks.OverallTopList.Items[i]].PLObjectives$"</p></td><td><p>"$PDat.Player[Ranks.OverallTopList.Items[i]].PLPersonalRecords[0]$"</p></td><td><p>"$PDat.Player[Ranks.OverallTopList.Items[i]].PLID$"</p></td></tr>";
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
    $"<tr><td><p>Authors</p></td><td><p>"$CREDITS$"</p></td><tr>"
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
    local int Minutes;
    local float Seconds;
    local string MinuteString, SecondString;

    Seconds     =   Abs( Value );
    Minutes     =   int( Seconds ) / 60;
    Seconds     -=  (Minutes * 60);

    SecondString    = Eval( Seconds < 10, "0"$Seconds, string( Seconds ) );
    if( Minutes == 0 )
    {
        if( Value < 0 )
            return "-"$SecondString;
        else return SecondString;
    }

    MinuteString    = Eval( Minutes < 10, "0"$Minutes, string( Minutes ) );

    // Negative?
    if( Value < 0 )
        return "-"$MinuteString$":"$SecondString;
    else return MinuteString$":"$SecondString;
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

final function RecordGhostForPlayer( PlayerController other )
{
    if( GhostManager == none )
        return;

    GhostManager.Saver.RecordPlayer( other );
}

final function RestartGhostRecording( PlayerController other )
{
    if( GhostManager == none )
        return;

    GhostManager.Saver.RecordPlayer( other );
}

final function KillGhostRecorders()
{
    if( GhostManager == none )
        return;

    GhostManager.Saver.EndRecording();
}

//==============================================================================
// Remove ghost from players list
function GetServerPlayers( out GameInfo.ServerResponseLine ServerState )
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
function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    if( CurMode != None )
    {
        CurMode.GetServerDetails( ServerState );
    }

    Super.GetServerDetails(ServerState);

    Level.Game.AddServerDetail( ServerState, "BTimes", "Version:"@BTVersion );
    if( ModeIsTrials() )
    {
        Level.Game.AddServerDetail( ServerState, "BTimes", "Most Recent Record:"@LastRecords[MaxRecentRecords-1] );
        Level.Game.AddServerDetail( ServerState, "BTimes", "Ghost Enabled:"@bSpawnGhost );
        Level.Game.AddServerDetail( ServerState, "BTimes", "Rankings Enabled:"@bShowRankings );
        Level.Game.AddServerDetail( ServerState, "BTimes", lzClientSpawn $ " Allowed:"@CurMode.CanSetClientSpawn() );

        if( RDat != none && MRI != none )
        {
            Level.Game.AddServerDetail( ServerState, "BTimes", "Records:"@MRI.RecordsCount$"/"$RDat.Rec.Length );
        }

        if( PDat != none )
        {
            Level.Game.AddServerDetail( ServerState, "BTimes", "Players:"@PDat.Player.Length );
        }
    }
}

static final function string MakeColor( byte R, byte G, byte B, optional byte A )
{
    return Class'GameInfo'.Static.MakeColorCode( Class'Canvas'.Static.MakeColor( R, G, B, A ) );
}

//==============================================================================
// Broadcast an announcement
final function BroadcastAnnouncement( name soundName )
{
    local Controller C;

    for( C = Level.ControllerList; C != none; C = C.NextController )
        if( PlayerController(C) != none )
            PlayerController(C).PlayRewardAnnouncement( soundName, 2, true );
}

final function BroadcastSound( sound Snd, optional Actor.ESoundSlot soundSlot )
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

private function UpdatePlayerCountry( PlayerController client, int playerIndex )
{
    local string s, curIp;

    if( Level.NetMode == NM_Standalone )
    {
        return;
    }

    s = client.GetPlayerNetworkAddress();
    curIp = Left( s, InStr( s, ":" ) );
    s = "";
    if( PDat.Player[playerIndex].LastIpAddress != curIp )
    {
        QueryPlayerCountry( playerIndex, curIp );
    }
}

final function NotifyPostLogin( PlayerController client, string guid )
{
    local int playerSlot;

    // Player joined while server traveling?
    if( PDat == none )
    {
        Warn( "PDat == none @ NotifyPostLogin" @ guid );
        return;
    }

    // Create one if none found.
    playerSlot = FindPlayerSlot( guid );
    if( playerSlot == -1 )
        playerSlot = CreatePlayerSlot( client, guid );

    -- playerSlot; // Real slot!

    // Update names, character etc
    UpdatePlayerSlot( client, playerSlot, false );
    UpdatePlayerCountry( client, playerSlot );

    PDat.Player[playerSlot]._LastLoginTime = Level.TimeSeconds;
    PDat.Player[playerSlot].LastPlayedDate = RDat.MakeCompactDate( Level );
    ++ PDat.Player[playerSlot].Played;

    // Get his score from last time he logged on this current round
    RetrieveScore( client, guid );

    // Start replicating rankings
    FullLog( "initializing replication for:" @ %PDat.Player[playerSlot].PLName );
    CreateReplication( client, guid, playerSlot );
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
final function CreateReplication( PlayerController PC, string SS, int playerIndex )
{
    local BTClient_ClientReplication CR;

    CR = GetRep( PC );
    if( CR == None )
    {
        Warn( "Found no CR for login" @ PC.GetHumanReadableName() );
        return;
    }

    CR.myPlayerSlot = playerIndex;
    CR.PlayerId = playerIndex + 1;
    PDat.Player[playerIndex].Controller = PC; // not saved
    if( !bSoloMap )
    {
        CR.ClientMatchStarting( Level.TimeSeconds );
    }

    // Server love
    if( PDat.Player[playerIndex].PlayHours >= 10 )
    {
        PDat.ProgressAchievementByID( playerIndex, 'playtime_0' );
        if( PDat.Player[playerIndex].PlayHours >= 1000 )
        {
            PDat.ProgressAchievementByID( playerIndex, 'playtime_1' );
        }
    }

    CR.Title = PDat.Player[playerIndex].Title;
    CR.BTLevel = PDat.GetLevel( playerIndex, CR.BTExperience );
    // Currency
    CR.BTPoints = PDat.Player[playerIndex].LevelData.BTPoints;
    // Achievement points
    CR.APoints = PDat.Player[playerIndex].PLAchiev;
    // Overalltop rank
    CR.Rank = PDat.Player[playerIndex].PLARank;
    CR.bIsPremiumMember = PDat.Player[playerIndex].bHasPremium;
    if( CR.bIsPremiumMember && Level.NetMode != NM_Standalone )
    {
        BroadcastLocalMessage( PC, class'BTClient_PremLocalMessage', "Premium player %PLAYER% has entered the game" );
    }

    if( Store != none )
    {
        if( ModeIsTrials() && PDat.Player[playerIndex].bPendingTeamReward )
        {
            Store.RewardTeamPlayer( CR );
            PDat.Player[playerIndex].bPendingTeamReward = false;
            PDat.Player[playerIndex].TeamPointsContribution = 0;
        }
        Store.ModifyPlayer( PC, PDat, CR );
    }
    WelcomePlayer( PC, CR );
}

final function WelcomePlayer( PlayerController PC, BTClient_ClientReplication CR )
{
    local bool suppressMotd;
    local int i, playerSlot;
    local float diff;
    local int packetNum, rankShift;

    playerSlot = CR.myPlayerSlot;
    if( playerSlot+1 != PDat.Player.Length )
    {
        CR.ClientSendText( "Welcome back" @ PC.GetHumanReadableName()$"!" );
        CR.ClientSendText( "" );
        CR.ClientSendText( cLight$"Checkout the latest maps by using console command \"RecentMaps\"." );
        CR.ClientSendText( cLight$"We also have \"ShowMissingRecords\", \"ShowBadRecords\", and \"RecentRecords\", etc." );
        CR.ClientSendText( cLight$"You can also checkout a player's profile with \"Player <Name/Id>\", or \"Map <Name>\" for map stats." );
    }
    else
    {
        // new player
        CR.ClientSendText( "Welcome to our server" @ PC.GetHumanReadableName()$"!" );
        CR.ClientSendText( "" );
        CR.ClientSendText( cLight$"You can set a CheckPoint by typing !cp in the chat!" );
        CR.ClientSendText( cLight$"Type it again if you want to turn it off!" );
    }

    // Check whether user lost some records since he logged off
    packetNum = PDat.Player[playerSlot].RecentLostRecords.Length;
    if( packetNum > 0 )
    {
        CR.ClientSendText( "" );
        if( packetNum >= 5 )
        {
            // Timeout
            PDat.ProgressAchievementByID( playerSlot, 'records_1' );
        }

        CR.ClientSendText( "You lost"@packetNum@"top record(s) since your last login!" );
        for( i = 0; i < packetNum; ++ i )
            CR.ClientSendText( PDat.Player[playerSlot].RecentLostRecords[i] );

        PDat.Player[playerSlot].RecentLostRecords.Length = 0;
        suppressMotd = true;
    }

    if( bShowRankings && PDat.Player[playerSlot].PLARank-1 != -1 )
    {
        diff = PDat.Player[playerSlot].PLPoints[0] - PDat.Player[playerSlot].LastKnownPoints;
        rankShift = (PDat.Player[playerSlot].LastKnownRank) - (PDat.Player[playerSlot].PLARank-1);
        if( diff != 0.00 || rankShift != 0 )
        {
            CR.ClientSendText( "" );
        }
        if( diff != 0.00 )
        {
            if( diff > 0 )
            {
                CR.ClientSendText( "Your rank score has increased by" @ "+"$cGreen$diff @ cWhite$"since your last login!");
            }
            else
            {
                CR.ClientSendText( "Your rank score has decreased by" @ "-"$cRed$Abs(diff) @ cWhite$"since your last login!");
            }
            suppressMotd = true;
        }
        if( rankShift != 0 )
        {
            if( rankShift > 0 )
            {
                CR.ClientSendText( "Your rank went up" @ "+"$cGreen$rankShift @ cWhite$"ranks since your last login!");
            }
            else
            {
                CR.ClientSendText( "Your rank went down" @ cRed$int(Abs(rankShift)) @ cWhite$"ranks since your last login!");
            }
            suppressMotd = true;
        }
    }

    if( EventDescription != "" && !suppressMotd )
    {
        SendEventDescription( CR );
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
        i = RDat.FindRecord( mapname );
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
final function string MaskToDate( int date )
{
    local int day, month, year;
    local string FixedDate;

    RDat.GetCompactDate( date, year, month, day );
        // Fix date
    if( day < 10 )
        FixedDate = "0"$day;
    else FixedDate = string(day);

    if( month < 10 )
        FixedDate $= "/0"$month;
    else FixedDate $= "/"$month;

    return FixedDate$"/"$Right( year, 2 );
}

//==============================================================================
// Update all the ClientReplication Packets
final function ClientForcePacketUpdate( int mapIndex, optional int recordRank )
{
    local Controller C;
    local BTClient_ClientReplication rep;
    local BTClient_LevelReplication myLevel;

    myLevel = GetObjectiveLevelByIndex( mapIndex );
    if( myLevel != none )
    {
        myLevel.NumRecords = RDat.Rec[mapIndex].PSRL.Length;
    }
    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( PlayerController(C) == None || C.PlayerReplicationInfo == None )
            continue;

        rep = GetRep( PlayerController(C) );
        if( rep == none || rep.RecordsPRI == none )
            continue;

        // Only update the records for clients who may have outdated records info.
        if( rep.RecordsPRI.RecordsQuery != RDat.Rec[mapIndex].TMN )
            continue;

        if( recordRank > 0 )
        {
            rep.RecordsPRI.ClientRemoveRecordRank( recordRank - 1 );
        }
        else
        {
            rep.RecordsPRI.ClientClearRecordRanks(); // Clients will request new ranks by themselves.
        }
    }
}

final function float GetAverageRecordTime( int recordSlot )
{
    local int i;
    local float mean;

    if( RDat.Rec[recordSlot].PSRL.Length == 0 )
    {
        return 0.0;
    }

    for( i = 0; i < RDat.Rec[recordSlot].PSRL.Length; ++ i )
    {
        mean += RDat.Rec[recordSlot].PSRL[i].SRT;
    }
    return mean / i;
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

//==============================Data functions==================================
final function LoadData()
{
    PDat = Level.Game.LoadDataObject( class'BTServer_PlayersData', PlayersDataFileName, PlayersDataFileName );
    if( PDat == none )
    {
        PDat = Level.Game.CreateDataObject( class'BTServer_PlayersData', PlayersDataFileName, PlayersDataFileName );
    }
    PDat.Init( self );

    RDat = Level.Game.LoadDataObject( class'BTServer_RecordsData', RecordsDataFileName, RecordsDataFileName );
    if( RDat == none )
    {
        RDat = Level.Game.CreateDataObject( class'BTServer_RecordsData', RecordsDataFileName, RecordsDataFileName );
    }
    RDat.Init( self );
}

final function SaveRecords()
{
    if( RDat != None )
    {
        Level.Game.SavePackage( RecordsDataFileName );
    }
}

final function SavePlayers()
{
    if( PDat != None )
    {
        Level.Game.SavePackage( PlayersDataFileName );
    }
}

final function SaveGhosts()
{
    local BTClient_LevelReplication myLevel;

    if( GhostManager == none )
        return;

    for( myLevel = MRI.BaseLevel; myLevel != none; myLevel = myLevel.NextLevel )
    {
        // Saves new, but deletes old unneeded ghosts!
        GhostManager.SaveRelevantGhosts( myLevel.GetFullName( CurrentMapName ) );
    }
}

final function SaveAll()
{
    SaveRecords();
    SavePlayers();
    SaveGhosts();
}

//==============================================================================
// Creates a data file from the current loaded ini/package.
final function CreateBackupData()
{
    local BTServer_RecordsData tempRDat;
    local BTServer_PlayersData tempPDat;

    // Records Data!
    tempRDat = Level.Game.CreateDataObject( Class'BTServer_RecordsData', RecordsDataFileName$"_backup", RecordsDataFileName$"_backup" );
    tempRDat.Rec = RDat.Rec;
    tempRDat.BT = self;
    Level.Game.SavePackage( RecordsDataFileName$"_backup" );

    // Players Data!
    tempPDat = Level.Game.CreateDataObject( Class'BTServer_PlayersData', PlayersDataFileName$"_backup", PlayersDataFileName$"_backup" );
    tempPDat.Player = PDat.Player;
    tempPDat.BT = self;
    Level.Game.SavePackage( PlayersDataFileName$"_backup" );
}

//==============================================================================
// Converts Backup data to current data file
final function RestoreBackupData()
{
    local BTServer_RecordsData tempRDat;
    local BTServer_PlayersData tempPDat;

    // Records Data!
    tempRDat = Level.Game.LoadDataObject( Class'BTServer_RecordsData', RecordsDataFileName$"_backup", RecordsDataFileName$"_backup" );
    RDat.Rec = tempRDat.Rec;
    RDat.BT = self;

    // Players Data!
    tempPDat = Level.Game.LoadDataObject( Class'BTServer_PlayersData', PlayersDataFileName$"_backup", PlayersDataFileName$"_backup" );
    PDat.Player = tempPDat.Player;
    PDat.BT = self;

    SaveAll();
}

final function bool MergeRecordsData( string uvxFileName )
{
    local BTServer_RecordsData sourceRDat;

    Log( "Loading records data from" @ uvxFileName, self.Name );
    sourceRDat = Level.Game.LoadDataObject( class'BTServer_RecordsData', RecordsDataFileName, uvxFileName );
    if( sourceRDat == none )
    {
        Log( "Couldn't find records data for file" @ uvxFileName, self.Name );
        foreach Level.Game.AllDataObjects( class'BTServer_RecordsData', sourceRDat, uvxFileName )
        {
            Log( string(sourceRDat), self.Name );
        }
        return false;
    }

    RDat.MergeDataFrom( PDat, sourceRDat, false );
    SaveRecords();
    return true;
}

//==============================================================================
// Exports a record array element out of RDat into a new .uvx file
final function bool ExportRecordData( string MapName )
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
final function bool ImportRecordData( string MapName )
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
//==============================Data functions==================================

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

static final function bool IsSpectator( PlayerReplicationInfo PRI )
{
    if( PRI != None && (PRI.bOnlySpectator || PRI.bIsSpectator) )
        return True;

    return False;
}

static final function bool IsAdmin( PlayerReplicationInfo PRI )
{
    if( PRI != None && (PRI.bAdmin || PRI.Level.NetMode == NM_StandAlone || MessagingSpectator(PRI.Owner) != none) )
        return True;

    return False;
}

//==============================================================================
// Converts 000001.011000 to 000001.01000. So resets last 4 decimals.
// Used for comparing, and to make Tie'ng records possible!
static final function float GetFixedTime( float TimeToFix )
{
    local string FixedTimeString;

    FixedTimeString = Left( string( TimeToFix ), InStr( string( TimeToFix ), "." ) + 3 );
    return float( FixedTimeString );
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
    if( BTServer_VotingHandler(Level.Game.VotingHandler) != none )
    {
        BTServer_VotingHandler(Level.Game.VotingHandler).DisableMidGameVote();
    }
    CurMode.PostRestartRound();
    UpdateEndMsg( "" );
    GotoState( '' );
}

final function UpdateEndMsg( string endMsg )
{
    MRI.EndMsg = endMsg;
    MRI.NetUpdateTime = Level.TimeSeconds - 1;
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
    local BTStructs.sConfigProperty prop;

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

    info.AddClass( class'BTServer_RegularModeConfig' );
    class'BTServer_RegularModeConfig'.static.FillPlayInfo( info );
    info.PoPClass();

    info.AddClass( class'BTServer_GroupModeConfig' );
    class'BTServer_GroupModeConfig'.static.FillPlayInfo( info );
    info.PoPClass();

    info.AddClass( class'BTServer_BunnyModeConfig' );
    class'BTServer_BunnyModeConfig'.static.FillPlayInfo( info );
    info.PoPClass();

    info.AddClass( class'BTServer_SoloModeConfig' );
    class'BTServer_SoloModeConfig'.static.FillPlayInfo( info );
    info.PoPClass();

/**    for( i = 0; i < default.TrialModes.Length; ++ i )
    {
        info.AddClass( default.TrialModes[i].default.ConfigClass );
        default.TrialModes[i].default.ConfigClass.static.FillPlayInfo( info );
    }*/
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
    Free();
}

defaultproperties
{
    UsedSlot=-1

    AnnouncementRecordImprovedVeryClose=HolyShit_F
    AnnouncementRecordImprovedClose=Unstoppable
    AnnouncementRecordHijacked=Hijacked
    AnnouncementRecordSet=WhickedSick
    AnnouncementRecordTied=Invulnerable
    AnnouncementRecordFailed=Denied
    AnnouncementRecordAlmost=Totalled

    CheckPointHandlerClass=class'BTServer_CheckPoint'
    CheckPointNavigationClass=class'BTServer_CheckPointNavigation'
    TrailerInfoClass=class'BTClient_TrailerInfo'
    RankTrailerClass=class'BTClient_RankTrailer'
    ClientStartPointClass=class'BTServer_ClientStartPoint'
    NotifyClass=class'BTServer_HttpNotificator'

    lzMapName="Map Name"
    lzPlayerName="Player Name"
    lzRecordTime="Record Time"
    lzRecordAuthor="Record Holder"
    lzRecordPoints="Points"
    lzFinished="Finished"
    lzHijacks="Hijacked"
    lzFailures="Failures"
    lzRecords="Records"

    lzRandomPick="Random Picks"

    lzCS_Set="'Client Spawn' set"
    lzCS_Deleted="'Client Spawn' deleted"
    lzCS_NotAllowed="Sorry! You cannot create a 'Client Spawn' nearby objectives, or certain triggers!"
    lzCS_Failed="Failed to set a 'Client Spawn' here. Please try move a little and try again"
    lzCS_ObjAndTrigger="You cannot interact with any objectives nor triggers while using a 'Client Spawn'"
    lzCS_Obj="You cannot interact with any objectives while using a 'Client Spawn'"
    lzCS_AllowComplete="You can complete the current map with a 'Client Spawn'"
    lzCS_NoPawn="Sorry you cannot set a 'Client Spawn' in this situation!"
    lzCS_NotEnabled="Sorry 'Client Spawn' is disabled for this trials mode"
    lzCS_NoQuickStartDelete="Sorry you cannot delete your 'Client Spawn' when quickstart is in progress"
    lzClientSpawn="Client Spawn"

    RecordsDataFileName="BestTimes_RecordsData"
    PlayersDataFileName="BestTimes_PlayersData"

    cDarkGray=(R=60,G=60,B=60,A=255)
    cLight=(R=204,G=204,B=204,A=255)
    cGold=(R=255,G=255,B=0,A=255)
    cWhite=(R=255,G=255,B=255,A=255)
    cRed=(R=255,G=0,B=0,A=255)
    cGreen=(R=0,G=255,B=0,A=255)
    cEnd="«"

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

    PointsPerObjective=0.25
    PPoints=(PlayerPoints[0]=(PPlayer[0]=5),PlayerPoints[1]=(PPlayer[0]=3,PPlayer[1]=3),PlayerPoints[2]=(PPlayer[0]=1,PPlayer[1]=1,PPlayer[2]=1))

    PointsPerLevel=1
    MaxLevel=100
    ObjectivesEXPDelay=10
    DropChanceCooldown=60

    TrialModes(0)=Class'BTServer_InvasionMode'
    TrialModes(1)=Class'BTServer_BunnyMode'
    TrialModes(2)=Class'BTServer_RegularMode'
    TrialModes(3)=Class'BTServer_GroupMode'
    TrialModes(4)=Class'BTServer_SoloMode'

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
    Commands(2)=(Cmd="DeletePlayerRecord",Params=("PlayerId","MapId"),Help="Deletes a player's record on the current map, or optionally by MapId")
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
    Commands(14)=(Cmd="MoveRecord",Params=("MapName","MapName"),Help="Moves a map's records and all its data to a new name (The server may not be running either of the two maps)")
    Commands(15)=(Cmd="DebugMode",Params=("None"),Help="Makes the debug logs display to all connected clients")
    Commands(16)=(Cmd="SetMaxRankedPlayers",Params=("Amount"),Help="Changes the amount of shown ranked players to the specified value")
    Commands(17)=(Cmd="SetGhostRecordFPS",Params=("Amount"),Help="Changes the amount of frames per second to the specified value")
    Commands(18)=(Cmd="SetQuickStartLimit",Params=("Amount"),Help="Changes the amount of maximum quickstarts to the specified value")
    Commands(19)=(Cmd="AddStart",Params=("TeamNum"),Help="Adds a player spawn for the specified team")
    Commands(20)=(Cmd="RemoveStarts",Params=("None"),Help="Removes all added player spawns")
    Commands(21)=(Cmd="GiveExperience",Params=("PartOfPlayerName","Amount"),Help="Gives experience to the specified player")
    Commands(22)=(Cmd="GiveCurrency",Params=("PartOfPlayerName","Amount"),Help="Gives currency to the specified player")
    Commands(23)=(Cmd="GiveItem",Params=("PartOfPlayerName","ItemID"),Help="Gives an item to the specified player")
    Commands(24)=(Cmd="RemoveItem",Params=("PartOfPlayerName","ItemID"),Help="Remove an item from the specified player")
    Commands(25)=(Cmd="GivePremium",Params=("PartOfPlayerName"),Help="Gives premium to the specified player")
    Commands(26)=(Cmd="RemovePremium",Params=("PartOfPlayerName"),Help="Removes premium from the specified player")
    Commands(27)=(Cmd="BT_ResetAchievements",Params=("PartOfPlayerName|All"),Help="Resets achievement stats of the specified player")
    Commands(28)=(Cmd="BT_ResetExperience",Params=("None"),Help="Resets everyone experience to 0")
    Commands(29)=(Cmd="BT_ResetCurrency",Params=("None"),Help="Resets everyone currency to 0")
    Commands(30)=(Cmd="BT_ResetObjectives",Params=("None"),Help="Resets everyone completed objectives count to 0")
    Commands(31)=(Cmd="BT_UpdateMapPrefixes",Params=("None"),Help="Converts AS-* existing records to their corresponding prefixes such as STR-*")
    Commands(32)=(Cmd="CompetitiveMode",Params=("None"),Help="Starts the competitive mode")
    Commands(33)=(Cmd="SetEventDesc",Params=("Message(1024)"),Help="Sets the BTimes MOTD")

    InvalidAccessMessage="Sorry! This server is not permitted to use MutBestTimes!"

    ConfigurableProperties(0)=(Property=BoolProperty'bGenerateBTWebsite',Description="Generate a WebBTimes.html File",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will create a WebBTimes.html file under Saves folder when a new record is set.")
    ConfigurableProperties(1)=(Property=BoolProperty'bSpawnGhost',Description="Record and Spawn Ghosts",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will record all players movements and spawn a ghost using the best player movements (ONLY FOR FAST SERVERS).")
    ConfigurableProperties(2)=(Property=BoolProperty'bDontEndGameOnRecord',Description="Don't End the Game on Record",AccessLevel=255,Weight=1,Hint="If Checked: The game will not end when a player sets a new record. bSpawnGhost must be disabled!")
    ConfigurableProperties(3)=(Property=BoolProperty'bEnhancedTime',Description="Dynamic RoundTime Limit",Weight=1,Hint="If Checked: BTimes will adjust the RoundTimeLimit of Assault based on the record time.")
    ConfigurableProperties(4)=(Property=BoolProperty'bDisableForceRespawn',Description="Disable Instant Respawning",Weight=1,Hint="If Checked: BTimes will not respawn dying players instantly.")
    ConfigurableProperties(5)=(Property=BoolProperty'bTriggersKillClientSpawnPlayers',Description="Triggers Should Kill ClientSpawn Players",AccessLevel=255,Weight=1,Hint="If Checked: BTimes will kill people coming near a trigger if using a 'Client Spawn'.")
    ConfigurableProperties(6)=(Property=BoolProperty'bClientSpawnPlayersCanCompleteMap',Description="Allow ClientSpawn to Complete Map",AccessLevel=255,Weight=1,Hint="If Checked: Players with a ClientSpawn will be able to complete solo maps.")
    ConfigurableProperties(7)=(Property=BoolProperty'bAddGhostTimerPaths',Description="Generate Ghost Time Paths",Weight=1,Hint="Whether to spawn ghost markers.")
    ConfigurableProperties(8)=(Property=IntProperty'GhostPlaybackFPS',Description="Ghost Recording Framerate",AccessLevel=255,Weight=1,Rules="2;1:25",Hint="Amount of frames recorded every second (DON'T SET THIS HIGH).")
    ConfigurableProperties(9)=(Property=FloatProperty'GhostSaveSpeed',Description="Ghost Saving Interval",AccessLevel=255,Weight=1,Hint="Amount of saving delay between every 10 Movements.")
    ConfigurableProperties(10)=(Property=IntProperty'MaxRankedPlayers',Description="Maximum Rankable Players",Weight=1,Rules="2;5:30",Hint="Amount of players to show in the ranking table and top records list.")
    ConfigurableProperties(11)=(Property=FloatProperty'TimeScaling',Description="Dynamic RoundTime Limit Scaler",Weight=1,Hint="RoundTimeLimit percent scaling.")
    ConfigurableProperties(12)=(Property=FloatProperty'CompetitiveTimeLimit',Description="RoundTime Limit for Competitive Mode",Weight=1,Hint="The time limit for the Competitive Mode.")
    ConfigurableProperties(13)=(Property=BoolProperty'bAllowCompetitiveMode',Description="Allow Competitive Mode",Weight=1)
    ConfigurableProperties(14)=(Property=IntProperty'MaxLevel',Description="Maximum Level a Player Can Become",AccessLevel=0,Weight=1,Rules="10:1000",Hint="")
    ConfigurableProperties(15)=(Property=IntProperty'PointsPerLevel',Description="Currency Bonus per Level when Leveling Up",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(16)=(Property=IntProperty'ObjectivesEXPDelay',Description="Objective Experience Reward Cooldown",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(17)=(Property=IntProperty'DropChanceCooldown',Description="Objective Item Drop Chance Cooldown",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(18)=(Property=IntProperty'MinExchangeableTrophies',Description="Minimum Amount of Trophies Required",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(19)=(Property=IntProperty'MaxExchangeableTrophies',Description="Maximum Amount of Exchangeable Trophies",AccessLevel=0,Weight=1,Hint="")
    ConfigurableProperties(20)=(Property=IntProperty'DaysCountToConsiderPlayerInactive',Description="Amount of Days to Consider a Player Inactive",AccessLevel=0,Weight=1,Hint="If a player remains inactive for the specified amount of days then the player will be hidden from rankings.")
    ConfigurableProperties(21)=(Property=BoolProperty'bNoRandomSpawnLocation',Description="Enable Fixed Player Spawns",Weight=1,Hint="If Checked: BTimes will force every player's spawn point to one fixed spawn point.")
    ConfigurableProperties(22)=(Property=StrProperty'EventDescription',Description="MOTD",AccessLevel=255,Weight=1,Rules="1024",Hint="Message of the day.")
    bEnableInstigatorEmpathy=true
    ConfigurableProperties(23)=(Property=BoolProperty'bEnableInstigatorEmpathy',Description="Reflect All Taken Damage from Players",AccessLevel=0,Weight=1,Hint="If checked: enemies cannot kill the enemy through means of weapons.")
}
