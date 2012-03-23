//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_VotingHandler extends xVotingHandler;

const COMPETITIVEMODE = "*-CompetitiveMode";
const ASTERIKPREFIX = "*";

var() globalconfig array<string> RandomMapModes;

var MutBestTimes RecordsManager;

var int ThisMapDSlot;
var int QuickStarts;

var() globalconfig int QuickStartLimit;
var() globalconfig bool bRankedVotingPriority;

struct sMapData
{
	var string Map;
	var int R;
};
var globalconfig array<sMapData> MapData;

var bool bThisMapHasD;

// Small fix
event timer()
{
	local int i;

	if(Level.bLevelChange)
	{
		if( Level.NextSwitchCountdown <= 0 )
		{
			ClearAllVotes();
			Level.bLevelChange = false;

			Level.Game.Broadcast(self,"Failed to travel. Please vote another map!");
		}
		return;
	}

	if(ScoreBoardTime > -1)
	{
		if(ScoreBoardTime == 0)
			OpenAllVoteWindows();
		ScoreBoardTime--;
		return;
	}
	TimeLeft--;

	if(TimeLeft == 60 || TimeLeft == 30 || TimeLeft == 20 || TimeLeft == 10)  // play announcer count down voice
	{
		for( i=0; i<MVRI.Length; i++)
			if(MVRI[i] != none && MVRI[i].PlayerOwner != none )
				MVRI[i].PlayCountDown(TimeLeft);
	}

	if(TimeLeft == 0)  // force level switch if time limit is up
		TallyVotes(true);   // if no-one has voted a random map will be choosen
}

function string GetCurrentGame()
{
	local string S;
	local int i;

	S = string(Self);
	S = Left(S,InStr(S,"."));
	i = InStr(S,"-");
	if( i==-1 )
		S = Left(S,2);
	else S = Left(S,i);
	For( i=0; i<GameConfig.Length; i++ )
	{
		if( GameConfig[i].Prefix~=S )
			Return GameConfig[i].GameName;
	}
	Return "Assault";
}

final function array<string> GetRandomMapModePrefixes( string randomMode )
{
	local int i;
	local array<string> modes;

	for( i = 0; i < RandomMapModes.Length; ++ i )
	{
		Split( RandomMapModes[i], "|", modes );
		if( modes[0] ~= randomMode )
		{
			modes.Remove( 0, 1 );
			return modes;
	 	}
	}
	modes.Length = 0;
	return modes;
}

final function bool IsRandom( string mapName, out array<string> randomModes )
{
	local int i;

	Log( mapName );
	i = InStr( Locs(mapName), "random:" );
	Log( i );
	if( i == -1 )
		return false;

	i += Len("random:");

   	Log( Mid( mapName, i ) );
  	randomModes = GetRandomMapModePrefixes( Mid( mapName, i ) );
  	return true;
}

final function bool GetRandomMapByPrefix( array<string> prefixes, out int mapIndex )
{
	local int i, j, prefixIndex;
	local array<int> selections;

	if( prefixes.Length == 0 )
		return false;

	for( i = 0; i < MapCount; ++ i )
	{
		if( !MapList[i].bEnabled )
			continue;

		prefixIndex = InStr( MapList[i].MapName, "-" );
		if( prefixIndex == -1 || InStr( Locs(MapList[i].MapName), Len(Left( MapList[i].MapName, prefixIndex ) $ "-Random:") ) != -1 )
			continue;

		for( j = 0; j < prefixes.Length; ++ j )
		{
	    	if( Left( MapList[i].MapName, Len(prefixes[j]) ) ~= prefixes[j] || (prefixes[j] ~= "ShieldGun" && InStr( Locs(MapList[i].MapName), "shieldgun" ) != -1) )
	    	{
	    		selections.Insert( 0, 1 );
	    		selections[0] = i;
	    	}
	    }
	}

	if( selections.Length == 0 )
		return false;

	mapIndex = selections[Rand( selections.Length-1 )];
	return true;
}

Function AddMapVoteReplicationInfo( PlayerController Player )
{
	local BTClient_VRI VRI;

	VRI = Spawn( Class'BTClient_VRI', Player );
	if( VRI == None )
		return;

	VRI.PlayerID = Player.PlayerReplicationInfo.PlayerID;
	MVRI[MVRI.Length] = VRI;
}

function SubmitMapVote(int MapIndex, int GameIndex, Actor Voter)
{
	local int Index, VoteCount, PrevMapVote, PrevGameVote;

	if( Level.bLevelChange )
	{
		PlayerController(Voter).ClientMessage( "You can not vote while LevelSwitch pending is in progress!" );
		return;
	}

	if( RecordsManager.bGhostIsSaving )
	{
		PlayerController(Voter).ClientMessage( "You can not vote while Ghost Saving is in progress!" );
		return;
	}

	if( RecordsManager.bQuickStart )
	{
		PlayerController(Voter).ClientMessage( "You can not vote while QuickStart is in progress!" );
		return;
	}

	Index = GetMVRIIndex(PlayerController(Voter));

	// check for invalid vote from unpatch players
	if( !IsValidVote(MapIndex, GameIndex) )
	{
		PlayerController(Voter).ClientMessage( "This shouldn't happen..." );
		return;
	}

	if( MapIndex < 0 || MapIndex >= MapCount || GameIndex >= GameConfig.Length || (MVRI[Index].GameVote == GameIndex && MVRI[Index].MapVote == MapIndex) )
	{
		return;
	}

	PrevMapVote = MVRI[Index].MapVote;
	PrevGameVote = MVRI[Index].GameVote;
	MVRI[Index].MapVote = MapIndex;
	MVRI[Index].GameVote = GameIndex;

	if( !PlayerController(Voter).PlayerReplicationInfo.bAdmin )
	{
		if( PlayerController(Voter).PlayerReplicationInfo.bOnlySpectator )
		{
			// Spectators cant vote
			PlayerController(Voter).ClientMessage(lmsgSpectatorsCantVote);
			return;
		}

		// check for invalid map, invalid gametype, player isnt revoting same as previous vote, and map choosen isnt disabled
		if( !MapList[MapIndex].bEnabled )
		{
			PlayerController(Voter).ClientMessage( "You cannot vote for a disabled map!" );
			return;
		}
	}

	PrevMapVote = MVRI[Index].MapVote;
	PrevGameVote = MVRI[Index].GameVote;
	MVRI[Index].MapVote = MapIndex;
	MVRI[Index].GameVote = GameIndex;

	if(bAccumulationMode)
	{
		if(bScoreMode)
		{
			VoteCount = GetAccVote(PlayerController(Voter)) + int(GetPlayerScore(PlayerController(Voter)));
			TextMessage = lmsgMapVotedForWithCount;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
		else
		{
			VoteCount = GetAccVote(PlayerController(Voter)) + 1;
			TextMessage = lmsgMapVotedForWithCount;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
	}
	else
	{
		if(bScoreMode)
		{
			VoteCount = int(GetPlayerScore(PlayerController(Voter)));
			TextMessage = lmsgMapVotedForWithCount;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%votecount%", string(VoteCount) );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
		else
		{
			VoteCount =  1;
			TextMessage = lmsgMapVotedFor;
			TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
			TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
			Level.Game.Broadcast(self,TextMessage);
		}
	}
	UpdateVoteCount(MapIndex, GameIndex, VoteCount);
	if( PrevMapVote > -1 && PrevGameVote > -1 )
		UpdateVoteCount(PrevMapVote, PrevGameVote, -MVRI[Index].VoteCount); // undo previous vote
	MVRI[Index].VoteCount = VoteCount;
	TallyVotes(PlayerController(Voter).PlayerReplicationInfo.bAdmin);
}

// TAKEN FROM:xVotingHandler -- Removed logs and added RandomVotes
function LoadMapList()
{
	local int i,EnabledMapCount;
	local MapListLoader Loader;

	MapList.Length = 0; // clear
	MapCount = 0;

	MapVoteHistoryClass = class<MapVoteHistory>(DynamicLoadObject(MapVoteHistoryType, class'Class'));
	History = new(None,"MapVoteHistory"$string(ServerNumber)) MapVoteHistoryClass;
	if(History == None) // Failed to spawn MapVoteHistory
		History = new(None,"MapVoteHistory"$string(ServerNumber)) class'MapVoteHistory_INI';

	if(GameConfig.Length == 0)
	{
		bAutoDetectMode = true;
		// default to ONLY current game type and maps
		GameConfig.Length = 1;
		GameConfig[0].GameClass = string(Level.Game.Class);
		GameConfig[0].Prefix = Level.Game.MapPrefix;
		GameConfig[0].Acronym = Level.Game.Acronym;
		GameConfig[0].GameName = Level.Game.GameName;
		GameConfig[0].Mutators="";
		GameConfig[0].Options="";
	}
	MapCount = 0;

	// NEW
	foreach DynamicActors( class'MutBestTimes', RecordsManager )
		break;

	if( RecordsManager.AllowCompetitiveMode() )
	{
		for( i = 0; i < GameConfig.Length; ++ i )
		{
			if( InStr( GameConfig[i].Prefix, "," $ ASTERIKPREFIX ) == -1 )
			{
				GameConfig[i].Prefix $= "," $ ASTERIKPREFIX;
			}
		}
	}
	// ..

	Loader = Spawn( class<MapListLoader>(DynamicLoadObject(MapListLoaderType, class'Class')) );

	if(Loader == None) // Failed to spawn MapListLoader
		Loader = spawn(class'DefaultMapListLoader'); // default

	Loader.LoadMapList(self);

	// NEW
  	AddRandomVotes();
	CheckMapData();
	// ..

	History.Save();

	if(bEliminationMode)
	{
		// Count the Remaining Enabled maps
		EnabledMapCount = 0;
		for(i=0;i<MapCount;i++)
		{
			if(MapList[i].bEnabled)
				EnabledMapCount++;
		}
		if(EnabledMapCount < MinMapCount || EnabledMapCount == 0)
		{
			log("Elimination Mode Reset/Reload.",'MapVote');
			RepeatLimit = 0;
			MapList.Length = 0;
			MapCount = 0;
			SaveConfig();
			Loader.LoadMapList(self);

	  		AddRandomVotes();
			CheckMapData();
		}
	}

	// NEW
	for( i = 0; i < MapCount; ++ i )
	{
		if( MapList[i].MapName ~= "GTR-GeometryBasics" )
		{
			if( RecordsManager.GroupFinishAchievementUnlockedNum < 10 )
			{
				MapList[i].bEnabled = false;
			}
			RecordsManager.bBlockSake = true;
			break;
		}
	}
	// ..

	Loader.Destroy();
}

function TallyVotes(bool bForceMapSwitch)
{
	local int        index,x,y,topmap,r,mapidx,gameidx,i;
	local array<int> VoteCount;
	local array<int> Ranking;
	local int        PlayersThatVoted;
	local int        TieCount;
	local string     CurrentMap;
	local array<string>     randomModes;
	local int        Votes;
	local MapHistoryInfo MapInfo;
//	local int		 VoteExceptionCount;
//	local string 	 VoterName;
	local int j, k;

	if(Level.bLevelChange)
		return;

	VoteCount.Length = GameConfig.Length * MapCount;

	for(x=0;x < MVRI.Length;x++) // for each player
	{
		if(MVRI[x] != none )
		{
			if( MVRI[x].MapVote > -1 && MVRI[x].GameVote > -1 )
			{
				// Don't count people that did vote and became spectater after...
				if( MVRI[x].PlayerOwner.PlayerReplicationInfo.bOnlySpectator )
					continue;

				PlayersThatVoted++;

				if(bScoreMode)
				{
					if(bAccumulationMode)
						Votes = GetAccVote(MVRI[x].PlayerOwner) + int(GetPlayerScore(MVRI[x].PlayerOwner));
					else
						Votes = int(GetPlayerScore(MVRI[x].PlayerOwner));
				}
				else
				{  // Not Score Mode == Majority (one vote per player)
					if(bAccumulationMode)
						Votes = GetAccVote(MVRI[x].PlayerOwner) + 1;
					else
						Votes = 1;
				}

				// Count top ranked players twice.
				// Hardcoded 3 because MaxRewardedPlayers adjusts when its holiday and so then almost everyone gets double votes which is just stupid
				if( bRankedVotingPriority && RecordsManager.IsRank( MVRI[x].PlayerOwner.GetPlayerIdHash(), 3/*RecordsManager.MaxRewardedPlayers*/ ) && !RecordsManager.FoundDuplicateID( MVRI[x].PlayerOwner ) )
				{
					PlayersThatVoted ++;
					Votes *= 2;
				}

				VoteCount[MVRI[x].GameVote * MapCount + MVRI[x].MapVote] += Votes;

				if(!bScoreMode)
				{
					// If more then half the players voted for the same map as this player then force a winner
					if(Level.Game.NumPlayers > 2 && float(VoteCount[MVRI[x].GameVote * MapCount + MVRI[x].MapVote]) / float(Level.Game.NumPlayers) > 0.5 && Level.Game.bGameEnded)
						bForceMapSwitch = true;
				}
			}
			/*else
			{
				VoterName = MVRI[x].PlayerOwner.PlayerReplicationInfo.PlayerName;
				if( InStr( VoterName, "(AFK)" ) != -1 )
					VoteExceptionCount ++;
			}*/
		}
	}
	//log("___Voted - " $ PlayersThatVoted,'MapVoteDebug');

	if(Level.Game.NumPlayers > 2 && !Level.Game.bGameEnded && !bMidGameVote && (float(PlayersThatVoted) / float(Level.Game.NumPlayers)) * 100 >= MidGameVotePercent) // Mid game vote initiated
	{
		Level.Game.Broadcast(self,lmsgMidGameVote);
		bMidGameVote = true;
		// Start voting count-down timer
		TimeLeft = VoteTimeLimit;
		ScoreBoardTime = 1;
		settimer(1,true);
	}

	index = 0;
	for(x=0;x < VoteCount.Length;x++) // for each map
	{
		if(VoteCount[x] > 0)
		{
			Ranking.Insert(index,1);
			Ranking[index++] = x; // copy all vote indexes to the ranking list if someone has voted for it.
		}
	}

	if(PlayersThatVoted > 1)
	{
		// bubble sort ranking list by vote count
		for(x=0; x<index-1; x++)
		{
			for(y=x+1; y<index; y++)
			{
				if(VoteCount[Ranking[x]] < VoteCount[Ranking[y]])
				{
				topmap = Ranking[x];
				Ranking[x] = Ranking[y];
				Ranking[y] = topmap;
				}
			}
		}
	}
	else
	{
		if(PlayersThatVoted == 0)
		{
			GetDefaultMap(mapidx, gameidx);
			topmap = gameidx * MapCount + mapidx;
		}
		else
			topmap = Ranking[0];  // only one player voted
	}

	//Check for a tie
	if(PlayersThatVoted > 1) // need more than one player vote for a tie
	{
		if(index > 1 && VoteCount[Ranking[0]] == VoteCount[Ranking[1]] && VoteCount[Ranking[0]] != 0)
		{
			TieCount = 1;
			for(x=1; x<index; x++)
			{
				if(VoteCount[Ranking[0]] == VoteCount[Ranking[x]])
				TieCount++;
			}
			//reminder ---> int Rand( int Max ); Returns a random number from 0 to Max-1.
			topmap = Ranking[Rand(TieCount)];

			// Don't allow same map to be choosen
			CurrentMap = GetURLMap();

			r = 0;
			while(MapList[topmap - (topmap/MapCount) * MapCount].MapName ~= CurrentMap)
			{
				topmap = Ranking[Rand(TieCount)];
				if(r++>100)
					break;  // just incase
			}
		}
		else
		{
			topmap = Ranking[0];
		}
	}

	// if everyone has voted go ahead and change map
	if( bForceMapSwitch || (PlayersThatVoted >= Level.Game.NumPlayers && Level.Game.NumPlayers > 0) )
	{
		i = topmap - topmap/MapCount * MapCount;

		if( MapList[i].MapName == "" )
			return;

		/* Activate Quick Restart when same map is voted */
		if( MapList[i].MapName ~= RecordsManager.CurrentMapName )
		{
			TextMessage = lmsgMapWon;
			TextMessage = repl(TextMessage,"%mapname%",MapList[i].MapName $ "(" $ GameConfig[topmap/MapCount].Acronym $ ")");
			Level.Game.Broadcast(self,TextMessage);

			MapList[i].Sequence = 1;
			MapInfo = History.PlayMap( MapList[i].MapName );
			History.Save();

			if( !bAutoDetectMode )
				SaveConfig();

			if( !RecordsManager.bQuickStart )
			{
				QuickStarts ++;
				Level.Game.Broadcast( Self, "QuickStart in progress..."@QuickStartLimit-QuickStarts@"remaining revotes!" );
				RecordsManager.Revoted();

				MapData[ThisMapDSlot].R = QuickStarts+1;

				if( QuickStarts >= QuickStartLimit )
				{
					MapList[i].bEnabled = False;
					MapData[ThisMapDSlot].R = QuickStartLimit;
					SaveConfig();
				}
			}
			else Level.Game.Broadcast( Self, "QuickStart denied..." );

			CloseAllVoteWindows();
			ClearAllVotes();
			return;
		}
		else if( MapList[i].MapName ~= COMPETITIVEMODE )
		{
			if( RecordsManager.EnableCompetitiveMode() )
			{
				Level.Game.Broadcast( self, "Competitive Mode is now enabled!" );
				MapList[i].bEnabled = false;
			}

			CloseAllVoteWindows();
			ClearAllVotes();
			return;
		}
		else
		{
			j = MapData.Length;
			for( k = 0; k < j; k ++ )
			{
				MapData[k].R --;
				if( MapData[k].R <= 0 )
				{
					MapData.Remove( k, 1 );
					j = MapData.Length;
					k --;
				}
			}
			SaveConfig();
		}

		if( IsRandom( MapList[i].MapName, randomModes ) )
		{
			GetRandomMapByPrefix( randomModes, i );
		}

		TextMessage = lmsgMapWon;
		TextMessage = repl(TextMessage,"%mapname%",MapList[i].MapName $ "(" $ GameConfig[topmap/MapCount].Acronym $ ")");
		Level.Game.Broadcast(self,TextMessage);

		CloseAllVoteWindows();

		MapInfo = History.PlayMap(MapList[i].MapName);

		ServerTravelString = SetupGameMap(MapList[i], topmap/MapCount, MapInfo);

		History.Save();

		if(bEliminationMode)
			RepeatLimit++;

		if(bAccumulationMode)
			SaveAccVotes(i, topmap/MapCount);

		//if(bEliminationMode || bAccumulationMode)
		CurrentGameConfig = topmap/MapCount;
		if( !bAutoDetectMode )
			SaveConfig();

		Level.ServerTravel(ServerTravelString, false);    // change the map
		SetTimer(Level.TimeDilation,true);  // timer() will monitor the server-travel and detect a failure
	}
}

Function ClearAllVotes()
{
	local int i, j, k, l;
	local array<MapVoteScore> MVCData;

	j = MapVoteCount.Length;
	for( i = 0; i < j; i ++ )
	{
		if( MapVoteCount[i].VoteCount > 0 )
		{
			MapVoteCount[i].VoteCount = 0;
			k = MVCData.Length;
			MVCData.Length = k + 1;
			MVCData[k] = MapVoteCount[i];
		}
	}

	if( j > 0 )
	{
		//MapVoteCount.Remove( j-1, j );
		MapVoteCount.Length = 0;
	}

	j = MVRI.Length;
	k = MVCData.Length;
	for( i = 0; i < j; i ++ )
	{
		if( MVRI[i] != None && MVRI[i].PlayerOwner != None )
		{
			for( l = 0; l < k; l ++ )
			{
				//UpdateVoteCount( MVRI[i].MapVote, MVRI[i].GameVote, MVRI[i].VoteCount );
				MVRI[i].ReceiveMapVoteCount( MVCData[l], False );
			}

			MVRI[i].VoteCount = -1;
			MVRI[i].MapVote = -1;
			MVRI[i].GameVote = -1;
		}
	}
	DisableMidGameVote();
}

Function DisableMidGameVote()
{
	bMidGameVote = False;
	SetTimer( 0, False );
	TimeLeft = 0;
	ScoreBoardTime = 0;
}

function AddRandomVotes()
{
	local int i, g, p;
	local array<string> modes;

	AddOtherVotes();

	for( g = 0; g < GameConfig.Length; ++ g )
	{
		for( i = 0; i < RandomMapModes.Length; ++ i )
		{
			modes = GetRandomMapModePrefixes( Left( RandomMapModes[i], InStr( RandomMapModes[i], "|" ) ) );
			if( GetRandomMapByPrefix( modes, p ) )
			{
				MapList.Insert( 0, 1 );
				MapList[0].bEnabled = true;
				MapList[0].MapName = Left( MapList[p].MapName, InStr( MapList[p].MapName, "-" ) ) $ "-Random:" $ Left( RandomMapModes[i], InStr( RandomMapModes[i], "|" ) );
			}
		}
	}
}

function AddOtherVotes()
{
	if( RecordsManager.AllowCompetitiveMode() && RecordsManager.bSoloMap && !RecordsManager.bGroupMap )
	{
		Log( "Competitive Mode supported by VotingHandler!", Name );
	}
	MapList.Insert( 0, 1 );
	MapList[0].bEnabled = true;
	MapList[0].MapName = COMPETITIVEMODE;
}

function CheckMapData()
{
	local string ActiveMap;
	local int CurMap, CurData;
	local bool bHasMapData;

	ActiveMap = Left( string(Self),InStr( string(Self), "." ) );
	if( MapData.Length > 0 )
	{
		for( CurMap = 0; CurMap < MapList.Length; CurMap ++)
		{
			for( CurData = 0; CurData < MapData.Length; CurData ++ )
			{
				if( !bHasMapData && MapData[CurData].Map == ActiveMap )
				{
					bHasMapData = true;
					ThisMapDSlot = CurData;
				}

				if( (MapList[CurMap].MapName == MapData[CurData].Map && MapData[CurData].R > 0) && (MapList[CurMap].MapName != ActiveMap) )
					MapList[CurMap].bEnabled = false;
			}
		}
	}

	if( !bHasMapData && !bThisMapHasD )
	{
		bThisMapHasD = true;
		CurData = MapData.Length;
		MapData.Length = CurData + 1;
		MapData[CurData].Map = ActiveMap;
		MapData[CurData].R = 2;
		ThisMapDSlot = CurData;

		SaveConfig();
	}
}

static function FillPlayInfo( PlayInfo Info )
{
	super.FillPlayInfo( Info );
	Info.AddSetting( default.MapVoteGroup, "bRankedVotingPriority", "Ranked Voting Priority", 0, 1, "Check" );
	Info.AddSetting( default.MapVoteGroup, "QuickStartLimit", "QuickStart Limit", 0, 1, "Text", "10;0:9999",, true, true );
}

static function string GetDescriptionText( string PropName )
{
	switch( PropName )
	{
		case "bRankedVotingPriority":
			return "Whether to give the top ranked players give an higher voting priority";

		case "QuickStartLimit":
			return "The amount of times people are allowed to vote for quickstart in one session";
	}
	return Super.GetDescriptionText(PropName);
}

DefaultProperties
{
	QuickStartLimit=10
	bMapVote=True
	bRankedVotingPriority=True

	RepeatLimit=0	// We have our own system and better!

	RandomMapModes(0)="Regular|AS|RTR"
	RandomMapModes(1)="Solo|AS-Solo|STR"
	RandomMapModes(2)="Group|AS-Group|GTR"
	RandomMapModes(3)="ShieldGun|AS-ShieldGun"
}
