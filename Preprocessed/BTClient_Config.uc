//==============================================================================
// BTClient_Config.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Store dynamic configuration data
*/
//  Coded by Eliot
//  Updated @ 01/12/2009
//==============================================================================
Class BTClient_Config extends Object
    Config(ClientBTimes)
    PerObjectConfig;

var BTClient_Config OldResult;

// Config
var() globalconfig
    int
    DrawFontSize,
    ScreenFontSize,
    GlobalSort;

var() globalconfig
    bool
    bShowRankingTable,
    bUseAltTimer,
    bShowZoneActors,
    bFadeTextColors,
    bDisplayCompletingMessages,
        bDisplayFail,
        bDisplayNew,
        bPlayCompletingSounds,
    bBaseTimeLeftOnPersonal,
    bPlayTickSounds,
    bDisplayFullTime,
    bResetGhostOnDead,
    bProfesionalMode,
    bAutoBehindView,
    bNoTrailers,
    bShowDodgeDelay,
    bShowDodgeReady;

var() globalconfig
    sound
    TickSound,
    LastTickSound,
    FailSound,
    NewSound,
    AchievementSound,
    TrophySound;

var() globalconfig
    Interactions.EInputKey
    RankingTableKey;

var() globalconfig
    color
    CTable,
    CGoldText,
    PreferedColor;

var() globalconfig
    string
    StoreFilter;

// .:..: Method
final static function BTClient_Config FindSavedData()
{
    local BTClient_Config C;

    if( Default.OldResult != None )
        return Default.OldResult;

    C = BTClient_Config(FindObject( "Package.BTConfig", Class'BTClient_Config' ));

    if( C == None )
        C = New( None, "BTConfig" ) Class'BTClient_Config';

    Default.OldResult = C;
    return C;
}

// Function by Gugi from ClanManager, Used with permission.
final static function Interactions.EInputKey ConvertToKey( string KeyStr ) // Converts the string to the enum. KeyStr example: F8
{
  local int CurKey;
  local Interactions.EInputKey LastKey;
  local int LastKeyInt;

  if (KeyStr ~= "")
    return IK_None;

  // Doesn't compile otherwise...
  LastKey = IK_OEMClear;
  LastKeyInt = int(LastKey);

  for(CurKey = 0; CurKey <= LastKey; ++CurKey)
  {
    if (KeyStr ~= class'Engine.Interactions'.static.GetFriendlyName(EInputKey(CurKey)))
      return EInputKey(CurKey);
  }

  return IK_None;
}

final function ResetSavedData()
{
    RankingTableKey                 = Default.RankingTableKey;
    DrawFontSize                    = Default.DrawFontSize;
    ScreenFontSize                  = Default.ScreenFontSize;
    bPlayTickSounds                 = Default.bPlayTickSounds;
    TickSound                       = Default.TickSound;
    LastTickSound                   = Default.LastTickSound;
    //bShowRankingTable             = Default.bShowRankingTable;
    bUseAltTimer                    = Default.bUseAltTimer;
    bShowZoneActors                 = Default.bShowZoneActors;
    bFadeTextColors                 = Default.bFadeTextColors;
    bDisplayCompletingMessages      = Default.bDisplayCompletingMessages;
    bDisplayFail                    = Default.bDisplayFail;
    bDisplayNew                     = Default.bDisplayNew;
    bPlayCompletingSounds           = Default.bPlayCompletingSounds;
    FailSound                       = Default.FailSound;
    NewSound                        = Default.NewSound;
    bBaseTimeLeftOnPersonal         = Default.bBaseTimeLeftOnpersonal;
    bDisplayFullTime                = Default.bDisplayFullTime;
    bResetGhostOnDead               = default.bResetGhostOnDead;
    bProfesionalMode                = default.bProfesionalMode;
    bAutoBehindView                 = default.bAutoBehindView;
    //bNoTrailers                       = default.bNoTrailers;
    //StoreFilter                       = default.StoreFilter;
    SaveConfig();
}

DefaultProperties
{
    StoreFilter="Other"

    RankingTableKey=IK_F12
    DrawFontSize=-3
    ScreenFontSize=2

    bPlayTickSounds=True
    TickSound=Sound'MenuSounds.select3'
    LastTickSound=Sound'MenuSounds.denied1'

    bShowRankingTable=True
    bUseAltTimer=False
    bShowZoneActors=False
    bFadeTextColors=True
    bDisplayFullTime=True
    bShowDodgeDelay=true
    bShowDodgeReady=true

    bDisplayCompletingMessages=True
        bDisplayFail=True
        bDisplayNew=True
        bPlayCompletingSounds=True
            FailSound=Sound'GameSounds.LadderClosed'
            NewSound=Sound'GameSounds.UT2K3Fanfare03'
    AchievementSound=Sound'GameSounds.UT2K3Fanfare08'
    TrophySound=Sound'GameSounds.UT2K3Fanfare08'

    bBaseTimeLeftOnPersonal=False
    bResetGhostOnDead=True

    CTable=(B=20,G=10,R=10,A=200)
    CGoldText=(R=255,G=255,B=0,A=255)
    PreferedColor=(R=255,G=255,B=255,A=255)
}
