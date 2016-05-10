class BTClient_LevelReplication extends ReplicationInfo;

var BTClient_LevelReplication NextLevel;
var private PlayerStart MyPlayerStart;
var private BTLevelTeleporter MyTeleporter;
var private GameObjective MyObjective;
var private string LevelName;
var private bool _IsSupremeLevel, _BoundByMap, _BoundByLevel;

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
		NextLevel, MyObjective, LevelName;

	reliable if( bNetDirty )
		TopRanks, TopTime, NumRecords,
		PrimaryGhostNumMoves;
}

simulated event PostNetBeginPlay()
{
	super.PostNetBeginPlay();

	if( Level.NetMode == NM_Standalone )
	{
		MyObjective = GameObjective(Owner);
	}

	if( Level.NetMode != NM_DedicatedServer && MyObjective != none )
	{
		MyObjective.SetActive( false );
		// MyObjective.bDisabled = true;
	}
}

function InitializeLevel( GameObjective obj )
{
	local NavigationPoint np;
	local name levelTag;
	local string fullTag;

	if( obj == none )
		return;

	MyObjective = obj;
	levelTag = obj.Tag;
	fullTag = string(levelTag);
	if( Left( fullTag, 4 ) ~= "map-" )
	{
		LevelName = Mid( fullTag, 4 );
		_BoundByMap = true;
	}
	else if( Left( fullTag, 6 ) ~= "level-" )
	{
		LevelName = Mid( fullTag, 6 );
		_BoundByLevel = true;
	}

	if( LevelName == "" )
	{
		if( _BoundByMap || _BoundByLevel )
		{
			Warn( "Detected a level objective with an invalid tag" @ fullTag );
		}
		_BoundByMap = false;
		_BoundByLevel = false;
		return;
	}

	_IsSupremeLevel = true;
	for( np = Level.NavigationPointList; np != none; np = np.NextNavigationPoint )
	{
		if( PlayerStart(np) != none && np.Tag == levelTag )
		{
			MyPlayerStart = PlayerStart(np);
			break;
		}
	}

	if( MyPlayerStart == none )
	{
		Warn( "Found no playerspawn for objective with tag" @ fullTag );
		return;
	}

	MyTeleporter = Spawn( class'BTLevelTeleporter', self, MyPlayerStart.Tag, MyPlayerStart.Location, MyPlayerStart.Rotation );
}

final function ResetObjective()
{
    MyObjective.Reset();
    MyObjective.DefenderTeamIndex = 1;
}

final static function string GetMapTag( string mapName )
{
	if( Left( Mid( mapName, 3/**AS-*/ ), 5 ) ~= "solo-" )
		return "AS-Solo";

	if( Left( mapName, 4 ) ~= "str-" )
		return "STR";

    return "AS";
}

// Server only
final function bool IsSupremeLevel()
{
	return _IsSupremeLevel;
}

// Client and Server
final function string GetLevelName()
{
	if( LevelName != "" )
	{
		return LevelName;
	}

	if( Level.Title == "untitled" || Level.Title == "" )
		return MyObjective.Objective_Info_Attacker;
	return Level.Title;
}

// Server only
final function bool IsValidPlayerStart( Controller player, PlayerStart start )
{
	return start == MyPlayerStart;
	// Inc "Map-"
	// return LevelName ~= string(start.Tag);
}

// Client and Server
final function string GetFullName( string mapName )
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
final function bool Represents( GameObjective obj )
{
	return MyObjective == obj;
}

defaultproperties
{
}