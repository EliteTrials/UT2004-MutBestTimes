//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_SoloMode extends BTServer_ASMode;

var() const bool bAllowWaging;

static function bool DetectMode( MutBestTimes M )
{
    return M.Objectives.Length == 1 || IsSolo( M.CurrentMapName );
}

static function bool IsSolo( string mapName )
{
    return Left( Mid( mapName, 3 ), 4 ) ~= default.ModeName || Left( mapName, 3 ) ~= default.ModePrefix;
}

protected function InitializeMode()
{
    local int i;

    super.InitializeMode();
    bSoloMap = true;
    MRI.bSoloMap = true;

    Tag = 'BT_SOLORECORD';
    for( i = 0; i < Objectives.Length; ++ i )
    {
        Objectives[i].Event = 'BT_SOLORECORD';
        // Remove objective sounds, we got our own!
        Objectives[i].Announcer_DisabledObjective = none;
        Objectives[i].Announcer_ObjectiveInfo = none;
        Objectives[i].Announcer_DefendObjective = none;

        if( Objectives[i].IsA('LCAKeyObjective') || Objectives[i].IsA('LCA_KeyObjective') )
        {
            bKeyMap = true;
            MRI.bKeyMap = true;
        }
        else if( Objectives[i].IsA('TriggeredObjective') && !ClientSpawnCanCompleteMap() )
        {
            bAlwaysKillClientSpawnPlayersNearTriggers = true;
        }
    }

    InitializeSoloSupreme();
}

protected function InitializeSoloSupreme()
{
    local int i, mapIndex;
    local BTClient_LevelReplication myLevel;
    local string levelName;

    for( i = 0; i < Objectives.Length; ++ i )
    {
        myLevel = Spawn( class'BTClient_LevelReplication', Objectives[i] );
        MRI.AddLevelReplication( myLevel );
        myLevel.InitializeLevel( Objectives[i] );

        levelName = myLevel.GetFullName( CurrentMapName );
        mapIndex = RDat.FindRecord( levelName );
        if( mapIndex == -1 )
        {
            mapIndex = RDat.CreateRecord( levelName, RDat.MakeCompactDate( Level ) );
        }

        myLevel.MapIndex = mapIndex;
        if( RDat.Rec[mapIndex].PSRL.Length > 0 )
        {
            myLevel.NumRecords = RDat.Rec[mapIndex].PSRL.Length;
            myLevel.TopTime = GetFixedTime( RDat.Rec[mapIndex].PSRL[0].SRT ); // assumes PSRL is always sorted by lowest time.
            myLevel.TopRanks = GetRecordTopHolders( mapIndex );
        }
    }

    if( Objectives.Length == 1 )
    {
        MRI.MapLevel = MRI.BaseLevel;
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
        case "resetcp":
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
    local BTClient_ClientReplication CRI;

    switch( command )
    {
        case "wager":
            ActivateWager( sender, value );
            return true;

        case "level":
            if( Objectives.Length < 2 )
                return false;

            CRI = GetRep( sender );
            CRI.PlayingLevel = GetObjectiveLevelByName( value );
            CRI.NetUpdateTime = Level.TimeSeconds - 1;
            if( sender.Pawn != none )
            {
                sender.Pawn.Suicide();
            }
            return true;
    }
    return super.ChatCommandExecuted( sender, command, value );
}

function bool ModeValidatePlayerStart( Controller player, PlayerStart start )
{
    local BTClient_ClientReplication CRI;

    CRI = GetRep( player );
    if( CRI == none || CRI.PlayingLevel == none )
    {
        return super.ModeValidatePlayerStart( player, start );
    }
    return CRI.PlayingLevel.IsValidPlayerStart( player, start );
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
    local int i, checkPointIndex;

    super.ModeModifyPlayer( other, c, CRI );
    /**
     * @Todo    Instead of restart recording, delete the few last saved moves
     * @Todo    Don't let the timer keep counting, instead remove what has counted since the last dead
     */
    if( other.LastStartSpot.IsA( CheckPointNavigationClass.Name )
        && CheckPointHandler.HasSavedCheckPoint( c, checkPointIndex ) )
    {
        CheckPointHandler.ApplyPlayerState( other, CheckPointHandler.SavedCheckPoints[checkPointIndex].SavedStats );
        CRI.ClientSpawnPawn = other; // re-use the ClientSpawn feature for this :), with this the timer won't restart for spectators.
    }
    // Check if a clientspawn is registered, not if we spawned on one, because we don't want to reset the time if a player switches team while having a clientspawn!
    else if( GetClientSpawnIndex( c ) == -1 /**!IsClientSpawnPlayer( other )*/ )
    {
        // Start timer
        CRI.PlayerSpawned();
        if( GhostManager != none )
        {
            // Restart ghost recording!
            RestartGhostRecording( PlayerController(c) );

            // Reset ghost, if wanted
            if( !RDat.Rec[UsedSlot].TMGhostDisabled && CRI.HasClientFlags( 0x00000001/**CFRESETGHOST*/ )
                && (c == LeadingGhost || Level.Game.NumPlayers <= 1) )
            {
                GhostManager.GhostsRespawn();
            }
        }

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

    if( !bGroupMap )
    {
        // Respawn all my stalkers!
        for( i = 0; i < Racers.Length; ++ i )
        {
            if( Racers[i].Leader == Other.Controller
                && Racers[i].Stalker != none
                && !Racers[i].Stalker.PlayerReplicationInfo.bIsSpectator
                && !Racers[i].Stalker.PlayerReplicationInfo.bOnlySpectator )
            {
                ModeRules.RespawnPlayer( Racers[i].Stalker.Pawn );
            }
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

    if( IsCompetitiveModeActive() )
    {
        TeamFinishedMap( player, playSeconds );
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
