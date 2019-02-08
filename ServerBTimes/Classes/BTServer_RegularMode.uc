//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_RegularMode extends BTServer_ASMode;

static function bool DetectMode( MutBestTimes M )
{
    // Not solo then were obviously a team mode
    return !Class'BTServer_SoloMode'.static.DetectMode( M );
}

static function bool IsRegular( string mapName )
{
    return !class'BTServer_SoloMode'.static.IsSolo( mapName )
        && !class'BTServer_GroupMode'.static.IsGroup( mapName )
        && (Left( mapName, 2 ) ~= "AS" || Left( mapName, 3 ) ~= default.ModePrefix);
}

protected function InitializeMode()
{
    local int mapIndex;
    local BTClient_LevelReplication myLevel;

    super.InitializeMode();
    bRegularMap = true;

    myLevel = Spawn( class'BTClient_LevelReplication', none );
    MRI.AddLevelReplication( myLevel );

    mapIndex = UsedSlot;
    myLevel.MapIndex = mapIndex;
    if( RDat.Rec[mapIndex].PSRL.Length > 0 )
    {
        myLevel.NumRecords = RDat.Rec[mapIndex].PSRL.Length;
        myLevel.TopTime = GetFixedTime( RDat.Rec[mapIndex].PSRL[0].SRT ); // assumes PSRL is always sorted by lowest time.
        myLevel.TopRanks = GetRecordTopHolders( mapIndex );
    }
    MRI.MapLevel = MRI.BaseLevel;
    for( myLevel = MRI.BaseLevel; myLevel != none; myLevel = myLevel.NextLevel )
    {
        myLevel.InitializeLevel( MRI );
    }
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
    super.ModeModifyPlayer( other, c, CRI );

    if (GhostManager != none) {
        GhostManager.Saver.RecordPlayer( PlayerController(c) );
    }
}

function PlayerCompletedObjective( PlayerController player, BTClient_ClientReplication LRI, float score )
{
    super.PlayerCompletedObjective( player, LRI, score );
    ClearClientStarts();
}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
    super.PlayerCompletedMap( player, playerSlot, playSeconds );

    // Completed a regular map.
    PDatManager.ProgressAchievementByID( playerSlot, 'mode_2' );
    // Has 10 or more regular records.
    if( PDat.FindAchievementStatusByID( playerSlot, 'records_4' ) == -1 && CountRecordsNum( regularNum, playerSlot ) >= 10 )
    {
        // Regular gamer.
        PDatManager.ProgressAchievementByID( playerSlot, 'records_4' );
    }
}

defaultproperties
{
    ModeName="Regular"
    ModePrefix="RTR"
    ConfigClass=class'BTServer_RegularModeConfig'

    ExperienceBonus=25

    // 60 Seconds
    MinRecordTime=60.00
    // Obsolete
    MaxRecordTIme=0.00
}
