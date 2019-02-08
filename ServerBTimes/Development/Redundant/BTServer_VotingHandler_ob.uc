// Used to be UT2xVotingHandler, now converted into bt.
// Coded by .:..: & Eliot.
Class BTServer_VotingHandler extends xVotingHandler;

var bool bHasLoaded;
var byte SwitchTries;
var array<string> DonePrefixes;
Const RandMapName="All:RandomVote";
Const SGRandMapName="ShieldGun:RandomVote";

var BTimesMute RecordsManager;

var int ThisMapDSlot;
var int QuickStarts;
var() config int QuickStartLimit;

struct sMapData
{
	var string Map;
	var int R;
};

var config array<sMapData> MapData;

var bool bThisMapHasD;

Function PostBeginPlay()
{
	Super.PostBeginPlay();

	ForEach DynamicActors( Class'BTimesMute', RecordsManager )
		break;
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

Function AddMapVoteReplicationInfo( PlayerController Player )
{
	local BTClient_VRI VRI;

	VRI = Spawn( Class'BTClient_VRI', Player );
	if( VRI == None )
		return;

	VRI.PlayerID = Player.PlayerReplicationInfo.PlayerID;
	MVRI[MVRI.Length] = VRI;
}

event timer()
{
	local int mapidx,gameidx, i;
	local MapHistoryInfo MapInfo;

	if(bLevelSwitchPending)
	{
		if( Level.NextURL == "" )
		{
			if(Level.NextSwitchCountdown < 0)  // if negative then level switch failed
			{
				if( SwitchTries>=4 )
				{
					Log("Emergency exit!!!!!!!!!!!!!!!!!!");
					Assert(False);
					Return;
				}
				Log("___Map change Failed, bad or missing map file.",'MapVote');
				GetDefaultMap(mapidx, gameidx);
				MapInfo = History.PlayMap(MapList[mapidx].MapName);
				ServerTravelString = SetupGameMap(MapList[mapidx], gameidx, MapInfo);
				//log("ServerTravelString = " $ ServerTravelString ,'MapVoteDebug');
				History.Save();
				Level.ServerTravel(ServerTravelString, false);    // change the map
				SwitchTries++;
			}
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

	if(TimeLeft == 0)  				// force level switch if time limit is up
		TallyVotes(true);   		// if no-one has voted, a random map will be choosen
}

function SubmitMapVote(int MapIndex, int GameIndex, Actor Voter)
{
	local int Index, VoteCount, PrevMapVote, PrevGameVote;
	local MapHistoryInfo MapInfo;
	local bool bRandomM, bRandSG;

	if(bLevelSwitchPending)
		return;

	Index = GetMVRIIndex(PlayerController(Voter));

	if( RecordsManager.bQuickStart )
	{
		PlayerController(Voter).ClientMessage( "You can not vote while QuickStart is in progress!" );
		return;
	}

	// check for invalid vote from unpatch players
	if( !IsValidVote(MapIndex, GameIndex) )
		return;

	if( IsRandomMapVote(MapList[MapIndex].MapName) )
		bRandomM = True;
	else if( IsSGRandomMapVote( MapList[MapIndex].MapName) )
		bRandSG = True;

	if(PlayerController(Voter).PlayerReplicationInfo.bAdmin)  // Administrator Vote
	{
		if( bRandomM )
		{
			Level.Game.Broadcast(self,"An Admin has forced to switch to a random map within"@GameConfig[GameIndex].GameName);
			MapIndex = GetRandomMapVote(GameConfig[GameIndex].Prefix);
		}
		else if( bRandSG )
		{
			Level.Game.Broadcast(self,"An Admin has forced to switch to a shieldgun random map within"@GameConfig[GameIndex].GameName);
			MapIndex = GetRandomMapVote(GameConfig[GameIndex].Prefix);
		}
		else
		{
			TextMessage = lmsgAdminMapChange;
			TextMessage = Repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")");
			Level.Game.Broadcast(self,TextMessage);
		}

		log("Admin has forced map switch to " $ MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")",'MapVote');

		CloseAllVoteWindows();

		bLevelSwitchPending = true;

		MapInfo = History.PlayMap(MapList[MapIndex].MapName);

		ServerTravelString = SetupGameMap(MapList[MapIndex], GameIndex, MapInfo);
		log("ServerTravelString = " $ ServerTravelString ,'MapVoteDebug');

		Level.ServerTravel(ServerTravelString, false);    // change the map

		settimer(1,true);
		return;
	}

	if( PlayerController(Voter).PlayerReplicationInfo.bOnlySpectator )
	{
		// Spectators cant vote
		PlayerController(Voter).ClientMessage(lmsgSpectatorsCantVote);
		return;
	}

	// check for invalid map, invalid gametype, player isnt revoting same as previous vote, and map choosen isnt disabled
	if( MapIndex < 0 || MapIndex >= MapCount || GameIndex >= GameConfig.Length || (MVRI[Index].GameVote == GameIndex && MVRI[Index].MapVote == MapIndex) || (!MapList[MapIndex].bEnabled && !bRandomM) )
		return;

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
			if( bRandomM || bRandSG )
				Level.Game.Broadcast(self,PlayerController(Voter).PlayerReplicationInfo.PlayerName@"Voted for"@MapList[MapIndex].MapName@GameConfig[GameIndex].GameName);
			else
			{
				TextMessage = lmsgMapVotedFor;
				TextMessage = repl(TextMessage, "%playername%", PlayerController(Voter).PlayerReplicationInfo.PlayerName );
				TextMessage = repl(TextMessage, "%mapname%", MapList[MapIndex].MapName $ "(" $ GameConfig[GameIndex].Acronym $ ")" );
				Level.Game.Broadcast(self,TextMessage);
			}
		}
	}

	UpdateVoteCount(MapIndex, GameIndex, VoteCount);
	if( PrevMapVote > -1 && PrevGameVote > -1 )
		UpdateVoteCount(PrevMapVote, PrevGameVote, -MVRI[Index].VoteCount); // undo previous vote

	MVRI[Index].VoteCount = VoteCount;
	TallyVotes(false);
}
static function bool IsEnabled()
{
	Return True;
}
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

	Loader = Spawn( class<MapListLoader>(DynamicLoadObject(MapListLoaderType, class'Class')) );

	if(Loader == None) // Failed to spawn MapListLoader
		Loader = spawn(class'DefaultMapListLoader'); // default

	Loader.LoadMapList(self);

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
		}
	}
	Loader.Destroy();
}
function AddMap(string MapName, string Mutators, string GameOptions) // called from the MapListLoader
{
	local MapHistoryInfo MapInfo;
	local bool bUpdate;
	local int i, j, k;
	local string S;
	local bool bHasMapData;

	i = InStr(MapName,"-");
	if( i!=-1 )
	{
		S = Caps( Left(MapName,i) );
		For( i=0; i<DonePrefixes.Length; i++ )
		{
			if( DonePrefixes[i]~=S )
				GoTo'AllDone';
		}

		i = DonePrefixes.Length;
		DonePrefixes.Length = i+1;
		DonePrefixes[i] = S;

		MapList.Length = MapCount + 1;
		MapList[MapCount].bEnabled = True;
		MapList[MapCount].Sequence = 0;
		MapList[MapCount].MapName = S$"-"$RandMapName;
		MapCount++;

		MapList.Length = MapCount + 1;
		MapList[MapCount].bEnabled = True;
		MapList[MapCount].Sequence = 0;
		MapList[MapCount].MapName = S$"-"$SGRandMapName;
		MapCount++;
	}
	AllDone:

	for(i=0; i < MapList.Length; i++)  // dont add duplicate map names
		if(MapName ~= MapList[i].MapName)
			return;

	MapInfo = History.GetMapHistory(MapName);

	MapList.Length = MapCount + 1;
	MapList[MapCount].MapName = MapName;
	MapList[MapCount].PlayCount = MapInfo.P;
	MapList[MapCount].Sequence = MapInfo.S;
	if(MapInfo.S <= RepeatLimit && MapInfo.S != 0)
		MapList[MapCount].bEnabled = false; // dont allow players to vote for this one
	else
		MapList[MapCount].bEnabled = true;

	j = MapData.Length;
	if( j > 0 )
	{
		for( k = 0; k < MapList.Length; k ++ )
		{
			for( i = 0; i < MapData.Length; i ++ )
			{
				if( MapData[i].Map == Left(string(Self),InStr(string(Self),".")) )
				{
					bHasMapData = True;
					ThisMapDSlot = i;
				}

				if( (MapList[k].MapName == MapData[i].Map && MapData[i].R > 0) && (MapList[k].MapName != Left(string(Self),InStr(string(Self),"."))) )
					MapList[k].bEnabled = False;
			}
		}
	}

	if( !bHasMapData && !bThisMapHasD )
	{
		bThisMapHasD = True;
		i = MapData.Length;
		MapData.Length = i + 1;
		MapData[i].Map = Left(string(Self),InStr(string(Self),"."));
		MapData[i].R = 2;
		ThisMapDSlot = i;
	}

	MapCount++;

	if(Mutators != "" && Mutators != MapInfo.U)
	{
		MapInfo.U = Mutators;
		bUpdate = True;
	}

	if(GameOptions != "" && GameOptions != MapInfo.G)
	{
		MapInfo.G = GameOptions;
		bUpdate = True;
	}

	if(MapInfo.M == "") // if map not found in MapVoteHistory then add it
	{
		MapInfo.M = MapName;
		bUpdate = True;
	}

	if(bUpdate)
		History.AddMap(MapInfo);
}
function bool IsRandomMapVote( string S )
{
	local int i;

	i = InStr(S,"-");
	if( i==-1 )
		Return False;
	else Return (Mid(S,i+1)~=RandMapName);
}
function int GetRandomMapVote( string Prefix )
{
	local int i,l,c;
	local array<int> ic;

	l = Len(Prefix);
	For( i=0; i<MapCount; i++ )
	{
		if( Left(MapList[i].MapName,l) != Prefix || !MapList[i].bEnabled || IsRandomSelection( Mid( MapList[i].MapName, l+1 ) ) )
			continue;

		ic.Length = c+1;
		ic[c] = i;
		c++;
	}
	if( c==0 )
		Return Rand(MapCount);
	c = Rand(c);
	Return ic[c];
}
function bool IsSGRandomMapVote( string S )
{
	local int i;

	i = InStr(S,"-");
	if( i==-1 )
		Return False;
	else Return (Mid(S,i+1)~=SGRandMapName);
}
function int GetSGRandomMapVote( string Prefix )
{
	local int i,l,c;
	local array<int> ic;

	l = Len(Prefix);
	For( i=0; i<MapCount; i++ )
	{
		if( Left(MapList[i].MapName,l) != Prefix || !MapList[i].bEnabled || IsRandomSelection( Mid( MapList[i].MapName, l+1 ) ) )
			continue;

		if( (InStr( MapList[i].MapName, "ShieldGun" )) != - 1)
		{
			ic.Length = c+1;
			ic[c] = i;
			c++;
		}
	}
	if( c==0 )
		Return Rand(MapCount);
	c = Rand(c);
	Return ic[c];
}

Function bool IsRandomSelection( string S )
{
	if( S ~= SGRandMapName )
		return True;

	if( S ~= RandMapName )
		return True;

	return False;
}

function TallyVotes(bool bForceMapSwitch)
{
	local int        index,x,y,topmap,r,mapidx,gameidx,i;
	local array<int> VoteCount;
	local array<int> Ranking;
	local int        PlayersThatVoted;
	local int        TieCount;
	local string     CurrentMap;
	local int        Votes;
	local MapHistoryInfo MapInfo;
//	local int		 VoteExceptionCount;
//	local string 	 VoterName;
	local int j, k;

	if(bLevelSwitchPending)
		return;

	VoteCount.Length = GameConfig.Length * MapCount;

	for(x=0;x < MVRI.Length;x++) // for each player
	{
		if(MVRI[x] != none )
		{
			if( MVRI[x].MapVote > -1 && MVRI[x].GameVote > -1 )
			{
				// Don't count people that did vote and became spectater after...
				if( MVRI[x].PlayerOwner.PlayerReplicationInfo.bOnlySpectator || MVRI[x].PlayerOwner.PlayerReplicationInfo.bIsSpectator )
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
				if( RecordsManager.IsRank( MVRI[x].PlayerOwner.GetPlayerIdHash(), 3 ) && !RecordsManager.FoundDuplicateID( MVRI[x].PlayerOwner ) )
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
			else Level.Game.Broadcast( Self, "QuickStart Denied..." );

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

		if( IsRandomMapVote(MapList[i].MapName) )
			i = GetRandomMapVote(GameConfig[topmap/MapCount].Prefix);
		else if( IsSGRandomMapVote(MapList[i].MapName) )
			i = GetSGRandomMapVote(GameConfig[topmap/MapCount].Prefix);

		TextMessage = lmsgMapWon;
		TextMessage = repl(TextMessage,"%mapname%",MapList[i].MapName $ "(" $ GameConfig[topmap/MapCount].Acronym $ ")");
		Level.Game.Broadcast(self,TextMessage);

		CloseAllVoteWindows();

		MapInfo = History.PlayMap(MapList[i].MapName);

		ServerTravelString = SetupGameMap(MapList[i], topmap/MapCount, MapInfo);
		//log("ServerTravelString = " $ ServerTravelString ,'MapVoteDebug');

		History.Save();

		if(bEliminationMode)
			RepeatLimit++;

		if(bAccumulationMode)
			SaveAccVotes(i, topmap/MapCount);

		//if(bEliminationMode || bAccumulationMode)
		CurrentGameConfig = topmap/MapCount;
		if( !bAutoDetectMode )
			SaveConfig();

		// Note BT about this
		RecordsManager.SwitchPending();

		bLevelSwitchPending = true;
		settimer(Level.TimeDilation,true);  // timer() will monitor the server-travel and detect a failure

		Level.ServerTravel(ServerTravelString, false);    // change the map
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
		MapVoteCount.Remove( j-1, j );
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

DefaultProperties
{
	QuickStartLimit=10
	bMapVote=True

	RepeatLimit=0	// We have our own system and better!
}
