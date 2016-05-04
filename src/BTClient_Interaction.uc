//==============================================================================
// BTClient_Interaction.uc (C) 2005-2010 Eliot and .:..:. All Rights Reserved
//
// This class handles the widgets on the HUD, the F12 tables and any interaction with BTimes.
//
//  Most recent update: $wotgreal_dt: 28/02/2012 11:54:19 $
//==============================================================================
class BTClient_Interaction extends Interaction;

#exec obj load file="UT2003Fonts.utx"
#exec obj load file="MenuSounds.uax"
#exec obj load file="ClientBTimes.utx" package="ClientBTimesV6"
#exec obj load file="CountryFlagsUT2K4.utx" package="ClientBTimesV6" group="CountryFlags"

struct sTableColumn
{
    var string Title;
    var string Format;
    var name id;
};

struct sCanvasColumn
{
    var float W, H;
};

/*const BorderSize = 2;
const ExTileWidth = 10;
const ExTextOffset = 1;*/

// Not localized so that changes will take affect for everyone, if a new version changes these...
// Besides i'm not gonna write them for all languages anyway?
var const
    string
    RecordTimeMsg,
    RecordHolderMsg,
    RecordTimeLeftMsg,
    RecordEmptyMsg,
    RecordHubMsg,
    RecordPrevTimeMsg,
    RecordTimeElapsed,
    RankingToggleMsg,
    RankingHideMsg;

var const array<sTableColumn> PlayersRankingColumns;
var const array<sTableColumn> RecordsRankingColumns;

var string
    RankingKeyMsg,
    OldKey;

var BTClient_MutatorReplicationInfo         MRI;                                // Set by BTClient_MutatorReplicationInfo
var HUD_Assault                             HU;                                 // Set by BTClient_MutatorReplicationInfo
var HUD                                     myHUD;
var BTClient_Config                         Options;                            // Object to Config, set on Initialized()
var BTClient_ClientReplication              SpectatedClient;                    // Set by PostRender(), used for showing the record timer of other players...
var BTClient_LevelReplication               ActiveLevel;

var array<Pickup> KeyPickupsList;

var const
    color
    Orange;

var bool
    bTestRun,
    bPauseTest,
    bMenuModified,
    bNoRenderZoneActors, bRenderAll, bRenderOnlyDynamic;

var name RenderTag;
var byte RenderMode;

// Table
// Page 0 : Draw Best Ranked Players
// Page 1 : Draw Best Top Records (current map)

var int ElapsedTime;

var float
    LastTickTime,
    Delay,
    YOffsetScale,                               // Offset scale for EndMap tables
    LastTime,
    DrawnTimer,
    LastShowAllCheck;

var bool bTimerPaused, bSoundTicking;
var() bool bShowRankingTable;

var const
    texture
    AlphaLayer,
    RankBeacon;

// DODGEPERK DATA
var Actor LastBase;
var Actor.EPhysics LastPhysicsState;
var Actor.EDoubleClickDir LastDoubleClickDir;
var float LastDodgeTime;
var float LastLandedTime;
var float LastPerformedDodgeTime;
var bool bPerformedDodge;
var bool bPreDodgeReady;
var bool bDodgeReady;
var bool bPromodeWasPerformed;
var bool bTimeViewTarget;
var PlayerInput PlayerInput;

/** Returns int A as a color tag. */
static final preoperator string $( int A )
{
    return Chr( 0x1B ) $ (Chr( Max(byte(A >> 16), 1)  ) $ Chr( Max(byte(A >> 8), 1) ) $ Chr( Max(byte(A & 0xFF), 1) ));
}

/** Returns color A as a color tag. */
static final preoperator string $( Color A )
{
    return (Chr( 0x1B ) $ (Chr( Max( A.R, 1 )  ) $ Chr( Max( A.G, 1 ) ) $ Chr( Max( A.B, 1 ) )));
}

/** Adds B as a color tag to the end of A. */
static final operator(40) string $( coerce string A, Color B )
{
    return A $ $B;
}

/** Adds A as a color tag to the begin of B. */
static final operator(40) string $( Color A, coerce string B )
{
    return $A $ B;
}

/** Adds B as a color tag to the end of A with a space inbetween. */
static final operator(40) string @( coerce string A, Color B )
{
    return A @ $B;
}

/** Adds A as a color tag to the begin of B with a space inbetween. */
static final operator(40) string @( Color A, coerce string B )
{
    return $A @ B;
}

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

/** Strips all color tags from A. */
static final preoperator string %( string A )
{
    local int i;

    while( true )
    {
        i = InStr( A, Chr( 0x1B ) );
        if( i != -1 )
        {
            A = Left( A, i ) $ Mid( A, i + 4 );
            continue;
        }
        break;
    }
    return A;
}

final static function Color MakeColor( optional byte r, optional byte g, optional byte b, optional byte a )
{
    local Color c;

    c.r = r;
    c.g = g;
    c.b = b;
    c.a = a;
    return c;
}

final static function Color Darken( Color c, float pct )
{
    pct = 1.0 - pct/100.0f;
    return MakeColor( c.R*pct, c.G*pct, c.B*pct, c.A );
}

final static function Color Lighten( Color c, float pct )
{
    pct = 1.0 + pct/100.0f;
    return MakeColor( c.R*pct, c.G*pct, c.B*pct, c.A );
}

final function SendConsoleMessage( string Msg )
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

exec function BTCommands()
{
    if( ViewportOwner.Actor.PlayerReplicationInfo.bAdmin )
    {
        ViewportOwner.Actor.ServerMutate( "BTCommands" );
    }
    else
    {
        SendConsoleMessage( "..." );
        SendConsoleMessage( "VoteMapSeq <Sequence>" );
        SendConsoleMessage( "VoteMap <MapName>" );
        SendConsoleMessage( "RevoteMap (Revotes the Current Map)" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "ToggleRanking (Opens the ranks scoreboard)" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "SpeedRun" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "StartTimer" );
        SendConsoleMessage( "PauseTimer" );
        SendConsoleMessage( "StopTimer" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "RecentRecords" );
        SendConsoleMessage( "RecentHistory" );
        SendConsoleMessage( "RecentMaps" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "ShowMapInfo <MapName>" );
        SendConsoleMessage( "ShowPlayerInfo <PlayerName>" );
        SendConsoleMessage( "ShowMissingRecords" );
        SendConsoleMessage( "ShowBadRecords" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "SetClientSpawn" );
        SendConsoleMessage( "DeleteClientSpawn" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "ToggleGhost (Only your Ghost!)" );
        SendConsoleMessage( "GhostFollow <PlayerName> (Costs money!)" );
        SendConsoleMessage( "GhostFollowID <PlayerID> (Only for admins, BTimes author and people with a ObjectivesLevel greater than 0)" );
        SendConsoleMessage( "..." );
        SendConsoleMessage( "TrailerMenu" );
        SendConsoleMessage( "SetTrailerColor 255 255 255 128 128 128 (Only if Ranked!)" );
        SendConsoleMessage( "SetTrailerTexture <Package.Group.Name> (Only if Ranked!)" );
        SendConsoleMessage( "..." );

        if( MRI.RankingPage != "" )
            SendConsoleMessage( "ShowBestTimes (Loads Website!)" );
    }
}

exec function SetConfigProperty( string Property, string Value )
{
    if( Options != None )
    {
        if( Options.SetPropertyText( Property, Value ) )
            Options.SaveConfig();
    }
}

exec function CloseDialog()
{
    MRI.CR.Text.Length = 0;
}

exec function SetTableColor( optional color tc )
{
    Options.CTable = tc;
    Options.SaveConfig();
}

exec function SetTextColor( optional color tc )
{
    Options.CGoldText = tc;
    Options.SaveConfig();
}

exec function SetPreferedColor( optional Color newPreferedColor )
{
    Options.PreferedColor = newPreferedColor;
    UpdatePreferedColor();
}

exec function UpdatePreferedColor()
{
    local string colorText;

    Options.SaveConfig();

    MRI.CR.ServerSetPreferedColor( Options.PreferedColor );

    colorText = Options.PreferedColor.R @ Options.PreferedColor.G @ Options.PreferedColor.B;
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

exec function SetGlobalSort( int sort )
{
    Options.GlobalSort = sort;
    Options.SaveConfig();
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

exec function ClearAttachments()
{
    local int i, j;
    local Pawn P;

    P = ViewportOwner.Actor.Pawn;
    if( P != None )
    {
        j = P.Attached.Length;
        for( i = 0; i < j; ++ i )
        {
            if( P.Attached[i] != None )
                P.Attached[i].Destroy();
        }
    }
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

exec function ToggleGhost()
{
    BT( "ToggleGhost" );
}

exec function GhostFollow( string playerName )
{
    BT( "GhostFollow" @ playerName );
}

exec function GhostFollowID( int playerID )
{
    BT( "GhostFollowID" @ playerID );
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
    Options.bUseAltTimer = !Options.bUseAltTimer;
    SendConsoleMessage( "SpeedRun:"$Options.bUseAltTimer );
    Options.SaveConfig();
}

exec function ToggleColorFade()
{
    Options.bFadeTextColors = !Options.bFadeTextColors;
    SendConsoleMessage( "FadeTextColors:"$Options.bFadeTextColors );
    Options.SaveConfig();
}

exec function TogglePersonalTimer()
{
    Options.bBaseTimeLeftOnPersonal = !Options.bBaseTimeLeftOnPersonal;
    SendConsoleMessage( "Using PersonalTime:"$Options.bBaseTimeLeftOnPersonal );
    Options.SaveConfig();
}

function bool KeyEvent( out EInputKey Key, out EInputAction Action, float Delta )
{
    local string S;

    S = Caps( ViewportOwner.Actor.ConsoleCommand( "KEYBINDING"@Chr( Key ) ) );
    if( InStr( S, "SHOWALL" ) != -1 )
        return true;        // Ignore Input!.

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

        if( Key == Options.RankingTableKey )
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

        if( bShowRankingTable )
        {
            if( Key == IK_GreyPlus )
            {
                Options.ScreenFontSize = Min( ++ Options.ScreenFontSize, 6 );
                return true;
            }
            else if( Key == IK_GreyMinus )
            {
                Options.ScreenFontSize = Max( -- Options.ScreenFontSize, -5 );
                return true;
            }
        }
        else
        {
            if( ViewportOwner.Actor.bBehindView )
            {
                if( Key == IK_GreyPlus )
                {
                    ViewportOwner.Actor.CameraDeltaRad += 5.f;
                    return true;
                }
                else if( Key == IK_GreyMinus )
                {
                    ViewportOwner.Actor.CameraDeltaRad -= 5.f;
                    return true;
                }
            }
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

event Tick( float DeltaTime )
{
    local Console C;
    local DefaultPhysicsVolume DPV;
    local xPawn p;
    local LinkedReplicationInfo LRI;

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
    ActiveLevel = GetCurrentLevel();

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

    if( MRI.CR != none && MRI.CR.bAllowDodgePerk )
    {
        PerformDodgePerk();
    }

    /* Anti-ShowAll */
    C = ViewportOwner.Actor.Player.Console;
    if( C != none )
    {
        // Kick if player is attempting to use the illegal command Showall.
        if( C.HistoryCur-1 > 16 || C.HistoryCur-1 < 0 )
            return;

        if( C.History[C.HistoryCur-1] ~= "ShowAll" || Left( C.History[C.HistoryCur-1] , 7 ) ~= "ShowAll" )
        {
            C.History[C.HistoryCur-1] = "";
            SendConsoleMessage( "ShowAll is not allowed on this server, therefor you have been kicked" );
            ConsoleCommand( "Disconnect" );
            return;
        }
    }

    if( ViewportOwner.Actor.Level.TimeSeconds > LastShowAllCheck )
    {
        foreach ViewportOwner.Actor.DynamicActors( class'DefaultPhysicsVolume', DPV )
        {
            if( !DPV.bHidden )
            {
                SendConsoleMessage( "ShowAll is not allowed on this server, therefor you have been kicked" );
                ConsoleCommand( "Disconnect" );
                return;
            }
            break;
        }
        LastShowAllCheck = ViewportOwner.Actor.Level.TimeSeconds+1.0;
    }
}

exec function TimeViewTarget()
{
    bTimeViewTarget = !bTimeViewTarget;
}

function PerformDodgePerk()
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
    if( Options != none && Options.bShowDodgeReady )
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

function PerformedDodge( Pawn other )
{
    bPerformedDodge = true;
    LastPerformedDodgeTime = ViewportOwner.Actor.Level.TimeSeconds - LastLandedTime;
    LastDodgeTime = ViewportOwner.Actor.Level.TimeSeconds;
}

function PerformedLanding( Pawn other )
{
    if( bPerformedDodge )
    {
        LastLandedTime = ViewportOwner.Actor.Level.TimeSeconds;
        bPerformedDodge = false;
    }
    LastDoubleClickDir = DCLICK_None;
}

function Vector RenderDodgeReady( Canvas C, float drawY )
{
    local string s;
    local float xl, yl;

    if( Options == none )
    {
        return vect(0,0,0);
    }

    if( Options.bShowDodgeDelay && (!bPreDodgeReady || !Options.bShowDodgeReady) )
    {
        s = string(LastPerformedDodgeTime/ViewportOwner.Actor.Level.TimeDilation)$"s";
    }
    else
    {
        if( !Options.bShowDodgeReady )
        {
            return vect(0,0,0);
        }

        if( Options.bShowDodgeDelay )
        {
            s = (ViewportOwner.Actor.Level.TimeSeconds - LastLandedTime)/ViewportOwner.Actor.Level.TimeDilation$"s";
        }
        else
        {
            s = "Ready";
        }
    }

    if( bDodgeReady )
    {
        C.DrawColor = class'HUD'.default.GreenColor;
    }
    else if( Options.bShowDodgeDelay && (!bPreDodgeReady || !Options.bShowDodgeReady) )
    {
        C.DrawColor = class'HUD'.default.CyanColor;
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

    // Hide the existing assault "Objective completed" message, as we have replaced this with our own record message.
    class'Message_Awards'.default.bComplexString = false;
    class'Message_Awards'.default.PosY = -1.0;

    Options = Class'BTClient_Config'.Static.FindSavedData();
    ForEach ViewportOwner.Actor.DynamicActors( Class'DefaultPhysicsVolume', DPV )
    {
        DPV.bHidden = True;
        break;
    }

    UpdateToggleKey();

    if( string(ViewportOwner.Actor.Level.ExcludeTag[0]) == Right( ReverseString( string(ViewportOwner.Actor.Level.Outer.Name) ), 5 ) )
    {
        bNoRenderZoneActors = true;
    }

    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_HUD', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_MultiColumnList', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_ListSelection', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Header', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Label', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY2EditBox', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY2SectionHeaderTop', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_Button', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_TabButton', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_CloseButton', true );
    GUIController(ViewportOwner.GUIController).RegisterStyle( class'BTClient_STY_ContextMenu', true );
}

static final function string ReverseString( string s )
{
    local string ss;
    local int i;

    while( i < Len( s ) )
    {
        ss = Mid( Left( s, i + 1 ), i ++ ) $ ss;
    }
    return ss;
}

// exec, cuz of lazyness, cba to find this inter from menu!
function UpdateToggleKey()
{
    local string Key;

    Key = class'Interactions'.static.GetFriendlyName( Options.RankingTableKey );
    if( Len( OldKey ) == 0 )
    {
        RankingKeyMsg = Repl( RankingKeyMsg, "%KEY%", Options.CGoldText$Key$class'HUD'.default.WhiteColor );
    }
    else
    {
        RankingKeyMsg = Repl( RankingKeyMsg, OldKey, Options.CGoldText $Key$class'HUD'.default.WhiteColor );
    }
    OldKey = Key;
}

final function ObjectsInitialized()
{
    local Pickup Key;

    if( ViewportOwner.Actor.myHUD != none && BTClient_TrialScoreBoard(ViewportOwner.Actor.myHUD.ScoreBoard) != none )
        BTClient_TrialScoreBoard(ViewportOwner.Actor.myHUD.ScoreBoard).myInter = self;

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
    local BTGUI_PlayerInventory invMenu;
    local BTGUI_Store storeMenu;
    local BTGUI_Rewards rewardsMenu;

    Menu = UT2K4PlayerLoginMenu(GUIController(ViewportOwner.Actor.Player.GUIController).FindPersistentMenuByName( UnrealPlayer(ViewportOwner.Actor).LoginMenuClass ));
    if( Menu != None )
    {
        Menu.BackgroundRStyle = MSTY_None;
        Menu.i_FrameBG.Image = Texture(DynamicLoadObject( "2k4Menus.NewControls.Display99", Class'Texture', True ));
        Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_AdvancedButton', True );
        Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_StoreButton', True );
        Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_BuyButton', True );
        Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_SellButton', True );

        invMenu = BTGUI_PlayerInventory(Menu.c_Main.AddTab( "Inventory", string(Class'BTGUI_PlayerInventory'),, "Manage your items" ));
        if( invMenu != none )
        {
            // invMenu.MyInteraction = self;
            invMenu.MyButton.StyleName = "StoreButton";
            invMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "StoreButton", invMenu.FontScale );
            invMenu.PostInitPanel();
        }

        storeMenu = BTGUI_Store(Menu.c_Main.AddTab( "Store", string(Class'BTGUI_Store'),, "Buy and manage items" ));
        if( storeMenu != none )
        {
            storeMenu.MyInteraction = self;
            storeMenu.MyButton.StyleName = "StoreButton";
            storeMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "StoreButton", storeMenu.FontScale );
            storeMenu.PostInitPanel();
        }

        rewardsMenu = BTGUI_Rewards(Menu.c_Main.AddTab( "Rewards", string(Class'BTGUI_Rewards'),, "Exchange and collect trophies" ));
        if( rewardsMenu != none )
        {
            rewardsMenu.MyInteraction = self;
            rewardsMenu.MyButton.StyleName = "StoreButton";
            rewardsMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "StoreButton", rewardsMenu.FontScale );
            rewardsMenu.PostInitPanel();
        }

        myMenu = BTClient_Menu(Menu.c_Main.AddTab( "Advanced", string(Class'BTClient_Menu'),, "View and configure BestTimes features" ));
        if( myMenu != None )
        {
            myMenu.MyInteraction = self;
            myMenu.MyButton.StyleName = "AdvancedButton";
            myMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "AdvancedButton", myMenu.FontScale );
            myMenu.PostInitPanel();
        }

        bMenuModified = True;
    }
}

event NotifyLevelChange()
{
    super.NotifyLevelChange();
    MRI = none;
    HU = none;
    myHUD = none;
    Options = none;
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
    if( Options.bFadeTextColors )
        return MRI.GetFadingColor( FadingColor );

    return FadingColor;
}

exec function ShowZoneActors( optional bool bshowAll, optional bool bdynamicOnly, optional name tag, optional byte rm )
{
    Options.bShowZoneActors = !Options.bShowZoneActors || bshowAll;
    SendConsoleMessage( "ShowZoneActors:"$Options.bShowZoneActors );
    Options.SaveConfig();

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

final function RenderZoneActors( Canvas C )
{
    local Actor A;
    local Teleporter NextTP;
    local vector Scre, Scre2;
    local string S;
    local float Dist, XL, YL;
    local PlayerController PC;
    local bool bWireframed;
    local byte oldRendMap;

    if( bNoRenderZoneActors )
        return;

    PC = ViewportOwner.Actor;
    if( PC == None || Pawn(PC.ViewTarget) == None )
        return;

    if( bRenderAll )
    {
        if( RenderMode == 1 )
        {
            bWireframed = true;
        }
        else
        {
            oldRendMap = PC.RendMap;
            PC.RendMap = RenderMode;
        }

        C.SetPos( 0, 0 );
        if( bRenderOnlyDynamic )
        {
            foreach PC.DynamicActors( class'Actor', A, RenderTag )
            {
                C.DrawActor( A, bWireframed );
            }
        }
        else
        {
            foreach PC.AllActors( class'Actor', A, RenderTag )
            {
                C.DrawActor( A, bWireframed );
            }
        }

        if( !bWireframed )
        {
            PC.RendMap = oldRendMap;
        }
        return;
    }

    ForEach PC.Region.Zone.ZoneActors( Class'Actor', A )
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
                    ForEach PC.AllActors( Class'Teleporter', NextTP )
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

// Calculation done by Freon_HUD !.
final function RenderRankIcon( Canvas C )
{
    local xPawn P;
    local vector Scre, CamLoc, X, Y, Z, Dir;
    local rotator CamRot;
    local float Dist, XL, YL, Scale, ScaleDist;
    local string S;
    local BTClient_ClientReplication CRI;

    ForEach ViewportOwner.Actor.DynamicActors( Class'xPawn', P )
    {
        if
        (
            P == ViewportOwner.Actor.ViewTarget
            ||
            P.IsA('Monster')
            ||
            P.bHidden
            ||
            P.bDeleteMe
            ||
            P.bDeRes
        )
        {
            continue;
        }

        C.GetCameraLocation( CamLoc, CamRot );
        Dir = P.Location - CamLoc;
        Dist = VSize( Dir );
        if( Dist > ViewportOwner.Actor.TeamBeaconMaxDist || !ViewportOwner.Actor.FastTrace( P.Location, CamLoc ) )
        {
            continue;
        }

        // Don't render pawns behind me!
        GetAxes( ViewportOwner.Actor.ViewTarget.Rotation, X, Y, Z );
        Dir /= Dist;
        if( !((Dir Dot X) > 0.6) )
        {
            continue;
        }

        if( Dist < ViewportOwner.Actor.TeamBeaconPlayerInfoMaxDist )
        {
            // Looks for the CRI of this Pawn
            ForEach ViewportOwner.Actor.DynamicActors( Class'BTClient_ClientReplication', CRI )
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

            if( CRI.Rank == 0 )
            {
                continue;
            }

            S = string( CRI.Rank );
            if( CRI.Rank < 10 )
            {
                S = "0"$S;
            }

            C.TextSize( S, XL, YL );

            Scre = C.WorldToScreen( P.Location + vect(0,0,1) * P.CollisionHeight );
            ScaleDist = ViewportOwner.Actor.TeamBeaconMaxDist * FClamp( 0.04 * P.CollisionRadius, 1.0, 2.0 );
            C.Style = 1;
            Scale = FClamp( 0.28 * (ScaleDist - Dist) / ScaleDist, 0.1, 0.25 );

            C.SetPos( (Scre.X - 0.125 * (RankBeacon.USize*0.5f)), (Scre.Y - (0.125 * RankBeacon.VSize) - 72) );
            C.DrawColor = myHUD.WhiteColor;
            C.DrawTile( RankBeacon, RankBeacon.USize * Scale, RankBeacon.VSize * Scale, 0.0, 0.0, RankBeacon.USize, RankBeacon.VSize );

            C.SetPos( (Scre.X - 0.120 * (RankBeacon.USize*0.5f)) + XL*0.5, (Scre.Y - (0.120 * RankBeacon.VSize) - 72+(YL*0.5)) );
            C.DrawColor = Options.CGoldText;
            C.DrawTextClipped( S, False );
        }
    }
}

exec function SetFontSize( int NewSize )
{
    Options.DrawFontSize = NewSize;
    Options.SaveConfig();
}

// As of LCA v3 ClientBTimes will no longer render keys, LCA v3 will now render the keys.
final function RenderKeys( Canvas C )
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
            if( ViewportOwner.Actor.Pawn != None )
            {
                for( Inv = ViewportOwner.Actor.Pawn.Inventory; Inv != None; Inv = Inv.Inventory )
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
            GetAxes( ViewportOwner.Actor.ViewTarget.Rotation, X, Y, Z );
            Dir = KeyPickupsList[i].Location - CamPos;
            Dist = VSize( Dir );
            Dir /= Dist;
            if( (Dir Dot X) > 0.6 && Dist < 3000 )  // only render if this location is not outside the player view.
            {
                C.Style = ViewportOwner.Actor.ERenderStyle.STY_Alpha;
                C.DrawColor = Class'HUD'.Default.GoldColor;
                if( HU != none )
                {
                    HUD_Assault(ViewportOwner.Actor.myHUD).Draw_2DCollisionBox( C, KeyPickupsList[i], C.WorldToScreen( KeyPickupsList[i].Location ), KeyName, KeyPickupsList[i].DrawScale, True );
                }
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

function RenderGhostMarkings( Canvas C )
{
    local BTClient_GhostMarker Marking;
    local vector Scr;
    local float XL, YL;
    local float T, YT;
    local string S;
    local vector Dir, X, Y, Z, CamPos;
    local rotator CamRot;
    local float Dist;
    local float topTime;

    if( ActiveLevel == none )
        return;

    topTime = GetTopTime();
    C.Font = GetScreenFont( C );
    foreach ViewportOwner.Actor.DynamicActors( class'BTClient_GhostMarker', Marking )
    {
        C.GetCameraLocation( CamPos, CamRot );
        GetAxes( ViewportOwner.Actor.ViewTarget.Rotation, X, Y, Z );
        Dir = Marking.Location - CamPos;
        Dist = VSize( Dir );
        Dir /= Dist;
        if( (Dir dot X) > 0.6 && Dist < 512 )   // only render if this location is not outside the player view.
        {
            T = topTime * (float(Marking.MoveIndex)/float(ActiveLevel.PrimaryGhostNumMoves));
            YT = T - (topTime - GetTimeLeft());
            if( YT >= 0 )
            {
                C.DrawColor = class'HUD'.default.GreenColor;
                S = "+"$FormatTimeCompact( YT );
            }
            else
            {
                C.DrawColor = class'HUD'.default.RedColor;
                S = FormatTimeCompact( YT );
            }
            C.StrLen( S, XL, YL );
            Scr = C.WorldToScreen( Marking.Location );
            C.SetPos( Scr.X - XL*0.5, Scr.Y - YL*0.5 );
            C.DrawText( S, false );
        }
    }
}

final function RenderTitle( Canvas C )
{
    local xPawn P;
    local vector Scre, CamLoc, X, Y, Z, Dir;
    local rotator CamRot;
    local float Dist, XL, YL;
    local string s;
    local BTClient_ClientReplication CRI;

    ForEach ViewportOwner.Actor.DynamicActors( Class'xPawn', P )
    {
        if
        (
            P == ViewportOwner.Actor.ViewTarget
            ||
            P.IsA('Monster')
            ||
            P.bHidden
            ||
            P.bDeleteMe
            ||
            P.bDeRes
        )
        {
            continue;
        }

        C.GetCameraLocation( CamLoc, CamRot );
        Dir = P.Location - CamLoc;
        Dist = VSize( Dir );
        if( Dist > ViewportOwner.Actor.TeamBeaconMaxDist || !ViewportOwner.Actor.FastTrace( P.Location, CamLoc ) )
        {
            continue;
        }

        // Don't render pawns behind me!
        GetAxes( ViewportOwner.Actor.ViewTarget.Rotation, X, Y, Z );
        Dir /= Dist;
        if( !((Dir Dot X) > 0.6) )
        {
            continue;
        }

        if( Dist < (ViewportOwner.Actor.TeamBeaconPlayerInfoMaxDist * 0.4f) )
        {
            // Looks for the CRI of this Pawn
            foreach ViewportOwner.Actor.DynamicActors( Class'BTClient_ClientReplication', CRI )
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

function RenderCompetitiveLayer( Canvas C )
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
    C.DrawColor = myHUD.GreenColor;
    C.SetPos( StartX, StartY );
    C.DrawTile( AlphaLayer, SizeX, YL, 0, 0, 256, 256 );

    gameScore = MRI.Level.GRI.Teams[0].Score + MRI.Level.GRI.Teams[1].Score;
    if( gameScore >= 0f )
    {
        redPct = MRI.Level.GRI.Teams[0].Score / gameScore;
        bluePct = MRI.Level.GRI.Teams[1].Score / gameScore;

        // Draw red's pct
        S = FormatTimeCompact( MRI.TeamTime[0] ) @ "-" @ string(int(MRI.Level.GRI.Teams[0].Score));
        C.TextSize( S, XL, YL );
        C.DrawColor = HU.GetTeamColor( 0 );
        C.SetPos( StartX - XL - 8, StartY );
        C.Style = 3;
        C.DrawText( S );

        C.SetPos( StartX, StartY );
        C.Style = 1;
        C.DrawTile( AlphaLayer, SizeX * (1f - bluePct), YL, 0, 0, 256, 256 );

        // Draw blue's pct
        S = string(int(MRI.Level.GRI.Teams[1].Score)) @ "-" @ FormatTimeCompact( MRI.TeamTime[1] );
        C.TextSize( S, XL, YL );
        C.DrawColor = HU.GetTeamColor( 1 );
        C.SetPos( StartX + SizeX + 8, StartY );
        C.Style = 3;
        C.DrawText( S );

        C.SetPos( StartX + (SizeX - SizeX * (1f - redPct)), StartY );
        C.Style = 1;
        C.DrawTile( AlphaLayer, SizeX * (1f - redPct), YL, 0, 0, 256, 256 );
    }

    C.Style = 3;
    S = "Team Balance";
    C.TextSize( S, XL, YL );
    C.SetPos( StartX + SizeX * 0.5 - XL * 0.5, StartY );
    C.DrawColor = myHUD.WhiteColor;
    C.DrawText( S );

    // Draw border
    C.CurX = StartX;
    C.DrawColor = Class'HUD'.Default.GrayColor;
    C.DrawColor.A = 100;
    class'BTLevelCompletedMessage'.Static.DrawHorizontal( C, StartY-2, SizeX );
    Class'BTLevelCompletedMessage'.Static.DrawHorizontal( C, StartY+YL, SizeX );
    C.CurY -= 2;
    Class'BTLevelCompletedMessage'.Static.DrawVertical( C, StartX, YL+4 );
    Class'BTLevelCompletedMessage'.Static.DrawVertical( C, StartX+SizeX, YL+4 );
}

function array<sCanvasColumn> CreateColumns( Canvas C, array<sTableColumn> columns, optional out float totalWidth, optional out float totalHeight )
{
    local int i;
    local float xl, yl, titleXL, titleYL;
    local array<sCanvasColumn> canvasColumns;

    canvasColumns.Length = columns.Length;
    for( i = 0; i < columns.Length; ++ i )
    {
        C.StrLen( columns[i].Format, xl, yl );
        C.StrLen( columns[i].Title, titleXL, titleYL );
        if( titleXL > xl )
        {
            xl = titleXL;
        }

        if( titleYL > yl )
        {
            yl = titleYL;
        }

        canvasColumns[i].W = xl + COLUMN_PADDING_X*2;
        canvasColumns[i].H = yl + COLUMN_PADDING_Y*2;

        totalWidth += canvasColumns[i].W;
        if( canvasColumns[i].H > totalHeight )
        {
            totalHeight = canvasColumns[i].H;
        }

    }
    return canvasColumns;
}

const TABLE_PADDING = 4;
const TAB_GUTTER = 4;
const HEADER_GUTTER = 2;
const COLUMN_MARGIN = 2;
const COLUMN_PADDING_X = 4;
const COLUMN_PADDING_Y = 2;
const ROW_MARGIN = 2;

final static function DrawLayer( Canvas C, float x, float y, float width, float height )
{
    C.SetPos( x, y );
    C.DrawTile( default.AlphaLayer, width, height, 0, 0, 256, 256 );
    C.SetPos( x, y ); // Reset pushment from DrawTile
}

final static function DrawHeaderTile( Canvas C, float x, float y, float width, float height )
{
    C.DrawColor = #0x99990066;
    DrawLayer( C, x, y, width, height );
}

final static function DrawHeaderText( Canvas C, float x, float y, string title )
{
    C.SetPos( x + COLUMN_PADDING_X, y + COLUMN_PADDING_Y );
    C.DrawColor = #0xFFFFFFFF;
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
        C.DrawColor = Options.CTable;
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
    C.DrawColor = Options.CTable;
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

function RenderFooter( Canvas C )
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
    C.Font = GetScreenFont( C );
    C.StrLen( "T", fontXL, fontYL );

    tableWidth = C.ClipX;
    tableHeight = (fontYL*3 + ROW_MARGIN) + ROW_MARGIN + HEADER_GUTTER;

    tableX = 0;
    tableY = C.ClipY - tableHeight;

    // Progressing render position, starting from the absolute table's position.
    drawX = tableX;
    drawY = tableY;

    // DRAW BACKGROUND
    // C.DrawColor = Options.CTable;
    // DrawLayer( C, drawX, drawY - TABLE_PADDING, tableWidth, tableHeight + TABLE_PADDING );

    drawX += TABLE_PADDING;

    // // Advertisement
    // s = "MutBestTimes";
    // C.StrLen( s, xl, yl );
    // width = xl + TABLE_PADDING*2;
    // height = (tableHeight - TABLE_PADDING*2)*0.5;
    // C.DrawColor = #0x0072C688;
    // DrawColumnTile( C, drawX, drawY, width, height );
    // DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );

    // s = "www.EliotVU.com";
    // C.StrLen( s, xl, yl );
    // width = xl + TABLE_PADDING*2;
    // drawY = tableY + tableHeight - height - TABLE_PADDING;
    // C.DrawColor = #0x0072C688;
    // DrawColumnTile( C, drawX, drawY, width, height );
    // DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );

    // Press F12 or Escape to hide this.
    s = RankingKeyMsg @ RankingHideMsg;
    C.StrLen( s, xl, yl );
    width = xl;
    height = (tableHeight - TABLE_PADDING)*0.5;
    drawX = tableWidth - TABLE_PADDING - xl;
    drawY = tableY + tableHeight - height - TABLE_PADDING;
    C.DrawColor = #0x0072C688;
    DrawHeaderTile( C, drawX, drawY, width, height );
    DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );
}

function PostRender( Canvas C )
{
    local string S;
    local float XL,YL;
    local int i, j, YLength, FLength;
    local float YP, XP;
    local float XP1;
    local xPawn p;

    if( ViewportOwner.Actor.myHUD.bShowScoreBoard || ViewportOwner.Actor.myHUD.bHideHUD || MRI == None || ViewportOwner.Actor.PlayerReplicationInfo == None )
        return;

    C.Font = Font'UT2003Fonts.jFontSmallText800x600';

    if( myHUD != none )
    {
        if( Options.bShowZoneActors )
            RenderZoneActors( C );

        if( MRI.bKeyMap )
            RenderKeys( C );

        RenderGhostMarkings( C );
    }
    if( Options.bProfesionalMode || bPromodeWasPerformed )
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
            else if( !Options.bProfesionalMode && bPromodeWasPerformed )
            {
                p.SoundVolume = p.default.SoundVolume;
                p.bHidden = false;
            }
        }

        if( bPromodeWasPerformed && !Options.bProfesionalMode )
        {
            bPromodeWasPerformed = false;
        }
    }

    if( MRI.CR == none )
        return;

    RenderTitle( C );
    // COMPETITIVE HUD
    if( MRI.bCompetitiveMode )
    {
        RenderCompetitiveLayer( C );
    }

    // TextBox code
    j = MRI.CR.Text.Length;
    if( j > 0 )
    {
        C.Font = GetScreenFont( C );
        C.StrLen( "T", xl, yl );

        YLength = yl*j + (j*3) + TABLE_PADDING;
        FLength = C.ClipY*0.5 - YLength*0.5;

        XP = C.ClipX*0.125;
        YP = FLength;

        XP1 = C.ClipX;
        // C.ClipX *= 0.9;
        C.SetPos( XP, YP - TABLE_PADDING );
        C.DrawColor = Options.CTable;
        C.Style = 1;
        C.DrawTile( AlphaLayer, C.ClipX*0.75, YLength + TABLE_PADDING, 0, 0, 256, 256 );

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
    // Ranking table code
    else if( bShowRankingTable )
    {
        if( ViewportOwner.Actor.Level.GRI != none )
        {
            RenderRankIcon( C );
        }
    }

    if( MRI.RecordState == RS_Active )
    {
        if( InvasionGameReplicationInfo(ViewportOwner.Actor.Level.GRI) == none )
        {
            bTimerPaused = (ViewportOwner.Actor.IsInState( 'GameEnded' )
                || ViewportOwner.Actor.IsInState( 'RoundEnded' )
                || ((ViewportOwner.Actor.IsInState( 'Dead' )
                || ViewportOwner.Actor.ViewTarget == none))
            );

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
            if( Options.bUseAltTimer )
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
            if( HU == none || !HU.ShouldShowObjectiveBoard() )
            {
                DrawRecordWidget( C );
            }
        }
        RenderHUDElements( C );
    }
    else
    {
        switch( MRI.RecordState )
        {
            case RS_Succeed:
                C.Font = GetScreenFont( C );
                if( MRI.GhostPercent < 100 )
                {
                    S = "Saving ghost " $ MRI.GhostPercent $ "%";
                    DrawElement( C, C.ClipX*0.5, C.ClipY*0.2, S,, true,, 4.5 );
                }

                S = MRI.EndMsg;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.05), S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.GoldColor );

                S = MRI.PlayersBestTimes;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.10), "Set by", S, true, C.ClipX*0.65, 4.5 );

                S = MRI.PointsReward;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.15), "Score", S, true, C.ClipX*0.65, 4.5 );
                break;

            case RS_Failure:
                C.Font = GetScreenFont( C );
                S = MRI.EndMsg;
                DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.05), S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.RedColor );
                break;

            case RS_QuickStart:
                C.Font = GetScreenFont( C );
                S = MRI.EndMsg;
                DrawElement( C, C.ClipX*0.5, C.ClipY*0.8, S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.TurqColor );
                break;
        }
    }
}

function RenderHUDElements( Canvas C )
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
        backupColor = Options.CTable;
        Options.CTable = #0xFB607FFF;
        Options.CTable.A = 100;
        v = DrawElement( C, drawX, drawY, "   Checkpoint" );
        Options.CTable = backupColor;

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
        backupColor = Options.CTable;
        Options.CTable = class'HUD'.default.GreenColor;
        Options.CTable.A = 100;
        Options.CTable.G = 150;
        drawY += DrawElement( C, drawX, drawY, s ).y*1.2;
        Options.CTable = backupColor;
    }

    if( SpectatedClient.BTWage > 0 )
    {
        // Draw Level and percent
        S = "Waging";
        backupColor = Options.CTable;
        Options.CTable = #0xFF00FFFF;
        Options.CTable.A = 100;
        drawY += DrawElement( C, drawX, drawY, s, string(SpectatedClient.BTWage) ).y*1.2;
        Options.CTable = backupColor;
    }

    if( MRI.SoloRecords > 0 )
    {
        // Draw Level and percent
        S = "Rank";
        drawY += DrawElement( C, drawX, drawY, s, Eval( SpectatedClient.SoloRank == 0, "?", SpectatedClient.SoloRank )  $ "/" $ MRI.SoloRecords ).y*1.2;
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
        C.StrLen( s, xl, yl );
        drawY += DrawElement( C, C.ClipX*0.5, drawY, "Speed", s, true, 200, 1.0, class'HUD'.default.GoldColor ).Y*1.2;
        if( MRI.CR.bAllowDodgePerk && (ViewportOwner.Actor.ViewTarget == ViewportOwner.Actor.Pawn || bTimeViewTarget) )
        {
            RenderDodgeReady( C, drawY );
        }
    }
}

final static function string Decimal( int number )
{
    local string s, ns;
    local int i;
    local byte l;

    s = string(number);
    ns = s;
    l = Len( s );
    for( i = 0; i < (l-1)/3; ++ i )
    {
        ns = Left( s, l - 3*(i+1) ) $ "," $ Right( ns, 3*(i+1)+i );
    }
    return ns;
}

function DrawRecordWidget( Canvas C )
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
    minWidth = 240;
    C.Style = 1;

    C.Font = GetScreenFont( C );
    drawX -= COLUMN_PADDING_X*2;

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

            if( Options.bPlayTickSounds && MRI.Level.TimeSeconds >= LastTime && int(DrawnTimer) >= 0 && DrawnTimer <= 10 )
            {
                if( ViewportOwner.Actor.ViewTarget != None )
                {
                    if( DrawnTimer < 0.21f )
                    {
                        LastTime = MRI.Level.TimeSeconds + 1.0f;
                        // Avoid a bug that cause the denied sound to be played twice(wtf?)
                        if( DrawnTimer > -0.91f )
                        {
                            ViewportOwner.Actor.ViewTarget.PlayOwnedSound( Options.LastTickSound, SLOT_Interact, 255 );
                            bSoundTicking = True;
                        }
                    }
                    else
                    {
                        LastTime = MRI.Level.TimeSeconds + 1.0f;
                        ViewportOwner.Actor.ViewTarget.PlayOwnedSound( Options.TickSound, SLOT_Interact, 255 );
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
            C.DrawColor = Options.CGoldText;
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
            C.DrawColor = Orange;
        else
        {
            if( DrawnTimer <= 0.0f )
                C.DrawColor = GetFadingColor( class'HUD'.default.RedColor );
            else C.DrawColor = GetFadingColor( class'HUD'.default.GreenColor );
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
        DrawElementValue( C, drawX - xl + COLUMN_PADDING_X*2, drawY, s, GetFadingColor( class'HUD'.default.GreenColor ) );
        drawY += height + COLUMN_PADDING_Y*3;
    }

    // Press F12 or Escape to hide this.
    s = "Leaderboards " $ Options.CGoldText $ "[" $ Class'Interactions'.Static.GetFriendlyName( Options.RankingTableKey ) $ "]";
    C.StrLen( s, width, height );
    C.DrawColor = #0x0088BBFF;
    C.DrawColor.A = Options.CTable.A;
    DrawColumnTile( C, drawX - width + COLUMN_PADDING_X, drawY, width+4, height+2 );
    DrawHeaderText( C, drawX - width + COLUMN_PADDING_X, drawY, s );
}

final static function DrawBorder( Canvas C, float X1, float Y1, float X2, float Y2 )
{
    local float width, height;
    local float bak[2];

    bak[0] = C.ClipX;
    bak[1] = C.ClipY;

    width = X2 - X1;
    height = Y2 - Y1 + 4;   // 2 for top and 2 for bottom

    C.DrawColor = class'HUD'.default.GrayColor;
    C.DrawColor.A = 100;

    C.SetPos( X1, Y1-2 );
    C.DrawTile( texture'UCGeneric.SolidColours.Black', width, 2, 0, 0, 2, 2 );
    C.SetPos( X1, Y2 );
    C.DrawTile( texture'UCGeneric.SolidColours.Black', width, 2, 0, 0, 2, 2 );

    C.SetPos( X1, Y1-2 );
    C.DrawTile( texture'UCGeneric.SolidColours.Black', 2, height, 0, 0, 2, 2 );

    C.SetPos( X2, Y1-2 );
    C.DrawTile( texture'UCGeneric.SolidColours.Black', 2, height, 0, 0, 2, 2 );

    C.ClipX = bak[0];
    C.ClipY = bak[1];
}

final function BTClient_LevelReplication GetCurrentLevel()
{
    local BTClient_LevelReplication curLevel;

    curLevel = SpectatedClient.PlayingLevel;
    if( curLevel == none )
        curLevel = MRI.MapLevel;

    return curLevel;
}

final function float GetTopTime()
{
    if( ActiveLevel == none )
        return 0.00;

    return ActiveLevel.TopTime;
}

final function float GetTimeLeft()
{
    if( MRI.bSoloMap )
    {
        if( Options.bBaseTimeLeftOnPersonal && SpectatedClient.PersonalTime > 0.f )
            return SpectatedClient.PersonalTime - (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
        else return GetTopTime() - (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
    }
    else return GetTopTime() - (MRI.Level.TimeSeconds - (MRI.MatchStartTime - MRI.CR.ClientMatchStartTime));
}

/*final function DrawTextBox( Canvas C, float X, float Y, string Text, string Value, color ValueColor )
{
    local string S;
    local float XL, YL;
    local byte PreStyle;

    PreStyle = C.Style;
    C.Style = 1;

    // Draw Box
    C.StrLen( Text$":"@Value, XL, YL );
    C.SetPos( (X - ((XL - ExTileWidth) - BorderSize)), (Y + YL) );
    C.DrawColor = Options.CTable;
    C.DrawTile( AlphaLayer, ((XL + ExTileWidth) + (BorderSize * 2)), YL, 0, 0, 256, 256 );

    // Draw Border
    C.DrawColor = Class'HUD'.Default.GrayColor;
    C.DrawColor.A = 100;
    C.CurX -= ((XL + ExTileWidth) + (BorderSize * 2));
    Class'BTLevelCompletedMessage'.Static.DrawHorizontal( C, (Y - BorderSize), ((XL + ExTileWidth) + (BorderSize * 2)) );
    Class'BTLevelCompletedMessage'.Static.DrawHorizontal( C, (Y + YL), ((XL + ExTileWidth) + (BorderSize * 2)) );
    C.CurY -= BorderSize;
    Class'BTLevelCompletedMessage'.Static.DrawVertical( C, (C.CurX - BorderSize), (YL + (BorderSize * 2)) );
    Class'BTLevelCompletedMessage'.Static.DrawVertical( C, X, (YL + (BorderSize * 2)) );

    // Draw Content
    C.SetPos( (X - (XL - (BorderSize * 2))), ((YL + ExTileWidth) + BorderSize + ExTextOffset) );
    C.DrawColor = Class'HUD'.Default.WhiteColor;
    C.DrawText( Text$":", True );

    C.StrLen( Value, XL, YL );
    C.SetPos( (X - (XL - (BorderSize * 2))), ((YL + ExTileWidth) + BorderSize + ExTextOffset) );
    C.DrawColor = ValueColor;
    C.DrawText( Value, True );
    C.Style = PreStyle;
}*/

// Enhanced copy of HUD_Assault.uc
final function DrawTextWithBackground( Canvas C, String Text, Color TextColor, float XO, float YO )
{
    local float XL, YL, XL2, YL2;

    C.StrLen( Text, XL, YL );

    XL2 = XL + 64 * myHUD.ResScaleX;
    YL2 = YL +  8 * myHUD.ResScaleY;

    C.DrawColor = Options.CTable;
    C.SetPos( XO - XL2*0.5, YO - YL2*0.5 );
    C.DrawTile( AlphaLayer, XL2, YL2, 0, 0, 256, 256 );

    C.DrawColor = TextColor;
    C.SetPos( XO - XL*0.5, YO - YL*0.5 );
    C.DrawText( Text, false );
}

static final function string Strl( float Value )
{
    return FormatTime( Value );
}

/** Formats the given time in seconds.deci_centi.
    Outputs:[-][00:00:]00.00 */
static final function string FormatTime( float value )                          // Based upon epic's Time Format code
{
    local string hourString, minuteString, secondString, output;
    local int minutes, hours;
    local float seconds;

    seconds = Abs( value );
    minutes = int(seconds) / 60;
    hours   = minutes / 60;
    seconds = seconds - (minutes * 60);
    minutes = minutes - (hours * 60);

    if( seconds < 10 ) secondString = "0" $ seconds; else secondString = string(seconds);
    if( minutes < 10 ) minuteString = "0" $ minutes; else minuteString = string(minutes);
    if( hours < 10 ) hourString = "0" $ hours; else hourString = string(hours);

    if( Class'BTClient_Config'.static.FindSavedData().bDisplayFullTime )
    {
        if( value < 0 )
            return "-" $ hourString $ ":" $ minuteString $ ":" $ secondString;
        else return hourString $ ":" $ minuteString $ ":" $ secondString;
    }
    else
    {
        if( hours != 0 )
            output = hourString $ ":";

        if( minutes != 0 )
            output $= minuteString $ ":";

        if( value < 0 )
            return "-" $ output $ secondString;
        else return output $ secondString;
    }
}

static final function string StrlNoMS( int Value )
{
    local string HourString, MinuteString, SecondString, Output;
    local int Minutes, Hours, Seconds;

    Seconds = Abs(Value);
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

    if( Class'BTClient_Config'.Static.FindSavedData().bDisplayFullTime )
    {
        if( Value < 0 )
            return "-"$HourString$":"$MinuteString$":"$SecondString;
        else return HourString$":"$MinuteString$":"$SecondString;
    }
    else
    {
        if( Hours != 0 )
            Output = HourString$":";

        if( Minutes != 0 )
            Output $= MinuteString$":";

        if( Value < 0 )
            return "-"$Output$SecondString;
        else return Output$SecondString;
    }
}

/** Formats the given time in seconds.deci_centi.
    Outputs:[-][00:00:]00.00 but only if the units are greater than zero! */
static final function string FormatTimeCompact( float value )
{
    local string hourString, minuteString, secondString, output;
    local int minutes, hours;
    local float seconds;

    seconds = Abs( value );
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

    if( value < 0 )
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

static final function string FixDate( int Date[3] )
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

DefaultProperties
{
    YOffsetScale=0.6
    Orange=(R=255,G=255,B=0,A=255)

    bVisible=True
    bRequiresTick=True

    RecordTimeMsg="Time"
    RecordPrevTimeMsg="Previous Time"
    RecordHolderMsg="Holder"
    RecordTimeLeftMsg="Record"
    RecordEmptyMsg="No record available"
    RecordHubMsg="Choose a level!"
    RecordTimeElapsed="Time"
    RankingKeyMsg="Escape/%KEY%"
    RankingToggleMsg="view next page"
    RankingHideMsg="to show/hide this"

    RankBeacon=Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final'
    AlphaLayer=Texture'BTScoreBoardBG'
}
