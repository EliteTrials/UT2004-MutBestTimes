//=============================================================================
// Copyright 2005-2016 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTClient_Config extends Object
    config(ClientBTimes)
    perobjectconfig;

const CONFIG_NAME = "BTConfig";

var() globalconfig
    int
    DrawFontSize,
    ScreenFontSize,
    GlobalSort;

var() globalconfig
    bool
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

var private BTClient_Config _ConfigInstance;

// Thanks to .:..:
final static function BTClient_Config FindSavedData()
{
    local BTClient_Config cfg;

    if( default._ConfigInstance != none )
        return default._ConfigInstance;

    cfg = BTClient_Config(FindObject( "Package."$CONFIG_NAME, default.Class ));
    if( cfg == none )
        cfg = new (none, CONFIG_NAME) default.Class;

    default._ConfigInstance = cfg;
    return cfg;
}

// Thanks to Gugi(ClanManager), used with permission.
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
    RankingTableKey                 = default.RankingTableKey;
    DrawFontSize                    = default.DrawFontSize;
    ScreenFontSize                  = default.ScreenFontSize;
    bPlayTickSounds                 = default.bPlayTickSounds;
    TickSound                       = default.TickSound;
    LastTickSound                   = default.LastTickSound;
    bUseAltTimer                    = default.bUseAltTimer;
    bShowZoneActors                 = default.bShowZoneActors;
    bFadeTextColors                 = default.bFadeTextColors;
    bDisplayCompletingMessages      = default.bDisplayCompletingMessages;
    bDisplayFail                    = default.bDisplayFail;
    bDisplayNew                     = default.bDisplayNew;
    bPlayCompletingSounds           = default.bPlayCompletingSounds;
    FailSound                       = default.FailSound;
    NewSound                        = default.NewSound;
    bBaseTimeLeftOnPersonal         = default.bBaseTimeLeftOnpersonal;
    bDisplayFullTime                = default.bDisplayFullTime;
    bResetGhostOnDead               = default.bResetGhostOnDead;
    bProfesionalMode                = default.bProfesionalMode;
    bAutoBehindView                 = default.bAutoBehindView;
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
