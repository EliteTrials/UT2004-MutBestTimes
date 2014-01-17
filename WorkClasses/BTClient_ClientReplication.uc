//==============================================================================
// BTClient_ClientReplication.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
			Receive all personal data from MutBestTimes
*/
//	Coded by Eliot
//	Updated @ 10/11/2009.
//	Updated @ 19/07/2011.
//==============================================================================
class BTClient_ClientReplication extends LinkedReplicationInfo;

//==============================================================================
// Structs

// Player Rankings
struct sGlobalPacket
{
	var string name;
	var float Points;
	var int Objectives;
	var int Hijacks;
};

struct sDailyPacket
{
	var string name;
	var float Points;
	var int Records;
};

struct sQuarterlyPacket
{
	var string name;
	var float Points;
	var int Records;
};

// Top Solo Rankings
struct sSoloPacket
{
	var string name;
	var float Points;
	var float Time;
	var string Date;
};

/** A structure that defines an earnable achievement. */
struct sAchievementState
{
	/** Title of the achievement e.g. "Recwhore" */
	var string Title;

	/** Description explaining what to do to earn this achievement. */
	var string Description;

	/** Icon portraying this achievement. */
	var string Icon;

	/** Progress of <type> this player has reached so far! */
  	var int Progress;

  	/** Amount of <type> necessary to earn this achievement. */
	var int Count;

	var int Points;

	var bool bEarned;
};

/** A structure that defines an completable challenge. */
struct sChallengeClient
{
	/** Title of the challenge e.g. "STR-SoloMap" */
	var string Title;

	/** Description explaining what to do to complete this challenge. */
	var string Description;

	var int Points;
};

/** A structure that defines a trophy. */
struct sTrophyClient
{
	/** Title of the trophy e.g. "STR-SoloMap Champion" */
	var string Title;
};

struct sItemClient
{
	var string Name;
 	var string ID;
 	var int Cost;
 	var bool bBought;
 	var bool bEnabled;
 	var byte Access;
 	var string Desc;
 	var Material IconTexture;

	var transient bool bSync;
	var transient bool bHasMeta;
};

struct sCategoryClient
{
	var string Name;
	var array<sItemClient> CachedItems;
};

var(DEBUG) array<sCategoryClient> Categories;
var(DEBUG) bool bReceivedCategories;	// SERVER and LOCAL

struct sPerkState
{
	var string Name;
	var float Points;
	var string Description;
	var Texture Icon;
	var bool bActive;
};

//==============================================================================

//==============================================================================
// REPLICATED VARIABLES
var bool bAllowDodgePerk;

var(DEBUG) array<sGlobalPacket> OverallTop;
var(DEBUG) array<sDailyPacket> DailyTop;
var(DEBUG) array<sQuarterlyPacket> QuarterlyTop;
var(DEBUG) array<sSoloPacket> SoloTop;

// Personal OverallTop for people not in the best of the top solo rankings list e.g. 25
var(DEBUG) sSoloPacket MySoloTop;			// Solo
var(DEBUG) sGlobalPacket MyOverallTop;		// Global

/** The states of all achievements that this player is working on. */
var(DEBUG) array<sAchievementState> AchievementsStates;
var sAchievementState LastAchievementEvent;

/** The currently available challenges that this player may work on. */
var(DEBUG) array<sChallengeClient> Challenges;

/** The Trophies that this player has earned via Challenges. */
var(DEBUG) array<sTrophyClient> Trophies;
var sTrophyClient LastTrophyEvent;

/** The availabe items for sale and bought. */
var(DEBUG) array<sItemClient> Items;

/** Available perks. */
var(DEBUG) array<sPerkState> Perks;


// --NOT REPLICATED
var(DEBUG) transient bool bItemsTransferComplete;

// TextBox used by console commands
// Cleared when F12 is pressed
var(DEBUG) array<string> Text;

// Some addional message for the rankings table e.g. You are..., Rewarded commands
var(DEBUG) string UserState[2];

// The rank position of this user, and the solo rank of this user
var int Rank, SoloRank;
var(DEBUG) string Title;

// Pawn of this user
var Pawn myPawn;
var Pawn LastPawn;
var private Pawn DeadPawn;

// #ifdef bSoloMap
// Solo Timer
	var float LastSpawnTime;		// Not replicated but simulated on both.
	var float PersonalTime;			// Best time for this player
	var transient string SFMSG;				// Solo Finish Messsage (the message displayed when a rec is made)
// #endif

var int BTLevel;
// Not to be confused with actual Ranking Points!
var int BTPoints;

var Color PreferedColor;

/** Percentage progress of the next level. */
var float BTExperience;
var float LastObjectiveCompletedTime;
// LOCAL ONLY
var float LastRenderedBTExperience;
var float LastRenderedBTLevel;
var float BTExperienceChangeTime;
var float BTExperienceDiff;
//----

var float ClientMatchStartTime;

const CFRESETGHOST 		= 0x00000001;
const CFCLIENTSPAWN 	= 0x00000002;
const CFCHECKPOINT		= 0x00000004;

var private int ClientFlags;

var Pawn ProhibitedCappingPawn;
var Pawn ClientSpawnPawn;

//==============================================================================

//==============================================================================
// CLIENTSIDE VARIABLES
var BTClient_Config Options;
var BTClient_MutatorReplicationInfo MRI;

//==============================================================================
// SERVERSIDE VARIABLES
var int myPlayerSlot;				// Cached slot of the PDat.Player list for this player
var bool bReceivedRankings;
var bool bAutoPress;
var bool bPermitBoosting;

var /**TEMP*/ string ClientMessage;

replication
{
	reliable if( bNetDirty )
		myPawn, PersonalTime,
		Rank, ClientFlags, SoloRank,
		BTLevel, BTExperience, BTPoints,
		PreferedColor;
		
	reliable if( bNetOwner )
		bAllowDodgePerk, ProhibitedCappingPawn, ClientSpawnPawn;

	unreliable if( bNetInitial && bNetOwner )
		UserState;

	reliable if( bNetInitial )
		Title;

	reliable if( Role == ROLE_Authority )
		// Rankings scoreboard
		ClientSendOverallTop, ClientUpdateOverallTop, ClientCleanOverallTop,
		ClientSendDailyTop, ClientUpdateDailyTop, ClientCleanDailyTop,
		ClientSendQuarterlyTop, ClientUpdateQuarterlyTop, ClientCleanQuarterlyTop,

		// Solo scoreboard
		ClientSendSoloTop, ClientUpdateSoloTop, ClientCleanSoloTop,

		// Personal stuff
		ClientSendPersonalOverallTop, ClientSendMyOverallTop,

		// Reset Timer
		ClientSpawn,
		ClientMatchStarting,

		// Stats
		ClientSendAchievementState, ClientAchievementAccomplished, ClientAchievementProgressed, ClientCleanAchievements,
		ClientSendChallenge,
		ClientSendPerk,
		ClientSendTrophy, ClientTrophyEarned, ClientCleanTrophies,
		ClientSendItem, ClientSendCategory,
		ClientSendItemsCompleted, ClientSendItemMeta, ClientSendItemData;

	// unreliable
	reliable if( Role == ROLE_Authority )
		ClientSendText, ClientCleanText, ClientSendMessage, ClientSendConsoleMessage;

	unreliable if( Role < ROLE_Authority )
		ServerSetClientFlags;

	reliable if( Role < ROLE_Authority )
		ServerSetPreferedColor;
}

simulated function InitializeClient( optional BTClient_Interaction myInter )
{
	Options = Class'BTClient_Config'.Static.FindSavedData();
	if( Options == None )
	{
		Log( "BTClient_Config not found!", Name );
	}

	SetOwner( Level.GetLocalPlayerController() );

	ReplicateResetGhost();
	ServerSetPreferedColor( Options.PreferedColor );
}

final function bool IsClient()
{
	return Level.NetMode == NM_Client || Level.NetMode == NM_Standalone;
}

// Client-side detection whether the pawn of this CRI owner died!
Simulated Function PostNetReceive()
{
	super.PostNetReceive();
	// Using Options to know whether were executing this on my own CRI
	if( Level.NetMode == NM_Client )
	{
		if( Options == None && (Owner == None || Viewport(PlayerController(Owner).Player) == None) )
		{
			// Pawn changed?
			if( myPawn != None && myPawn != DeadPawn )
			{
			    if( Class'BTClient_Config'.static.FindSavedData().bProfesionalMode )
			    {
					myPawn.SoundVolume = 0;
					myPawn.TransientSoundVolume = 0;
					myPawn.SoundRadius = 0;
					myPawn.TransientSoundRadius = 0;
			    	myPawn.bHidden = true;
			    }

				if( !HasClientFlags( CFCLIENTSPAWN | CFCHECKPOINT ) )
				{
					ClientSpawn();
				}
				DeadPawn = myPawn;
			}
  		}
  		else if( Options != none )
  		{
  			if( Options.bAutoBehindView )
  			{
				Level.GetLocalPlayerController().BehindView( true );
			}
  		}
	}
}

Simulated Function ReplicateResetGhost()
{
	ServerSetClientFlags( CFRESETGHOST, class'BTClient_Config'.static.FindSavedData().bResetGhostOnDead );
}

// Can be called by client. It is private to avoid abuse.
private function ServerSetClientFlags( int newFlags, bool bAdd )
{
	SetClientFlags( newFlags, bAdd );
}

function ServerSetPreferedColor( Color newPreferedColor )
{
	PreferedColor = newPreferedColor;
}

// Server Only
simulated function bool HasClientFlags( int flags )
{
	return (ClientFlags & flags) != 0;
}

// Server Only
function SetClientFlags( int newFlags, bool bAdd )
{
	if( bAdd )
	{
		ClientFlags = ClientFlags | newFlags;
	}
	else
	{
		ClientFlags = ClientFlags & ~newFlags;
	}
}


simulated function ClientSendMessage( class<BTClient_LocalMessage> messageClass, string message, 
	optional byte switch, 
	optional PlayerReplicationInfo PRI2
	)
{
	// HACK: Respect the options specifically for record messages.
	if( messageClass == class'BTClient_SoloFinish' && Options.bDisplayCompletingMessages )
	{
		if( (switch == 0 || switch == 2) && Options.bDisplayFail )
		{
			if( Options.bPlayCompletingSounds && PlayerController(Owner).ViewTarget != none )
				PlayerController(Owner).ViewTarget.PlayOwnedSound( Options.FailSound, SLOT_Interface, 255, true );
		}
		else if( switch == 1 && Options.bDisplayNew )
		{
			if( Options.bPlayCompletingSounds && PlayerController(Owner).ViewTarget != none )
				PlayerController(Owner).ViewTarget.PlayOwnedSound( Options.NewSound, SLOT_Interface, 255, true );
		}
		else
		{
			// When both are disabled, still print a message in the console
			ClientSendConsoleMessage( message );
			return;
		}
	}

	// Temporary copy for the LocalMessage class to copy.
	ClientMessage = message;
	PlayerController(Owner).ReceiveLocalizedMessage( messageClass, 
		int(switch), 
		PlayerController(Owner).PlayerReplicationInfo, PRI2, 
		self 
	);
}

// Call this on server instead of clientspawn!
Function PlayerSpawned()
{
	LastSpawnTime = Level.TimeSeconds;
	ClientSpawn();
}

Function ClientSetPersonalTime( float CPT )
{
	PersonalTime = CPT;
}

// Client spawned, reset timer...
Simulated Function ClientSpawn()
{
	if( Role == ROLE_Authority )
		return;

	LastSpawnTime = Level.TimeSeconds;
}

Simulated Function ClientSendConsoleMessage( coerce string Msg )
{
	PlayerController(Owner).Player.Console.Message( Msg, 1.0 );
}

//==============================================================================
// OVERALL TOP FUNCTIONS
Simulated Function ClientCleanOverallTop()
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	OverallTop.Length = 0;
}

Simulated function ClientSendOverallTop( sGlobalPacket APacket )
{
	local int j;

	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	j = OverallTop.Length;
	OverallTop.Length = j+1;
	OverallTop[j] = APacket;
}

Simulated function ClientUpdateOverallTop( sGlobalPacket APacket, byte Slot )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	if( Slot > OverallTop.Length-1 )
		return;

	OverallTop[Slot] = APacket;
}
//==============================================================================

Simulated Function ClientCleanQuarterlyTop()
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	QuarterlyTop.Length = 0;
}

Simulated function ClientSendQuarterlyTop( sQuarterlyPacket APacket )
{
	local int j;

	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	j = QuarterlyTop.Length;
	QuarterlyTop.Length = j+1;
	QuarterlyTop[j] = APacket;
}

Simulated function ClientUpdateQuarterlyTop( sQuarterlyPacket APacket, byte Slot )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	if( Slot > QuarterlyTop.Length-1 )
		return;

	QuarterlyTop[Slot] = APacket;
}

Simulated Function ClientCleanDailyTop()
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	DailyTop.Length = 0;
}

Simulated function ClientSendDailyTop( sDailyPacket APacket )
{
	local int j;

	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	j = DailyTop.Length;
	DailyTop.Length = j+1;
	DailyTop[j] = APacket;
}

Simulated function ClientUpdateDailyTop( sDailyPacket APacket, byte Slot )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	if( Slot > DailyTop.Length-1 )
		return;

	DailyTop[Slot] = APacket;
}

Simulated Function ClientCleanSoloTop()
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	SoloTop.Length = 0;
}

Simulated function ClientSendSoloTop( sSoloPacket APacket )
{
	local int j;

	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	j = SoloTop.Length;
	SoloTop.Length = j+1;
	SoloTop[j] = APacket;
}

Simulated Function ClientUpdateSoloTop( sSoloPacket APacket, byte Slot )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	if( Slot > SoloTop.Length-1 )
		return;

	SoloTop[Slot] = APacket;
}

Simulated function ClientSendPersonalOverallTop( sSoloPacket APacket )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	MySoloTop = APacket;
}

Simulated function ClientSendMyOverallTop( sGlobalPacket APacket )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	MyOverallTop = APacket;
}

Simulated Function ClientSendText( string Packet )
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	Text[Text.Length] = Packet;
}

Simulated Function ClientCleanText()
{
	if( Role == ROLE_Authority && Level.NetMode != NM_StandAlone )
		return;

	Text.Length = 0;
}

simulated function ClientMatchStarting( float serverTime )
{
	ClientMatchStartTime = serverTime - Level.TimeSeconds;
}

simulated final function ClientSendAchievementState( string title, string description, string icon, int progress, int count, int points )
{
	AchievementsStates.Insert( 0, 1 );
	AchievementsStates[0].Title = title;
	AchievementsStates[0].Description = description;
	AchievementsStates[0].Icon = icon;
	AchievementsStates[0].Progress = progress;
	AchievementsStates[0].Count = count;
	AchievementsStates[0].Points = points;
	AchievementsStates[0].bEarned = progress == -1 || (count > 0 && progress >= count);
}

simulated final function ClientSendChallenge( string title, string description, int points )
{
	Challenges.Insert( 0, 1 );
	Challenges[0].Title = title;
	Challenges[0].Description = description;
	Challenges[0].Points = points;
}

simulated final function ClientSendPerk( string name, string description, int points, Texture icon, bool bActive )
{
	Perks.Insert( 0, 1 );
	Perks[0].Name = name;
	Perks[0].Description = description;
	Perks[0].Points = points;
	Perks[0].Icon = icon;
	Perks[0].bActive = bActive;
}

simulated final function ClientSendTrophy( string title )
{
	Trophies.Insert( 0, 1 );
	Trophies[0].Title = title;
}

simulated final function ClientTrophyEarned( string title )
{
	LastTrophyEvent.Title = title;

	PlayerController(Owner).ReceiveLocalizedMessage( Class'BTUI_TrophyState', 0,,, self );
	if( PlayerController(Owner).ViewTarget != none )
		PlayerController(Owner).ViewTarget.PlayOwnedSound( Options.TrophySound, SLOT_Interface, 255, True );
}

simulated final function ClientCleanTrophies()
{
	Trophies.Length = 0;
}

simulated final function ClientAchievementProgressed( string title, string icon, int progress, int count )
{
	// Worth noting?
	if( progress % Max( Round( count * 0.10 ), 1 ) == 0 )
	{
		LastAchievementEvent.Title = title;
		LastAchievementEvent.Icon = icon;
		LastAchievementEvent.Progress = progress;
		LastAchievementEvent.Count = count;

	    PlayerController(Owner).ReceiveLocalizedMessage( class'BTUI_AchievementState', 0,,, self );

	    if( PlayerController(Owner).ViewTarget != none )
			PlayerController(Owner).ViewTarget.PlayOwnedSound( Options.AchievementSound, SLOT_Interface, 255, true );
	}

	ClientSendConsoleMessage( "You have made progress on the achievement" @ title );
}

simulated final function ClientAchievementAccomplished( string title, optional string icon )
{
	LastAchievementEvent.Title = title;
	LastAchievementEvent.Icon = icon;

	PlayerController(Owner).ReceiveLocalizedMessage( class'BTUI_AchievementState', 0,,, self );

	if( PlayerController(Owner).ViewTarget != none )
		PlayerController(Owner).ViewTarget.PlayOwnedSound( Options.AchievementSound, SLOT_Interface, 255, true );

	ClientSendConsoleMessage( "You accomplished the achievement" @ title );
}

simulated final function ClientCleanAchievements()
{
	AchievementsStates.Length = 0;
}

/** Merges all three variables into one chunk. */
final static function int CompressStoreData( int cost, bool bBought, bool bEnabled, byte access )
{
	local int data;

 	data = cost & 0x0000FFFF;
 	if( bBought )
 	{
 		data = data | 0x10000;
 	}

 	if( bEnabled )
 	{
 		data = data | 0x20000;
 	}
 	
 	data = data | (access << 24);
 	return data;
}

final static function DecompressStoreData( int data, out int price, out byte bBought, out byte bEnabled, out byte access )
{
	local int acc;
	
	// Separately handled due implicit compiler casting to byte.
	acc = data & 0x0F000000;
	access = acc >> 24;
	
 	price = data & 0x0000FFFF;
 	//bBought = ((data & 0x10000) >> 16);
 	//bEnabled = ((data & 0x20000) >> 16);
 	bBought = byte((((data & 0xFFFF0000) >> 16) & 0x00000001) != 0);
 	bEnabled = byte((((data & 0xFFFF0000) >> 16) & 0x00000002) != 0);
}

//int cost, bool bBought, bool bEnabled
simulated final function ClientSendItem( string itemName, string id, int data )
{
	local byte bBought, bEnabled, access;
 	local int cost;

	Items.Insert( 0, 1 );
	DecompressStoreData( data, cost, bBought, bEnabled, access );

	Items[0].Name = itemName;
	Items[0].ID = id;
	Items[0].Cost = cost;
	Items[0].bBought = bBought > 0;
	Items[0].bEnabled = bEnabled > 0;
	Items[0].Access = access;
}

simulated final function ClientSendItemMeta( string id, string desc, Material image )
{
	local int i;
	
	for( i = 0; i< Items.Length; ++ i )
	{
		if( Items[i].id == id )
		{
			Items[i].IconTexture = image;
			Items[i].Desc = desc;
			Items[i].bSync = true;
			Items[i].bHasMeta = true;
			break;
		}
	}	
}

simulated final function ClientSendItemData( string id, int data )
{
	local int i;
	local byte bBought, bEnabled, access;
	
	for( i = 0; i< Items.Length; ++ i )
	{
		if( Items[i].id == id )
		{
			DecompressStoreData( data, Items[i].Cost, bBought, bEnabled, access );
			Items[i].bBought = bool(bBought);
			Items[i].bEnabled = bool(bEnabled);
			break;
		}
	}		
}

simulated final function ClientSendCategory( string categoryName )
{
	Categories.Insert( 0, 1 );
	Categories[0].Name = categoryName;
}

simulated final function ClientSendItemsCompleted()
{
	bItemsTransferComplete = true;
}

event Tick( float deltaTime )
{
	local UseObjective objective;
	
	if( PlayerController(Owner) == none )
	{
		Destroy();
		return;
	}
	
	if( PlayerController(Owner).Pawn != none && bAutoPress )
	{
		foreach PlayerController(Owner).Pawn.TouchingActors( class'UseObjective', objective )
		{
			if( objective.bDisabled )
				continue;
				
			PlayerController(Owner).ServerUse();
		}		
	}
}

DefaultProperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	//bSkipActorPropertyReplication=false
	bNetNotify=true

	myPlayerSlot=-1

	NetUpdateFrequency=0.5
	// NetPriority=0.5
}
