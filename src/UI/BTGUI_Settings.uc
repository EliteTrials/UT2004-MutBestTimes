class BTGUI_Settings extends BTGUI_TabBase;

var automated GUIButton
    b_Save,
    b_Reset;

var automated moCheckBox
    cb_UseAltTimer,
    cb_ShowZoneActors,
    cb_FadeTextColors,
    cb_DCM,
    cb_OIF,
    cb_OIN,
    cb_PCS,
    cb_PT,
    cb_PTS,
    cb_DFT,
    cb_PM,
    cb_ABV;

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
    cb_DCM.Checked( btConfig.bDisplayCompletingMessages );
    cb_OIF.Checked( btConfig.bDisplayFail );
    cb_OIN.Checked( btConfig.bDisplayNew );
    cb_PCS.Checked( btConfig.bPlayCompletingSounds );
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
}

private function SaveBTConfig()
{
    local BTClient_Config btConfig;

    btConfig = class'BTClient_Config'.static.FindSavedData();
    btConfig.bUseAltTimer = cb_UseAltTimer.IsChecked();
    btConfig.bShowZoneActors = cb_ShowZoneActors.IsChecked();
    btConfig.bFadeTextColors = cb_FadeTextColors.IsChecked();
    btConfig.bDisplayCompletingMessages = cb_DCM.IsChecked();
    btConfig.bDisplayFail = cb_OIF.IsChecked();
    btConfig.bDisplayNew = cb_OIN.IsChecked();
    btConfig.bPlayCompletingSounds = cb_PCS.IsChecked();
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
        Caption="Use Alternative Timer"
        Hint="If Checked: The record timer will be displayed at bottom center of your screen"
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
        Hint="If Checked: Common invisible actors within your zone will be drawn in wireframe or just an icon if no mesh is available"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_ShowZoneActors=ShowZoneActors

    Begin Object class=moCheckBox name=FadeTextColors
        WinTop=0.244000
        WinLeft=0.050000
        WinWidth=0.4200000
        WinHeight=0.048125
        Caption="Fade Text Colors"
        Hint="If Checked: Text colors will fade between white and their default Color"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_FadeTextColors=FadeTextColors

    Begin Object class=moCheckBox name=DCM
        WinTop=0.316000
        WinLeft=0.050000
        WinWidth=0.4200000
        WinHeight=0.048125
        Caption="Display Completing Messages"
        Hint="If Checked: Completing messages will be displayed(Solo Only)"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_DCM=DCM

    Begin Object class=moCheckBox name=OIF
        WinTop=0.3880000
        WinLeft=0.100000
        WinWidth=0.370000
        WinHeight=0.048125
        Caption="Failed"
        Hint="If Checked: Failures will be displayed(Solo Only)"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_OIF=OIF

    Begin Object class=moCheckBox name=OIN
        WinTop=0.460000
        WinLeft=0.100000
        WinWidth=0.370000
        WinHeight=0.048125
        Caption="Succeed"
        Hint="If Checked: Succeeds will be displayed(Solo Only)"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_OIN=OIN

    Begin Object class=moCheckBox name=PCS
        WinTop=0.532
        WinLeft=0.100000
        WinWidth=0.370000
        WinHeight=0.048125
        Caption="Play Sounds"
        Hint="If Checked: Completing messages will also play a sound(Solo Only)"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_PCS=PCS

    Begin Object class=GUIEditBox name=FailSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.594000
        WinLeft=0.050000
        WinWidth=0.420000
        WinHeight=0.050000
        Hint="Sound for the failure message"
        OnChange=InternalOnChange
    End Object
    eb_FailSound=FailSound

    Begin Object class=GUIEditBox name=SucceedSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.666
        WinLeft=0.050000
        WinWidth=0.420000
        WinHeight=0.050000
        Hint="Sound for the succeed message"
        OnChange=InternalOnChange
    End Object
    eb_SucceedSound=SucceedSound

    // Right Side

    Begin Object class=moCheckBox name=PT
        WinTop=0.100000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Personal Timer"
        Hint="If Checked: Record timer will be based on your Personal Time(Solo Only)"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_PT=PT

    Begin Object class=moCheckBox name=DFT
        WinTop=0.172000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Display Full Time"
        Hint="If UnChecked: Record timer will show (e.g. 00:00:10.41) only those who have actually a value, will be drawn (e.g. 10.41)"
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
        Hint="Key to toggle tables of BTimes"
        OnChange=InternalOnChange
    End Object
    eb_ToggleKey=ToggleKey

    Begin Object class=moCheckBox name=PM
        WinTop=0.388000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Profesional Mode"
        Hint="If Checked: All players will be invisible and make no sound(Online and Solo only)"
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
        Hint="If Checked: BehindView will be automatic enabled on spawn(Online and Solo only)"
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
        Hint="If Checked: Tick sounds are played"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_PTS=PTS

    Begin Object class=GUIEditBox name=TickSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.594000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.050000
        Hint="Sound for ticking timer"
        OnChange=InternalOnChange
    End Object
    eb_TickSound=TickSound

    Begin Object class=GUIEditBox name=LastTickSound
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.656000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.050000
        Hint="Final sound for ticking timer"
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
        Hint="Reset all the changes you've done back to default"
    End Object
    b_Reset=ResetButton

    Begin Object class=GUIButton name=SaveButton
        Caption="Save"
        WinTop=0.800000
        WinLeft=0.825000
        WinWidth=0.130000
        WinHeight=0.050000
        Hint="Save all the changes you've done"
        OnClick=InternalOnClick
    End Object
    b_Save=SaveButton
}