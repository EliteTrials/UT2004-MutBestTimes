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
#Exec obj load file="Content/ClientBTimes.utx" package="ClientBTimesV4D"

const META_DECOMPILER_VAR_AUTHOR				= "Eliot Van Uytfanghe";
const META_DECOMPILER_VAR_COPYRIGHT				= "(C) 2005-2012 Eliot and .:..:. All Rights Reserved";
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
	bNoRenderZoneActors;

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

final static preoperator Color #( int rgbInt )
{
	local Color c;
	
	c.R = rgbInt >> 24;	
	c.G = rgbInt >> 16;	
	c.B = rgbInt >> 8;	
	c.A = (rgbInt & 255);	
	return c;
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
	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

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

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

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
	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

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

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

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

Final Function ModifyMenu()
{
	local UT2K4PlayerLoginMenu Menu;
	local BTClient_Menu myMenu;

	Menu = UT2K4PlayerLoginMenu(GUIController(ViewportOwner.Actor.Player.GUIController).FindPersistentMenuByName( UnrealPlayer(ViewportOwner.Actor).LoginMenuClass ));
	if( Menu != None )
	{
		Menu.BackgroundRStyle = MSTY_None;
		Menu.i_FrameBG.Image = Texture(DynamicLoadObject( "2k4Menus.NewControls.Display99", Class'Texture', True ));

		/*Menu.WinHeight = 0.85;
		Menu.WinWidth = 0.75;
		Menu.WinLeft = 0.175;
		Menu.WinTop = 0.075;*/

		myMenu = BTClient_Menu(Menu.c_Main.AddTab( "Advanced", string(Class'BTClient_Menu'),, "View and configure BestTimes features" ));
		if( myMenu != None )
		{
			myMenu.MyInteraction = self;
			Menu.c_Main.Controller.RegisterStyle( Class'BTClient_STY_BTButton', True );
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

Exec Function ShowZoneActors()
{
	Options.bShowZoneActors = !Options.bShowZoneActors;
	SendConsoleMessage( "ShowZoneActors:"$Options.bShowZoneActors );
	Options.SaveConfig();
}

Final Function RenderZoneActors( Canvas C )
{
	local Actor A;
	local Teleporter NextTP;
	local vector Scre, Scre2;
	local string S;
	local float Dist, XL, YL;
	local PlayerController PC;

	if( bNoRenderZoneActors )
		return;

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

	PC = ViewportOwner.Actor;
	if( PC == None || Pawn(PC.ViewTarget) == None )
		return;

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

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

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

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

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
	     	C.DrawText( S, true );
	    }
	}
}

final function RenderTitle( Canvas C )
{
	local xPawn P;
	local vector Scre, CamLoc, X, Y, Z, Dir;
	local rotator CamRot;
	local float Dist, XL, YL;
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

		if( Dist < (ViewportOwner.Actor.TeamBeaconPlayerInfoMaxDist * 0.4f) )
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

			if( CRI.Title == "" )
			{
				continue;
			}

			S = CRI.Title;
			C.TextSize( Class'GUIComponent'.static.StripColorCodes( S ), XL, YL );

			Scre = C.WorldToScreen( P.Location - vect(0,0,1) * P.CollisionHeight );

			C.SetPos( Scre.X - XL * 0.5f, Scre.Y - YL * 0.5f );
			C.Style = 1;
			C.DrawColor = Options.CTable;
			C.DrawTile( AlphaLayer, XL, YL, 0, 0, 256, 256 );

			// Draw border
			C.CurX = Scre.X - XL * 0.5f;
			C.DrawColor = Class'HUD'.Default.GrayColor;
			C.DrawColor.A = 100;
			class'BTClient_SoloFinish'.Static.DrawHorizontal( C, Scre.Y - YL * 0.5f - 2, XL );
			Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, Scre.Y - YL * 0.5f + YL, XL );
			C.CurY -= 2;
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, Scre.X - XL * 0.5f, YL+4 );
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, Scre.X - XL * 0.5f + XL, YL+4 );
			// ...

			C.SetPos( Scre.X - XL * 0.5f + 1, Scre.Y - YL * 0.5f );
			C.Style = 3;
			C.DrawColor = class'HUD'.default.WhiteColor;
			C.DrawTextClipped( S, False );
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
	RenderRecordsTable( C );
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

final function DrawLayer( Canvas C, float x, float y, float width, float height )
{
	C.SetPos( x, y );
	C.DrawTile( AlphaLayer, width, height, 0, 0, 256, 256 );
	C.SetPos( x, y ); // Reset pushment from DrawTile
}

final function DrawHeaderTile( Canvas C, float x, float y, float width, float height )
{
	C.DrawColor = #0x99990066;
	DrawLayer( C, x, y, width, height );
}

final function DrawHeaderText( Canvas C, float x, float y, string title )
{
	C.SetPos( x + COLUMN_PADDING_X, y + COLUMN_PADDING_Y );
	C.DrawColor = #0xFFFFFFFF;
	C.DrawText( title, false );
	C.SetPos( x, y ); // Reset pushment from DrawText
}

final function DrawColumnTile( Canvas C, float x, float y, float width, float height )
{
	DrawLayer( C, x, y, width, height );
}

final function DrawColumnText( Canvas C, float x, float y, string title )
{
	C.SetPos( x + COLUMN_MARGIN, y + COLUMN_MARGIN );
	C.DrawText( title, false );
	C.SetPos( x, y ); // Reset pushment from DrawText
}

final function RenderRankingsTable( Canvas C )
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

	C.DrawColor = #0xEDEDED88;
	DrawColumnTile( C, drawX, drawY, tableWidth, headerHeight );
	DrawHeaderText( C, drawX, drawY, 
		Eval(Options.GlobalSort == 0, "Top Players - All Time", 
			Eval(Options.GlobalSort == 1, "Top Players - Monthly", 
				Eval(Options.GlobalSort == 2, "Top Players - Daily", "")
			) 
		)
	);
	drawY += headerHeight + ROW_MARGIN*2;

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
			C.DrawColor = #0x222222FF;
		}
		else
		{
			C.DrawColor = #0x22222244;
		}
		DrawColumnTile( C, drawX, drawY, tableWidth, headerHeight );
		for( columnIdx = 0; columnIdx < columns.length; ++ columnIdx )
		{
			value = "---";
			switch( columnIdx )
			{
				case 0: // "Rank (Any)"
					C.DrawColor = #0x666666FF;
					value = string(i + 1);
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

	tableX = C.ClipX - tableWidth - TABLE_PADDING;
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

	C.DrawColor = #0xEDEDED88;
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
			C.DrawColor = #0x222222FF;
		}
		else
		{
			C.DrawColor = #0x22222244;
		}
		DrawColumnTile( C, drawX, drawY, tableWidth, headerHeight );
		for( columnIdx = 0; columnIdx < columns.length; ++ columnIdx )
		{
			switch( columnIdx )
			{
				case 0: // "Rank"
					C.DrawColor = #0x666666FF;
					value = string(i + 1);
					break;

				case 1: // "Score"
					C.DrawColor = #0xFFFFF0FF;
					value = string(int(MRI.CR.SoloTop[i].Points));
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

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:
	
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
		C.StrLen( "T", FXL, FYL );

		YLength = (FYL * (j+2));
		FLength = ((C.ClipY*0.5)-(YLength*0.5));

		// Draw begin line
		ViewportOwner.Actor.myHUD.DrawCanvasLine( 0, FLength-1, C.ClipX, FLength-1, Options.CGoldText );

		C.SetPos( TableOffset, FLength );
		C.DrawColor = Options.CTable;
		C.Style = 1;
		C.DrawTile( AlphaLayer, C.ClipX, YLength, 0, 0, 256, 256 );
		//C.Style = 3;

		// Draw header
		YP = FLength;
		C.SetPos( TableOffset, YP );
		C.DrawColor = class'HUD'.default.WhiteColor;
		C.DrawText( RankingKeyMsg@RankingHideMsg, True );

		YP += FYL;

		// Draw the packets
		C.DrawColor = class'HUD'.default.WhiteColor;
		for( i = 0; i < j; ++ i )
		{
			YP += FYL;

			C.SetPos( TableOffset, YP );
			C.DrawText( MRI.CR.Text[i], True );
		}

		// Draw end line
		ViewportOwner.Actor.myHUD.DrawCanvasLine( 0, YP+FYL, C.ClipX, YP+FYL-1, Options.CGoldText );
	}
	// Ranking table code
	else if( Options.bShowRankingTable )
	{
	    if( ViewportOwner.Actor.Level.GRI != none )
	    {
			RenderRankIcon( C );
			RenderTables( C );
		}

		// Draw bottom bar
		C.Font = GetScreenFont( C );
		C.StrLen( "T", XL, YL );

		C.SetPos( 0, C.ClipY - (YL * 2) );
		C.Style = 1;
		C.DrawColor = Options.CTable;
		C.DrawTile( AlphaLayer, C.ClipX, (YL * 2), 0, 0, 256, 256 );

		// Stats
		C.SetPos( 4, C.ClipY - (YL * 2) ); // Upper
		C.DrawColor = class'HUD'.default.WhiteColor;
		S = "Players:" $ MRI.PlayersCount;
		C.StrLen( S, XL, YL );
		C.DrawText( S, true );

		C.SetPos( 4, C.ClipY - YL ); // Bottom
		S = "Records:" $ Eval( MRI.RecordsCount > 0, MRI.RecordsCount, "???" )  $ "/" $ MRI.MaxRecords;
		C.StrLen( S, XL, YL );
		C.DrawText( S, true );

		C.SetPos( 4 + XL + 8, C.ClipY - (YL * 2) ); // Upper
		C.DrawColor = class'HUD'.default.WhiteColor;
		S = "Currency Spent:" $ MRI.TotalCurrencySpent;
		C.DrawText( S, true );

		C.SetPos( 4 + XL + 8, C.ClipY - YL ); // Bottom
		S = "Items Bought:" $ MRI.TotalItemsBought;
		C.DrawText( S, true );

		S = RankingKeyMsg @ RankingHideMsg;
		C.StrLen( S, XL, YL );

		C.SetPos( C.ClipX - XL - 4, C.ClipY - (YL * 2) ); // Upper
		C.DrawText( S, true );

		S = "eliotvu.com";
		C.StrLen( S, XL, YL );

		C.SetPos( C.ClipX - XL - 4, C.ClipY - YL ); // Bottom
		C.DrawText( S, true );

		// Credits
		C.StrLen( class'GUIComponent'.static.StripColorCodes( MRI.Credits ), XL, YL );
		// Center Bottom
		C.SetPos( (C.ClipX * 0.5) - (XL * 0.5), C.ClipY - YL );
		C.DrawText( MRI.Credits, true );

		C.DrawColor = Class'HUD'.Default.GrayColor;
		C.DrawColor.A = 100;
		class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.ClipY - (YL * 2) - 2, C.ClipX );
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
			YP = (C.ClipY * 0.5);
			if( MRI.CR.ClientSpawnPawn != none )
			{
				C.DrawColor = class'HUDBase'.default.GoldColor;
				C.Style = 1;

				if( MRI.Level.GRI != none && MRI.Level.GRI.GameName == "Capture the Flag" )
				{
					S = "CheckPoint";
				}
				else
				{
					S = "ClientSpawn";
				}
				C.StrLen( S, XL, YL );

				C.SetPos( 0, YP - (YL * 0.5) );
				C.DrawTile( AlphaLayer, XL + 12, YL, 0, 0, 256, 256 );

				C.CurX = 6;
				C.DrawColor = Class'HUD'.default.WhiteColor;
				C.Style = 1;//3;
				C.DrawText( S );

				// Border
				C.Style = 1;
				C.DrawColor = Class'HUD'.default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = 0;

				Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - (YL * 0.5) - 2/*border width*/, XL + 12 );
 				Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - (YL * 0.5) + YL, XL + 12 );

 				C.CurY = YP - (YL * 0.5) - 2;
 				Class'BTClient_SoloFinish'.static.DrawVertical( C, XL + 12, YL + 4 );
 				YP += YL * 1.8;
			}
			
			if( MRI.CR.ProhibitedCappingPawn != none )
			{
				C.DrawColor = class'HUDBase'.default.GoldColor;
				C.Style = 1;

				S = "Boost";
				C.StrLen( S, XL, YL );

				C.SetPos( 0, YP - (YL * 0.5) );
				C.DrawTile( AlphaLayer, XL + 12, YL, 0, 0, 256, 256 );

				C.CurX = 6;
				C.DrawColor = Class'HUD'.default.WhiteColor;
				C.Style = 1;//3;
				C.DrawText( S );

				// Border
				C.Style = 1;
				C.DrawColor = Class'HUD'.default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = 0;

				Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - (YL * 0.5) - 2/*border width*/, XL + 12 );
 				Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - (YL * 0.5) + YL, XL + 12 );

 				C.CurY = YP - (YL * 0.5) - 2;
 				Class'BTClient_SoloFinish'.static.DrawVertical( C, XL + 12, YL + 4 );
 				YP += YL * 1.8;	
			}
			
			if( MRI.CR.SoloTop.Length > 0 )
			{
				C.DrawColor = Options.CTable;
				C.Style = 1;

				S = "Rank:" @ Eval( SpectatedClient.SoloRank == 0, "?", SpectatedClient.SoloRank )  $ "/" $ MRI.SoloRecords;
				C.StrLen( S, XL, YL );

				C.SetPos( 0, YP - (YL * 0.5) );
				C.DrawTile( AlphaLayer, XL + 12, YL, 0, 0, 256, 256 );

				C.CurX = 6;
				C.DrawColor = Class'HUD'.default.WhiteColor;
				C.Style = 1;//3;
				C.DrawText( S );

				// Border
				C.Style = 1;
				C.DrawColor = Class'HUD'.default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = 0;

				Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - (YL * 0.5) - 2/*border width*/, XL + 12 );
 				Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - (YL * 0.5) + YL, XL + 12 );

 				C.CurY = YP - (YL * 0.5) - 2;
 				Class'BTClient_SoloFinish'.static.DrawVertical( C, XL + 12, YL + 4 );
 				YP += YL * 1.2;
 			}

			// Draw Level and percent
 			C.DrawColor = Options.CTable;
			C.Style = 1;

			S = "Level:" @ SpectatedClient.BTLevel;
			C.StrLen( S, XL, YL );

			C.CurY = YP;
			TableXL = XL + 12;
			C.CurX = 0;
			C.DrawTile( AlphaLayer, TableXL, YL, 0, 0, 256, 256 );

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

			C.DrawColor = Class'HUD'.default.GreenColor;
			C.CurX = 0;
			C.DrawTile( AlphaLayer, TableXL * SpectatedClient.BTExperience, YL, 0, 0, 256, 256 );
			SpectatedClient.LastRenderedBTExperience = SpectatedClient.BTExperience;
			SpectatedClient.LastRenderedBTLevel = SpectatedClient.BTLevel;

			C.CurX = (TableXL * 0.5f) - (XL * 0.5f);
			C.DrawColor = Class'HUD'.default.WhiteColor;
			C.Style = 1;//3;
			C.DrawText( S );

			if( SpectatedClient.Level.TimeSeconds - SpectatedClient.BTExperienceChangeTime <= 1.5f && SpectatedClient.BTExperienceDiff != 0f )
			{
				C.CurX = TableXL + 8;
				C.CurY = YP;
				C.Style = 1;
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

			// Border
			C.Style = 1;
			C.DrawColor = Class'HUD'.default.GrayColor;
			C.DrawColor.A = 100;

			C.CurX = 0;
			Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - 2/*border width*/, TableXL );
			Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP + YL, TableXL );

			C.CurY = YP - 2;
			Class'BTClient_SoloFinish'.static.DrawVertical( C, TableXL, YL + 4 );

			YP += YL * 1.8;

			// Draw currency points
			C.DrawColor = Options.CTable;
			C.Style = 1;

			S = "Currency:" @ SpectatedClient.BTPoints;
			C.StrLen( S, XL, YL );

			C.CurY = YP;
			TableXL = XL + 12;
			C.CurX = 0;
			C.DrawTile( AlphaLayer, TableXL, YL, 0, 0, 256, 256 );

			C.CurX = (TableXL * 0.5f) - (XL * 0.5f);
			C.DrawColor = Class'HUD'.default.WhiteColor;
			C.Style = 1;//3;
			C.DrawText( S );

			// Border
			C.Style = 1;
			C.DrawColor = Class'HUD'.default.GrayColor;
			C.DrawColor.A = 100;

			C.CurX = 0;
			Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - 2/*border width*/, TableXL );
			Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP + YL, TableXL );

			C.CurY = YP - 2;
			class'BTClient_SoloFinish'.static.DrawVertical( C, TableXL, YL + 4 );
		}
	}
	else
	{
		goto 'Ff';
		if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
		if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
		if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
		if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
		if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
		if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) && bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
		Ff:

		switch( MRI.RecordState )
		{
			case RS_Succeed:
				//RenderRecordDetails( C );
				C.Font = myHUD.LoadFont( 7 );
				//C.Font = HU.GetFontSizeIndex( C, Options.DrawFontSize );

				// Draw Ghost stuff
				if( int(MRI.GhostPercent) == 100 )
					S = "Ghost Saving Complete";
				else S = "Ghost Saved Percent:"$MRI.GhostPercent$"%";

				C.StrLen( S, XL, YL );
				YLength = YL + 16;

				if( MRI.GhostPercent > 0.00f )
				{
					C.SetPos( 0, (C.ClipY*0.2) );
					C.DrawColor = Options.CTable;
					C.Style = 1;
					C.DrawTile( AlphaLayer, C.ClipX, YL*2, 0, 0, 256, 256 );

					// Border
					C.DrawColor = Class'HUD'.Default.GrayColor;
					C.DrawColor.A = 100;

					C.CurX = 0;
					// Parms: CurY, XLength
					Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, (C.ClipY*0.2)-2 /* Start 2pixels before */, C.ClipX );
	 				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, (C.ClipY*0.2)+(YL*2), C.ClipX );
	 				// ...

	 				C.Style = 3;

					C.SetPos( (C.ClipX*0.5)-(XL*0.5), ((C.Clipy*0.2)+((YL*2)*0.5))-(YL*0.5) );
					C.DrawColor = GetFadingColor( Options.CGoldText );
					C.DrawText( S );
				}

				// Draw Players
				C.StrLen( Class'GUIComponent'.Static.StripColorCodes( MRI.PlayersBestTimes ), XL, YL );
				C.SetPos( (C.ClipX*0.25), (C.ClipY*(YOffsetScale+0.05)) );
				C.DrawColor = Options.CTable;
				C.Style = 1;
				C.DrawTile( AlphaLayer, (C.ClipX*0.5), YLength, 0, 0, 256, 256 );

				// Border
				C.DrawColor = Class'HUD'.Default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = (C.ClipX*0.25);
				C.CurY = (C.ClipY*(YOffsetScale+0.05));
				// Parms: CurY, XLength
				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, (C.ClipX*0.5) );
 				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YLength, (C.ClipX*0.5) );

 				C.CurY -= 2;
				// Parms: CurX, YLength
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YLength+4 );
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+(C.ClipX*0.5), YLength+4 );
 				// ...

 				//C.Style = 3;

				C.SetPos( (C.ClipX*0.5)-(XL*0.5), ((C.Clipy*(YOffsetScale+0.05))+(YLength*0.5))-(YL*0.5) );
				C.DrawColor = myHUD.WhiteColor;
				C.DrawText( MRI.PlayersBestTimes );

				// Draw Info
				C.StrLen( MRI.EndMsg, XL, YL );
				C.SetPos( (C.ClipX*0.25), (C.ClipY*(YOffsetScale+0.10)) );
				C.DrawColor = Options.CTable;
				C.Style = 1;
				C.DrawTile( AlphaLayer, (C.ClipX*0.5), YLength, 0, 0, 256, 256 );

				// Border
				C.DrawColor = Class'HUD'.Default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = (C.ClipX*0.25);
				C.CurY = (C.ClipY*(YOffsetScale+0.10));
				// Parms: CurY, XLength
				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, (C.ClipX*0.5) );
 				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YLength, (C.ClipX*0.5) );

 				C.CurY -= 2;
				// Parms: CurX, YLength
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YLength+4 );
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+(C.ClipX*0.5), YLength+4 );
 				// ...

 				//C.Style = 3;

				C.SetPos( (C.ClipX*0.5)-(XL*0.5), ((C.Clipy*(YOffsetScale+0.10))+(YLength*0.5))-(YL*0.5) );
				C.DrawColor = GetFadingColor( Options.CGoldText );
				C.DrawText( MRI.EndMsg );

				// Draw Points
				C.StrLen( MRI.PointsReward, XL, YL );
				C.SetPos( (C.ClipX*0.25), (C.ClipY*(YOffsetScale+0.15)) );
				C.DrawColor = Options.CTable;
				C.Style = 1;
				C.DrawTile( AlphaLayer, (C.ClipX*0.5), YLength, 0, 0, 256, 256 );

				// Border
				C.DrawColor = Class'HUD'.Default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = (C.ClipX*0.25);
				C.CurY = (C.ClipY*(YOffsetScale+0.15));
				// Parms: CurY, XLength
				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, (C.ClipX*0.5) );
 				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YLength, (C.ClipX*0.5) );

 				C.CurY -= 2;
				// Parms: CurX, YLength
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YLength+4 );
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+(C.ClipX*0.5), YLength+4 );
 				// ...

 				//C.Style = 3;

				C.SetPos( (C.ClipX*0.5)-(XL*0.5), ((C.Clipy*(YOffsetScale+0.15))+(YLength*0.5))-(YL*0.5) );
				C.DrawColor = myHUD.WhiteColor;
				C.DrawText( MRI.PointsReward );
				break;

			case RS_Failure:
				C.Font = myHUD.GetFontSizeIndex( C, Options.DrawFontSize );

				C.StrLen( MRI.EndMsg, XL, YL );
				YLength = YL*3;
				C.SetPos( (C.ClipX*0.25), (C.ClipY*(YOffsetScale+0.15)) );
				C.DrawColor = Options.CTable;
				C.Style = 1;
				C.DrawTile( AlphaLayer, (C.ClipX*0.5), YLength, 0, 0, 256, 256 );

				// Border
				C.DrawColor = Class'HUD'.Default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = (C.ClipX*0.25);
				C.CurY = (C.ClipY*(YOffsetScale+0.15));
				// Parms: CurY, XLength
				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, (C.ClipX*0.5) );
 				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YLength, (C.ClipX*0.5) );

 				C.CurY -= 2;
				// Parms: CurX, YLength
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YLength+4 );
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+(C.ClipX*0.5), YLength+4 );
 				// ...

 				//C.Style = 3;

				C.SetPos( (C.ClipX*0.5)-(XL*0.5), ((C.Clipy*(YOffsetScale+0.15))+(YLength*0.5))-(YL*0.5) );
				C.DrawColor = GetFadingColor( myHUD.RedColor );
				C.DrawText( MRI.EndMsg );
				break;

			case RS_QuickStart:
				C.Font = myHUD.GetFontSizeIndex( C, Options.DrawFontSize );

				C.StrLen( MRI.EndMsg, XL, YL );
				YLength = YL*3;
				C.SetPos( (C.ClipX*0.5)-((XL + (64 * myHUD.ResScaleX))*0.5), (C.ClipY*(YOffsetScale+0.15)) );
				C.DrawColor = Options.CTable;
				C.Style = 1;
				C.DrawTile( AlphaLayer, (XL + (64 * myHUD.ResScaleX)), YLength, 0, 0, 256, 256 );

				// Border
				C.DrawColor = Class'HUD'.Default.GrayColor;
				C.DrawColor.A = 100;

				C.CurX = (C.ClipX*0.5)-((XL + (64 * myHUD.ResScaleX))*0.5);
				C.CurY = (C.ClipY*(YOffsetScale+0.15));
				// Parms: CurY, XLength
				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, (XL + (64 * myHUD.ResScaleX)) );
 				Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YLength, (XL + (64 * myHUD.ResScaleX)) );

 				C.CurY -= 2;
				// Parms: CurX, YLength
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YLength+4 );
 				Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+(XL + (64 * myHUD.ResScaleX)), YLength+4 );
 				// ...

 				//C.Style = 3;

				C.SetPos( (C.ClipX*0.5)-(XL*0.5), ((C.Clipy*(YOffsetScale+0.15))+(YLength*0.5))-(YL*0.5) );
				C.DrawColor = GetFadingColor( myHUD.TurqColor );
				C.DrawText( MRI.EndMsg );
				break;
		}

		if( !PlatformIs64Bit() && MRI.ADMessage != "" )
		{
			// Draw advertise
			C.StrLen( MRI.ADMessage, XL, YL );
			C.SetPos( C.ClipX * 0.5f - XL * 0.5f, C.ClipY * 0.25f );
			C.DrawColor = Options.CTable;
			C.Style = 1;
			C.DrawTile( AlphaLayer, XL, YL, 0, 0, 256, 256 );

			// Border
			C.DrawColor = Class'HUD'.Default.GrayColor;
			C.DrawColor.A = 100;

			C.CurX = C.ClipX * 0.5f - XL * 0.5f;
			C.CurY = C.ClipY * 0.25f;
			// Parms: CurY, XLength
			Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, XL );
			Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YL, XL );

			C.CurY -= 2;
			// Parms: CurX, YLength
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YL+4 );
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX + XL, YL+4 );
			// ...

			//C.Style = 3;

			C.SetPos( C.ClipX * 0.5f - XL * 0.5f, C.Clipy * 0.25f );
			C.DrawColor = myHUD.GreenColor;
			C.DrawText( MRI.ADMessage );
		}
	}
}

function DrawRecordWidget( Canvas C )
{
	local string S, timeLeftF, bestTimeF;
	local float XL1, XL2, XL3, XL4;
	local float YL, YL2, YL3, YL4;
	local float YP;

	C.Font = GetScreenFont( C );
	if( MRI.PlayersBestTimes == "" )
		S = RecordEmptyMsg;

	YP = 7;
	if( myHUD.bShowPersonalInfo && ASGameReplicationInfo(ViewportOwner.Actor.Level.GRI) == none )
	{
		YP += 50 * myHUD.HUDScale;
	}

	if( S != RecordEmptyMsg )
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
			S = RecordTimeMsg$":"@FormatTime( MRI.MapBestTime );
			if( MRI.PreviousBestTime > 0 )
				S $= "/"$FormatTime( MRI.PreviousBestTime );

			C.StrLen( S, XL1, YL3 );
			C.SetPos( C.ClipX-8-XL1, YP );

			C.Style = 1;
			C.DrawColor = Options.CTable;
			C.DrawTile( AlphaLayer, XL1+8, YL3, 0, 0, 256, 256 );

			// Border
			C.DrawColor = Class'HUD'.Default.GrayColor;
			C.DrawColor.A = 100;

			C.CurX = C.ClipX-8-XL1;
			// Parms: CurY, XLength
			class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP-2 /* Start 2pixels before */, XL1+8 );
			class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP+YL3, XL1+8 );

			C.CurY -= 2;
			// Parms: CurX, YLength
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX-10-XL1, YL3+4 );
			class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX, YL3+4 );
			// ...

			C.Style = 3;

			C.DrawColor = class'HUD'.default.WhiteColor;

			C.SetPos( C.ClipX-4-XL1, YP );
			C.DrawTextClipped( RecordTimeMsg$":" );

			C.DrawColor = Options.CGoldText;
			S = FormatTime( MRI.MapBestTime );
			if( MRI.PreviousBestTime > 0 )
				S $= "/"$FormatTime( MRI.PreviousBestTime );
			C.StrLen( S, XL1, YL3 );
			C.SetPos( C.ClipX-4-XL1, YP );
			C.DrawText( S );

			YP += YL3 + 6;
		}

		// Record Author
		// Title
		S = RecordHolderMsg$":"@MRI.PlayersBestTimes;
		C.StrLen( Class'GUIComponent'.Static.StripColorCodes( S ), XL1, YL );

		C.Style = 1;
		C.DrawColor = Options.CTable;
		C.SetPos( C.ClipX-8-XL1, YP );
		C.DrawTile( AlphaLayer, XL1+8, YL, 0, 0, 256, 256 );

		// Border
		C.DrawColor = Class'HUD'.Default.GrayColor;
		C.DrawColor.A = 100;

		C.CurX = C.ClipX-8-XL1;
		// Parms: CurY, XLength
		class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP-2 /* Start 2pixels before */, XL1+8 );
		class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP+YL, XL1+8 );

		C.CurY -= 2;
		// Parms: CurX, YLength
		Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX-10-XL1, YL+4 );
		Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX, YL+4 );
		// ...

		C.Style = 3;

		C.DrawColor = class'HUD'.default.WhiteColor;
		C.SetPos( C.ClipX-5-XL1, YP );
		C.DrawText( RecordHolderMsg$":" );

		C.Style = 1;

		// Name
		C.DrawColor = class'HUD'.default.WhiteColor;
		S = Class'GUIComponent'.Static.StripColorCodes( MRI.PlayersBestTimes );
		C.StrLen( S, XL1, YL );
		C.SetPos( C.ClipX-XL1-4, YP );
		C.CurX = Min( C.CurX+XL1-4, C.ClipX-XL1-4 );
		//C.Style = 1;
		C.DrawTextClipped( MRI.PlayersBestTimes );

		YP += YL + 6;

		// ...

		// Record Timer
		// DRAWS: Time Left: TIMELEFT/BESTTIME
		timeLeftF = FormatTime( DrawnTimer );
		bestTimeF = FormatTime( MRI.MapBestTime );

		S = RecordTimeLeftMsg $ ":" @ timeLeftF;
		if( MRI.bSoloMap )
		{
			S $= " / " $ bestTimeF;
		}
		C.StrLen( S, XL1, YL2 );
		C.SetPos( C.ClipX-8-XL1, YP );

		//C.Style = 1;
		C.DrawColor = Options.CTable;
		C.DrawTile( AlphaLayer, XL1+8, YL2, 0, 0, 256, 256 );
		DrawBorder( C, C.ClipX-8-XL1, YP, C.ClipX, YP + YL2 );
		C.Style = 3;

		C.SetPos( C.ClipX-4-XL1, YP );
		C.DrawColor = class'HUD'.default.WhiteColor;
		C.DrawText( RecordTimeLeftMsg $ ":" );

		C.StrLen( timeLeftF, XL2, YL2 );
		if( MRI.bSoloMap )
		{
			C.StrLen( " / ", XL4, YL2 );
			C.StrLen( bestTimeF, XL3, YL2 );
		}
		C.SetPos( C.ClipX-4-(XL2+XL3+XL4), YP );
		if( bSoundTicking )
			C.DrawColor = Orange;
		else
		{
			if( DrawnTimer <= 0.0f )
				C.DrawColor = GetFadingColor( class'HUD'.default.RedColor );
			else C.DrawColor = GetFadingColor( class'HUD'.default.GreenColor );
		}
		C.DrawText( timeLeftF );

		if( MRI.bSoloMap )
		{
			C.SetPos( C.ClipX-4-(XL3+XL4), YP );
			C.DrawColor = class'HUD'.default.WhiteColor;
			C.DrawText( " / " );

			C.SetPos( C.ClipX-4-(XL3), YP );
			C.DrawColor = class'HUD'.default.GoldColor;
			C.DrawText( bestTimeF );
		}

		C.Style = 1;
	}
	else	// No Record avaible.
	{
		C.StrLen( RecordEmptyMsg, XL1, YL );

		C.SetPos( C.ClipX-8-XL1, YP );
		C.Style = 1;
		C.DrawColor = Options.CTable;
		C.DrawTile( AlphaLayer, XL1+12, YL, 0, 0, 256, 256 );

		// Border
		C.DrawColor = Class'HUD'.Default.GrayColor;
		C.DrawColor.A = 100;

		C.CurX = C.ClipX-8-XL1;
		// Parms: CurY, XLength
		class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP-2 /* Start 2pixels before */, XL1+12 );
		class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YL + YP, XL1+12 );

		C.CurY -= 2;
		// Parms: CurX, YLength
		Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX-10-XL1, YL+4 );
		Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX, YL+4 );
		// ...

		C.Style = 3;

		C.DrawColor = myHUD.WhiteColor;
		C.SetPos( C.ClipX-4-XL1, YP );
		C.DrawText( RecordEmptyMsg );

		YP += YL + 6;

		if( MRI.bSoloMap )
		{
			DrawnTimer = (MRI.Level.TimeSeconds-SpectatedClient.LastSpawnTime);
			S = FormatTime( DrawnTimer );
			C.StrLen( RecordTimeElapsed$":"@S, XL1, YL2 );

			C.SetPos( C.ClipX-8-XL1, YP );

			C.Style = 1;
			C.DrawColor = Options.CTable;
			C.DrawTile( AlphaLayer, XL1+12, YL2, 0, 0, 256, 256 );

			// Border
			C.DrawColor = Class'HUD'.Default.GrayColor;
			C.DrawColor.A = 100;

			C.CurX = C.ClipX-8-XL1;
			// Parms: CurY, XLength
			class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP-2 /* Start 2pixels before */, XL1+12 );
			class'BTClient_SoloFinish'.Static.DrawHorizontal( C, YP + YL2, XL1+12 );

			C.CurY -= 2;
			// Parms: CurX, YLength
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX-10-XL1, YL2+4 );
			Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.ClipX, YL2+4 );
			// ...

			C.Style = 3;

			C.SetPos( C.ClipX-4-XL1, YP );
			C.DrawColor = class'HUD'.default.WhiteColor;
			C.DrawText( RecordTimeElapsed$":" );

			C.StrLen( S, XL1, YL2 );
			C.SetPos( C.ClipX-4-XL1, YP );
			C.DrawColor = GetFadingColor( class'HUD'.default.GreenColor );
			C.DrawText( S );
		}
	}
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

	RecordTimeMsg="Record Time"
	RecordPrevTimeMsg="Previous Time"
	RecordHolderMsg="Record Holder(s)"
	RecordTimeLeftMsg="Record Timer"
	RecordEmptyMsg="No Record Available"
	RecordTimeElapsed="Elapsed Time"
	RankingKeyMsg="Press %KEY% or Escape to"
	RankingToggleMsg="view next page"
	RankingHideMsg="hide this"

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

	PlayersRankingColumns(0)=(Title="#",Format="000")
	PlayersRankingColumns(1)=(Title="Score",Format="00000")
	PlayersRankingColumns(2)=(Title="Player",Format="WWWWWWWWWWWW")
	PlayersRankingColumns(3)=(Title="Records",Format="0000")
	PlayersRankingColumns(4)=(Title="Hijacks",Format="0000")
	PlayersRankingColumns(5)=(Title="Objectives",Format="00000")

	RecordsRankingColumns(0)=(Title="#",Format="000")
	RecordsRankingColumns(1)=(Title="Score",Format="0000")
	RecordsRankingColumns(2)=(Title="Player",Format="WWWWWWWWWWWW")
	RecordsRankingColumns(3)=(Title="Time",Format="00:00:00.00")
	RecordsRankingColumns(4)=(Title="Date",Format="0000/00/00")
}
