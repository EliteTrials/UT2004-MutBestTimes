//==============================================================================
// BTClient_Interaction.uc (C) 2005-2019 Eliot and .:..:. All Rights Reserved
//
// This class handles the widgets on the HUD, the F12 tables and any interaction with BTimes.
//==============================================================================
class BTClient_Interaction extends Interaction;

#exec obj load file="UT2003Fonts.utx"
#exec obj load file="Textures/ClientBTimes.utx" package="ClientBTimesV7b"
#exec obj load file="Textures/CountryFlagsUT2K4.utx" package="ClientBTimesV7b" group="CountryFlags"

// Not localized so that changes will take affect for everyone, if a new version changes these...
// Besides i'm not gonna write them for all languages anyway?
var private const
    string
    RecordTimeMsg,
    RecordHolderMsg,
    RecordTimeLeftMsg,
    RecordEmptyMsg,
    RecordHubMsg,
    RecordTimeElapsed,
    RankingHideMsg;

var private string
    RankingKeyMsg,
    OldKey;

var private BTClient_MutatorReplicationInfo     MRI;                                // Set by BTClient_MutatorReplicationInfo
var private HUD                                 myHUD;
var private BTClient_Config                     BTConfig;                            // Object to Config, set on Initialized()
var private BTClient_ClientReplication          SpectatedClient;                    // Set by PostRender(), used for showing the record timer of other players...
var private BTClient_LevelReplication           ActiveLevel;

var private array<Pickup> KeyPickupsList;

var private Color
    TimePositiveColor,
    TimeNegativeColor,
    TimeCheckColor,
    TimeTickColor;

var private bool
    bTestRun,
    bPauseTest,
    bMenuModified,
    bRenderAll, bRenderOnlyDynamic;

var private name RenderTag;
var private byte RenderMode;

var private int ElapsedTime;

var private float
    LastTickTime,
    Delay,
    YOffsetScale,                               // Offset scale for EndMap tables
    LastTime,
    DrawnTimer;

var private bool bTimerPaused, bSoundTicking;

var private const Texture BackgroundTexture;

var private const TexRotator MarkerArrow;

// DODGEPERK DATA
var private Actor LastBase;
var private Actor.EPhysics LastPhysicsState;
var private Actor.EDoubleClickDir LastDoubleClickDir;
var private float LastDodgeTime;
var private float LastLandedTime;
var private float LastPerformedDodgeTime;
var private bool bPerformedDodge;
var private bool bPreDodgeReady;
var private bool bDodgeReady;
var private bool bPromodeWasPerformed;
var private bool bTimeViewTarget;

private function SendConsoleMessage( string Msg )
{
    ViewportOwner.Actor.Player.Console.Message( Msg, 1.0 );
}

exec function TestAchievement( optional bool bProgress )
{
    if( bProgress )
    {
        MRI.CR.ClientAchievementProgressed( "Hello, Achievement!", "", 10, 100 );
        return;
    }
    MRI.CR.ClientAchievementAccomplished( "Hello, Achievement!", "" );
}

// Shortcut for Mutate
exec function BT( string Command )
{
    if( Delay > ViewportOwner.Actor.Level.TimeSeconds )
        return;

    Delay = ViewportOwner.Actor.Level.TimeSeconds + 0.5;
    ViewportOwner.Actor.ServerMutate( Command );
}

exec function Store( string command )
{
    local array<string> params;

    if( Delay > ViewportOwner.Actor.Level.TimeSeconds )
        return;

    Delay = ViewportOwner.Actor.Level.TimeSeconds + 0.5;

    Split( Locs( command ), " ", params );
    if( params.Length < 2 || params[1] == "" )
    {
        return;
    }

    switch( params[0] )
    {
        case "edit": case "edititem":
            ConsoleCommand( "edit_" $ params[1] );
            break;

        case "buy": case "buyitem":
            ViewportOwner.Actor.ServerMutate( "buyitem" @ params[1] );
            break;

        case "sell": case "sellitem":
            ViewportOwner.Actor.ServerMutate( "sellitem" @ params[1] );
            break;

        case "destroyitem":
            ViewportOwner.Actor.ServerMutate( "destroyitem" @ params[1] );
            break;

        case "giveitem":
            ViewportOwner.Actor.ServerMutate( "giveitem" @ params[1] @ params[2] );
            break;

        case "toggleitem":
            ViewportOwner.Actor.ServerMutate( "toggleitem" @ params[1] );
            break;
    }
}

exec function TradeMoney( string playerName, int amount )
{
    BT( "TradeMoney" @ playerName @ amount );
}

exec function ActivateKey( string key )
{
    BT( "ActivateKey" @ key );
}

exec function SetConfigProperty( string Property, string Value )
{
    if( BTConfig != None )
    {
        if( BTConfig.SetPropertyText( Property, Value ) )
            BTConfig.SaveConfig();
    }
}

exec function CloseDialog()
{
    MRI.CR.Text.Length = 0;
}

exec function UpdatePreferedColor()
{
    local string colorText;

    BTConfig.SaveConfig();

    MRI.CR.ServerSetPreferedColor( BTConfig.PreferedColor );

    colorText = BTConfig.PreferedColor.R @ BTConfig.PreferedColor.G @ BTConfig.PreferedColor.B;
    ConsoleCommand( "SetTrailerColor" @ colorText @ colorText );
}

exec function PreferedColorDialog()
{
    ViewportOwner.Actor.ClientOpenMenu( string(class'BTGUI_ColorDialog') );
}

exec function SetYOffsetScale( float newScale )
{
    YOffsetScale = newScale;
}

exec function ShowBestTimes()
{
    local string FPage;

    FPage = MRI.RankingPage;
    if( FPage != "" )
    {
        if( InStr( FPage, "http://" ) != -1 )
        {
            ConsoleCommand( "EndFullScreen" );
            ConsoleCommand( "open"@FPage );
            return;
        }

        FPage = "http://"$FPage;
        ConsoleCommand( "EndFullScreen" );
        ConsoleCommand( "open"@FPage );
    }
    else SendConsoleMessage( "Sorry ShowBestTimes is not available on this server!" );
}

exec function edit_Trailer()
{
    TrailerMenu();
}

exec function edit_MNAFAccess()
{
    ConsoleCommand( "ShieldGunMenu" );
}

exec function TrailerMenu()
{
    if( ViewportOwner.Actor.Pawn == none )
        return;

    ViewportOwner.Actor.ClientOpenMenu( string( Class'BTClient_TrailerMenu' ) );
}

exec function Kill(){FastSuicide();}
exec function FastSuicide()
{
    if( ViewportOwner.Actor.Pawn == None )
        return;

    BT( "Suicide" );
}

exec function RecentRecords()
{
    BT( "RecentRecords" );
}

exec function RecentHistory()
{
    BT( "RecentHistory" );
}

exec function RecentMaps()
{
    BT( "RecentMaps" );
}

exec function SetTrailerColor( string CmdLine )
{
    BT( "SetTrailerColor" @ CmdLine );
}

exec function SetTrailerTexture( string CmdLine )
{
    BT( "SetTrailerTexture" @ CmdLine );
}

exec function Player( string playerName ){ShowPlayerInfo(playerName);}
exec function ShowPlayerInfo( string playerName )
{
    BT( "ShowPlayerInfo" @ playerName );
}

exec function Map( string mapName ){ShowMapInfo(mapName);}
exec function ShowMapInfo( string mapName )
{
    BT( "ShowMapInfo" @ mapName );
}

exec function ShowMissingRecords()
{
    BT( "ShowMissingRecords" );
}

exec function ShowBadRecords()
{
    BT( "ShowBadRecords" );
}

exec function SetClientSpawn()
{
    BT( "SetClientSpawn" );
}

exec function CreateClientSpawn()
{
    BT( "CreateClientSpawn" );
}

exec function MakeClientSpawn()
{
    BT( "MakeClientSpawn" );
}

exec function DeleteClientSpawn()
{
    BT( "DeleteClientSpawn" );
}

exec function RemoveClientSpawn()
{
    BT( "RemoveClientSpawn" );
}

exec function KillClientSpawn()
{
    BT( "KillClientSpawn" );
}

exec function ResetCheckPoint()
{
    BT( "ResetCheckPoint" );
}

exec function VoteMapSeq( int sequence )
{
    BT( "VoteMapSeq" @ sequence );
}

exec function RevoteMap()
{
    if( ViewportOwner.Actor.PlayerReplicationInfo.bAdmin || ViewportOwner.Actor.Level.NetMode == NM_StandAlone )
        BT( "QuickStart" );
    else BT( "VoteMap" @ Left( string(MRI), InStr( string(MRI), "." ) ) );
}

exec function VoteMap( string PartInMapName )
{
    BT( "VoteMap" @ PartInMapName );
}

exec function Race( string playerName )
{
    BT( "Race" @ playerName );
}

exec function ToggleRanking()
{
    ViewPortOwner.GUIController.OpenMenu( string(class'BTGUI_RankingsMenu') );
}

exec function SpeedRun()
{
    BTConfig.bUseAltTimer = !BTConfig.bUseAltTimer;
    SendConsoleMessage( "SpeedRun:"$BTConfig.bUseAltTimer );
    BTConfig.SaveConfig();
}

function bool KeyEvent( out EInputKey Key, out EInputAction Action, float Delta )
{
    // Wait until the game's state is completely replicated.
    if( MRI.CR == none )
        return false;

    if( Action == IST_Press )
    {
        if( Key == IK_MiddleMouse )
        {
            ResetCheckPoint();
            return false;
        }

        if( Key == BTConfig.RankingTableKey )
        {
            if( MRI.CR.Text.Length > 0 )
                MRI.CR.Text.Length = 0;
            else ToggleRanking();
            return false;
        }

        if( Key == IK_Escape || (MRI.CR.Text.Length > 0 && Key == IK_Enter) )
        {
            if( MRI.CR.Text.Length > 0 )
            {
                MRI.CR.Text.Length = 0;
                return true;
            }
            return false;
        }

        if( Key == IK_GreyPlus )
        {
            BTConfig.ScreenFontSize = Min( ++ BTConfig.ScreenFontSize, 6 );
            return true;
        }
        else if( Key == IK_GreyMinus )
        {
            BTConfig.ScreenFontSize = Max( -- BTConfig.ScreenFontSize, -5 );
            return true;
        }
    }
    return false;
}

exec function StartTimer()
{
    bTestRun = true;
    LastTickTime = MRI.Level.TimeSeconds;
    SendConsoleMessage( "Test-Run:ON" );
}

exec function PauseTimer()
{
    if( bTestRun )
    {
        bPauseTest = !bPauseTest;
        SendConsoleMessage( "Test-Run Paused:"$bPauseTest );
    }
}

exec function StopTimer()
{
    SendConsoleMessage( "Test-Run:OFF" );
    bTestRun = False;
    bPauseTest = False;
    //ElapsedTime = StopTime - StartTime;
    SendConsoleMessage( "Test-Run:"$FormatTime( ElapsedTime ) );

    ElapsedTime = 0;
    LastTickTime = 0;
}

exec function GotoLevel(coerce string levelName)
{
    // TODO: Make a mutate call
    ConsoleCommand("say"@"!level"@levelName);
}

exec function ShowLevelsMenu()
{
    GUIController(ViewportOwner.Actor.Player.GUIController).OpenMenu(string(class'BTGUI_LevelMenu'));
}

event Tick( float DeltaTime )
{
    local xPawn p;
    local LinkedReplicationInfo LRI;
    local BTClient_LevelReplication lastActiveLevel;

    // Wait for replication
    if( ViewportOwner.Actor.PlayerReplicationInfo != none )
    {
        if( BTConfig != none && (BTConfig.bProfesionalMode || bPromodeWasPerformed) )
        {
            foreach ViewportOwner.Actor.DynamicActors( class'xPawn', p )
            {
                if( p.PlayerReplicationInfo == none )
                {
                    continue;
                }

                if( p == ViewportOwner.Actor.ViewTarget )
                {
                    if( p.bHidden )
                    {
                        p.SoundVolume = p.default.SoundVolume;
                        p.bHidden = false;
                    }
                    continue;
                }

                if( !p.bHidden )
                {
                    p.SoundVolume = 0;
                    p.bHidden = true;
                    bPromodeWasPerformed = true;
                }
                else if( !BTConfig.bProfesionalMode && bPromodeWasPerformed )
                {
                    p.SoundVolume = p.default.SoundVolume;
                    p.bHidden = false;
                }
            }

            if( bPromodeWasPerformed && !BTConfig.bProfesionalMode )
            {
                bPromodeWasPerformed = false;
            }
        }

        // See if client is spectating someone!
        SpectatedClient = none;
        P = xPawn(ViewportOwner.Actor.ViewTarget);
        if( p != none && p != ViewportOwner.Actor.Pawn )
        {
            if( p != none && p.PlayerReplicationInfo != none )
            {
                for( LRI = p.PlayerReplicationInfo.CustomReplicationInfo; LRI != none; LRI = LRI.NextReplicationInfo )
                {
                    if( BTClient_ClientReplication(LRI) != none )
                    {
                        SpectatedClient = BTClient_ClientReplication(LRI);
                        break;
                    }
                }
            }
        }

        // Look for our ClientReplication object
        if( MRI.CR == none )
        {
            for( LRI = ViewportOwner.Actor.PlayerReplicationInfo.CustomReplicationInfo; LRI != none; LRI = LRI.NextReplicationInfo )
            {
                if( BTClient_ClientReplication(LRI) != none )
                {
                    MRI.CR = BTClient_ClientReplication(LRI);
                    MRI.CR.MRI = MRI;
                    break;
                }
            }
        }

        // Not spectating anyone, assign to myself!
        if( SpectatedClient == none )
        {
            SpectatedClient = MRI.CR;
        }
        lastActiveLevel = ActiveLevel;
        ActiveLevel = GetCurrentLevel();
        if( ActiveLevel != lastActiveLevel )
        {
            if( lastActiveLevel != none )
            {
                lastActiveLevel.HideObjective();
            }

            if( ActiveLevel != none )
            {
                ActiveLevel.ShowObjective();
                HUD_Assault(myHUD).CurrentObjective = ActiveLevel.GetObjective();
            }
        }

        if( ActiveLevel == none )
        {
            HUD_Assault(myHUD).CurrentObjective = none;
        }

        if( MRI.CR != none && MRI.CR.bAllowDodgePerk )
        {
            PerformDodgePerk();
        }
    }

    if( !bMenuModified )
        ModifyMenu();

    ReplaceVotingMenu();

    /* Speed Timer */
    if( bTestRun && !bPauseTest )
    {
        if( MRI.Level.TimeSeconds >= LastTickTime )
        {
            ++ ElapsedTime;
            LastTickTime = MRI.Level.TimeSeconds + 1.0;
        }
    }

    if(!ViewportOwner.Actor.Level.PhysicsVolume.bHidden)
    {
        SendConsoleMessage( "ShowAll is not allowed on this server, therefor you have been kicked" );
        ConsoleCommand( "Disconnect" );
    }
}

exec function TimeViewTarget()
{
    bTimeViewTarget = !bTimeViewTarget;
}

private function PerformDodgePerk()
{
    local Pawn p;
    local bool bDodgePossible;
    local Actor.EPhysics phy;
    local Actor.EDoubleClickDir dir;
    local name anim;
    local float animFrame, animRate;

    if( bTimeViewTarget )
    {
        p = Pawn(ViewportOwner.Actor.ViewTarget);
    }
    else
    {
        p = ViewportOwner.Actor.Pawn;
    }
    if( p == none )
        return;

    if( SpectatedClient.LastPawn != p )
    {
        bPerformedDodge = false;
        LastLandedTime = ViewportOwner.Actor.Level.TimeSeconds;
        LastDodgeTime = ViewportOwner.Actor.Level.TimeSeconds;
        LastDoubleClickDir = DClick_None;
        LastPhysicsState = PHYS_None;
        LastBase = none;
        bPreDodgeReady = true;
        bDodgeReady = true;
    }

    phy = p.Physics;
    if( MRI.CR.bAllowDodgePerk )
    {
        bDodgePossible = ((phy == PHYS_Falling && p.bCanWallDodge) || phy == PHYS_Walking) && !p.bIsCrouched && !p.bWantsToCrouch;
        bPreDodgeReady = (ViewportOwner.Actor.Level.TimeSeconds-LastLandedTime)/ViewportOwner.Actor.Level.TimeDilation >= 0.10 && !bPerformedDodge && bDodgePossible;
        bDodgeReady = (ViewportOwner.Actor.Level.TimeSeconds-LastLandedTime)/ViewportOwner.Actor.Level.TimeDilation >= 0.35 && !bPerformedDodge && bDodgePossible;
    }

    if( (LastPhysicsState != PHYS_Walking && phy == PHYS_Walking) || (bTimeViewTarget && p.Base != LastBase) )
    {
        //ViewportOwner.Actor.ClientMessage( "Land!" );
        PerformedLanding( p );
    }

    dir = xPawn(p).CurrentDir;
    p.GetAnimParams(0, anim, animFrame, animRate); // for simulated pawns.
    if( (bTimeViewTarget && !bPerformedDodge && (dir > DCLICK_None || InStr(Caps(anim), "DODGE") != -1)) || dir > DCLICK_None )
    {
        PerformedDodge( p );
        xPawn(p).CurrentDir = DCLICK_None;
    }

    LastPhysicsState = phy;
    LastBase = p.Base;
    SpectatedClient.LastPawn = p;
}

private function PerformedDodge( Pawn other )
{
    bPerformedDodge = true;
    LastPerformedDodgeTime = ViewportOwner.Actor.Level.TimeSeconds - LastLandedTime;
    LastDodgeTime = ViewportOwner.Actor.Level.TimeSeconds;
}

private function PerformedLanding( Pawn other )
{
    if( bPerformedDodge )
    {
        LastLandedTime = ViewportOwner.Actor.Level.TimeSeconds;
        bPerformedDodge = false;
    }
    LastDoubleClickDir = DCLICK_None;
}

private function Vector RenderDodgeReady( Canvas C, float drawY )
{
    local string s;
    local float xl, yl;

    if( !bPreDodgeReady )
    {
        s = string(LastPerformedDodgeTime/ViewportOwner.Actor.Level.TimeDilation)$"s";
    }
    else
    {
        s = (ViewportOwner.Actor.Level.TimeSeconds - LastLandedTime)/ViewportOwner.Actor.Level.TimeDilation$"s";
    }

    if( bDodgeReady )
    {
        C.DrawColor = class'HUD'.default.GreenColor;
    }
    else if( !bPreDodgeReady )
    {
        C.DrawColor = class'HUD'.default.TurqColor;
    }
    else
    {
        C.DrawColor = class'HUD'.default.RedColor;
    }
    C.StrLen( s, xl, yl );
    return DrawElement( C, C.ClipX*0.5, drawY, Mid(GetEnum( enum'EDoubleClickDir', ViewportOwner.Actor.DoubleClickDir ), 7), s, true, 200, 1.0, C.DrawColor );
}

event Initialized()
{
    local DefaultPhysicsVolume DPV;

    BTConfig = class'BTClient_Config'.static.FindSavedData();

    // Hide so that "ShowAll" will set bHidden to false, and if so, we can kick the player for using "ShowAll".
    foreach ViewportOwner.Actor.DynamicActors( class'DefaultPhysicsVolume', DPV )
    {
        DPV.bHidden = true;
        break;
    }

    UpdateToggleKey();

    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_HUD', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_MultiColumnList', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_ListSelection', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Header', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Footer', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Label', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY2EditBox', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY2SectionHeaderTop', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Button', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_TabButton', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_CloseButton', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_ContextMenu', true );
}

exec function UpdateToggleKey()
{
    local string Key;

    Key = class'Interactions'.static.GetFriendlyName( BTConfig.RankingTableKey );
    if( Len( OldKey ) == 0 )
    {
        RankingKeyMsg = Repl( RankingKeyMsg, "%KEY%", BTConfig.CGoldText$Key$class'HUD'.default.WhiteColor );
    }
    else
    {
        RankingKeyMsg = Repl( RankingKeyMsg, OldKey, BTConfig.CGoldText $Key$class'HUD'.default.WhiteColor );
    }
    OldKey = Key;
}

final function ObjectsInitialized( BTClient_MutatorReplicationInfo mutRep )
{
    local Pickup Key;

    MRI = mutRep;
    myHUD = ViewportOwner.Actor.myHUD;

    if( MRI != None )
    {
        if( MRI.bKeyMap )
        {
            foreach ViewportOwner.Actor.AllActors( class'Pickup', Key )
            {
                if( Key.IsA('LCAKeyPickup') )
                    KeyPickupsList[KeyPickupsList.Length] = Key;
            }
        }

        if( MRI.bSoloMap )
        {
            // Hide the existing assault "Objective completed" message, as we have replaced this with our own record message.
            class'Message_Awards'.default.bComplexString = false;
            class'Message_Awards'.default.PosY = -1.0;
        }
    }
}

private function ReplaceVotingMenu()
{
    local GUIController c;
    local VotingReplicationInfo vri;
    local int menuIndex;

    vri = VotingReplicationInfo(ViewportOwner.Actor.VoteReplicationInfo);
    if( vri == none || !vri.bMapVote )
        return;

    c = GUIController(ViewportOwner.Actor.Player.GUIController);
    if( c == none )
        return;

    menuIndex = c.FindMenuIndexByName( c.MapVotingMenu );
    if( menuIndex != -1 )
    {
        if( GUIQuestionPage(c.TopPage()) != none )
        {
            c.CloseMenu( true );
        }
        c.RemoveMenuAt( menuIndex, true );
        c.OpenMenu( string(class'BTClient_MapVotingPage') );
    }
}

private function ModifyMenu()
{
    local UT2K4PlayerLoginMenu Menu;
    local BTClient_Menu myMenu;
    local BTGUI_Store storeMenu;

    Menu = UT2K4PlayerLoginMenu(GUIController(ViewportOwner.Actor.Player.GUIController).FindPersistentMenuByName( UnrealPlayer(ViewportOwner.Actor).LoginMenuClass ));
    if( Menu != none )
    {
        Menu.BackgroundRStyle = MSTY_None;
        Menu.i_FrameBG.Image = Texture(DynamicLoadObject( "2k4Menus.NewControls.Display99", Class'Texture', True ));
        Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_AdvancedButton', True );
        Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_StoreButton', True );

        storeMenu = BTGUI_Store(Menu.c_Main.AddTab( "Item Shop", string(Class'BTGUI_Store'),, "Buy Items" ));
        if( storeMenu != none )
        {
            storeMenu.MyButton.StyleName = "StoreButton";
            storeMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "StoreButton", storeMenu.FontScale );
            storeMenu.PostInitPanel();
        }

        myMenu = BTClient_Menu(Menu.c_Main.AddTab( "My Profile", string(Class'BTClient_Menu'),, "Your BTimes Profile" ));
        if( myMenu != none )
        {
            myMenu.MyButton.StyleName = "AdvancedButton";
            myMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "AdvancedButton", myMenu.FontScale );
            myMenu.PostInitPanel();
        }

        bMenuModified = true;
    }
}

event NotifyLevelChange()
{
    super.NotifyLevelChange();
    MRI = none;
    myHUD = none;
    BTConfig = none;
    SpectatedClient = none;
    ActiveLevel = none;
    KeyPickupsList.Length = 0;
    LastBase = none;
    Master.RemoveInteraction( self );

    // Restore the objective completed message!
    class'Message_Awards'.default.bComplexString = true;
    class'Message_Awards'.default.PosY = 0.242;
}

final function Color GetFadingColor( color FadingColor )
{
    if( BTConfig.bFadeTextColors )
        return MRI.GetFadingColor( FadingColor );

    return FadingColor;
}

exec function ShowZoneActors( optional bool bshowAll, optional bool bdynamicOnly, optional name tag, optional byte rm )
{
    BTConfig.bShowZoneActors = !BTConfig.bShowZoneActors || bshowAll;
    SendConsoleMessage( "ShowZoneActors:"$BTConfig.bShowZoneActors );
    BTConfig.SaveConfig();

    bRenderAll = bshowAll;
    bRenderOnlyDynamic = bdynamicOnly;
    RenderTag = tag;
    RenderMode = rm;
}

exec function ShowCollision()
{
    ToggleShowFlag( 31 );
}

exec function ToggleShowFlag( byte bit )
{
    local int flag;

    if( ViewPortOwner.Actor.Level.NetMode != NM_StandAlone )
        return;

    flag = 0x1 << bit;
    if( (ViewPortOwner.Actor.ShowFlags & flag) == flag )
    {
        ViewPortOwner.Actor.ShowFlags = ViewPortOwner.Actor.ShowFlags & (~flag);
    }
    else ViewPortOwner.Actor.ShowFlags = ViewPortOwner.Actor.ShowFlags | flag;
}

exec function ToggleMisc1( byte bit )
{
    local int flag;

    if( ViewPortOwner.Actor.Level.NetMode != NM_StandAlone )
        return;

    flag = 0x1 << bit;
    if( (ViewPortOwner.Actor.Misc1 & flag) == flag )
    {
        ViewPortOwner.Actor.Misc1 = ViewPortOwner.Actor.Misc1 & (~flag);
    }
    else ViewPortOwner.Actor.Misc1 = ViewPortOwner.Actor.Misc1 | flag;
}

exec function ToggleMisc2( byte bit )
{
    local int flag;

    if( ViewPortOwner.Actor.Level.NetMode != NM_StandAlone )
        return;

    flag = 0x1 << bit;
    if( (ViewPortOwner.Actor.Misc2 & flag) == flag )
    {
        ViewPortOwner.Actor.Misc2 = ViewPortOwner.Actor.Misc2 & (~flag);
    }
    else ViewPortOwner.Actor.Misc2 = ViewPortOwner.Actor.Misc2 | flag;
}

private function RenderZoneActors( Canvas C, PlayerController player )
{
    local Actor A;
    local Teleporter NextTP;
    local vector Scre, Scre2;
    local string S;
    local float Dist, XL, YL;
    local bool bWireframed;
    local byte oldRendMap;

    if( Pawn(player.ViewTarget) == none )
        return;

    if( bRenderAll )
    {
        if( RenderMode == 1 )
        {
            bWireframed = true;
        }
        else
        {
            oldRendMap = player.RendMap;
            player.RendMap = RenderMode;
        }

        C.SetPos( 0, 0 );
        if( bRenderOnlyDynamic )
        {
            foreach player.DynamicActors( class'Actor', A, RenderTag )
            {
                C.DrawActor( A, bWireframed );
            }
        }
        else
        {
            foreach player.AllActors( class'Actor', A, RenderTag )
            {
                C.DrawActor( A, bWireframed );
            }
        }

        if( !bWireframed )
        {
            player.RendMap = oldRendMap;
        }
        return;
    }

    foreach player.Region.Zone.ZoneActors( Class'Actor', A )
    {
        if( Mover(A) != None )
        {
            if( ViewportOwner.Actor.LineOfSightTo( A ) )
            {
                C.SetPos( 0, 0 );
                C.DrawActor( A, True );
            }
            continue;
        }
        else if( BlockingVolume(A) != None || PhysicsVolume(A) != None )
        {
            if( ViewportOwner.Actor.LineOfSightTo( A ) )
            {
                C.SetPos( 0, 0 );
                C.DrawActor( A, True );
            }
            continue;
        }
        else if( StaticMeshActor(A) != None && (!A.bBlockNonZeroExtentTraces || !A.bCollideActors) )
        {
            if( ViewportOwner.Actor.LineOfSightTo( A ) )
            {
                C.SetPos( 0, 0 );
                C.DrawActor( A, True );
            }
            continue;
        }
        else if( Teleporter(A) != None )
        {
            if( ViewportOwner.Actor.LineOfSightTo( A ) )
            {
                C.SetPos( 0, 0 );
                C.DrawActor( A, True );

                Scre = C.WorldToScreen( A.Location );
                if( Teleporter(A).URL != "" )
                {
                    S = Teleporter(A).URL;
                    foreach player.AllActors( Class'Teleporter', NextTP )
                    {
                        if( string( NextTP.Tag ) == S )
                        {
                            Dist = VSize( NextTP.Location - A.Location );
                            if( Dist <= 1000 )
                            {
                                Scre2 = C.WorldToScreen( NextTP.Location );
                                Class'HUD'.Static.StaticDrawCanvasLine( C, Scre.X, Scre.Y, Scre2.X, Scre2.Y, myHUD.BlueColor );

                                C.StrLen( "End", XL, YL );
                                C.SetPos( Scre2.X - (XL*0.5), Scre2.Y - (YL*1.2) );
                                C.SetDrawColor( 0, 255, 0, 255 );
                                C.DrawText( S, True );
                            }
                        }
                    }

                    if( NextTP == None )
                        continue;

                    C.SetDrawColor( 0, 255, 0, 255 );
                    C.StrLen( "Start", XL, YL );
                    C.SetPos( Scre.X - (XL*0.5), Scre.Y - (YL*1.2) );
                    C.DrawText( S, True );
                }
            }
            continue;
        }
        else if( GameObjective(A) != None )
        {
            if( ViewportOwner.Actor.LineOfSightTo( A ) )
            {
                C.SetPos( 0, 0 );
                C.DrawActor( A, True );
            }
            continue;
        }
    }
}

// As of LCA v3 ClientBTimes will no longer render keys, LCA v3 will now render the keys.
private function RenderKeys( Canvas C, PlayerController player )
{
    local int i, j;
    local string KeyName;
    local Inventory Inv;
    local bool bHasThisKey;
    local vector CamPos;
    local rotator CamRot;
    local vector X, Y, Z;
    local float Dist;
    local vector Dir;

    j = KeyPickupsList.Length;
    if( j > 0 )
    {
        for( i = 0; i < j; ++ i )
        {
            if( KeyPickupsList[i] == None )
                continue;

            KeyName = "";
            KeyName = KeyPickupsList[i].GetPropertyText( "KeyName" );
            bHasThisKey = False;
            // Check if already have!
            if( player.Pawn != None )
            {
                for( Inv = player.Pawn.Inventory; Inv != None; Inv = Inv.Inventory )
                {
                    if( Inv.IsA('LCAKeyInventory') && KeyName == Inv.GetPropertyText( "KeyName" ) )
                    {
                        bHasThisKey = True;
                        break;
                    }
                }
            }

            if( bHasThisKey )
                continue;

            C.GetCameraLocation( CamPos, CamRot );
            GetAxes( player.ViewTarget.Rotation, X, Y, Z );
            Dir = KeyPickupsList[i].Location - CamPos;
            Dist = VSize( Dir );
            Dir /= Dist;
            if( (Dir Dot X) > 0.6 && Dist < 3000 )  // only render if this location is not outside the player view.
            {
                C.Style = player.ERenderStyle.STY_Alpha;
                C.DrawColor = Class'HUD'.Default.GoldColor;
                class'HUD_Assault'.static.Draw_2DCollisionBox( C, KeyPickupsList[i], C.WorldToScreen( KeyPickupsList[i].Location ), KeyName, KeyPickupsList[i].DrawScale, True );
                continue;
            }
        }
    }
}

// Adapted code from HUD.uc->GetConsoleFont
final static function Font GetScreenFont( Canvas C )
{
    local int FontSize;

    FontSize = 7 - class'BTClient_Config'.static.FindSavedData().ScreenFontSize;
    if( C.ClipX < 640 )
        ++ FontSize;
    if( C.ClipX < 800 )
        ++ FontSize;
    if( C.ClipX < 1024 )
        ++ FontSize;
    if( C.ClipX < 1280 )
        ++ FontSize;
    if( C.ClipX < 1600 )
        ++ FontSize;
    return class'HUDBase'.static.LoadFontStatic( Min( 8, FontSize ) );
}

private function RenderPathTimers(Canvas C, PlayerController player)
{
    local BTClient_GhostMarker Marking;
    local vector Scr;
    local float XL, YL, yPadding;
    local float T, YT, lastRenderTimePct, lastRenderTimeDelta;
    local string S;
    local vector Dir, X, Y, Z, CamPos, mX, mY;
    local rotator CamRot;
    local float Dist, markDir;
    local float topTime;

    const MAX_MARKING_DIST = 1024f;
    const MAX_MARKING_NEAR_DIST = 512f;

    topTime = GetTopTime();
    C.GetCameraLocation(CamPos, CamRot);
    GetAxes(CamRot, X, Y, Z);

    C.Style = 5;
    foreach player.DynamicActors(class'BTClient_GhostMarker', Marking) {
        Dir = Marking.Location - CamPos;
        Dist = VSize( Dir );
        if (Dist > MAX_MARKING_DIST) {
            continue;
        }

        markDir = (vector(Marking.Rotation) dot X);
        if (markDir < 0.0) {
            continue;
        }

        lastRenderTimeDelta = player.Level.TimeSeconds - Marking.LastRenderTimeX;

        Dir /= Dist;
        // only render if this location is not outside the player view.
        if ((Dir dot X) > 0.6) {
            T = topTime * (float(Marking.MoveIndex)/ActiveLevel.PrimaryGhostNumMoves);
            YT = T - (topTime - GetTimeLeft());
            if (YT >= 0f) {
                S = "+"$FormatTimeCompact(YT);
                C.DrawColor = TimePositiveColor;
            }
            else {
                S = FormatTimeCompact(YT);
                C.DrawColor = TimeNegativeColor;
            }

            if (BTConfig.bRenderPathTimerIndex) {
                S @= "#" $ Marking.MoveIndex+1;
            }

            if (Dist < MAX_MARKING_NEAR_DIST) {
                lastRenderTimePct = FMin(lastRenderTimeDelta/0.3f, 1.0f);
                Scr.X = Marking.LastRenderScr.X*(1.0 - lastRenderTimePct) + (C.ClipX*0.5*lastRenderTimePct);
                Scr.Y = Marking.LastRenderScr.Y*(1.0 - lastRenderTimePct) + (C.ClipY*0.4*lastRenderTimePct);
                C.DrawColor.A = 255f*(Dist/MAX_MARKING_NEAR_DIST);
            }
            else {
                Scr = C.WorldToScreen(Marking.Location);
                C.DrawColor.A = 255f - 255f*(Dist/MAX_MARKING_DIST);
            }

            C.StrLen(S, XL, YL);
            C.SetPos(Scr.X - XL*0.5, Scr.Y - YL*0.5);
            C.DrawText(S, false);

            GetAxes(Marking.Rotation, mX, mY, z);
            MarkerArrow.Rotation.Yaw = Atan(Normal(mX).X, Normal(mY).Y) * 32768 / PI;
            C.SetPos(Scr.X - YL*0.5, Scr.Y - YL*0.5 - YL - 4f);
            C.DrawTile(MarkerArrow, YL, YL, 0.0, 0.0, 128f, 128f);

            Marking.LastRenderScr = Scr;
            Marking.LastRenderTimeX = player.Level.TimeSeconds;
            Marking.LastRecordTimeDelta = YT;
        } else if (lastRenderTimeDelta <= 2.0) {
            YT = Marking.LastRecordTimeDelta;
            if (YT >= 0f) {
                S = "+"$FormatTimeCompact(YT);
                C.DrawColor = TimeCheckColor;
            }
            else {
                S = FormatTimeCompact(YT);
                C.DrawColor = TimeNegativeColor;
            }

            if (BTConfig.bRenderPathTimerIndex) {
                S @= "#" $ Marking.MoveIndex+1;
            }

            lastRenderTimePct = FMin(lastRenderTimeDelta, 1.0f);
            Scr.X = C.ClipX*0.5;
            Scr.Y = C.ClipY*0.4*(1.0 - lastRenderTimePct) + (C.ClipY*0.35 - yPadding)*lastRenderTimePct;
            C.DrawColor.A = 255f*FMin(Dist/MAX_MARKING_NEAR_DIST, 1.0 - lastRenderTimePct);

            C.StrLen(S, XL, YL);
            C.SetPos(Scr.X - XL*0.5, Scr.Y - YL*0.5);
            C.DrawText(S, false);

            yPadding += YL+8f;
        }
    }
    C.Style = 1;
}

private function RenderTitle( Canvas C, PlayerController player )
{
    local xPawn P;
    local vector Scre, CamLoc, X, Y, Z, Dir;
    local rotator CamRot;
    local float Dist, XL, YL;
    local string s;
    local BTClient_ClientReplication CRI;

    foreach player.DynamicActors( Class'xPawn', P )
    {
        if( P == player.ViewTarget
            || P.IsA('Monster')
            || P.bHidden
            || P.bDeleteMe
            || P.bDeRes)
        {
            continue;
        }

        C.GetCameraLocation( CamLoc, CamRot );
        Dir = P.Location - CamLoc;
        Dist = VSize( Dir );
        if( Dist > player.TeamBeaconMaxDist || !player.FastTrace( P.Location, CamLoc ) )
        {
            continue;
        }

        // Don't render pawns behind me!
        GetAxes( player.ViewTarget.Rotation, X, Y, Z );
        Dir /= Dist;
        if( !((Dir Dot X) > 0.6) )
        {
            continue;
        }

        if( Dist < (player.TeamBeaconPlayerInfoMaxDist * 0.4f) )
        {
            // Looks for the CRI of this Pawn
            foreach player.DynamicActors( Class'BTClient_ClientReplication', CRI )
            {
                if( CRI.myPawn == P )
                {
                    break;
                }
            }

            if( CRI == None )
            {
                continue;
            }

            if( CRI.Title == "" )
            {
                continue;
            }

            s = CRI.Title;
            C.TextSize( %s, XL, YL );
            Scre = C.WorldToScreen( P.Location - vect(0,0,1) * P.CollisionHeight );
            DrawElement( C, Scre.X, Scre.Y - YL*0.5f, s, "", true );
        }
    }
}

private function RenderCompetitiveLayer( Canvas C )
{
    local float XL, YL;
    local float gameScore, redPct, bluePct;
    local float StartX, StartY, SizeX;
    local string S;

    // Simulate the CurrentObjective widget position!
    C.Font = myHUD.GetMediumFont( C.ClipX * myHUD.HUDScale );
    C.TextSize( "Team Balance", XL, YL );

    SizeX = Max( C.ClipX * 0.15f, XL );
    StartX = C.ClipX * 0.5f - SizeX * 0.5f;
    StartY = YL + YL;

    C.Style = 1;
    C.DrawColor = class'HUD'.default.GreenColor;
    C.SetPos( StartX, StartY );
    C.DrawTile( BackgroundTexture, SizeX, YL, 0, 0, 256, 256 );

    gameScore = MRI.Level.GRI.Teams[0].Score + MRI.Level.GRI.Teams[1].Score;
    if( gameScore >= 0f )
    {
        redPct = MRI.Level.GRI.Teams[0].Score / gameScore;
        bluePct = MRI.Level.GRI.Teams[1].Score / gameScore;

        // Draw red's pct
        S = FormatTimeCompact( MRI.TeamTime[0] ) @ "-" @ string(int(MRI.Level.GRI.Teams[0].Score));
        C.TextSize( S, XL, YL );
        C.DrawColor = class'HUD_Assault'.static.GetTeamColor( 0 );
        C.SetPos( StartX - XL - 8, StartY );
        C.Style = 3;
        C.DrawText( S );

        C.SetPos( StartX, StartY );
        C.Style = 1;
        C.DrawTile( BackgroundTexture, SizeX * (1f - bluePct), YL, 0, 0, 256, 256 );

        // Draw blue's pct
        S = string(int(MRI.Level.GRI.Teams[1].Score)) @ "-" @ FormatTimeCompact( MRI.TeamTime[1] );
        C.TextSize( S, XL, YL );
        C.DrawColor = class'HUD_Assault'.static.GetTeamColor( 1 );
        C.SetPos( StartX + SizeX + 8, StartY );
        C.Style = 3;
        C.DrawText( S );

        C.SetPos( StartX + (SizeX - SizeX * (1f - redPct)), StartY );
        C.Style = 1;
        C.DrawTile( BackgroundTexture, SizeX * (1f - redPct), YL, 0, 0, 256, 256 );
    }

    C.Style = 3;
    S = "Team Balance";
    C.TextSize( S, XL, YL );
    C.SetPos( StartX + SizeX * 0.5 - XL * 0.5, StartY );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.DrawText( S );

    // Draw border
    C.CurX = StartX;
    C.DrawColor = class'HUD'.default.GrayColor;
    C.DrawColor.A = 100;
    class'BTLevelCompletedMessage'.static.DrawHorizontal( C, StartY-2, SizeX );
    class'BTLevelCompletedMessage'.static.DrawHorizontal( C, StartY+YL, SizeX );
    C.CurY -= 2;
    class'BTLevelCompletedMessage'.static.DrawVertical( C, StartX, YL+4 );
    class'BTLevelCompletedMessage'.static.DrawVertical( C, StartX+SizeX, YL+4 );
}

const TABLE_PADDING = 4;
const HEADER_GUTTER = 2;
const COLUMN_MARGIN = 2;
const COLUMN_PADDING_X = 4;
const COLUMN_PADDING_Y = 2;
const ROW_MARGIN = 2;

final static function DrawLayer( Canvas C, float x, float y, float width, float height )
{
    C.SetPos( x, y );
    C.DrawTile( default.BackgroundTexture, width, height, 0, 0, 256, 256 );
    C.SetPos( x, y ); // Reset pushment from DrawTile
}

final static function DrawHeaderTile( Canvas C, float x, float y, float width, float height )
{
    C.DrawColor = #0xEA200A78;
    DrawLayer( C, x, y, width, height );
}

final static function DrawHeaderText( Canvas C, float x, float y, string title )
{
    C.SetPos( x + COLUMN_PADDING_X, y + COLUMN_PADDING_Y );
    C.DrawColor = #0xD4D4D4FF;
    C.DrawText( title, false );
    C.SetPos( x, y ); // Reset pushment from DrawText
}

final static function DrawColumnTile( Canvas C, float x, float y, float width, float height )
{
    DrawLayer( C, x, y, width, height );
}

final static function DrawColumnText( Canvas C, float x, float y, string title )
{
    C.SetPos( x + COLUMN_MARGIN, y + COLUMN_MARGIN );
    C.DrawText( title, false );
    C.SetPos( x, y ); // Reset pushment from DrawText
}

final function Vector DrawElement( Canvas C, float x, float y, string title, optional coerce string value, optional bool bCenter, optional float minWidth, optional float scaling, optional Color textColor, optional Color tileColor )
{
    local float xl, yl, valueXL;
    local Vector v;
    local string s;

    if( minWidth == 0 )
    {
        minWidth = 120;
    }

    if( scaling == 0.0 )
    {
        scaling = 1.0;
    }

    if( value != "" )
    {
        s = title $ " " $ value;
        C.StrLen( %value, valueXL, yl );
    }
    else
    {
        s = title;
    }
    C.StrLen( %s, xl, yl );
    xl = Max( xl, minWidth );
    if( tileColor.A == 0 )
    {
        C.DrawColor = BTConfig.CTable;
    }
    else
    {
        C.DrawColor = tileColor;
    }
    if( bCenter )
    {
        x = x - xl*0.5;
    }
    DrawLayer( C, x, y, xl + COLUMN_PADDING_X*2*scaling, yl + COLUMN_PADDING_Y*2*scaling );

    if( value != "" )
    {
        C.SetPos( x + COLUMN_PADDING_X*scaling, y + COLUMN_PADDING_Y*scaling + COLUMN_MARGIN );
    }
    else
    {
        C.StrLen( %title, valueXL, yl );
        C.SetPos( x + xl*0.5 - valueXL*0.5 + COLUMN_PADDING_X*scaling, y + COLUMN_PADDING_Y*scaling + COLUMN_MARGIN );
    }

    if( value == "" && textColor.A != 0 )
    {
        C.DrawColor = textColor;
    }
    else
    {
        C.DrawColor = #0xEEEEEEFF;
    }
    C.DrawTextClipped( title, false );

    if( value != "" )
    {
        C.SetPos( x + xl - valueXL + COLUMN_PADDING_X*scaling, y + COLUMN_PADDING_Y*scaling + COLUMN_MARGIN );
        if( textColor.A == 0 )
        {
            C.DrawColor = #0xCCCCCCEFF;
        }
        else
        {
            C.DrawColor = textColor;
        }
        C.DrawTextClipped( value, false );
    }
    if( bCenter )
    {
        x = x + xl*0.5;
    }
    C.SetPos( x, y ); // Reset pushment from DrawText

    v.x = xl + COLUMN_PADDING_X*2*scaling;
    v.y = yl + COLUMN_PADDING_Y*2*scaling;
    return v;
}

final function DrawElementTile( Canvas C, float x, float y, float width, float height )
{
    C.DrawColor = BTConfig.CTable;
    DrawLayer( C, x, y, width + COLUMN_PADDING_X*2, height + COLUMN_PADDING_Y*2 );
}

final static function DrawElementPart( Canvas C, float x, float y, string title, optional Color textColor )
{
    C.SetPos( x, y + COLUMN_PADDING_Y + COLUMN_MARGIN );
    if( textColor.A == 0 )
    {
        C.DrawColor = #0xFFFFFFFF;
    }
    else
    {
        C.DrawColor = textColor;
    }
    C.DrawText( title, false );
    C.SetPos( x, y ); // Reset pushment from DrawText
}

final static function DrawElementText( Canvas C, float x, float y, string title )
{
    C.SetPos( x + COLUMN_PADDING_X, y + COLUMN_PADDING_Y + COLUMN_MARGIN );
    C.DrawColor = #0xFFFFFFFF;
    C.DrawText( title, false );
    C.SetPos( x, y ); // Reset pushment from DrawText
}

final static function DrawElementValue( Canvas C, float x, float y, string title, optional Color textColor )
{
    C.SetPos( x - COLUMN_PADDING_X, y + COLUMN_PADDING_Y + COLUMN_MARGIN );
    if( textColor.A == 0 )
    {
        C.DrawColor = #0xFFFFFFFF;
    }
    else
    {
        C.DrawColor = textColor;
    }
    C.DrawTextClipped( title );
    C.SetPos( x, y ); // Reset pushment from DrawText
}

private function RenderFooter( Canvas C )
{
    // PRE-RENDERED
    local float tableX, tableY;
    local float tableWidth, tableHeight;
    local float drawX, drawY;
    local float fontXL, fontYL;

    // Temporary string measures.
    local float xl, yl, width, height;
    local string s;

    // PRE-RENDERING
    C.StrLen( "T", fontXL, fontYL );

    tableWidth = C.ClipX;
    tableHeight = (fontYL*3 + ROW_MARGIN) + ROW_MARGIN + HEADER_GUTTER;

    tableX = 0;
    tableY = C.ClipY - tableHeight;

    // Progressing render position, starting from the absolute table's position.
    drawX = tableX + TABLE_PADDING;
    drawY = tableY;

    // Press F12 or Escape to hide this.
    s = RankingKeyMsg @ RankingHideMsg;
    C.StrLen( s, xl, yl );
    width = xl;
    height = (tableHeight - TABLE_PADDING)*0.5;
    drawX = tableWidth - TABLE_PADDING - xl;
    drawY = tableY + tableHeight - height - TABLE_PADDING;
    C.DrawColor = #0x0072C688;
    DrawColumnTile( C, drawX, drawY, width, height );
    DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );
}

function PreRender( Canvas C )
{
    TimePositiveColor = GetFadingColor(class'HUD'.default.GreenColor);
    TimeNegativeColor = GetFadingColor(class'HUD'.default.RedColor);
    TimeCheckColor = GetFadingColor(class'HUD'.default.TurqColor);
}

function PostRender( Canvas C )
{
    local string S;
    local float XL,YL;
    local int i, j, YLength, FLength;
    local float YP, XP;
    local float XP1;
    local PlayerController player;

    player = ViewportOwner.Actor;
    if( player.myHUD.bShowScoreBoard
        || player.myHUD.bHideHUD
        || MRI == None
        || player.PlayerReplicationInfo == None )
        return;

    C.Font = GetScreenFont( C );
    if( myHUD != none ) {
        for( i = 0; i < myHUD.Overlays.Length; ++ i ) {
            if( myHUD.Overlays[i] == none ) {
                myHUD.Overlays.Remove( i --, 1 );
            }
        }

        if( MRI.bKeyMap ) {
            RenderKeys( C, player );
        }

        if( !MRI.bSoloMap && BTConfig.bShowZoneActors ) {
            RenderZoneActors( C, player );
        }

        if (BTConfig.bRenderPathTimers && ActiveLevel != none) {
            RenderPathTimers( C, player );
        }
    }

    RenderTitle( C, player );
    if( MRI.CR == none )
        return;

    // COMPETITIVE HUD
    if( MRI.bCompetitiveMode )
    {
        RenderCompetitiveLayer( C );
        C.Font = GetScreenFont( C ); // Re set our font.
    }

    // TextBox code
    j = MRI.CR.Text.Length;
    if( j > 0 )
    {
        C.StrLen( "T", xl, yl );

        YLength = yl*j + (j*3) + TABLE_PADDING;
        FLength = C.ClipY*0.5 - YLength*0.5;

        XP = C.ClipX*0.125;
        YP = FLength;

        XP1 = C.ClipX;
        C.SetPos( XP, YP - TABLE_PADDING );
        C.DrawColor = BTConfig.CTable;
        C.Style = 1;
        C.DrawTile( BackgroundTexture, C.ClipX*0.75, YLength + TABLE_PADDING, 0, 0, 256, 256 );

        // Draw the packets
        YP += TABLE_PADDING;
        for( i = 0; i < j; ++ i )
        {
            C.SetPos( XP + TABLE_PADDING*2, YP + i*yl );
            if( i == 0 )
            {
                C.StrLen( %MRI.CR.Text[i], xl, yl );
                C.DrawColor = #0x00529668;
                DrawColumnTile( C, C.CurX, C.CurY, xl+4, yl+2 );
                DrawHeaderText( C, C.CurX, C.CurY, MRI.CR.Text[i] );
            }
            else
            {
                C.DrawColor = class'HUD'.default.WhiteColor;
                C.DrawText( MRI.CR.Text[i] );
            }

            YP += 3;
        }
        C.ClipX = XP1;

        RenderFooter( C );
    }

    if (InvasionGameReplicationInfo(player.Level.GRI) != none) {
        return;
    }

    if( MRI.RecordState == RS_Active )
    {
        bTimerPaused = (player.IsInState( 'GameEnded' ) || player.IsInState( 'RoundEnded' ));
        if (!bTimerPaused && MRI.bSoloMap) {
            bTimerPaused = player.IsInState( 'Dead' )
                || player.ViewTarget == none
                || (xPawn(player.ViewTarget) != none && (xPawn(player.ViewTarget).bPlayedDeath || xPawn(player.ViewTarget).IsInState('Dying')));
        }

        if( bTestRun )
        {
            C.Font = myHUD.GetMediumFont( C.ClipX * (myHUD.HUDScale*0.75) );

            if( bPauseTest )
                C.DrawColor = C.Default.DrawColor;
            else C.DrawColor = class'HUD'.default.WhiteColor;

            DrawTextWithBackground( C, FormatTime( ElapsedTime ), C.DrawColor, C.ClipX*0.5, C.ClipY*0.75 );
            return;
        }

        /* Simple drawing */
        if( BTConfig.bUseAltTimer )
        {
            // Don't count if game ended etc
            if( bTimerPaused )
            {
                if( DrawnTimer == 0.0f )
                    DrawnTimer = GetTopTime();
            }
            else
            {
                DrawnTimer = GetTimeLeft();
            }

            if( DrawnTimer <= 0 )
                C.DrawColor = class'HUD'.default.RedColor;
            else C.DrawColor = class'HUD'.default.WhiteColor;

            C.Font = myHUD.GetMediumFont( C.ClipX * (myHUD.HUDScale*0.75) );
            DrawTextWithBackground( C, FormatTime( DrawnTimer ), C.DrawColor, C.ClipX*0.5, C.ClipY*0.75 );
            return;
        }

        // Draw record information!.
        // Don't render anything when the objectives board is displayed.
        if( HUD_Assault(myHUD) == none || !HUD_Assault(myHUD).ShouldShowObjectiveBoard() )
        {
            DrawRecordWidget( C );
        }
        RenderHUDElements( C );
    }
    else
    {
        switch( MRI.RecordState )
        {
            case RS_Succeed:
                S = MRI.EndMsg;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.05), S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.GoldColor );

                S = MRI.PlayersBestTimes;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.10), "Set by", S, true, C.ClipX*0.65, 4.5 );

                S = MRI.PointsReward;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.15), "Score", S, true, C.ClipX*0.65, 4.5 );
                break;

            case RS_Failure:
                S = MRI.EndMsg;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.05), S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.RedColor );
                break;

            case RS_QuickStart:
                S = MRI.EndMsg;
                DrawElement( C, C.ClipX*0.5, C.ClipY*0.8, S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.TurqColor );
                break;
        }
    }
}

private function RenderHUDElements( Canvas C )
{
    // PRE-RENDERED
    local float drawX, drawY;

    // Temporary string measures.
    local float vXL, xl, yl;
    local Vector v;
    local string s;
    local Color backupColor;
    local int i;

    drawX = COLUMN_PADDING_X;
    drawY = (C.ClipY * 0.5);
    C.Style = 1;
    C.StrLen( "9", xl, yl );
    if( SpectatedClient.ClientSpawnPawn != none )
    {
        backupColor = BTConfig.CTable;
        BTConfig.CTable = #0xFB607FFF;
        BTConfig.CTable.A = 100;
        v = DrawElement( C, drawX, drawY, "   Checkpoint" );
        BTConfig.CTable = backupColor;

        vXL = 54f/76f*yl;
        C.SetPos( drawX + COLUMN_PADDING_X, drawY );
        C.DrawColor = #0xFB607FFF;
        C.DrawTile( Texture'HudContent.Generic.Hud', vXL, yl, 340, 130, 54, 76 );

        drawY += v.Y*1.2;
    }

    if( SpectatedClient.ProhibitedCappingPawn != none )
    {
        // Draw Level and percent
        S = "Boost";
        backupColor = BTConfig.CTable;
        BTConfig.CTable = class'HUD'.default.GreenColor;
        BTConfig.CTable.A = 100;
        BTConfig.CTable.G = 150;
        drawY += DrawElement( C, drawX, drawY, s ).y*1.2;
        BTConfig.CTable = backupColor;
    }

    if( SpectatedClient.BTWage > 0 )
    {
        // Draw Level and percent
        S = "Waging";
        backupColor = BTConfig.CTable;
        BTConfig.CTable = #0xFF00FFFF;
        BTConfig.CTable.A = 100;
        drawY += DrawElement( C, drawX, drawY, s, string(SpectatedClient.BTWage) ).y*1.2;
        BTConfig.CTable = backupColor;
    }

    if( ActiveLevel != none && ActiveLevel.NumRecords > 0 )
    {
        // Draw Level and percent
        S = "Rank";
        drawY += DrawElement( C, drawX, drawY, s, Eval(
                SpectatedClient.SoloRank == 0,
                "?",
                SpectatedClient.SoloRank
            ) $ "/" $ ActiveLevel.NumRecords
        ).y*1.2;
    }

    // Draw Level and percent
    S = "Level";
    v = DrawElement( C, drawX, drawY, s, SpectatedClient.BTLevel );
        if( SpectatedClient.BTExperience > SpectatedClient.LastRenderedBTExperience )
        {
            SpectatedClient.BTExperienceChangeTime = SpectatedClient.Level.TimeSeconds;

            if( SpectatedClient.BTLevel < SpectatedClient.LastRenderedBTLevel )
            {
                SpectatedClient.BTExperienceDiff = -(1.0f - SpectatedClient.BTExperience + SpectatedClient.LastRenderedBTExperience) * 100f;
            }
            else
            {
                SpectatedClient.BTExperienceDiff = (SpectatedClient.BTExperience - SpectatedClient.LastRenderedBTExperience) * 100f;
            }
        }
        else if( SpectatedClient.BTLevel > SpectatedClient.LastRenderedBTLevel )
        {
            SpectatedClient.BTExperienceChangeTime = SpectatedClient.Level.TimeSeconds;
            SpectatedClient.BTExperienceDiff = (1.0f - SpectatedClient.LastRenderedBTExperience + SpectatedClient.BTExperience) * 100f;
        }

        C.DrawColor = #0x00AA0088;
        DrawLayer( C, drawX, drawY, v.x*SpectatedClient.BTExperience, v.y );
        SpectatedClient.LastRenderedBTExperience = SpectatedClient.BTExperience;
        SpectatedClient.LastRenderedBTLevel = SpectatedClient.BTLevel;

        if( SpectatedClient.Level.TimeSeconds - SpectatedClient.BTExperienceChangeTime <= 1.5f && SpectatedClient.BTExperienceDiff != 0f )
        {
            C.SetPos( drawX + v.x, drawY + v.y*0.5 - YL*0.5);
            if( SpectatedClient.BTExperienceDiff > 0 )
            {
                C.DrawColor = Class'HUD'.default.GreenColor;
                C.DrawText( "+ " $ SpectatedClient.BTExperienceDiff $ "%" );
            }
            else if( SpectatedClient.BTExperienceDiff < 0 )
            {
                C.DrawColor = Class'HUD'.default.RedColor;
                C.DrawText( "- " $ -SpectatedClient.BTExperienceDiff $ "%" );
            }
        }
    drawY += v.y*1.2;

    s = "$";
    DrawElement( C, drawX, drawY, s, Decimal(SpectatedClient.BTPoints),,,, class'HUD'.default.GreenColor );
    drawY += v.y*1.2;

    s = "AP";
    DrawElement( C, drawX, drawY, s, Decimal(SpectatedClient.APoints),,,, class'HUD'.default.WhiteColor, #0x91A79D88 );

    // render team status on right side of hud centered vertically.
    if( MRI.Teams[0].Name != "" )
    {
        drawX = C.ClipX*0.5;
        drawY = C.ClipY*0.6;
        if( SpectatedClient.EventTeamIndex == -1 )
        {
            drawY +=DrawElement( C, drawX, drawY, "Please vote for a team in the store!",, true, 200,, class'HUD'.default.WhiteColor, #0x44444488 ).Y*1.2;

            drawY +=DrawElement( C, drawX, drawY, "Earn points for a team by improving records!",, true, 200,, class'HUD'.default.WhiteColor, #0x88884488 ).Y*1.2;

            drawY +=DrawElement( C, drawX, drawY, "Members whom have supported its team will receive rewards!",, true, 200,, class'HUD'.default.WhiteColor, #0x88884488 ).Y*1.2;
        }

        drawX = C.ClipX - 250;
        drawY = C.ClipY*0.5 - ArrayCount(MRI.Teams)*(YL*(COLUMN_PADDING_Y*2)*1.2);
        for( i = 0; i < ArrayCount(MRI.Teams); ++ i )
        {
            if( MRI.Teams[i].Name == "" )
                continue;

            s = MRI.Teams[i].Name $ "[" $ MRI.Teams[i].Voters $ "]";
            if( SpectatedClient.EventTeamIndex == i )
            {
                s = ">" @ s;
            }
            drawY += DrawElement( C, drawX, drawY, s, MRI.Teams[i].Points,, 200,, class'HUD'.default.WhiteColor, #0xFF224488 ).Y*1.2;
        }
    }

    if( Pawn(ViewportOwner.Actor.ViewTarget) != none )
    {
        drawY = C.ClipY*0.825f;
        v = ViewportOwner.Actor.ViewTarget.Velocity;
        v.Z = 0;
        s = Decimal(VSize(v))@":"@Decimal(VSize(ViewportOwner.Actor.ViewTarget.Velocity*vect(0,0,1)))@"uu/s";
        drawY += DrawElement( C, C.ClipX*0.5, drawY, "Speed", s, true, 200, 1.0, class'HUD'.default.GoldColor ).Y*1.2;
        if( MRI.CR.bAllowDodgePerk && (ViewportOwner.Actor.ViewTarget == ViewportOwner.Actor.Pawn || bTimeViewTarget) )
        {
            RenderDodgeReady( C, drawY );
        }
    }
}

private function DrawRecordWidget( Canvas C )
{
    local string timeLeftF, bestTimeF;
    local float minWidth;

    // PRE-RENDERED
    local float drawX, drawY;
    local float width, height;

    // Temporary string measures.
    local float xl, yl, xl2, yl2, xl3, yl3;
    local string s;

    drawX = C.ClipX - COLUMN_PADDING_X;
    if( myHUD.bShowPersonalInfo && ASGameReplicationInfo(ViewportOwner.Actor.Level.GRI) == none )
    {
        drawY += 50 * myHUD.HUDScale;
    }
    drawY = COLUMN_PADDING_Y;
    drawX -= COLUMN_PADDING_X*2;
    minWidth = 240;
    C.Style = 1;

    if( ActiveLevel == none )
        s = RecordHubMsg;
    else if( ActiveLevel.TopRanks == "" )
        s = RecordEmptyMsg;

    if( s == "" )
    {
        // =============================================================
        // Record Ticker
        if( bTimerPaused )
        {
            if( DrawnTimer == 0.0f )
                DrawnTimer = ActiveLevel.TopTime;
        }
        else
        {
            DrawnTimer = GetTimeLeft();

            // Tick
            if( MRI.Level.TimeSeconds-(LastTime-1.0) >= 0.25f )
                bSoundTicking = false;

            if( BTConfig.bPlayTickSounds && MRI.Level.TimeSeconds >= LastTime && int(DrawnTimer) >= 0 && DrawnTimer <= 10 )
            {
                if( ViewportOwner.Actor.ViewTarget != None )
                {
                    if( DrawnTimer < 0.21f )
                    {
                        LastTime = MRI.Level.TimeSeconds + 1.0f;
                        // Avoid a bug that cause the denied sound to be played twice(wtf?)
                        if( DrawnTimer > -0.91f )
                        {
                            ViewportOwner.Actor.ViewTarget.PlayOwnedSound( BTConfig.LastTickSound, SLOT_Interact, 255 );
                            bSoundTicking = True;
                        }
                    }
                    else
                    {
                        LastTime = MRI.Level.TimeSeconds + 1.0f;
                        ViewportOwner.Actor.ViewTarget.PlayOwnedSound( BTConfig.TickSound, SLOT_Interact, 255 );
                        bSoundTicking = True;
                    }
                }
            }
        }

        // =============================================================
        // Record Info
        // Record Time
        if( !MRI.bSoloMap )
        {
            s = RecordTimeMsg $ " " $ FormatTime( ActiveLevel.TopTime );
            C.StrLen( s, width, height );
            width = FMax( width, minWidth );
            DrawElementTile( C, drawX - width, drawY, width, height );

            s = RecordTimeMsg $ " ";
            DrawElementText( C, drawX - width, drawY, s );

            s = FormatTime( ActiveLevel.TopTime );
            C.StrLen( s, xl, yl );
            C.DrawColor = BTConfig.CGoldText;
            DrawElementValue( C, drawX - xl + COLUMN_PADDING_X*2, drawY, s );
            drawY += height + COLUMN_PADDING_Y*3;
        }

        // Record Author
        // Title
        s = RecordHolderMsg $ " " $ ActiveLevel.TopRanks;
        C.TextSize( %s, width, height );
        width = FMax( width, minWidth );
        DrawElementTile( C, drawX - width, drawY, width, height );

        // Left column
        s = RecordHolderMsg $ " ";
        DrawElementText( C, drawX - width, drawY, s );

        // Right column
        s = ActiveLevel.TopRanks;
        C.TextSize( %s, xl, yl );
        DrawElementValue( C, drawX - xl + COLUMN_PADDING_X*2, drawY, s );
        drawY += height + COLUMN_PADDING_Y*3;
        // ...

        // Record Timer
        // DRAWS: Time Left: TIMELEFT/BESTTIME
        timeLeftF = FormatTime( DrawnTimer );
        bestTimeF = FormatTime( ActiveLevel.TopTime );

        s = RecordTimeLeftMsg $ " " $ timeLeftF;
        if( MRI.bSoloMap )
        {
            s $= " / " $ bestTimeF;
        }
        C.StrLen( s, width, height );
        width = FMax( width, minWidth );
        DrawElementTile( C, drawX - width, drawY, width, height );

        s = RecordTimeLeftMsg $ " ";
        DrawElementText( C, drawX - width, drawY, s );

        if( MRI.bSoloMap )
        {
            // Draws > 00.00 / [00.00]
            C.StrLen( bestTimeF, xl, yl );
            DrawElementPart( C, drawX - xl + COLUMN_PADDING_X, drawY, bestTimeF, class'HUD'.default.GoldColor );

            // Draws > 00.00[ / ]00.00
            s = " / ";
            C.StrLen( s, xl2, yl2 );
            DrawElementPart( C, drawX - xl - xl2 + COLUMN_PADDING_X, drawY, s );
        }
        else
        {
            xl = 0;
        }

        // Draws > [00.00] / 00.00
        s = timeLeftF;
        C.StrLen( s, xl3, yl3 );
        if( bSoundTicking )
            C.DrawColor = TimeTickColor;
        else
        {
            if( DrawnTimer <= 0.0f )
                C.DrawColor = TimeNegativeColor;
            else C.DrawColor = TimePositiveColor;
        }
        DrawElementPart( C, drawX - xl - xl2 - xl3 + COLUMN_PADDING_X, drawY, s, C.DrawColor );
        drawY += height + COLUMN_PADDING_Y*3;
    }
    else    // No Record avaible.
    {
        if( MRI.bSoloMap )
        {
            DrawnTimer = (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
        }
        else
        {
            DrawnTimer = MRI.Level.TimeSeconds - (MRI.MatchStartTime - MRI.CR.ClientMatchStartTime);
        }
        s = FormatTime( DrawnTimer );
        C.StrLen( RecordTimeElapsed $ " " $ s, width, height );
        width = FMax( width, minWidth );
        DrawElementTile( C, drawX - width, drawY, width, height );

        C.StrLen( s, xl, yl );
        DrawElementText( C, drawX - width, drawY, RecordTimeElapsed $ " " );
        DrawElementValue( C, drawX - xl + COLUMN_PADDING_X*2, drawY, s, TimePositiveColor );
        drawY += height + COLUMN_PADDING_Y*3;
    }

    // Press F12 or Escape to hide this.
    s = "Leaderboards " $ BTConfig.CGoldText $ "[" $ Class'Interactions'.Static.GetFriendlyName( BTConfig.RankingTableKey ) $ "]";
    C.StrLen( s, width, height );
    C.DrawColor = #0x0088BBFF;
    C.DrawColor.A = BTConfig.CTable.A;
    DrawColumnTile( C, drawX - width + COLUMN_PADDING_X, drawY, width+4, height+2 );
    DrawHeaderText( C, drawX - width + COLUMN_PADDING_X, drawY, s );
}

private function BTClient_LevelReplication GetCurrentLevel()
{
    if( SpectatedClient == none )
    {
        return MRI.MapLevel;
    }

    if( SpectatedClient.PlayingLevel != none )
    {
        return SpectatedClient.PlayingLevel;
    }
    return MRI.MapLevel;
}

private function float GetTopTime()
{
    if( ActiveLevel == none )
        return 0.00;

    return ActiveLevel.TopTime;
}

private function float GetTimeLeft()
{
    if( MRI.bSoloMap )
    {
        if( BTConfig.bBaseTimeLeftOnPersonal && SpectatedClient.PersonalTime > 0.f )
            return SpectatedClient.PersonalTime - (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
        else return GetTopTime() - (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
    }
    else return GetTopTime() - (MRI.Level.TimeSeconds - (MRI.MatchStartTime - MRI.CR.ClientMatchStartTime));
}


// Enhanced copy of HUD_Assault.uc
private function DrawTextWithBackground( Canvas C, String Text, Color TextColor, float XO, float YO )
{
    local float XL, YL, XL2, YL2;

    C.StrLen( Text, XL, YL );

    XL2 = XL + 64 * myHUD.ResScaleX;
    YL2 = YL +  8 * myHUD.ResScaleY;

    C.DrawColor = BTConfig.CTable;
    C.SetPos( XO - XL2*0.5, YO - YL2*0.5 );
    C.DrawTile( BackgroundTexture, XL2, YL2, 0, 0, 256, 256 );

    C.DrawColor = TextColor;
    C.SetPos( XO - XL*0.5, YO - YL*0.5 );
    C.DrawText( Text, false );
}

/** Formats the given time in seconds.deci_centi.
    Outputs:[-][00:00:]00.00 */
static final function string FormatTime( float time, optional bool forceFull )                          // Based upon epic's Time Format code
{
    local string hourString, minuteString, secondString, output;
    local int minutes, hours;
    local float seconds;

    seconds = Abs(int(time*100)/100.f);
    minutes = int(seconds) / 60;
    hours   = minutes / 60;
    seconds = seconds - (minutes * 60);
    minutes = minutes - (hours * 60);

    if( seconds < 10 ) secondString = "0" $ seconds; else secondString = string(seconds);
    if( minutes < 10 ) minuteString = "0" $ minutes; else minuteString = string(minutes);
    if( hours < 10 ) hourString = "0" $ hours; else hourString = string(hours);

    if( forceFull || Class'BTClient_Config'.static.FindSavedData().bDisplayFullTime )
    {
        if( time < 0 )
            return "-" $ hourString $ ":" $ minuteString $ ":" $ secondString;
        else return hourString $ ":" $ minuteString $ ":" $ secondString;
    }
    else
    {
        if( hours != 0 )
            output = hourString $ ":";

        if( minutes != 0 )
            output $= minuteString $ ":";

        if( time < 0 )
            return "-" $ output $ secondString;
        else return output $ secondString;
    }
}

static final function string StrlNoMS( int time )
{
    local string HourString, MinuteString, SecondString, Output;
    local int Minutes, Hours, Seconds;

    Seconds = Abs(time);
    Minutes = Seconds / 60;
    Hours   = Minutes / 60;
    Seconds = Seconds - (Minutes * 60);
    Minutes = Minutes - (Hours * 60);

    if (Seconds < 10)
        SecondString = "0"$Seconds;
    else
        SecondString = string(Seconds);

    if (Minutes < 10)
        MinuteString = "0"$Minutes;
    else
        MinuteString = string(Minutes);

    if (Hours < 10)
        HourString = "0"$Hours;
    else
        HourString = string(Hours);

    if( Class'BTClient_Config'.static.FindSavedData().bDisplayFullTime )
    {
        if( time < 0 )
            return "-"$HourString$":"$MinuteString$":"$SecondString;
        else return HourString$":"$MinuteString$":"$SecondString;
    }
    else
    {
        if( Hours != 0 )
            Output = HourString$":";

        if( Minutes != 0 )
            Output $= MinuteString$":";

        if( time < 0 )
            return "-"$Output$SecondString;
        else return Output$SecondString;
    }
}

/** Formats the given time in seconds.deci_centi.
    Outputs:[-][00:00:]00.00 but only if the units are greater than null! */
static final function string FormatTimeCompact( float time )
{
    local string hourString, minuteString, secondString, output;
    local int minutes, hours;
    local float seconds;

    seconds = Abs(int(time*100)/100.f);
    minutes = int(seconds) / 60;
    hours   = minutes / 60;
    seconds = seconds - (minutes * 60);
    minutes = minutes - (hours * 60);

    if( seconds < 10 ) secondString = "0" $ seconds; else secondString = string(seconds);
    if( minutes < 10 ) minuteString = "0" $ minutes; else minuteString = string(minutes);
    if( hours < 10 ) hourString = "0" $ hours; else hourString = string(hours);

    if( hours != 0 )
        output = hourString $ ":";

    if( minutes != 0 )
        output $= minuteString $ ":";

    if( time < 0 )
        return "-" $ output $ secondString;
    else return output $ secondString;
}

static final function string CompactDateToString( int date )
{
    local int d[3];

    d[0] = byte(date & 0xFF);
    d[1] = byte(date >> 8);
    d[2] = date >> 16;
    return FixDate( d );
}

private static function string FixDate( int Date[3] )
{
    local string FixedDate;

    // Fix date
    if( Date[0] < 10 )
        FixedDate = "0"$Date[0];
    else FixedDate = string(Date[0]);

    if( Date[1] < 10 )
        FixedDate $= "/0"$Date[1];
    else FixedDate $= "/"$Date[1];

    return FixedDate$"/"$Right( Date[2], 2 );
}

defaultproperties
{
    begin object class=TexRotator name=oMarkerArrow
        Material=Texture'AS_FX_TX.HUD.Objective_Primary_Indicator'
        UOffset=64
        VOffset=64
    end object
    MarkerArrow=oMarkerArrow

    YOffsetScale=0.6
    TimeTickColor=(R=255,G=255,B=0,A=255)
    BackgroundTexture=Texture'BTScoreBoardBG'

    bVisible=True
    bRequiresTick=True

    RecordTimeMsg="Time"
    RecordHolderMsg="Holder"
    RecordTimeLeftMsg="Record"
    RecordEmptyMsg="No record available"
    RecordHubMsg="Choose a level!"
    RecordTimeElapsed="Time"
    RankingKeyMsg="Escape/%KEY%"
    RankingHideMsg="to show/hide this"

}

#include classes/BTColorHashUtil.uci
#include classes/BTColorStripUtil.uci
#include classes/BTStringColorUtils.uci
#include classes/BTStringDecimalUtil.uci