Class BTServer_BroadcastHandler Extends UnrealChatHandler;
/*
Function BroadcastText( PlayerReplicationInfo Sender, PlayerController Receiver, coerce string Msg, optional name Type )
{
	local int i, j;
	local array<string> S;

	if( BTimesMute(Owner) != None && PlayerController(Sender.Owner) != None && (Type == 'Say' || Type == 'TeamSay') )
	{
		if( Msg ~= "LatestRecords" )
		{
			for( i = 0; i < 3; i ++ )
				PlayerController(Sender.Owner).ClientMessage( "LatestRecord("$i$")"@BTimesMute(Owner).LastRecords[i] );
			Broadcast( Self, "You can type"@Msg@"to show latest made records" );
		}
		else if( Left( Msg, 11 ) ~= "ShowMapInfo" )
		{
			S = GetMapInfo( Mid( Msg, 12 ) );
			j = S.Length;
			for( i = 0; i < j; i ++ )
				PlayerController(Sender.Owner).ClientMessage( S[i] );
			Broadcast( Self, "You can type"@Msg@"to show record of that map" );
		}
		else if( Left( Msg, 14 ) ~= "ShowPlayerInfo" )
		{
			S = GetPlayerInfo( Mid( Msg, 15 ) );
			j = S.Length;
			for( i = 0; i < j; i ++ )
				PlayerController(Sender.Owner).ClientMessage( S[i] );
			Broadcast( Self, "You can type"@Msg@"to show records made by that player" );
		}
		else if( BTimesMute(Owner).bAntiSpam && BlockTextMessage( Msg, PlayerController(Sender.Owner) ) )
			return;
	}
	Super.BroadcastText(Sender,Receiver,Msg,Type);
}

Function array<string> GetMapInfo( string MapName )
{
	local array<string> MapInfo;
	local int i, j;

	j = BTimesMute(Owner).BMTL.Length;
	for( i = 0; i < j; i ++ )
	{
		if( MapName ~= BTimesMute(Owner).BMTL[i].TMN )
		{
			MapInfo[MapInfo.Length] = "MapName:"$BTimesMute(Owner).BMTL[i].TMN;
			MapInfo[MapInfo.Length] = "MapBestTime:"$BTimesMute(Owner).BMTL[i].TMT;
			break;
		}
	}
	return MapInfo;
}

Function array<string> GetPlayerInfo( string PlayerName )
{
	local array<string> PlayerInfo;
	local int i, j, PlayerSlot, l;

	j = BTimesMute(Owner).STORPL.Length;
	for( i = 0; i < j; i ++ )
	{
		if( PlayerName ~= BTimesMute(Owner).STORPL[i].PLName )
		{
			PlayerSlot = i;
			PlayerInfo[PlayerInfo.Length] = "PlayerName:"$BTimesMute(Owner).STORPL[i].PLName;
			break;
		}
	}
	j = BTimesMute(Owner).BMTL.Length;
	for( i = 0; i < j; i ++ )
	{
		for( l = 0; l < 3; l ++ )
		{
			if( BTimesMute(Owner).BMTL[i].PLs[l] == PlayerSlot )
			{
				PlayerInfo[PlayerInfo.Length] = "MapName:"$BTimesMute(Owner).BMTL[i].TMN;
				PlayerInfo[PlayerInfo.Length] = "MapBestTime:"$BTimesMute(Owner).BMTL[i].TMT;
				break;	// Scan next map.
			}
		}
	}
	return PlayerInfo;
}

function bool BlockTextMessage( string Msg, Playercontroller C )
{
	local int i,l,j;

	if( C.PlayerReplicationInfo.bAdmin || Level.NetMode != NM_DedicatedServer )
		return false;

	if ( (Level.TimeSeconds - C.LastBroadcastTime) < 2 )
	{
		C.ClientMessage("Please do not say your chat messages too rapidly");
		return true;
	}

	// lower frequency if same text
	if ( Level.TimeSeconds - C.LastBroadcastTime < 5 )
	{
		l = Len(Msg);
		for ( i=0; i<4; i++ )
		{
			if ( C.LastBroadcastString[i] ~= Msg )
			{
				C.ClientMessage("Please don't repeat your chat messages too rapidly.");
				return true;
			}
			j = Len(C.LastBroadcastString[i]);
			if( (j+5)>l && j<l && Left(Msg,j)~=C.LastBroadcastString[i] ) // Make sure noobs just dont add couple !!'s after..
			{
				C.ClientMessage("Please don't repeat your chat messages too rapidly.");
				return true;
			}
		}
	}
	for ( i=0; i<3; i++ )
		C.LastBroadcastString[i] = C.LastBroadcastString[i+1];

	C.LastBroadcastString[0] = Msg;
	C.LastBroadcastTime = Level.TimeSeconds;
	return false;
}
*/

defaultproperties
{
}
