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
    cb_RGOD,
    cb_PM,
    cb_ABV,
    cb_DodgeDelay,
    cb_DodgeReady;

var automated GUIEditBox
    eb_TickSound,
    eb_LastTickSound,
    eb_FailSound,
    eb_SucceedSound,
    eb_ToggleKey;

var automated AltSectionBackground
    SB_Border;

// Used for saving.
var bool bCanSave;

var BTClient_Config Options;

event Free()
{
    Options = none;
    super.Free();
}

function InitPanel()
{
    super.InitPanel();

    Options = Class'BTClient_Config'.static.FindSavedData();
    if( Options == None )
    {
        Log( "BTClient_Config not found!", Name );
        return;
    }

    CopyOptions();
}

function CopyOptions()
{
    cb_UseAltTimer.Checked( Options.bUseAltTimer );
    cb_ShowZoneActors.Checked( Options.bShowZoneActors );
    cb_FadeTextColors.Checked( Options.bFadeTextColors );
    cb_DCM.Checked( Options.bDisplayCompletingMessages );
    cb_OIF.Checked( Options.bDisplayFail );
    cb_OIN.Checked( Options.bDisplayNew );
    cb_PCS.Checked( Options.bPlayCompletingSounds );
    cb_PT.Checked( Options.bBaseTimeLeftOnPersonal );
    cb_PTS.Checked( Options.bPlayTickSounds );
    cb_DFT.Checked( Options.bDisplayFullTime );
    cb_RGOD.Checked( Options.bResetGhostOnDead );
    cb_PM.Checked( Options.bProfesionalMode );
    cb_ABV.Checked( Options.bAutoBehindView );
    cb_DodgeDelay.Checked( Options.bShowDodgeDelay );
    cb_DodgeReady.Checked( Options.bShowDodgeReady );

    eb_TickSound.SetText( string(Options.TickSound) );
    eb_LastTickSound.SetText( string(Options.LastTickSound) );
    eb_FailSound.SetText( string(Options.FailSound) );
    eb_SucceedSound.SetText( string(Options.NewSound) );
    eb_ToggleKey.SetText( Class'Interactions'.static.GetFriendlyName( Options.RankingTableKey ) );
}

function bool InternalOnClick( GUIComponent Sender )
{
    if( Sender == b_Save )
    {
        DisableComponent( b_Save );

        SaveData();
        return true;
    }
    else if( Sender == b_Reset )
    {
        DisableComponent( b_Reset );

        Options.ResetSavedData();
        CopyOptions();
        return true;
    }
    return false;
}

function InternalOnChange( GUIComponent Sender )
{
    EnableComponent( b_Save );
    EnableComponent( b_Reset );
}

// Update ini config
function SaveData()
{
    Options.bUseAltTimer = cb_UseAltTimer.IsChecked();
    Options.bShowZoneActors = cb_ShowZoneActors.IsChecked();
    Options.bFadeTextColors = cb_FadeTextColors.IsChecked();
    Options.bDisplayCompletingMessages = cb_DCM.IsChecked();
    Options.bDisplayFail = cb_OIF.IsChecked();
    Options.bDisplayNew = cb_OIN.IsChecked();
    Options.bPlayCompletingSounds = cb_PCS.IsChecked();
    Options.bBaseTimeLeftOnPersonal = cb_PT.IsChecked();
    Options.bPlayTickSounds = cb_PTS.IsChecked();
    Options.bDisplayFullTime = cb_DFT.IsChecked();
    Options.bResetGhostOnDead = cb_RGOD.IsChecked();
    Options.bProfesionalMode = cb_PM.IsChecked();
    Options.bAutoBehindView = cb_ABV.IsChecked();
    Options.bShowDodgeDelay = cb_DodgeDelay.IsChecked();
    Options.bShowDodgeReady = cb_DodgeReady.IsChecked();

    Options.TickSound = Sound(DynamicLoadObject( eb_TickSound.GetText(), Class'Sound', True ));
    Options.LastTickSound = Sound(DynamicLoadObject( eb_LastTickSound.GetText(), Class'Sound', True ));
    Options.FailSound = Sound(DynamicLoadObject( eb_FailSound.GetText(), Class'Sound', True ));
    Options.NewSound = Sound(DynamicLoadObject( eb_SucceedSound.GetText(), Class'Sound', True ));

    Options.RankingTableKey = Options.static.ConvertToKey( eb_ToggleKey.GetText() );

    Options.SaveConfig();

    MyMenu.MyInteraction.MRI.CR.ReplicateResetGhost();
    MyMenu.MyInteraction.UpdateToggleKey();
}

defaultproperties
{
    bCanSave=true

    Begin Object class=AltSectionBackground name=border
        WinTop      =   0.025000
        WinLeft     =   0.025000
        WinWidth    =   0.950000
        WinHeight   =   0.900000
        Caption="Options"
//      HeaderBar=None
//      HeaderBase=Material'2K4Menus.NewControls.Display99'
    End Object
    SB_Border=border

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

    Begin Object class=moCheckBox name=RGOD
        WinTop=0.244000
        WinLeft=0.530000
        WinWidth=0.425000
        WinHeight=0.048125
        Caption="Reset Ghost"
        Hint="If Checked: Ghost will restart to the start whenever you respawn(Solo only and if alone)"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_RGOD=RGOD

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

    Begin Object class=moCheckBox name=oDodgeReady
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.728
        WinLeft=0.530000
        WinWidth=0.195000
        WinHeight=0.050000
        Caption="Dodge Ready"
        Hint="(Dodge Perk)Shows when you are able to dodge to again!"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_DodgeReady=oDodgeReady

    Begin Object class=moCheckBox name=oDodgeDelay
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.728
        WinLeft=0.760000
        WinWidth=0.195000
        WinHeight=0.050000
        Caption="Dodge Delay"
        Hint="(Dodge Perk)Helps you research your dodge timing!"
        bAutoSizeCaption=True
        OnChange=InternalOnChange
    End Object
    cb_DodgeDelay=oDodgeDelay

    // bottom

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