class BTClient_LevelReplication extends ReplicationInfo;

var BTClient_LevelReplication NextLevel;

var private PlayerStart MyPlayerStart;
var private BTLevelTeleporter MyTeleporter;
var private GameObjective MyObjective;

/** The level's id without (map- or level-). */
var private string LevelName;
var private bool _IsSupremeLevel, _BoundByMap, _BoundByLevel;

/** (Server) The level id(inc map- or level-) of the level that this level locks and unlocks. */
var string LevelId, LockedLevelName;
var BTClient_LevelReplication LockedLevel; // set by level with levelid as LockedLevelName

/** (Server) Whether this level is access restricted. */
var bool bRestrictAccess;

// Record state
var string TopRanks;
var float TopTime;
var int NumRecords;
var int PrimaryGhostNumMoves;

// Serverside only
var int MapIndex; // Index to RecordsData.Rec array.

replication
{
	reliable if( bNetInitial )
		NextLevel, MyObjective;

	reliable if( bNetDirty )
		TopRanks, TopTime, NumRecords,
		PrimaryGhostNumMoves;
}

event PostBeginPlay()
{
	MyObjective = GameObjective(Owner);
}

simulated event PostNetBeginPlay()
{
	local name levelTag;

	if( MyObjective == none )
	{
		return;
	}

	// To hide it from the x* count
	MyObjective.bOptionalObjective = true;
	HideObjective();

	levelTag = MyObjective.Tag;
	LevelId = string(levelTag);
	if( Left( LevelId, 4 ) ~= "map-" )
	{
		LevelName = Mid( LevelId, 4 );
		_BoundByMap = true;
	}
	else if( Left( LevelId, 6 ) ~= "level-" )
	{
		LevelName = Mid( LevelId, 6 );
		_BoundByLevel = true;
	}

	if( LevelName == "" )
	{
		if( _BoundByMap || _BoundByLevel )
		{
			Warn( "Detected a level objective with an invalid tag" @ LevelId );
		}
		_BoundByMap = false;
		_BoundByLevel = false;
		return;
	}
	_IsSupremeLevel = true;
	LockedLevelName = ParseMapId( MyObjective.Event );
}

private static function string ParseMapId( coerce string s )
{
	if( Left( s, 4 ) ~= "map-" )
	{
		return Mid( s, 4 );
	}
	else if( Left( s, 6 ) ~= "level-" )
	{
		return Mid( s, 6 );
	}
	return "";
}

function InitializeLevel( BTClient_MutatorReplicationInfo MRI )
{
	local NavigationPoint np;
	local BTClient_LevelReplication myLevel;

	if( !IsSupremeLevel() )
		return;

    for( myLevel = MRI.BaseLevel; myLevel != none; myLevel = myLevel.NextLevel )
	{
		if( myLevel == self )
			continue;

		if( myLevel.LockedLevelName ~= LevelName )
		{
			myLevel.LockedLevel = self;
			bRestrictAccess = true;
			break;
		}
	}

	for( np = Level.NavigationPointList; np != none; np = np.NextNavigationPoint )
	{
		if( PlayerStart(np) != none && np.Tag == MyObjective.Tag )
		{
			MyPlayerStart = PlayerStart(np);
			break;
		}
	}
	if( MyPlayerStart == none )
	{
		Warn( "Found no playerspawn for objective with tag" @ MyObjective.Tag );
		return;
	}
	MyTeleporter = Spawn( class'BTLevelTeleporter', self, MyPlayerStart.Tag, MyPlayerStart.Location, MyPlayerStart.Rotation );
}

// Server only
final function bool IsValidPlayerStart( Controller player, PlayerStart start )
{
	return start == MyPlayerStart;
	// Inc "Map-"
	// return LevelName ~= string(start.Tag);
}

final function ResetObjective()
{
    MyObjective.Reset();
    MyObjective.DefenderTeamIndex = 1;
}

final simulated function ShowObjective()
{
	MyObjective.bUsePriorityOnHUD = true;
}

final simulated function HideObjective()
{
	MyObjective.bUsePriorityOnHUD = false;
}

final simulated function GameObjective GetObjective()
{
	return MyObjective;
}

final function vector GetSpawnLocation()
{
	return MyPlayerStart.Location;
}

final function rotator GetSpawnRotation()
{
	return MyPlayerStart.Rotation;
}

final static function string GetMapTag( string mapName )
{
	if( Left( Mid( mapName, 3/**AS-*/ ), 5 ) ~= "solo-" )
		return "AS-Solo";

	if( Left( mapName, 4 ) ~= "str-" )
		return "STR";

    return "AS";
}

// Client and Server
final simulated function bool IsSupremeLevel()
{
	return _IsSupremeLevel;
}

// Client and Server
final simulated function string GetLevelName()
{
	if( LevelName != "" )
	{
		return LevelName;
	}

	if( Level.Title == "untitled" || Level.Title == "" )
		return MyObjective.Objective_Info_Attacker;
	return Level.Title;
}

// Client and Server
final simulated function string GetFullName( string mapName )
{
	if( LevelName != "" )
	{
		if( _BoundByMap )
		{
			return GetMapTag( mapName )$"-"$LevelName;
		}

		if( _BoundByLevel )
		{
			return mapName$"-"$LevelName;
		}

		Warn( "GetFullname with LevelName != \"\" did not return the correct data!" );
	}
	return mapName;
}

// Client and Server
final simulated function bool Represents( GameObjective obj )
{
	return MyObjective == obj;
}

defaultproperties
{
	NetUpdateFrequency=1
	bReplicateMovement=false
}