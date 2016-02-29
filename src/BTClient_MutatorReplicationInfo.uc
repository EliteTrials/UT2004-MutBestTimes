//==============================================================================
// BTClient_MutatorReplicationInfo.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Receive all kind of record details data from MutBestTimes
            Initialize Client
            Psuedo-Timer
*/
//  Coded by Eliot and .:..:
//  Updated @ XX/04/2009.
//==============================================================================
class BTClient_MutatorReplicationInfo extends ReplicationInfo;

var string
    PlayersBestTimes,
    EndMsg,
    PointsReward,
    Credits,
    RankingPage;

var float
    MapBestTime,
    GhostPercent,
    ObjectiveTotalTime,
    MatchStartTime;

var bool
    bSoloMap,
    bKeyMap,
    bHasInitialized,                                                            // Client Only
    bUpdatingGhost,                                                             // Server Only
    bCompetitiveMode;

/* Server and Client */
var enum ERecordState
{
    RS_Active,
    RS_Succeed,
    RS_Failure,
    RS_QuickStart,
} RecordState;

/* Local, ClientReplication */
var BTClient_ClientReplication CR;                                              // Client Only

// Server side stats
var int RecordsCount;
var int MaxRecords;
var int PlayersCount;
var int MaxMoves;
var int SoloRecords;
var int MaxRankedPlayersCount;

var float TeamTime[2];

// Maybe abit bandwith expensive, but no big deal.
var struct sTeam{
    var string Name;
    var float Points;
    var int Voters;
} Teams[3];

replication
{
    reliable if( Role == ROLE_Authority )
        PlayersBestTimes, MapBestTime, MatchStartTime,
        RecordState, EndMsg, PointsReward, ObjectiveTotalTime,
        MaxMoves, SoloRecords, bCompetitiveMode, Teams;

    // Only replicated once
    reliable if( bNetInitial )
        Credits, RankingPage,
        bSoloMap, bKeyMap,
        RecordsCount, MaxRecords, MaxRankedPlayersCount, PlayersCount;

    // Only replicated when saving
    reliable if( bNetDirty && bUpdatingGhost )
        GhostPercent;

    reliable if( bNetDirty && bCompetitiveMode )
        TeamTime;
}

simulated Event PostBeginPlay()
{
    Super.PostBeginPlay();

    // Because PostNetBeginPlay is never called on standalone games!
    if( Level.NetMode == NM_StandAlone )
        PostNetBeginPlay();
}

simulated event PostNetBeginPlay()
{
    Super.PostNetBeginPlay();
    SetTimer( 1.0, True );
}

simulated event Timer()
{
    if( !bHasInitialized && Level.GetLocalPlayerController() != None )
    {
        InitializeClient();
        SetTimer( 0, false );
    }
}

simulated function InitializeClient()
{
    local PlayerController PC;
    local BTClient_Interaction Inter;
    local LinkedReplicationInfo LRI;

    PC = Level.GetLocalPlayerController();
    if( PC != None && PC.Player != None )
    {
        Inter = BTClient_Interaction(PC.Player.InteractionMaster.AddInteraction( string(Class'BTClient_Interaction'), PC.Player ));
        if( Inter != None )
        {
            Inter.MRI = Self;
            Inter.HU = HUD_Assault(PC.myHud);
            Inter.myHUD = PC.myHud;
            Inter.ObjectsInitialized();

            if( CR == none )
            {
                for( LRI = PC.PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
                {
                    if( BTClient_ClientReplication(LRI) != None )
                    {
                        CR = BTClient_ClientReplication(LRI);
                        CR.MRI = Self;
                        break;
                    }
                }
            }
            bHasInitialized = True;
        }
    }
}

function SetBestTime( float NewTime )
{
    if( bSoloMap )
    {
        MapBestTime = NewTime;
        return;
    }

    MapBestTime = NewTime;
}

function Reset()
{
    RecordState = RS_Active;
}

// Moved to here for the color operators
final simulated function Color GetFadingColor( Color FadingColor )
{
    local float pulse;

    pulse = 1.0 - (Level.TimeSeconds % 1.0);
    return FadingColor * (1.0 - pulse) + class'HUD'.default.WhiteColor * pulse;
}

defaultproperties
{
    RecordState=RS_Active

    bAlwaysRelevant=true

    NetUpdateFrequency=1.0
    NetPriority=1.0
}
