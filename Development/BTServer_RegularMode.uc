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
    super.InitializeMode();
    bRegularMap = true;
}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
    super.PlayerCompletedMap( player, playerSlot, playSeconds );

    // Completed a regular map.
    PDat.ProgressAchievementByID( playerSlot, 'mode_2' );
    // Has 10 or more regular records.
    if( PDat.FindAchievementByID( playerSlot, 'records_4' ) == -1 && CountRecordsNum( regularNum, playerSlot ) >= 10 )
    {
        // Regular gamer.
        PDat.ProgressAchievementByID( playerSlot, 'records_4' );
    }
}

defaultproperties
{
    ModeName="Regular"
    ModePrefix="RTR"

    ExperienceBonus=25

    // 60 Seconds
    MinRecordTime=60.00
    // Obsolete
    MaxRecordTIme=0.00
}
