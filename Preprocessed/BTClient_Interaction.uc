//==============================================================================
// BTClient_Interaction.uc (C) 2005-2010 Eliot and .:..:. All Rights Reserved
//
// This class handles the widgets on the HUD, the F12 tables and any interaction with BTimes.
//
//	Most recent update: $wotgreal_dt: 28/02/2012 11:54:19 $
//==============================================================================
class BTClient_Interaction extends Interaction;

#Exec obj load file="UT2003Fonts.utx"
#Exec obj load file="MenuSounds.uax"
#Exec obj load file="Content/ClientBTimes.utx" package="ClientBTimesV5"

const META_DECOMPILER_VAR_AUTHOR				= "Eliot Van Uytfanghe";
const META_DECOMPILER_VAR_COPYRIGHT				= "(C) 2005-2014 Eliot and .:..:. All Rights Reserved";
const META_DECOMPILER_EVENT_ONLOAD_MESSAGE		= "Please, only decompile this for learning purposes, do not edit the author/copyright information!";

struct LongBuggyCompilerStruct
{
	var int LongBuggyCompilerStruct;
};

replication
{
	reliable if( bool(int(False)) )
		Orange;
}

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
	RecordPrevTimeMsg,
	RecordTimeElapsed,
	Table_Rank,
	Table_PlayerName,
	Table_Points,
	Table_Objectives,
	Table_Records,
	Table_Top,
	Table_Date,
	Table_Time,
	RankingToggleMsg,
	RankingHideMsg;

var const array<sTableColumn> PlayersRankingColumns;
var const array<sTableColumn> RecordsRankingColumns;
var const array<string> RankingRanges;

var string
	RankingKeyMsg,
	OldKey;

var BTClient_MutatorReplicationInfo 		MRI;								// Set by BTClient_MutatorReplicationInfo
var HUD_Assault 							HU;									// Set by BTClient_MutatorReplicationInfo
var HUD										myHUD;
var BTClient_Config 						Options;							// Object to Config, set on Initialized()
var BTClient_ClientReplication 				SpectatedClient;					// Set by PostRender(), used for showing the record timer of other players...

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

var int
	ElapsedTime,
	// Current drawn Table index( see comment above )
	TablePage,
	SelectedIndex,
	SelectedTable,
	SelectedMapTab;

var float
	LastTickTime,
	Delay,
	YOffsetScale,								// Offset scale for EndMap tables
	LastTime,
	DrawnTimer,
	LastShowAllCheck;

var bool bTimerPaused, bSoundTicking;

var const
	texture
	AlphaLayer,
	Layer,
	RankBeacon;
	
// DODGEPERK DATA
var Actor.EPhysics LastPhysicsState;
var Actor.EDoubleClickDir LastDoubleClickDir;
var float LastDodgeTime;
var float LastLandedTime;
var bool bPerformedDodge;
var bool bPreDodgeReady;
var bool bDodgeReady;

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

Final Function SendConsoleMessage( string Msg )
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
Exec Function BT( string Command )
{
	if( Delay > ViewportOwner.Actor.Level.TimeSeconds )
		return;

	Delay = ViewportOwner.Actor.Level.TimeSeconds + 0.5;
	ViewportOwner.Actor.ServerMutate( Command );
}

Exec Function Store( string command )
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

		case "giveitem":
			ViewportOwner.Actor.ServerMutate( "giveitem" @ params[1] @ params[2] );
			break;

		case "toggleitem":
			ViewportOwner.Actor.ServerMutate( "toggleitem" @ params[1] );
			break;
	}
}

exec function TradeCurrency( string playerName, int amount )
{
	BT( "TradeCurrency" @ playerName @ amount );
}

exec function ActivateKey( string key )
{
	BT( "ActivateKey" @ key );
}

exec Function BTCommands()
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
		SendConsoleMessage( "ToggleRanking (Toggles the ScoreBoard)" );
		SendConsoleMessage( "SwitchPage (Switches the Ranking page)" );
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
		SendConsoleMessage( "GhostFollow <PlayerName> (Costs currency!)" );
		SendConsoleMessage( "GhostFollowID <PlayerID> (Only for admins, BTimes author and people with a ObjectivesLevel greater than 0)" );
		SendConsoleMessage( "..." );
		SendConsoleMessage( "TrailerMenu" );
		SendConsoleMessage( "SetTrailerColor 255 255 255 128 128 128 (Only if Ranked!)" );
		SendConsoleMessage( "SetTrailerTexture <Package.Group.Name> (Only if Ranked!)" );
		SendConsoleMessage( "..." );
		//SendConsoleMessage( "AutoPress" );

		if( MRI.RankingPage != "" )
			SendConsoleMessage( "ShowBestTimes (Loads Website!)" );
	}
}

Exec Function SetConfigProperty( string Property, string Value )
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

/*Exec Function AutoPress()
{
	if( MRI.CR.Rank <= MRI.CR.OverallTop.Length && MRI.CR.Rank > 0 )
	{
		MRI.CR.bAutoPress = !MRI.CR.bAutoPress;
		SendConsoleMessage( "AutoPress ON:"$MRI.CR.bAutoPress );
	}
	else SendConsoleMessage( "Sorry you need to be in the top"@MRI.CR.OverallTop.Length$"!" );
}*/

Exec Function SetTableColor( optional color tc )
{
	Options.CTable = tc;
	Options.SaveConfig();
}

Exec Function SetTextColor( optional color tc )
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

Exec Function SetYOffsetScale( float newScale )
{
	YOffsetScale = newScale;
}

exec function SetGlobalSort( int sort )
{
	Options.GlobalSort = sort;
	Options.SaveConfig();
}

Exec Function ShowBestTimes()
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

Exec Function ClearAttachments()
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

Exec Function FastSuicide()
{
	if( ViewportOwner.Actor.Pawn == None )
		return;

	BT( "Suicide" );
}

Exec Function RecentRecords()
{
	BT( "RecentRecords" );
}

Exec Function RecentHistory()
{
	BT( "RecentHistory" );
}

Exec Function RecentMaps()
{
	BT( "RecentMaps" );
}

Exec Function SetTrailerColor( string CmdLine )
{
	BT( "SetTrailerColor" @ CmdLine );
}

Exec Function SetTrailerTexture( string CmdLine )
{
	BT( "SetTrailerTexture" @ CmdLine );
}

Exec Function ShowPlayerInfo( string playerName )
{
	BT( "ShowPlayerInfo" @ playerName );
}

Exec Function ShowMapInfo( string mapName )
{
	BT( "ShowMapInfo" @ mapName );
}

Exec Function ShowMissingRecords()
{
	BT( "ShowMissingRecords" );
}

Exec Function ShowBadRecords()
{
	BT( "ShowBadRecords" );
}

Exec Function SetClientSpawn()
{
	BT( "SetClientSpawn" );
}

Exec Function CreateClientSpawn()
{
	BT( "CreateClientSpawn" );
}

Exec Function MakeClientSpawn()
{
	BT( "MakeClientSpawn" );
}

Exec Function DeleteClientSpawn()
{
	BT( "DeleteClientSpawn" );
}

Exec Function RemoveClientSpawn()
{
	BT( "RemoveClientSpawn" );
}

Exec Function KillClientSpawn()
{
	BT( "KillClientSpawn" );
}

Exec Function ResetCheckPoint()
{
	BT( "ResetCheckPoint" );
}

Exec Function VoteMapSeq( int sequence )
{
	BT( "VoteMapSeq" @ sequence );
}

Exec Function RevoteMap()
{
	if( ViewportOwner.Actor.PlayerReplicationInfo.bAdmin || ViewportOwner.Actor.Level.NetMode == NM_StandAlone )
		BT( "QuickStart" );
	else BT( "VoteMap" @ Left( string(MRI), InStr( string(MRI), "." ) ) );
}

Exec Function VoteMap( string PartInMapName )
{
	BT( "VoteMap" @ PartInMapName );
}

Exec Function ToggleGhost()
{
	BT( "ToggleGhost" );
}

Exec Function GhostFollow( string playerName )
{
	BT( "GhostFollow" @ playerName );
}

Exec Function GhostFollowID( int playerID )
{
	BT( "GhostFollowID" @ playerID );
}

Exec Function Race( string playerName )
{
	BT( "Race" @ playerName );
}

Exec Function ToggleRanking()
{
	/*if( MRI.bSoloMap && MRI.CR.SoloTop.Length != 0 )
	{
		if( !Options.bShowRankingTable && TablePage == 0 )
			TablePage = -1;

		if( TablePage == -1 )
		{
			Options.bShowRankingTable = True;
			Options.SaveConfig();
		}
		++ TablePage;
		if( TablePage > 1 )
		{
			TablePage = -1;
			Options.bShowRankingTable = False;
			Options.SaveConfig();
		}
		return;
	}*/

	Options.bShowRankingTable = !Options.bShowRankingTable;
	Options.SaveConfig();
}

Exec Function SpeedRun()
{
	Options.bUseAltTimer = !Options.bUseAltTimer;
	SendConsoleMessage( "SpeedRun:"$Options.bUseAltTimer );
	Options.SaveConfig();
}

Exec Function ToggleColorFade()
{
	Options.bFadeTextColors = !Options.bFadeTextColors;
	SendConsoleMessage( "FadeTextColors:"$Options.bFadeTextColors );
	Options.SaveConfig();
}

Exec Function TogglePersonalTimer()
{
	Options.bBaseTimeLeftOnPersonal = !Options.bBaseTimeLeftOnPersonal;
	SendConsoleMessage( "Using PersonalTime:"$Options.bBaseTimeLeftOnPersonal );
	Options.SaveConfig();
}

Function bool KeyEvent( out EInputKey Key, out EInputAction Action, float Delta )
{
	local string S;

	S = Caps( ViewportOwner.Actor.ConsoleCommand( "KEYBINDING"@Chr( Key ) ) );
	if( InStr( S, "SHOWALL" ) != -1 )
		return True;		// Ignore Input!.

	if( Action == IST_Press )
	{
		if( !PlatformIs64Bit() && Key == IK_Enter && MRI.RecordState != RS_Active )
		{
			ConsoleCommand( "Minimize" );
			ConsoleCommand( "open" @ MRI.ADURL );
			return true;
		}

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

			if( Options.bShowRankingTable )
			{
				if( MRI.CR != none && MRI.CR.OverallTop.Length == 0 )
				{
					ViewportOwner.Actor.ServerMutate( "BTClient_RequestRankings" );
				}
			}
			return False;
		}

		if( Key == IK_Escape )
		{
			if( MRI.CR.Text.Length > 0 )
			{
				MRI.CR.Text.Length = 0;
				return True;
			}

			if( Options.bShowRankingTable )
			{
				Options.bShowRankingTable = False;
				Options.SaveConfig();
				TablePage = -1;
				return True;
			}
			return false;
		}

		if( Options.bShowRankingTable )
		{
			if( MRI.CR.Text.Length == 0 )
			{
				if( Key == IK_Left )
				{
					SelectedTable = 0;
					SelectedIndex = Min( SelectedIndex, MRI.CR.OverallTop.Length - 1 );
					return true;
				}
				else if( Key == IK_Right && MRI.CR.SoloTop.Length > 0 )
				{
					SelectedTable = 1;
					SelectedIndex = Min( SelectedIndex, MRI.CR.SoloTop.Length - 1 );
					return true;
				}

				if( SelectedTable == 0 )
				{
					if( Key == IK_Tab )
					{
						if( Options.GlobalSort >= 2 )
						{
							Options.GlobalSort = -1;
						}
						++ Options.GlobalSort;

						Options.SaveConfig();

						if( Options.GlobalSort == 0 )
						{
							SelectedIndex = Min( SelectedIndex, MRI.CR.OverallTop.Length - 1 );
						}
						else if( Options.GlobalSort == 0 )
						{
							SelectedIndex = Min( SelectedIndex, MRI.CR.QuarterlyTop.Length - 1 );
						}
						else if( Options.GlobalSort == 0 )
						{
							SelectedIndex = Min( SelectedIndex, MRI.CR.DailyTop.Length - 1 );
						}
						return true;
					}

					if( Options.GlobalSort == 0 )
					{
						if( Key == IK_Down )
						{
							if( ++ SelectedIndex >= MRI.CR.OverallTop.Length )
							{
								Selectedindex = 0;
							}
							return True;
						}
						else if( Key == IK_Up )
						{
							if( -- SelectedIndex < 0 )
							{
								Selectedindex = MRI.CR.OverallTop.Length - 1;
							}
							return True;
						}
						else if( Key == IK_Enter )
						{
							ViewportOwner.Actor.ServerMutate( "ShowPlayerInfo" @ Class'GUIComponent'.Static.StripColorCodes( MRI.CR.OverallTop[SelectedIndex].Name ) );
							return True;
						}
					}
					else if( Options.GlobalSort == 1 )
					{
						if( Key == IK_Down )
						{
							if( ++ SelectedIndex >= MRI.CR.QuarterlyTop.Length )
							{
								Selectedindex = 0;
							}
							return True;
						}
						else if( Key == IK_Up )
						{
							if( -- SelectedIndex < 0 )
							{
								Selectedindex = MRI.CR.QuarterlyTop.Length - 1;
							}
							return True;
						}
						else if( Key == IK_Enter )
						{
							ViewportOwner.Actor.ServerMutate( "ShowPlayerInfo" @ Class'GUIComponent'.Static.StripColorCodes( MRI.CR.QuarterlyTop[SelectedIndex].Name ) );
							return True;
						}
					}
					else if( Options.GlobalSort == 2 )
					{
						if( Key == IK_Down )
						{
							if( ++ SelectedIndex >= MRI.CR.DailyTop.Length )
							{
								Selectedindex = 0;
							}
							return True;
						}
						else if( Key == IK_Up )
						{
							if( -- SelectedIndex < 0 )
							{
								Selectedindex = MRI.CR.DailyTop.Length - 1;
							}
							return True;
						}
						else if( Key == IK_Enter )
						{
							ViewportOwner.Actor.ServerMutate( "ShowPlayerInfo" @ Class'GUIComponent'.Static.StripColorCodes( MRI.CR.DailyTop[SelectedIndex].Name ) );
							return True;
						}
					}
				}
				else if( SelectedTable == 1 )
				{
					if( Key == IK_Tab )
					{
						if( MRI.Level.Screenshot == none )
						{
							SelectedMapTab = 0;
						}
						else
						{
							++ SelectedMapTab;
							if( SelectedMapTab > 1 )
							{
								SelectedMapTab = 0;
							}
						}
						return true;
					}
					else if( Key == IK_Down )
					{
						if( ++ SelectedIndex >= MRI.CR.SoloTop.Length )
						{
							SelectedIndex = 0;
						}
						return True;
					}
					else if( Key == IK_Up )
					{
						if( -- SelectedIndex < 0 )
						{
							SelectedIndex = MRI.CR.SoloTop.Length - 1;
						}
						return True;
					}
					else if( Key == IK_Enter )
					{
						ViewportOwner.Actor.ServerMutate( "ShowPlayerInfo" @ class'GUIComponent'.Static.StripColorCodes( MRI.CR.SoloTop[SelectedIndex].Name ) );
						return True;
					}
				}
			}

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
	return False;
}

Exec Function StartTimer()
{
	bTestRun = true;
	LastTickTime = MRI.Level.TimeSeconds;
	SendConsoleMessage( "Test-Run:ON" );
}

Exec Function PauseTimer()
{
	if( bTestRun )
	{
		bPauseTest = !bPauseTest;
		SendConsoleMessage( "Test-Run Paused:"$bPauseTest );
	}
}

Exec Function StopTimer()
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
			
	if( MRI.CR.bAllowDodgePerk )
	{
		PerformDodgePerk();
	}
	
	/* Anti-ShowAll */
	C = ViewportOwner.Actor.Player.Console;
	if( C != None )
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
		ForEach ViewportOwner.Actor.DynamicActors( Class'DefaultPhysicsVolume', DPV )
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

function PerformDodgePerk()
{
	local Pawn p;
	local bool bDodgePossible;
	local Actor.EPhysics phy;
	local Actor.EDoubleClickDir dir;
	
	p = ViewportOwner.Actor.Pawn;
	if( p == none )
		return;
		
	if( MRI.CR.LastPawn != p )
	{
		bPerformedDodge = false;
		LastLandedTime = ViewportOwner.Actor.Level.TimeSeconds;
		LastDodgeTime = ViewportOwner.Actor.Level.TimeSeconds;
		LastDoubleClickDir = DClick_None;
		LastPhysicsState = PHYS_None;
		bPreDodgeReady = true;
		bDodgeReady = true;
	}
		
	phy = p.Physics;
	dir = xPawn(p).CurrentDir;
	
	if( Options != none && Options.bShowDodgeReady )
	{
		bDodgePossible = ((phy == PHYS_Falling && p.bCanWallDodge) || phy == PHYS_Walking) && !p.bIsCrouched && !p.bWantsToCrouch;
		bPreDodgeReady = ViewportOwner.Actor.Level.TimeSeconds-LastLandedTime >= 0.10 && !bPerformedDodge && bDodgePossible;
		bDodgeReady = ViewportOwner.Actor.Level.TimeSeconds-LastLandedTime >= 0.35 && !bPerformedDodge && bDodgePossible;
	}
	
	if( LastPhysicsState != PHYS_Walking && phy == PHYS_Walking )
	{
		//ViewportOwner.Actor.ClientMessage( "Land!" );	
		PerformedLanding( p );	
	}
	
	if( dir > DCLICK_None )
	{
		//ViewportOwner.Actor.ClientMessage( "Dodge!" );
		PerformedDodge( p );	
		xPawn(p).CurrentDir = DCLICK_None;	 
	}

	LastPhysicsState = phy;
	
	MRI.CR.LastPawn = p;
}

function PerformedDodge( Pawn other )
{
	local float diff;
	
	bPerformedDodge = true;
	if( Options.bShowDodgeDelay )
	{
		diff = ViewportOwner.Actor.Level.TimeSeconds - LastLandedTime;
		if( diff > 0.1f )
		{
			ViewportOwner.Actor.ClientMessage( "DodgeDelay:" $ diff );	
		}
	}
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

Event Initialized()
{
	local DefaultPhysicsVolume DPV;

	Options = Class'BTClient_Config'.Static.FindSavedData();
	if( Options == None )
	{
		Log( "BTClient_Config not found!", Name );
		return;
	}

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

	Key = Class'Interactions'.Static.GetFriendlyName( Options.RankingTableKey );
	if( Len( OldKey ) == 0 )
	{
		RankingKeyMsg = Repl( RankingKeyMsg, "%KEY%", Class'GameInfo'.Static.MakeColorCode( Options.CGoldText )$Key$Class'GameInfo'.Static.MakeColorCode( Class'HUD'.Default.WhiteColor ) );
	}
	else
	{
		RankingKeyMsg = Repl( RankingKeyMsg, OldKey, Class'GameInfo'.Static.MakeColorCode( Options.CGoldText )$Key$Class'GameInfo'.Static.MakeColorCode( Class'HUD'.Default.WhiteColor ) );
	}
	OldKey = Key;
}

Final Function ObjectsInitialized()
{
	local Pickup Key;

	if( ViewportOwner.Actor.myHUD != None && BTClient_TrialScoreBoard(ViewportOwner.Actor.myHUD.ScoreBoard) != None )
		BTClient_TrialScoreBoard(ViewportOwner.Actor.myHUD.ScoreBoard).myInter = Self;

	if( MRI != None )
	{
		if( MRI.bKeyMap )
		{
			ForEach ViewportOwner.Actor.AllActors( Class'Pickup', Key )
			{
				if( Key.IsA('LCAKeyPickup') )
					KeyPickupsList[KeyPickupsList.Length] = Key;
			}
		}
	}

	/*if( Options.bShowRankingTable && MRI.CR != none && MRI.CR.OverallTop.Length == 0 )
	{
		ViewportOwner.Actor.ServerMutate( "BTClient_RequestRankings" );
	}*/
}

final function ReplaceVotingMenu()
{
	local GUIController c;
	local VotingReplicationInfo vri;

	c = GUIController(ViewportOwner.Actor.Player.GUIController);
	if( c.ActivePage != none && c.ActivePage.Class == class'MapVotingPage' )
	{
		vri = VotingReplicationInfo(ViewportOwner.Actor.VoteReplicationInfo);
		if( vri != none && !(vri.GameConfig.Length < vri.GameConfigCount || vri.MapList.Length < vri.MapCount) && vri.bMapVote )
		{
			c.CloseMenu( true );
			c.OpenMenu( string(class'BTClient_MapVotingPage') );
		}
	}
}

Final Function ModifyMenu()
{
	local UT2K4PlayerLoginMenu Menu;
	local BTClient_Menu myMenu;
	local BTGUI_Store storeMenu;

	Menu = UT2K4PlayerLoginMenu(GUIController(ViewportOwner.Actor.Player.GUIController).FindPersistentMenuByName( UnrealPlayer(ViewportOwner.Actor).LoginMenuClass ));
	if( Menu != None )
	{
		Menu.BackgroundRStyle = MSTY_None;
		Menu.i_FrameBG.Image = Texture(DynamicLoadObject( "2k4Menus.NewControls.Display99", Class'Texture', True ));
		Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_BTButton', True );
		Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_StoreButton', True );
		Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_BuyButton', True );
		Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_SellButton', True );

		storeMenu = BTGUI_Store(Menu.c_Main.AddTab( "Store", string(Class'BTGUI_Store'),, "Buy and manage items" ));
		if( storeMenu != none )
		{
			storeMenu.MyInteraction = self;
			storeMenu.MyButton.StyleName = "StoreButton";
			storeMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "StoreButton", storeMenu.FontScale );
			storeMenu.PostInitPanel();
		}

		myMenu = BTClient_Menu(Menu.c_Main.AddTab( "Advanced", string(Class'BTClient_Menu'),, "View and configure BestTimes features" ));
		if( myMenu != None )
		{
			myMenu.MyInteraction = self;
			myMenu.MyButton.StyleName = "BTButton";
			myMenu.MyButton.Style = Menu.c_Main.Controller.GetStyle( "BTButton", myMenu.FontScale );
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
	if( Options != none )
	{
		Options.OldResult = none;
		Options = none;
	}
	SpectatedClient = none;
	KeyPickupsList.Length = 0;
	Master.RemoveInteraction( self );
}

Final Function Color GetFadingColor( color FadingColor )
{
	if( Options.bFadeTextColors )
		return MRI.GetFadingColor( FadingColor );

	return FadingColor;
}

Exec Function ShowZoneActors( optional bool bshowAll, optional bool bdynamicOnly, optional name tag, optional byte rm )
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

Final Function RenderZoneActors( Canvas C )
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
Final Function RenderRankIcon( Canvas C )
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

Exec Function SetFontSize( int NewSize )
{
	Options.DrawFontSize = NewSize;
	Options.SaveConfig();
}

// As of LCA v3 ClientBTimes will no longer render keys, LCA v3 will now render the keys.
Final Function RenderKeys( Canvas C )
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
			if( (Dir Dot X) > 0.6 && Dist < 3000 )	// only render if this location is not outside the player view.
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

	FontSize = 8 - class'BTClient_Config'.static.FindSavedData().ScreenFontSize;
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

	if( MRI == none || SpectatedClient == none )
		return;

	foreach ViewportOwner.Actor.DynamicActors( class'BTClient_GhostMarker', Marking )
	{
		C.GetCameraLocation( CamPos, CamRot );
		GetAxes( ViewportOwner.Actor.ViewTarget.Rotation, X, Y, Z );
		Dir = Marking.Location - CamPos;
		Dist = VSize( Dir );
		Dir /= Dist;
		if( (Dir Dot X) > 0.6 && Dist < 512 )	// only render if this location is not outside the player view.
		{
			T = MRI.MapBestTime * (float(Marking.MoveIndex) / float(MRI.MaxMoves));
			YT = T - (MRI.MapBestTime - GetTimeLeft());
			if( YT >= 0 )
			{
				C.DrawColor = class'HUD'.default.GreenColor;
			}
			else
			{
				C.DrawColor = class'HUD'.default.RedColor;
			}
			S = FormatTimeCompact( T ) @ "+" @ FormatTimeCompact( YT );
			C.StrLen( S, XL, YL );

	     	Scr = C.WorldToScreen( Marking.Location );
	     	C.SetPos( Scr.X - (XL * 0.5), Scr.Y - (YL * 0.5) );
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
	class'BTClient_SoloFinish'.Static.DrawHorizontal( C, StartY-2, SizeX );
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, StartY+YL, SizeX );
	C.CurY -= 2;
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, StartX, YL+4 );
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, StartX+SizeX, YL+4 );
}

function RenderDodgeReady( Canvas C )
{
	local string s;
	local float XL, YL;
	
	if( Options != none && Options.bShowDodgeReady && bPreDodgeReady )
	{
		s = "Dodge: Ready";
		C.StrLen( s, XL, YL );
		C.SetPos( C.ClipX * 0.5 - XL * 0.5, C.ClipY * 0.85 );
		if( bDodgeReady )
		{
			C.DrawColor = class'HUD'.default.GreenColor;
		}
		else C.DrawColor = Orange;
		C.Style = 1;
		C.DrawText( s );
	}
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

final function RenderTables( Canvas C )
{
	RenderRankingsTable( C );

	if( MRI.bSoloMap ){
		RenderRecordsTable( C );
	}
}

// Top players count
final function int GetRankingsCount()
{
	if( Options.GlobalSort == 0 )
	{
		return MRI.CR.OverallTop.Length;
	}
	else if( Options.GlobalSort == 1 )
	{
		return MRI.CR.QuarterlyTop.Length;
	}
	else if( Options.GlobalSort == 2 )
	{
		return MRI.CR.DailyTop.Length;
	}	
}

// Top records count
final function int GetRecordsCount()
{
	return MRI.CR.SoloTop.Length;
}

final function bool IsSelectedTable( int index )
{
	return SelectedTable == index;
}

final function bool IsSelectedRow( int index )
{
	return Selectedindex == index;
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

final function RenderRankingsTable( Canvas C )
{
	// PRE-RENDERED
	local int totalRows, itemsCount;
	local array<sCanvasColumn> columns;
	local float headerWidth, headerHeight;
	local float tableX, tableY;
	local float tableWidth, tableHeight;
	local float drawX, drawY;
	local float fontXL, fontYL;

	// Temporary string measures.
	local float xl, yl;
	local string s;

	// FLOW
	local int columnIdx;
	local int i;
	local string value;
	local bool isFocused, isRowSelected;

	// PRE-RENDERING
	C.Font = GetScreenFont( C );
	C.StrLen( "T", fontXL, fontYL );

	isFocused = IsSelectedTable( 0 );
	itemsCount = GetRankingsCount();	
	totalRows = itemsCount + 1; // +1 TABS ROW	
	if( isFocused || itemsCount == 0 )
	{
		++ totalRows; // Inlined tooltip
	}

	columns = CreateColumns( C, PlayersRankingColumns, headerWidth, headerHeight );

	tableWidth = headerWidth;
	tableHeight = (headerHeight + ROW_MARGIN)*(totalRows + 1) + ROW_MARGIN + HEADER_GUTTER;

	tableX = 0;
	tableY = C.ClipY*0.5 - tableHeight*0.5;	// Centered;

	// Progressing render position, starting from the absolute table's position.
	drawX = tableX;
	drawY = tableY;

	// STYLING
	C.DrawColor = #0xFFFFFF;

	if( !isFocused )
	{
		C.bForceAlpha = true;
		C.ForcedAlpha = 0.5;
	}

	// POST-RENDERING
	// Draw body
	C.DrawColor = Options.CTable;
	DrawLayer( C, drawX, drawY - TABLE_PADDING, tableWidth + TABLE_PADDING*2, tableHeight + TABLE_PADDING*2 );
	drawX += TABLE_PADDING;
	tableX = drawX;
	tableY = drawY;

	s = "Top Players";
	C.StrLen( s, xl, yl );

	// hover: 3d96d8
	C.DrawColor = #0x0072C688;
	DrawColumnTile( C, drawX, drawY, xl + COLUMN_PADDING_X*2, headerHeight );
	DrawHeaderText( C, drawX, drawY, s );

	s = RankingRanges[Options.GlobalSort] $ " (Tab to switch)";
	C.Strlen( s, xl, yl );
	drawX = tableX + tableWidth - TABLE_PADDING - (xl + COLUMN_PADDING_X);
	C.DrawColor = #0x00529668;
	DrawColumnTile( C, drawX, drawY, xl + COLUMN_PADDING_X*2, headerHeight );
	DrawHeaderText( C, drawX, drawY, s );
	drawY += headerHeight + ROW_MARGIN*2;
	drawX = tableX;

	// Draw headers
	for( columnIdx = 0; columnIdx < columns.length; ++ columnIdx )
	{
		DrawHeaderTile( C, drawX + COLUMN_MARGIN, drawY, columns[columnIdx].W - COLUMN_MARGIN*2, columns[columnIdx].H );
		DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, PlayersRankingColumns[columnIdx].Title );
		drawX += columns[columnIdx].W;
	}
	drawX = tableX;
	drawY += headerHeight + HEADER_GUTTER;

	if( itemsCount == 0 )
	{
		C.DrawColor = #0x666666EE;
		s = "No data found, please try again later...";
		DrawColumnText( C, drawX, drawY, s );
	}

	for( i = 0; i < itemsCount; ++ i )
	{
		isRowSelected = isFocused && IsSelectedRow( i );	
		drawY += ROW_MARGIN;
		if( isRowSelected)
		{
			C.DrawColor = #0x222222BB;
		}
		else
		{
			C.DrawColor = #0x22222244;
		}
		DrawColumnTile( C, drawX, drawY, tableWidth, headerHeight );
		if( Options.GlobalSort == 0 && MRI.CR.OverallTop[i].bIsSelf || i == MRI.CR.Rank-1 )
		{
			C.DrawColor = #0x88880044;
			C.SetPos( drawX, drawY + headerHeight-2 );
			C.DrawTile( Texture'Engine.WhiteSquareTexture', tableWidth*0.5, 2, 0, 0, 1, 1 );			

			C.SetPos( drawX, drawY + headerHeight*0.5 );
			C.DrawTile( Texture'Engine.WhiteSquareTexture', 2, headerHeight*0.5, 0, 0, 1, 1 );
		}

		for( columnIdx = 0; columnIdx < columns.length; ++ columnIdx )
		{
			value = "---";
			switch( columnIdx )
			{
				case 0: // "Rank (Any)"
					C.DrawColor = #0x666666FF;
					if( Options.GlobalSort == 0 && MRI.CR.OverallTop[i].bIsSelf )
					{
						value = string(MRI.CR.Rank);
					}
					else
					{
						value = string(i + 1);
					}
					break;

				case 5: // "Tasks (Overall)"
					C.DrawColor = #0x555555FF;
					if( Options.GlobalSort == 0 )
						value = string(MRI.CR.OverallTop[i].Objectives);
					break;	

				case 2: // "Player (All)"
					C.DrawColor = #0xFFFFFFFF;
					if( Options.GlobalSort == 0 )
						value = MRI.CR.OverallTop[i].Name;
					if( Options.GlobalSort == 1 )
						value = MRI.CR.QuarterlyTop[i].Name;
					if( Options.GlobalSort == 2 )
						value = MRI.CR.DailyTop[i].Name;
					break;				

				case 1: // "Score (All)"
					C.DrawColor = #0xFFFFF0FF;
					if( Options.GlobalSort == 0 )
						value = string(int(MRI.CR.OverallTop[i].Points));
					if( Options.GlobalSort == 1 )
						value = string(int(MRI.CR.QuarterlyTop[i].Points));
					if( Options.GlobalSort == 2 )
						value = string(int(MRI.CR.DailyTop[i].Points));
					break;				

				case 3: // "Records (All)"
					C.DrawColor = #0xAAAAAAFF;
					if( Options.GlobalSort == 0 )
						value = string(MRI.CR.OverallTop[i].Hijacks & 0x0000FFFF);
					if( Options.GlobalSort == 1 )
						value = string(MRI.CR.QuarterlyTop[i].Records);
					if( Options.GlobalSort == 2 )
						value = string(MRI.CR.DailyTop[i].Records);
					break;

				case 4: // "Hijacks (Overall)"
					C.DrawColor = #0xAAAAAAFF;
					if( Options.GlobalSort == 0 )
						value = string(MRI.CR.OverallTop[i].Hijacks >> 16);
					break;
			}

			if( isRowSelected )
			{
				C.DrawColor = Lighten( C.DrawColor, 50F );
			}
			DrawColumnText( C, drawX, drawY, value );
			drawX += columns[columnIdx].W;
		}	

		// Tooltip
		if( isRowSelected )
		{
			drawX = tableX;
			drawY += headerHeight + ROW_MARGIN;

			C.DrawColor = #0x666666EE;
			s = "Press " $ $class'HUD'.default.GoldColor $ "Enter" $ $C.DrawColor $ " to see more statistics of this player ...";
			DrawColumnText( C, drawX, drawY, s );
		}

		drawX = tableX;
		drawY += headerHeight;
	}
	C.bForceAlpha = false;
}

final function RenderRecordsTable( Canvas C )
{
	// PRE-RENDERED
	local int totalRows, itemsCount;
	local array<sCanvasColumn> columns;
	local float headerWidth, headerHeight;
	local float tableX, tableY;
	local float drawX, drawY;
	local float tableWidth, tableHeight;
	local float fontXL, fontYL;

	// Temporary string measures.
	local float xl, yl;
	local string s;

	// FLOW
	local int columnIdx;
	local int i;
	local string value;
	local bool isFocused, isRowSelected;

	// PRE-RENDERING
	C.Font = GetScreenFont( C );
	C.StrLen( "T", fontXL, fontYL );

	isFocused = IsSelectedTable( 1 );

	itemsCount = GetRecordsCount();	
	totalRows = itemsCount + 1; // +1 TABS ROW	
	if( isFocused || itemsCount == 0 )
	{
		++ totalRows; // Inlined tooltip
	}
	columns = CreateColumns( C, RecordsRankingColumns, headerWidth, headerHeight );

	tableWidth = headerWidth;
	tableHeight = (headerHeight + ROW_MARGIN)*(totalRows + 1) + ROW_MARGIN + HEADER_GUTTER;

	tableX = C.ClipX - tableWidth - TABLE_PADDING*2;
	tableY = C.ClipY*0.5 - tableHeight*0.5;	// Centered;

	// Progressing render position, starting from the absolute table's position.
	drawX = tableX;
	drawY = tableY;

	// STYLING
	C.DrawColor = #0xFFFFFF;

	if( !isFocused )
	{
		C.bForceAlpha = true;
		C.ForcedAlpha = 0.5;
	}

	// POST-RENDERING
	// Draw body
	C.DrawColor = Options.CTable;
	DrawLayer( C, drawX, drawY - TABLE_PADDING, tableWidth + TABLE_PADDING*2, tableHeight + TABLE_PADDING*2 );
	drawX += TABLE_PADDING;
	// drawY += TABLE_PADDING;
	tableX = drawX;
	tableY = drawY;

	C.DrawColor = #0x0072C688;
	DrawColumnTile( C, drawX, drawY, tableWidth, headerHeight );
	DrawHeaderText( C, drawX, drawY, "Top Records" );
	drawY += headerHeight + ROW_MARGIN*2;

	// Draw headers
	for( columnIdx = 0; columnIdx < columns.length; ++ columnIdx )
	{
		DrawHeaderTile( C, drawX + COLUMN_MARGIN, drawY, columns[columnIdx].W - COLUMN_MARGIN*2, columns[columnIdx].H );
		DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, RecordsRankingColumns[columnIdx].Title );
		drawX += columns[columnIdx].W;
	}
	drawX = tableX;
	drawY += headerHeight + HEADER_GUTTER;

	if( itemsCount == 0 )
	{
		C.DrawColor = #0x666666EE;
		s = "No data found, please try again later...";
		DrawColumnText( C, drawX, drawY, s );
	}

	for( i = 0; i < itemsCount; ++ i )
	{
		isRowSelected = isFocused && IsSelectedRow( i );
		drawY += ROW_MARGIN;
		if( isRowSelected )
		{
			C.DrawColor = #0x222222BB;
		}
		else
		{
			C.DrawColor = #0x22222244;
		}

		DrawColumnTile( C, drawX, drawY, tableWidth, headerHeight );
		if( MRI.CR.SoloTop[i].bIsSelf || i == MRI.CR.SoloRank-1 )
		{
			C.DrawColor = #0x88880044;
			C.SetPos( drawX, drawY + headerHeight-2 );
			C.DrawTile( Texture'Engine.WhiteSquareTexture', tableWidth*0.5, 2, 0, 0, 1, 1 );			

			C.SetPos( drawX, drawY + headerHeight*0.5 );
			C.DrawTile( Texture'Engine.WhiteSquareTexture', 2, headerHeight*0.5, 0, 0, 1, 1 );
		}

		for( columnIdx = 0; columnIdx < columns.length; ++ columnIdx )
		{
			switch( columnIdx )
			{
				case 0: // "Rank"
					C.DrawColor = #0x666666FF;
					if( MRI.CR.SoloTop[i].bIsSelf )
					{
						value = string(MRI.CR.SoloRank);
					}
					else
					{
						value = string(i + 1);
					}
					break;

				case 1: // "Score"
					C.DrawColor = #0xFFFFF0FF;
					value = string(MRI.CR.SoloTop[i].Points);
					break;				

				case 2: // "Player"
					C.DrawColor = #0xFFFFFFFF;
					value = MRI.CR.SoloTop[i].Name;
					break;				

				case 3: // "Time"
					C.DrawColor = #0xAAAAAAFF;
					value = FormatTimeCompact(MRI.CR.SoloTop[i].Time);
					break;

				case 4: // "Date"
					C.DrawColor = #0xAAAAAAFF;
					value = MRI.CR.SoloTop[i].Date;
					break;
			}

			if( isRowSelected )
			{
				C.DrawColor = Lighten( C.DrawColor, 50F );
			}
			DrawColumnText( C, drawX, drawY, value );
			drawX += columns[columnIdx].W;
		}	

		// Tooltip
		if( isRowSelected )
		{
			drawX = tableX;
			drawY += headerHeight + ROW_MARGIN;

			C.DrawColor = #0x666666EE;
			s = "Press " $ $class'HUD'.default.GoldColor $ "Enter" $ $C.DrawColor $ " to see more statistics of this player ...";
			DrawColumnText( C, drawX, drawY, s );
		}

		drawX = tableX;
		drawY += headerHeight;
	}
	C.bForceAlpha = false;
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
	C.DrawColor = Options.CTable;
	DrawLayer( C, drawX, drawY - TABLE_PADDING, tableWidth, tableHeight + TABLE_PADDING );

	drawX += TABLE_PADDING;

	// Advertisement
	s = "MutBestTimes";
	C.StrLen( s, xl, yl );
	width = xl + TABLE_PADDING*2;
	height = (tableHeight - TABLE_PADDING*2)*0.5;
	C.DrawColor = #0x0072C688;
	DrawColumnTile( C, drawX, drawY, width, height );
	DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );

	s = "www.EliotVU.com";
	C.StrLen( s, xl, yl );
	width = xl + TABLE_PADDING*2;
	drawY = tableY + tableHeight - height - TABLE_PADDING;
	C.DrawColor = #0x0072C688;
	DrawColumnTile( C, drawX, drawY, width, height );
	DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );

	// Press F12 or Escape to hide this.
	s = RankingKeyMsg @ RankingHideMsg;
	C.StrLen( s, xl, yl );
	width = xl;
	height = (tableHeight - TABLE_PADDING*2)*0.5;
	drawX = tableWidth - TABLE_PADDING - xl;
	drawY = tableY + tableHeight - height - TABLE_PADDING;
	C.DrawColor = #0x0072C688;
	DrawHeaderTile( C, drawX, drawY, width, height );
	DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, s );
}

function PostRender( Canvas C )
{
	local string S;
	local float XL,YL,YL2,YL3,YL4;
	local int i, j, YLength, ExYL, FLength;
	local float YP, XP, XPL, YPL;
	local float XP1, XP2, XP3, XP4, XP5;
	local float nXP, nYP;
	local float TableXL;
	local float TableOffset;
	local float FXL, FYL;
	local float rXL;
	local LinkedReplicationInfo LRI;
	
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
	RenderTitle( C );

	// Look for our ClientReplication object
	if( MRI.CR == None )
	{
		for( LRI = ViewportOwner.Actor.PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
		{
			if( BTClient_ClientReplication(LRI) != None )
			{
				MRI.CR = BTClient_ClientReplication(LRI);
				MRI.CR.MRI = MRI;
				break;
			}
		}
	}

	if( MRI.CR == None )
		return;
		
	if( ViewportOwner.Actor.Pawn != none )
	{
		RenderDodgeReady( C );
	}

	// See if client is spectating someone!
	if( MRI.bSoloMap )
	{
		SpectatedClient = None;
		if( Pawn(ViewportOwner.Actor.ViewTarget) != None && ViewportOwner.Actor.ViewTarget != ViewportOwner.Actor.Pawn )
		{
			for( LRI = Pawn(ViewportOwner.Actor.ViewTarget).PlayerReplicationInfo.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
			{
				if( BTClient_ClientReplication(LRI) != None )
				{
					SpectatedClient = BTClient_ClientReplication(LRI);
					break;
				}
			}
		}

		// Not spectating anyone, assign to myself!
		if( SpectatedClient == None )
		{
			SpectatedClient = MRI.CR;
		}
	}
	else
	{
		SpectatedClient = MRI.CR;
	}

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

		XP = 0;
		YP = FLength;

		XP1 = C.ClipX;
		// C.ClipX *= 0.9;
		C.SetPos( XP, YP - TABLE_PADDING );
		C.DrawColor = Options.CTable;
		C.Style = 1;
		C.DrawTile( AlphaLayer, C.ClipX, YLength + TABLE_PADDING, 0, 0, 256, 256 );

		// Draw the packets
		YP += TABLE_PADDING;
		C.DrawColor = class'HUD'.default.WhiteColor;
		for( i = 0; i < j; ++ i )
		{
			C.SetPos( XP + TABLE_PADDING, YP + i*yl );
			C.DrawText( MRI.CR.Text[i] );
			YP += 3;
		}
		C.ClipX = XP1;

		RenderFooter( C );
	}
	// Ranking table code
	else if( Options.bShowRankingTable )
	{
	    if( ViewportOwner.Actor.Level.GRI != none )
	    {
			RenderRankIcon( C );
			RenderTables( C );
		}

		RenderFooter( C );
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
				if( MRI.PlayersBestTimes != "" )
				{
					// Don't count if game ended etc
					if( bTimerPaused )
					{
						if( DrawnTimer == 0.0f )
							DrawnTimer = MRI.MapBestTime;
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
			}

			// Draw record information!.
			// Don't render anything when the objectives board is displayed.
			if( HU == none || !HU.ShouldShowObjectiveBoard() )
			{
				DrawRecordWidget( C );
			}
		}
		// Solo Rank
		if( !Options.bShowRankingTable && MRI.CR.Text.Length == 0 )
		{	
			RenderHUDElements( C );
		}
	}
	else
	{
		switch( MRI.RecordState )
		{
			case RS_Succeed:
				C.Font = myHUD.LoadFont( 7 );
				if( MRI.GhostPercent < 100 )
				{
					S = "Saving ghost " $ MRI.GhostPercent $ "%";
					DrawElement( C, C.ClipX*0.5, C.ClipY*0.2, S,, true,, 4.5 );
				}

				S = MRI.EndMsg;
				DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.05), S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.GoldColor );

				S = MRI.PlayersBestTimes;
				DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.10), "Holder", S, true, C.ClipX*0.65, 4.5 );

				S = MRI.PointsReward;
				DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.15), "Reward", S, true, C.ClipX*0.65, 4.5 );
				break;

			case RS_Failure:
				C.Font = myHUD.GetFontSizeIndex( C, Options.DrawFontSize );

				S = MRI.EndMsg;
				DrawElement( C, C.ClipX*0.5, C.ClipY*(YOffsetScale + 0.05), S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.RedColor );
				break;

			case RS_QuickStart:
				C.Font = myHUD.GetFontSizeIndex( C, Options.DrawFontSize );

				S = MRI.EndMsg;
				DrawElement( C, C.ClipX*0.5, C.ClipY*0.8, S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.TurqColor );
				break;
		}

		if( !PlatformIs64Bit() && MRI.ADMessage != "" )
		{
			S = MRI.ADMessage;
			DrawElement( C, C.ClipX*0.5, C.ClipY*0.2, S, "", true, C.ClipX*0.65, 4.5, class'HUD'.default.GreenColor );
		}
	}
}

function RenderHUDElements( Canvas C )
{
	// PRE-RENDERED
	local float drawX, drawY;
	local float fontXL, fontYL;

	// Temporary string measures.
	local float xl, yl;
	local Vector v;
	local string s;
	local Color backupColor;

	drawX = COLUMN_PADDING_X;
	drawY = (C.ClipY * 0.5);
	C.Style = 1;
	if( MRI.CR.ClientSpawnPawn != none )
	{
		if( MRI.Level.GRI != none && MRI.Level.GRI.GameName == "Capture the Flag" )
		{
			S = "CheckPoint";
		}
		else
		{
			S = "ClientSpawn";
		}

		backupColor = Options.CTable;
		Options.CTable = class'HUD'.default.GreenColor;
		Options.CTable.A = 100;
		Options.CTable.G = 150;
		drawY += DrawElement( C, drawX, drawY, s ).y*1.2;
		Options.CTable = backupColor;
	}
	
	if( MRI.CR.ProhibitedCappingPawn != none )
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
	
	if( MRI.CR.SoloTop.Length > 0 )
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
			C.SetPos( drawX + v.x, drawY + v.y*0.5 );
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

	s = "Currency";
	DrawElement( C, drawX, drawY, s, SpectatedClient.BTPoints );
}

function DrawRecordWidget( Canvas C )
{
	local string timeLeftF, bestTimeF;
	local float minWidth;

	// PRE-RENDERED
	local float drawX, drawY;
	local float fontXL, fontYL;
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

	if( MRI.PlayersBestTimes == "" )
		s = RecordEmptyMsg;
	
	if( s != RecordEmptyMsg )
	{
		// =============================================================
		// Record Ticker
		if( bTimerPaused )
		{
			if( DrawnTimer == 0.0f )
				DrawnTimer = MRI.MapBestTime;
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
			s = RecordTimeMsg $ " " $ FormatTime( MRI.MapBestTime );
			if( MRI.PreviousBestTime > 0 )
			{
				s $= " / " $ FormatTime( MRI.PreviousBestTime );
			}
			C.StrLen( s, width, height );
			width = FMax( width, minWidth );
			DrawElementTile( C, drawX - width, drawY, width, height );

			s = RecordTimeMsg $ " ";
			DrawElementText( C, drawX - width, drawY, s );

			s = FormatTime( MRI.MapBestTime );
			if( MRI.PreviousBestTime > 0 )
			{
				s $= " / " $ FormatTime( MRI.PreviousBestTime );
			}
			C.StrLen( s, xl, yl );
			C.DrawColor = Options.CGoldText;
			DrawElementValue( C, drawX - xl + COLUMN_PADDING_X*2, drawY, s );
			drawY += height + COLUMN_PADDING_Y*3;
		}

		// Record Author
		// Title
		s = RecordHolderMsg $ " " $ MRI.PlayersBestTimes;
		C.TextSize( %s, width, height );
		width = FMax( width, minWidth );
		DrawElementTile( C, drawX - width, drawY, width, height );

		// Left column
		s = RecordHolderMsg $ " ";
		DrawElementText( C, drawX - width, drawY, s );

		// Right column
		s = MRI.PlayersBestTimes;
		C.TextSize( %s, xl, yl );
		DrawElementValue( C, drawX - xl + COLUMN_PADDING_X*2, drawY, s );
		drawY += height + COLUMN_PADDING_Y*3;
		// ...

		// Record Timer
		// DRAWS: Time Left: TIMELEFT/BESTTIME
		timeLeftF = FormatTime( DrawnTimer );
		bestTimeF = FormatTime( MRI.MapBestTime );

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
	else	// No Record avaible.
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
	s = "Rankings " $ Options.CGoldText $ "[" $ Class'Interactions'.Static.GetFriendlyName( Options.RankingTableKey ) $ "]";
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
	height = Y2 - Y1 + 4;	// 2 for top and 2 for bottom

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

final function float GetTimeLeft()
{
	if( MRI.bSoloMap )
	{
		if( Options.bBaseTimeLeftOnPersonal && SpectatedClient.PersonalTime > 0.f )
			return SpectatedClient.PersonalTime - (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
		else return MRI.MapBestTime - (MRI.Level.TimeSeconds - SpectatedClient.LastSpawnTime);
	}
	else
	{
		if( MRI.MatchStartTime != 0 )
		{
			return MRI.MapBestTime - (MRI.Level.TimeSeconds - (MRI.MatchStartTime - MRI.CR.ClientMatchStartTime));
		}
		else
		{
			return MRI.MapBestTime;
		}
	}
}

/*Final Function DrawTextBox( Canvas C, float X, float Y, string Text, string Value, color ValueColor )
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
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, (Y - BorderSize), ((XL + ExTileWidth) + (BorderSize * 2)) );
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, (Y + YL), ((XL + ExTileWidth) + (BorderSize * 2)) );
	C.CurY -= BorderSize;
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, (C.CurX - BorderSize), (YL + (BorderSize * 2)) );
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, X, (YL + (BorderSize * 2)) );

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
Final Function DrawTextWithBackground( Canvas C, String Text, Color TextColor, float XO, float YO )
{
	local float	XL, YL, XL2, YL2;

	C.StrLen( Text, XL, YL );

	XL2	= XL + 64 * myHUD.ResScaleX;
	YL2	= YL +  8 * myHUD.ResScaleY;

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
static final function string FormatTime( float value ) 							// Based upon epic's Time Format code
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

DefaultProperties
{
	YOffsetScale=0.6
	TablePage=0

	Orange=(R=255,G=255,B=0,A=255)

	bVisible=True
	bRequiresTick=True

	RecordTimeMsg="Time"
	RecordPrevTimeMsg="Previous Time"
	RecordHolderMsg="Holder"
	RecordTimeLeftMsg="Timer"
	RecordEmptyMsg="No record available"
	RecordTimeElapsed="Time"
	RankingKeyMsg="Escape/%KEY%"
	RankingToggleMsg="view next page"
	RankingHideMsg="to show/hide this"

	Table_Rank="Rank"
	Table_PlayerName="PlayerName"
	Table_Points="Points"
	Table_Objectives="Objectives"
	Table_Records="Records"
	Table_Time="Time"
	Table_Top="Top"
	Table_Date="Date"

	RankBeacon=Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final'
	AlphaLayer=Texture'BTScoreBoardBG'
	Layer=Texture'BTScoreBoardBG' 

	PlayersRankingColumns(0)=(Title="#",Format="0000")
	PlayersRankingColumns(1)=(Title="Score",Format="00000")
	PlayersRankingColumns(2)=(Title="Player",Format="WWWWWWWWWWWW")
	PlayersRankingColumns(3)=(Title="Records",Format="0000")
	PlayersRankingColumns(4)=(Title="Hijacks",Format="0000")
	PlayersRankingColumns(5)=(Title="Objectives",Format="00000")

	RecordsRankingColumns(0)=(Title="#",Format="000")
	RecordsRankingColumns(1)=(Title="Score",Format="00.00")
	RecordsRankingColumns(2)=(Title="Player",Format="WWWWWWWWWWWW")
	RecordsRankingColumns(3)=(Title="Time",Format="00:00:00.00")
	RecordsRankingColumns(4)=(Title="Date",Format="0000/00/00")

	RankingRanges(0)="All Time"
	RankingRanges(1)="Monthly"
	RankingRanges(2)="Daily"
}
