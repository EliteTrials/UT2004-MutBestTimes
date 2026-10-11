class BTGUI_Account extends BTGUI_TabBase;

var automated GUIButton b_TradeCurrency;
var automated GUIEditBox eb_TradePlayer, eb_TradeAmount;
var automated GUIButton b_LinkDiscord, b_CopyDiscord, b_ConfirmDiscord, b_CancelDiscord;
var automated GUIEditBox eb_DiscordCommand;
var automated GUILabel l_DiscordStatus, l_DiscordProfile;

private function SetDiscordButtonEnabled(GUIButton Button, bool bEnabled)
{
    if (bEnabled && Button.MenuState == MSAT_Disabled)
        EnableComponent(Button);
    else if (!bEnabled && Button.MenuState != MSAT_Disabled)
        DisableComponent(Button);
}

function bool UpdateDiscordPanel(Canvas C)
{
    local BTClient_ClientReplication CRI;
    local bool bCodeReady, bPending;
    local int Seconds;
    CRI = class'BTClient_ClientReplication'.static.GetCRI(PlayerOwner().PlayerReplicationInfo);
    if (CRI == none || !CRI.bDiscordAvailable)
    {
        SetDiscordButtonEnabled(b_LinkDiscord, false);
        SetDiscordButtonEnabled(b_CopyDiscord, false);
        SetDiscordButtonEnabled(b_ConfirmDiscord, false);
        SetDiscordButtonEnabled(b_CancelDiscord, false);
        l_DiscordStatus.Caption = "Discord linking is unavailable on this server.";
        l_DiscordProfile.Caption = "";
        eb_DiscordCommand.SetText("");
        return true;
    }
    Seconds = Max(0, int(CRI.DiscordCodeExpiresAt - PlayerOwner().Level.TimeSeconds));
    bCodeReady = CRI.DiscordLinkState == 2 && CRI.DiscordLinkCode != "" && Seconds > 0;
    bPending = CRI.DiscordLinkState >= 1 && CRI.DiscordLinkState <= 3;
    SetDiscordButtonEnabled(b_LinkDiscord, !CRI.bDiscordAuthenticated && !bPending);
    SetDiscordButtonEnabled(b_CopyDiscord, bCodeReady);
    SetDiscordButtonEnabled(b_ConfirmDiscord, CRI.DiscordLinkState == 3);
    SetDiscordButtonEnabled(b_CancelDiscord, bPending);
    l_DiscordStatus.Caption = CRI.DiscordLinkMessage;
    if (l_DiscordStatus.Caption == "")
        l_DiscordStatus.Caption = "Choose Link Discord to connect your account.";
    if (CRI.bDiscordAuthenticated)
    {
        l_DiscordProfile.Caption = "Discord: " $ CRI.DiscordProfile.DisplayName $ " (@"
            $ CRI.DiscordProfile.Username $ ") | ID: " $ CRI.DiscordProfile.UserId;
        l_DiscordStatus.Caption = "Your Discord account is linked. Authentication will restore when you reconnect.";
    }
    else
    {
        l_DiscordProfile.Caption = "";
    }
    if (bCodeReady)
    {
        eb_DiscordCommand.SetText("/link code:" $ CRI.DiscordLinkCode);
        l_DiscordStatus.Caption = "Code ready (" $ Seconds $ "s remaining). Copy it and submit /link in Discord.";
    }
    else
        eb_DiscordCommand.SetText("");
    return true;
}

function bool InternalOnClick( GUIComponent sender )
{
    local BTClient_ClientReplication CRI;
    CRI = class'BTClient_ClientReplication'.static.GetCRI(PlayerOwner().PlayerReplicationInfo);
    if (sender == b_LinkDiscord && CRI != none && CRI.bDiscordAvailable)
    {
        CRI.DiscordLinkState = 1;
        CRI.DiscordLinkMessage = "Requesting a Discord code...";
        CRI.DiscordLinkCode = "";
        PlayerOwner().ConsoleCommand("mutate discordlinkui");
        return true;
    }
    if (sender == b_CopyDiscord && CRI != none && CRI.DiscordLinkState == 2
        && CRI.DiscordLinkCode != "" && CRI.DiscordCodeExpiresAt > PlayerOwner().Level.TimeSeconds)
    {
        PlayerOwner().CopyToClipboard("/link code:" $ CRI.DiscordLinkCode);
        return true;
    }
    if (sender == b_ConfirmDiscord)
    {
        PlayerOwner().ConsoleCommand("mutate discordconfirm");
        return true;
    }
    if (sender == b_CancelDiscord)
    {
        PlayerOwner().ConsoleCommand("mutate discordcancel");
        return true;
    }
    if( sender == b_TradeCurrency )
    {
        PlayerOwner().ConsoleCommand( "CloseDialog" );
        if( eb_TradePlayer.GetText() == "" )
        {
            PlayerOwner().ClientMessage( "Please specifiy a player's name!" );
            return false;
        }

        if( eb_TradeAmount.GetText() == "" )
        {
            PlayerOwner().ClientMessage( "Please enter amount of money that you want to give!" );
            return false;
        }

        if( int(eb_TradeAmount.GetText()) <= 0 )
        {
            PlayerOwner().ClientMessage( "Please send more than 0$!" );
            return false;
        }

        PlayerOwner().ConsoleCommand( "TradeMoney" @ eb_TradePlayer.GetText() @ int(eb_TradeAmount.GetText()) );
        return true;
    }
    return false;
}

defaultproperties
{
    OnPreDraw=UpdateDiscordPanel

    Begin Object class=GUILabel name=oDiscordStatus
        Caption="Choose Link Discord to connect your account."
        WinTop=0.14
        WinLeft=0.0
        WinWidth=1.0
        WinHeight=0.06
        bScaleToParent=True
        bBoundToParent=True
        TextColor=(R=255,G=255,B=255,A=255)
        FontScale=FNS_Small
        StyleName="BTLabel"
    End Object
    l_DiscordStatus=oDiscordStatus

    Begin Object class=GUILabel name=oDiscordProfile
        WinTop=0.21
        WinLeft=0.0
        WinWidth=1.0
        WinHeight=0.06
        bScaleToParent=True
        bBoundToParent=True
        TextColor=(R=182,G=182,B=182,A=255)
        FontScale=FNS_Small
        StyleName="BTLabel"
    End Object
    l_DiscordProfile=oDiscordProfile

    Begin Object class=GUIButton name=oLinkDiscord
        Caption="Link Discord"
        WinTop=0.29
        WinLeft=0.0
        WinWidth=0.24
        WinHeight=0.05
        bScaleToParent=True
        bBoundToParent=True
        OnClick=InternalOnClick
        Hint="Request a code to link your Discord account."
    End Object
    b_LinkDiscord=oLinkDiscord

    Begin Object class=GUIEditBox name=oDiscordCommand
        WinTop=0.36
        WinLeft=0.0
        WinWidth=0.73
        WinHeight=0.05
        bScaleToParent=True
        bBoundToParent=True
        bReadOnly=True
        Hint="Submit this command in the configured Discord server."
    End Object
    eb_DiscordCommand=oDiscordCommand

    Begin Object class=GUIButton name=oCopyDiscord
        Caption="Copy"
        WinTop=0.36
        WinLeft=0.75
        WinWidth=0.24
        WinHeight=0.05
        bScaleToParent=True
        bBoundToParent=True
        OnClick=InternalOnClick
        Hint="Copy the /link command to your clipboard."
    End Object
    b_CopyDiscord=oCopyDiscord

    Begin Object class=GUIButton name=oConfirmDiscord
        Caption="Confirm"
        WinTop=0.43
        WinLeft=0.0
        WinWidth=0.24
        WinHeight=0.05
        bScaleToParent=True
        bBoundToParent=True
        OnClick=InternalOnClick
        Hint="Confirm the Discord account shown above after submitting /link."
    End Object
    b_ConfirmDiscord=oConfirmDiscord

    Begin Object class=GUIButton name=oCancelDiscord
        Caption="Cancel"
        WinTop=0.43
        WinLeft=0.26
        WinWidth=0.24
        WinHeight=0.05
        bScaleToParent=True
        bBoundToParent=True
        OnClick=InternalOnClick
        Hint="Cancel the current link request. Use /unlink in Discord to remove a saved link."
    End Object
    b_CancelDiscord=oCancelDiscord

    Begin Object class=GUIButton name=oTradeCurrency
        Caption="Trade Money"
        WinTop=0.01
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Trade currency with the specified player."
    End Object
    b_TradeCurrency=oTradeCurrency

    Begin Object class=GUIEditBox name=oTradePlayer
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.01
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        Hint="Player Name"
    End Object
    eb_TradePlayer=oTradePlayer

    Begin Object class=GUIEditBox name=oTradeAmount
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.01
        WinLeft=0.52
        WinWidth=0.25
        WinHeight=0.05
        Hint="Money (20% of this will be used as fee!)"
    End Object
    eb_TradeAmount=oTradeAmount
}
