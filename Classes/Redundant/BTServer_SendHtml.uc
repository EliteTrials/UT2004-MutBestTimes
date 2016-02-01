Class BTServer_SendHtml Extends TcpLink
	Config(BTServer_SendHtml);

var()
	config
	string
	URL,
	User,
	Password,
	Page;

var()
	config
	bool
	bEnabled;

//var()
//	config
//	int
//	WebPort;

var int
	CurPacket,
	TotPackets;

const MaxPacketLength = 250;

var array<string> PacketsToSend;

Event Resolved( IpAddr Addr )
{
	//Log( "LinkState:"$string( LinkState ), Name );								// 0.

	/*Addr.Port = WebPort;
	if( BindPort( WebPort ) == 0 )
	{
		Log( "Could not BindPort "$WebPort, Name );
		Destroy();
		return;
	}*/

	Open( Addr );
	if( !IsConnected() )
	{
		Log( "Could not Connect to "$URL, Name );
		Destroy();
		return;
	}
}

Event Opened()
{
	local int i, j;

	Log( "Opened", Name );

	Log( "Sending Login Info", Name );

	SendText( "USER"@User );

	SendText( "PASS"@Password );

	SendText( "ACCT"@User@Password );

	SendText( "SIZE /"$Page$".html" );

	SendText( "TYPE A" );

	// Specifies the host and port to which the server should connect for the next file transfer. This is interpreted as IP address a1.a2.a3.a4, port p1*256+p2.
	j = BindPort( 0, True );
	while( j > 256 )
	{
		i++;
		j-=256;
	}
	SendText( "PORT 255,255,255,255,"$i$","$j );

	SetTimer( 0.025, True );
}

Event Timer()
{
	SendText( PacketsToSend[CurPacket] );
	CurPacket ++;

	Log( string( float( CurPacket ) / float( TotPackets ) * 100 )$"% Complete", Name );

	if( CurPacket == TotPackets )
	{
		SendText( "STOR /"$Page$".html" );
		Log( "Sending Completed", Name );
		SetTimer( 0, False );
		Log( "Timer:Close", Name );
		Close();
	}
}

Event Closed()
{
	Log( "Closed", Name );

	Destroy();
}

Event ResolveFailed()
{
	Log( "ResolveFailed", Name );
	Log( "LastError:"$string( GetLastError() ), Name );
}

Function SendPacketsToFTP( array<string> ThePackets )
{
	local string MegaString;
	local int i,j;

	j = ThePackets.Length;
	For( i=0; i<j; i++ )
		MegaString = MegaString$Chr(10)$ThePackets[i];
	j = Len(MegaString);

	i = 0;
	While( j>MaxPacketLength )
	{
		PacketsToSend.Length = i+1;
		PacketsToSend[i] = Left(MegaString,MaxPacketLength);
		MegaString = Mid(MegaString,MaxPacketLength);
		i++;
		j-=MaxPacketLength;
	}
	PacketsToSend.Length = i+1;
	PacketsToSend[i] = MegaString;
	i++;
	TotPackets = i;
	CurPacket = 0;

	ReceiveMode = RMODE_Event;
	LinkMode = MODE_Line;
	Resolve( URL );
}

DefaultProperties
{
	Page="WebBTimes"
}
