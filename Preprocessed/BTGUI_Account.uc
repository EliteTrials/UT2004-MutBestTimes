class BTGUI_Account extends BTGUI_TabBase;

var automated GUIButton b_TradeCurrency;
var automated GUIEditBox eb_TradePlayer, eb_TradeAmount;

var automated GUIButton b_GhostFollow;
var automated GUIEditBox eb_GhostPlayer;

var automated GUIButton b_ActivateKey;
var automated GUIEditBox eb_Key;

function bool InternalOnClick( GUIComponent sender )
{
    PlayerOwner().ConsoleCommand( "CloseDialog" );
    if( sender == b_TradeCurrency )
    {
        if( eb_TradePlayer.GetText() == "" )
        {
            PlayerOwner().ClientMessage( "Please specifiy a player's name!" );
            return false;
        }

        if( eb_TradeAmount.GetText() == "" )
        {
            PlayerOwner().ClientMessage( "Please enter amount of currency that you want to send!" );
            return false;
        }

        if( int(eb_TradeAmount.GetText()) <= 0 )
        {
            PlayerOwner().ClientMessage( "Please send more than 0 currency!" );
            return false;
        }

        PlayerOwner().ConsoleCommand( "TradeCurrency" @ eb_TradePlayer.GetText() @ int(eb_TradeAmount.GetText()) );
        return true;
    }
    else if( sender == b_GhostFollow )
    {
        if( eb_GhostPlayer.GetText() == "" && Locs(eb_GhostPlayer.GetText()) != Locs("exec:None") )
        {
            PlayerOwner().ClientMessage( "Please specifiy a player's name! If you are trying to remove it, then specify exec:None" );
            return false;
        }

        PlayerOwner().ConsoleCommand( "GhostFollow" @ eb_GhostPlayer.GetText() );
        return true;
    }
    else if( sender == b_ActivateKey )
    {
        if( eb_Key.GetText() == "" )
        {
            PlayerOwner().ClientMessage( "Please input a valid key." );
            return false;
        }

        PlayerOwner().ConsoleCommand( "ActivateKey" @ eb_Key.GetText() );
        return true;
    }
    return false;
}

defaultproperties
{
    Begin Object class=GUIButton name=oTradeCurrency
        Caption="Trade Currency"
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
        Hint="Currency(20% of this will be used as fee!)"
    End Object
    eb_TradeAmount=oTradeAmount

    // GhostFollow
    Begin Object class=GUIButton name=oGhostFollow
        Caption="Hire Ghost"
        WinTop=0.07
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Hire the ghost for 25 currency! Note: Ghost can be rehired by someone else when you have it!"
    End Object
    b_GhostFollow=oGhostFollow

    Begin Object class=GUIEditBox name=oGhostPlayer
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.07
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        Hint="Player Name"
    End Object
    eb_GhostPlayer=oGhostPlayer

    // ActivateKey
    Begin Object class=GUIButton name=oActivateKey
        Caption="Activate Key"
        WinTop=0.89
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Activate a BestTimes key"
    End Object
    b_ActivateKey=oActivateKey

    Begin Object class=GUIEditBox name=oKey
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.89
        WinLeft=0.26
        WinWidth=0.74
        WinHeight=0.05
        Hint="A BestTimes key"
    End Object
    eb_Key=oKey
}