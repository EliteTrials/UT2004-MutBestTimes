class BTClient_LevelReplication extends ReplicationInfo;

var BTClient_LevelReplication NextLevel;
var private PlayerStart MyPlayerStart;
var private BTLevelTeleporter MyTeleporter;
var private GameObjective MyObjective;
var private string LevelName;

// Record state
var string TopRanks;
var float TopTime;
var int NumRecords;

// Serverside only
var int MapIndex; // Index to RecordsData.Rec array.

replication
{
	reliable if( bNetInitial )
		NextLevel, MyObjective, LevelName;

	reliable if( bNetDirty )
		TopRanks, TopTime, NumRecords;
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

	MyObjective = obj;
	LevelName = string(obj.Tag);

	for( np = Level.NavigationPointList; np != none; np = np.NextNavigationPoint )
	{
		if( PlayerStart(np) != none && string(np.Tag) ~= LevelName )
		{
			MyPlayerStart = PlayerStart(np);
			break;
		}
	}

	if( MyPlayerStart == none )
	{
		Warn("Found no playerspawn for level" @ LevelName);
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
	if( Left( Mid( mapName, 3/**AS-*/ ), 5 ) ~= "Solo-" )
		return "AS-Solo";

	if( Left( mapName, 4 ) ~= "STR-" )
		return "STR";

    return "AS";
}

final function string GetLevelName()
{
	if( Left( LevelName, 4 ) ~= "Map-" )
	{
		return Mid( LevelName, 4 );
	}
	else if( Left( LevelName, 6 ) ~= "Level-" )
	{
		return Mid( LevelName, 6 );
	}
	if( Level.Title == "untitled" || Level.Title == "" )
		return MyObjective.Objective_Info_Attacker;
	return Level.Title;
}

final function bool IsValidPlayerStart( Controller player, PlayerStart start )
{
	return start == MyPlayerStart;
	// Inc "Map-"
	// return LevelName ~= string(start.Tag);
}

final function string GetFullName( string mapName )
{
	if( Left( LevelName, 4 ) ~= "Map-" )
	{
		return GetMapTag( mapName )$"-"$Mid( LevelName, 4 );
	}
	else if( Left( LevelName, 6 ) ~= "Level-" )
	{
		return mapName$"-"$Mid( LevelName, 6 );
	}
	return mapName;
}

final function bool Represents( GameObjective obj )
{
	return MyObjective == obj;
}

defaultproperties
{

}