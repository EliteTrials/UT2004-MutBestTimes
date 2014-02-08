//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_VotingCommands extends Object
	hidedropdown;

final static function VoteMapSeq( PlayerController sender, int sequence )
{
	local int i, j;
	local xVotingHandler H;

	if( sequence < 1 )
	{
		sender.ClientMessage( sequence @ "is too low, please enter an higher sequence number" );
		return;
	}

	H = xVotingHandler(sender.Level.Game.VotingHandler);
	if( H != None && H.bMapVote )
	{
		j = H.MapCount;
		for( i = 0; i < j; ++ i )
		{
			if( H.MapList[i].Sequence == sequence )
			{
				if( H.MapList[i].bEnabled || sender.PlayerReplicationInfo.bAdmin )
				{
					H.SubmitMapVote( i, H.CurrentGameConfig, sender );
					return;
				}
				else
				{
					sender.ClientMessage( "Sorry this map is not enabled" );
					return;
				}
			}
		}
		sender.ClientMessage( "Sorry no map with this sequence was found in the map list..." );
	}
	else
	{
		sender.ClientMessage( "Sorry mapvoting is not enabled on this server!" );
	}
}

final static function VoteMap( PlayerController sender, string mapName )
{
	local int i, j;
	local xVotingHandler H;

	if( Len( mapName ) < 4 )
	{
		sender.ClientMessage( "Please input a map name longer than 3 characters" );
		return;
	}

	mapName = Caps( mapName );
	H = xVotingHandler(sender.Level.Game.VotingHandler);
	if( H != None && H.bMapVote )
	{
		j = H.MapCount;
		for( i = 0; i < j; ++ i )
		{
			if( InStr( Caps( H.MapList[i].MapName ), mapName ) != -1 )
			{
				if( H.MapList[i].bEnabled || sender.PlayerReplicationInfo.bAdmin )
				{
					H.SubmitMapVote( i, H.CurrentGameConfig, sender );
					return;
				}
				else
				{
					sender.ClientMessage( "Sorry this map is not enabled" );
					return;
				}
			}
		}
		sender.ClientMessage( "Sorry this map is not found in the map list..." );
	}
	else
	{
		sender.ClientMessage( "Sorry mapvoting is not enabled on this server!" );
	}
}
