//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_SoloMode extends BTServer_ASMode;

var() const bool bAllowWaging;

static function bool DetectMode( MutBestTimes M )
{
    return M.Objectives.Length == 1;
}

static function bool IsSolo( string mapName )
{
    return Left( Mid( mapName, 3 ), 4 ) ~= default.ModeName || Left( mapName, 3 ) ~= default.ModePrefix;
}

protected function InitializeMode()
{
    super.InitializeMode();
    bSoloMap = true;
    MRI.bSoloMap = true;
    Objectives[0].Event = 'BT_SOLORECORD';
    Tag = 'BT_SOLORECORD';

    // Remove objective sounds, we got our own!
    Objectives[0].Announcer_DisabledObjective = none;
    Objectives[0].Announcer_ObjectiveInfo = none;
    Objectives[0].Announcer_DefendObjective = none;

    if( Objectives[0].IsA('LCAKeyObjective') || Objectives[0].IsA('LCA_KeyObjective') )
    {
        bKeyMap = true;
        MRI.bKeyMap = true;
    }
    else if( Objectives[0].IsA('TriggeredObjective') )
    {
        bAlwaysKillClientSpawnPlayersNearTriggers = true;
    }
}

function ModePostBeginPlay()
{
    super.ModePostBeginPlay();
    if( CheckPointHandlerClass != none )
    {
        CheckPointHandler = Spawn( CheckPointHandlerClass, Outer );
    }
}

function bool ClientExecuted( PlayerController sender, string command, array<string> params )
{
    local bool bmissed;

    switch( command )
    {
        case "resetcheckpoint":
            if( bQuickStart )
            {
                break;
            }
            ResetCheckPoint( sender );
            break;

        default:
            bmissed = true;
            break;
    }

    if( !bmissed )
    {
        return true;
    }
    return super.ClientExecuted( sender, command, params );
}

function bool ChatCommandExecuted( PlayerController sender, string command, string value )
{
    switch( command )
    {
        case "wager":
            ActivateWager( sender, value );
            return true;
    }
    return super.ChatCommandExecuted( sender, command, value );
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
    super.ModeModifyPlayer( other, c, CRI );

    // Enable waging for this run.
    if( CRI != none )
    {
        if( CRI.bWantsToWage )
        {
            CRI.BTWage = CRI.AmountToWage;
            SendSucceedMessage( PlayerController(c), "You are now waging " $ CRI.BTWage $ " currency! Everytime you die you will lose the amount you're waging!, or if you beat your personal/top record you will gain triple the amount you waged!" );

            CRI.bWantsToWage = false;
        }
        else if( CRI.AmountToWage == 0 )
        {
            CRI.BTWage = 0;
        }
    }
}

function ModePlayerKilled( Controller player )
{
    local BTClient_ClientReplication LRI;

    super.ModePlayerKilled( player );

    if( bQuickStart )
    {
        return;
    }

    LRI = GetRep(player);
    if( LRI == none || LRI.BTWage <= 0 )
    {
        return;
    }
    WageFailed( LRI, LRI.BTWage );
}

function WageFailed( BTClient_ClientReplication wager, int wagedPoints )
{
    SendErrorMessage( PlayerController(wager.Owner), "You failed your wage!" );
    PDat.GiveCurrencyPoints( wager.myPlayerSlot, -wagedPoints, true );
    if( wager.BTPoints < wagedPoints )
    {
        ActivateWager( PlayerController(wager.Owner), 0 );
    }
}

function WageSuccess( BTClient_ClientReplication wager, int wagedPoints )
{
    SendSucceedMessage( PlayerController(wager.Owner), "You succeeded your wage!" );
    PDat.GiveCurrencyPoints( wager.myPlayerSlot, wagedPoints*3, true );
    wager.BTWage = 0;
    wager.AmountToWage = 0;
    wager.bWantsToWage = false;
}

function ActivateWager( PlayerController sender, coerce int wagerAmount )
{
    local BTClient_ClientReplication LRI;

    if( !bAllowWaging )
    {
        SendErrorMessage( sender, "Waging is currently disabled on this server! " );
        return;
    }

    if( RDat.Rec[UsedSlot].PSRL.Length < 3 && !IsAdmin( sender.PlayerReplicationInfo ) )
    {
        SendErrorMessage( sender, "Waging is disabled on this map until 3 or more records are available!" );
        return;
    }

    LRI = GetRep(sender);
    if( LRI == none )
    {
        Log("LRI none when waging!!!");
        return;
    }

    if( !LRI.bIsPremiumMember && !IsAdmin( sender.PlayerReplicationInfo ) )
    {
        SendErrorMessage( sender, "Waging is only for premium members!" );
        return;
    }

    if( wagerAmount == 0 )
    {
        if( LRI.BTWage > 0 || LRI.AmountToWage > 0 )
        {
            SendSucceedMessage( sender, "Waging disabled, wage will update when you respawn!" );
            LRI.AmountToWage = 0;
            LRI.bWantsToWage = false;
        }
        else
        {
            SendSucceedMessage( sender, "Please specify a wage amount, for example: !wager 100" );
        }
        return;
    }

    wagerAmount = Min( Max( wagerAmount, 0 ), Min( LRI.BTPoints, 1000 ) );
    if( wagerAmount <= 0 )
    {
        SendErrorMessage( sender, "You cannot wage this amount!" );
        return;
    }
    SendSucceedMessage( sender, "Wage amount will become " $ wagerAmount $ " when you respawn!" );

    LRI.AmountToWage = wagerAmount;
    LRI.bWantsToWage = true;
}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
    super.PlayerCompletedMap( player, playerSlot, playSeconds );

    DeleteClientSpawn( player, true );
    if( bGroupMap )
    {
        // Complete a Group map
        ProcessGroupFinishAchievement( playerSlot );
        if( PDat.FindAchievementByID( playerSlot, 'records_5' ) == -1 && CountRecordsNum( groupNum, playerSlot ) >= 4 )
        {
            // Group gamer
            PDat.ProgressAchievementByID( playerSlot, 'records_5' );
        }
        return;
    }

    if( IsCompetitive() )
    {
        TeamFinishedMap( player );
    }

    if( Left( Level.Title, 13 ) == "TechChallenge" )
    {
        PDat.ProgressAchievementByType( playerSlot, 'FinishTech', 1 );
    }
    else if( Left( Level.Title, 9 ) == "EgyptRuin" )
    {
        PDat.ProgressAchievementByType( playerSlot, 'FinishRuin', 1 );
    }

    // Complete a Solo map
    PDat.ProgressAchievementByType( playerSlot, 'FinishSolo', 1 );

    if( Level.Hour >= 0 && Level.Hour <= 6 )
    {
        PDat.ProgressAchievementByID( playerSlot, 'mode_3_night' );
    }

    // Has 50 or more records.
    if( PDat.FindAchievementByID( playerSlot, 'records_3' ) == -1 && CountRecordsNum( soloNum, playerSlot ) >= 50 )
    {
        // Solo gamer
        PDat.ProgressAchievementByID( playerSlot, 'records_3' );
    }
}

defaultproperties
{
    ModeName="Solo"
    ModePrefix="STR"
    ConfigClass=class'BTServer_SoloModeConfig'

    ExperienceBonus=5

    // 45 Seconds
    MinRecordTime=60.00
    // 5 Minutes
    MaxRecordTIme=300.00
}
