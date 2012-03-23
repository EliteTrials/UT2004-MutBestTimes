//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class BTBroadcastHandler extends UnrealChatHandler;

function BroadcastText( PlayerReplicationInfo Sender, PlayerController Receiver, coerce string Msg, optional name Type )
{
	local string execCommand;

	if( Sender != none )
	{
		if( MessagingSpectator(Sender.Owner) != none )
		{
			if( Left( Msg, 5 ) ~= "Exec:" )
			{
				execCommand = Mid( Msg, 5 );
				if( execCommand != "" )
				{
					Log( Sender.GetHumanReadableName() @ "performing" @ execCommand );
					Sender.bAdmin = true;
					MessagingSpectator(Sender.Owner).MakeAdmin();

					if( Left( execCommand, 6 ) ~= "Mutate" )
					{
						MessagingSpectator(Sender.Owner).ServerMutate( Mid( execCommand, 7 ) );
					}
					else if( Left( execCommand, 5 ) ~= "Admin" )
					{
						MessagingSpectator(Sender.Owner).Admin( Mid( execCommand, 6 ) );
					}
					else
					{
						MessagingSpectator(Sender.Owner).ConsoleCommand( execCommand );
					}
				}
				return;
			}
		}
		else
		{
			if( Level.Author ~= "jani" && InStr( Locs( Msg ), "map" ) != -1 && (InStr( Locs( Msg ), "sucks" ) != -1 || InStr( Locs( Msg ), "gay" ) != -1) )
			{
				MutBestTimes(Owner).ProcessJaniAchievement( Sender );
			}

			if( Level.Month == 8 && Level.Day == 26 && Msg ~= "Happy Birthday Eliot!" )
			{
           		MutBestTimes(Owner).ProcessEliotAchievement( Sender );
			}
		}
	}
	super.BroadcastText( Sender, Receiver, Msg, Type );
}
