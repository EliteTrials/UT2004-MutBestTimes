class BTGUI_Settings extends BTGUI_TabBase;

var automated GUIButton
    b_Save,
    b_Reset;

var automated moCheckBox
    cb_UseAltTimer,
    cb_ShowZoneActors,
    cb_FadeTextColors,
    cb_OIF,
    cb_OIN,
    cb_PT,
    cb_PTS,
    cb_DFT,
    cb_PM,
    cb_ABV,
    cb_RenderPathTimers, cb_RenderPathTimerIndexes;

var automated GUIEditBox
    eb_TickSound,
    eb_LastTickSound,
    eb_FailSound,
    eb_SucceedSound,
    eb_ToggleKey;

function InitPanel()
{
    super.InitPanel();
    LoadBTConfig();
}

function bool InternalOnClick( GUIComponent Sender )
{
    if( Sender == b_Save )
    {
        DisableComponent( b_Save );
        SaveBTConfig();
        return true;
    }
    else if( Sender == b_Reset )
    {
        DisableComponent( b_Reset );
        ResetBTConfig();
        LoadBTConfig();
        return true;
    }
    return false;
}

function InternalOnChange( GUIComponent Sender )
{
    EnableComponent( b_Save );
    EnableComponent( b_Reset );
}

private function ResetBTConfig()
{
    class'BTClient_Config'.static.FindSavedData().ResetSavedData();
}

private function LoadBTConfig()
{
    local BTClient_Config btConfig;

    btConfig = class'BTClient_Config'.static.FindSavedData();
    cb_UseAltTimer.Checked( btConfig.bUseAltTimer );
    cb_ShowZoneActors.Checked( btConfig.bShowZoneActors );
    cb_FadeTextColors.Checked( btConfig.bFadeTextColors );
    cb_OIF.Checked( btConfig.bDisplayFail );
    cb_OIN.Checked( btConfig.bDisplayNew );
    cb_PT.Checked( btConfig.bBaseTimeLeftOnPersonal );
    cb_PTS.Checked( btConfig.bPlayTickSounds );
    cb_DFT.Checked( btConfig.bDisplayFullTime );
    cb_PM.Checked( btConfig.bProfesionalMode );
    cb_ABV.Checked( btConfig.bAutoBehindView );

    eb_TickSound.SetText( string(btConfig.TickSound) );
    eb_LastTickSound.SetText( string(btConfig.LastTickSound) );
    eb_FailSound.SetText( string(btConfig.FailSound) );
    eb_SucceedSound.SetText( string(btConfig.NewSound) );
    eb_ToggleKey.SetText( class'Interactions'.static.GetFriendlyName( btConfig.RankingTableKey ) );

    cb_RenderPathTimers.Checked( btConfig.bRenderPathTimers );
    cb_RenderPathTimerIndexes.Checked( btConfig.bRenderPathTimerIndex );
}

private function SaveBTConfig()
{
    local BTClient_Config btConfig;

    btConfig = class'BTClient_Config'.static.FindSavedData();
    btConfig.bUseAltTimer = cb_UseAltTimer.IsChecked();
    btConfig.bShowZoneActors = cb_ShowZoneActors.IsChecked();
    btConfig.bFadeTextColors = cb_FadeTextColors.IsChecked();
    btConfig.bDisplayFail = cb_OIF.IsChecked();
    btConfig.bDisplayNew = cb_OIN.IsChecked();
    btConfig.bBaseTimeLeftOnPersonal = cb_PT.IsChecked();
    btConfig.bPlayTickSounds = cb_PTS.IsChecked();
    btConfig.bDisplayFullTime = cb_DFT.IsChecked();
    btConfig.bProfesionalMode = cb_PM.IsChecked();
    btConfig.bAutoBehindView = cb_ABV.IsChecked();
    btConfig.TickSound = Sound(DynamicLoadObject( eb_TickSound.GetText(), Class'Sound', True ));
    btConfig.LastTickSound = Sound(DynamicLoadObject( eb_LastTickSound.GetText(), Class'Sound', True ));
    btConfig.FailSound = Sound(DynamicLoadObject( eb_FailSound.GetText(), Class'Sound', True ));
    btConfig.NewSound = Sound(DynamicLoadObject( eb_SucceedSound.GetText(), Class'Sound', True ));
    btConfig.RankingTableKey = btConfig.static.ConvertToKey( eb_ToggleKey.GetText() );
    btConfig.bRenderPathTimers = cb_RenderPathTimers.IsChecked();
    btConfig.bRenderPathTimerIndex = cb_RenderPathTimerIndexes.IsChecked();
    btConfig.SaveConfig();

    PlayerOwner().ConsoleCommand("UpdateToggleKey");
}

defaultproperties
{
    // Left Side
    Begin Object class=moCheckBox name=UseAltTimer
        WinTop      =   0.100000
        WinLeft     =   0.050000
        WinWidth    =   0.4200000
        WinHeight   =   0.048125
        Caption="Draw Alternative Timer"
        Hint="The record timer will be drawn at the bottom center of your screen"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_UseAltTimer=UseAltTimer

    Begin Object class=moCheckBox name=ShowZoneActors
        WinTop=0.172000
        WinLeft=0.050000
        WinWidth=0.4200000
        WinHeight=0.048125
        Caption="Show Zone Actors"
        Hint="Common invisible actors within your current zone will be drawn in wireframe or as an icon if no mesh is available"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_ShowZoneActors=ShowZoneActors

    Begin Object class=moCheckBox name=FadeTextColors
        WinTop=0.244000
        WinLeft=0.050000
        WinWidth=0.4200000
        WinHeight=0.048125
        Caption="Animate Timer Colors"
        Hint="Timer colors will be animated"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_FadeTextColors=FadeTextColors

    Begin Object class=moCheckBox name=cbRenderPathTimers
        WinTop=0.312000
        WinLeft=0.050000
        WinWidth=0.420000
        WinHeight=0.048125
        Caption="Draw Path Timers"
        Hint="Path Timers of the #1 Ghost's path will be drawn"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_RenderPathTimers=cbRenderPathTimers

    Begin Object class=moCheckBox name=cbRenderPathTimerIndex
        WinTop=0.384000
        WinLeft=0.050000
        WinWidth=0.420000
        WinHeight=0.048125
        Caption="Draw Path Timer Index"
        Hint="Path Timers will be drawn with their index number next to its time"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_RenderPathTimerIndexes=cbRenderPathTimerIndex

    Begin Object class=moCheckBox name=OIF
        WinTop=0.594000
        WinLeft=0.050000
        WinWidth=0.170000
        WinHeight=0.048125
        Caption="Play Sound"
        Hint="Record failure notifications will play a sound"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_OIF=OIF

    Begin Object class=GUIEditBox name=FailSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.594
        WinLeft=0.250000
        WinWidth=0.220000
        WinHeight=0.050000
        Hint="Path to the sound to play on a record failure"
        OnChange=InternalOnChange
    End Object
    eb_FailSound=FailSound

    Begin Object class=moCheckBox name=OIN
        WinTop=0.662000
        WinLeft=0.050000
        WinWidth=0.170000
        WinHeight=0.048125
        Caption="Play Sound"
        Hint="New record notifications will play a sound"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_OIN=OIN

    Begin Object class=GUIEditBox name=SucceedSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.662
        WinLeft=0.250000
        WinWidth=0.220000
        WinHeight=0.050000
        Hint="Path to the sound to play on a new record"
        OnChange=InternalOnChange
    End Object
    eb_SucceedSound=SucceedSound

    // Right Side
    Begin Object class=moCheckBox name=PT
        WinTop=0.100000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Relative Timer"
        Hint="The record timer will start based off of your personal record time"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_PT=PT

    Begin Object class=moCheckBox name=DFT
        WinTop=0.172000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Render Full Timer"
        Hint="The record timer will render all decimals, even if they are null e.g. 00:00:10.41"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_DFT=DFT

    Begin Object class=GUIEditBox name=ToggleKey
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.316000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.050000
        Hint="Key to open the leaderboards"
        OnChange=InternalOnChange
    End Object
    eb_ToggleKey=ToggleKey

    Begin Object class=moCheckBox name=PM
        WinTop=0.388000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Professional Mode"
        Hint="Hides all players and mute most player caused sounds"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_PM=PM

    Begin Object class=moCheckBox name=ABV
        WinTop=0.460000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Auto BehindView"
        Hint="Will automatically switch your camera to \"BehindView\" on spawn"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_ABV=ABV

    Begin Object class=moCheckBox name=PTS
        WinTop=0.532000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Play Tick Sounds"
        Hint="Play a tick sound for every second of the last 10 seconds"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_PTS=PTS

    Begin Object class=GUIEditBox name=TickSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.594000
        WinLeft=0.530000
        WinWidth=0.225000
        WinHeight=0.050000
        Hint="Path to the sound to play for timer ticks"
        OnChange=InternalOnChange
    End Object
    eb_TickSound=TickSound

    Begin Object class=GUIEditBox name=LastTickSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.656000
        WinLeft=0.530000
        WinWidth=0.225000
        WinHeight=0.050000
        Hint="Path to the final sound to play for timer ticks"
        OnChange=InternalOnChange
    End Object
    eb_LastTickSound=LastTickSound

    Begin Object class=GUIButton name=ResetButton
        Caption="Reset"
        WinTop=0.800000
        WinLeft=0.050000
        WinWidth=0.130000
        WinHeight=0.050000
        OnClick=InternalOnClick
        OnChange=InternalOnChange
        Hint="Restore all settings back to their default values"
    End Object
    b_Reset=ResetButton

    Begin Object class=GUIButton name=SaveButton
        Caption="Save"
        WinTop=0.800000
        WinLeft=0.825000
        WinWidth=0.130000
        WinHeight=0.050000
        Hint="Save all settings"
        OnClick=InternalOnClick
    End Object
    b_Save=SaveButton
}