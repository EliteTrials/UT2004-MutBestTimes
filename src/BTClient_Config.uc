//=============================================================================
// Copyright 2005-2016 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTClient_Config extends Object
    config(ClientBTimes)
    perobjectconfig;

const CONFIG_NAME = "BTConfig";
const CONFIG_VERSION = 1.1;

var globalconfig float SavedWithVersion;

var() globalconfig
    int
    ScreenFontSize;

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
    bProfesionalMode,
    bAutoBehindView,
    bNoTrailers;

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

    if( cfg.SavedWithVersion < CONFIG_VERSION )
    {
        PatchSavedData( cfg );
        cfg.SavedWithVersion = CONFIG_VERSION;
        cfg.SaveConfig();
    }

    default._ConfigInstance = cfg;
    return cfg;
}

private static function PatchSavedData( BTClient_Config cfg )
{
    if( cfg.SavedWithVersion < 1 )
    {
        cfg.CTable = default.CTable;
    }

    if (cfg.SavedWithVersion < 1.1) {
        cfg.ScreenFontSize = default.ScreenFontSize;
    }
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
    bProfesionalMode                = default.bProfesionalMode;
    bAutoBehindView                 = default.bAutoBehindView;
    CTable                          = default.CTable;
    CGoldText                       = default.CGoldText;
    SaveConfig();
}

defaultproperties
{
    StoreFilter="Other"

    RankingTableKey=IK_F12
    ScreenFontSize=1

    bPlayTickSounds=True
    TickSound=Sound'MenuSounds.select3'
    LastTickSound=Sound'MenuSounds.denied1'

    bUseAltTimer=False
    bShowZoneActors=False
    bFadeTextColors=True
    bDisplayFullTime=false

    bDisplayCompletingMessages=True
        bDisplayFail=True
        bDisplayNew=True
        bPlayCompletingSounds=True
            FailSound=Sound'GameSounds.LadderClosed'
            NewSound=Sound'GameSounds.UT2K3Fanfare03'
    AchievementSound=Sound'GameSounds.UT2K3Fanfare08'
    TrophySound=Sound'GameSounds.UT2K3Fanfare08'

    bBaseTimeLeftOnPersonal=False

    CTable=(B=18,G=12,R=12,A=200)
    CGoldText=(R=255,G=255,B=0,A=255)
    PreferedColor=(R=255,G=255,B=255,A=255)
}
