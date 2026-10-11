class BTGUI_Commands extends BTGUI_TabBase;

var automated GUIButton
    b_ShowMapInfo,
    b_ShowPlayerInfo,
    b_ShowMissingRecords,
    b_ShowBadRecords,
    b_SetClientSpawn,
    b_DeleteClientSpawn,
    b_RecentRecords,
    b_RecentMaps,
    b_RecentHistory,
    b_ToggleRanking,
    b_RevoteMap;

var automated GUIEditBox eb_ShowMapInfo, eb_ShowPlayerInfo;
var automated GUIScrollTextBox eb_Desc;

function InitComponent( GUIController InController, GUIComponent InOwner )
{
    super.InitComponent( InController,InOwner );

    eb_Desc.MyScrollText.SetContent( "You are allowed to say things in the chat as a command by prefixing it with a ! symbol.||Such as:|"
        $ "!Red, !Blue|!CP|!Revote, !Vote, !VoteMap <Filter>|!Join, !Spec|!Wager <Value>, !Title <Title>|"
    );
    eb_Desc.MyScrollBar.AlignThumb();
    eb_Desc.MyScrollBar.UpdateGripPosition( 0 );
}

function bool InternalOnClick( GUIComponent sender )
{
    PlayerOwner().ConsoleCommand( "CloseDialog" );
    if( sender == b_ShowMapInfo )
    {
        PlayerOwner().ConsoleCommand( "ShowMapInfo" @ eb_ShowMapInfo.GetText() );
        return true;
    }
    else if( sender == b_ShowPlayerInfo )
    {
        PlayerOwner().ConsoleCommand( "ShowPlayerInfo" @ eb_ShowPlayerInfo.GetText() );
        return true;
    }
    else if( sender == b_ShowMissingRecords )
    {
        PlayerOwner().ConsoleCommand( "ShowMissingRecords" );
        return true;
    }
    else if( sender == b_ShowBadRecords )
    {
        PlayerOwner().ConsoleCommand( "ShowBadRecords" );
        return true;
    }
    else if( sender == b_SetClientSpawn )
    {
        PlayerOwner().ConsoleCommand( "SetClientSpawn" );
        return true;
    }
    else if( sender == b_DeleteClientSpawn )
    {
        PlayerOwner().ConsoleCommand( "DeleteClientSpawn" );
        return true;
    }
    else if( sender == b_RecentRecords )
    {
        PlayerOwner().ConsoleCommand( "RecentRecords" );
        return true;
    }
    else if( sender == b_RecentHistory )
    {
        PlayerOwner().ConsoleCommand( "RecentHistory" );
        return true;
    }
    else if( sender == b_RecentMaps )
    {
        PlayerOwner().ConsoleCommand( "RecentMaps" );
        return true;
    }
    else if( sender == b_ToggleRanking )
    {
        PlayerOwner().ConsoleCommand( "ToggleRanking" );
        return true;
    }
    else if( sender == b_RevoteMap )
    {
        PlayerOwner().ConsoleCommand( "RevoteMap" );
        return true;
    }
    return false;
}

defaultproperties
{
    Begin Object class=GUIButton name=oShowPlayerInfo
        Caption="Show Player Info"
        WinTop=0.01
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Shows a dialog with info of the inputted player"
    End Object
    b_ShowPlayerInfo=oShowPlayerInfo

    Begin Object class=GUIEditBox name=oPlayerName
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.01
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        Hint="Player Name"
    End Object
    eb_ShowPlayerInfo=oPlayerName

    Begin Object class=GUIButton name=oShowMapInfo
        Caption="Show Map Info"
        WinTop=0.07
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Shows a dialog with info of the inputted map"
    End Object
    b_ShowMapInfo=oShowMapInfo

    Begin Object class=GUIEditBox name=oMapName
        bScaleToParent=True
        bBoundToParent=True
        WinTop=0.07
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        Hint="Map Name"
    End Object
    eb_ShowMapInfo=oMapName

    Begin Object class=GUIButton name=oShowMissingRecords
        Caption="Show Available Records"
        WinTop=0.13
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Shows a dialog with info of what solo records you haven't yet recorded"
    End Object
    b_ShowMissingRecords=oShowMissingRecords

    Begin Object class=GUIButton name=oShowBadRecords
        Caption="Show Bad Records"
        WinTop=0.13
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Shows a dialog with info of what solo records you are not in the top 3"
    End Object
    b_ShowBadRecords=oShowBadRecords

    Begin Object class=GUIButton name=oSetClientSpawn
        Caption="Set Client Spawn"
        WinTop=0.19
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Sets you a new client spawn point at your present position"
    End Object
    b_SetClientSpawn=oSetClientSpawn

    Begin Object class=GUIButton name=oDeleteClientSpawn
        Caption="Delete Client Spawn"
        WinTop=0.19
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Deletes your client spawn point"
    End Object
    b_DeleteClientSpawn=oDeleteClientSpawn

    Begin Object class=GUIButton name=oToggleRanking
        Caption="Show Rankings"
        WinTop=0.25
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Show all time top rankings(F12)"
    End Object
    b_ToggleRanking=oToggleRanking

    Begin Object class=GUIButton name=oRevoteMap
        Caption="Revote Current Map"
        WinTop=0.31
        WinLeft=0.0
        WinWidth=0.51
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Revote the currently playing map"
    End Object
    b_RevoteMap=oRevoteMap

    Begin Object class=GUIButton name=oRecentRecords
        Caption="Recent Records"
        WinTop=0.87
        WinLeft=0.0
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Show recently set records"
    End Object
    b_RecentRecords=oRecentRecords

    Begin Object class=GUIButton name=oRecentMaps
        Caption="Recent Maps"
        WinTop=0.87
        WinLeft=0.26
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Show recently new added maps"
    End Object
    b_RecentMaps=oRecentMaps

    Begin Object class=GUIButton name=oRecentHistory
        Caption="Recent History"
        WinTop=0.87
        WinLeft=0.52
        WinWidth=0.25
        WinHeight=0.05
        OnClick=InternalOnClick
        Hint="Show recently history, such as records being deleted"
    End Object
    b_RecentHistory=oRecentHistory

    // Right nav
    Begin Object Class=GUIScrollTextBox Name=oDescription
        WinWidth    =   0.48
        WinHeight   =   0.85
        WinLeft     =   0.52
        WinTop      =   0.01
        bBoundToParent=False
        bScaleToParent=False
        StyleName="NoBackground"
        bNoTeletype=true
        bNeverFocus=true
    End Object
    eb_Desc=oDescription
}