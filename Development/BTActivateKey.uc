//=============================================================================
// Copyright 2005-2012 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTActivateKey extends Info	
	config(MutBestTimes);

var() const string Host;
var() const string VerifySerialAction;
var() const string ConsumeSerialAction;
var PlayerController Requester;

var transient string PerformedGet;

var struct sSerial
{
	var int Id;
	var int Token;
	var bool bConsumed;
	var bool Valid;
	var string Type; 
	var string Code;
} Serial;

#exec obj load file="LibHTTP4.u" package="ServerBTimes"

var HttpSock Sock;

function SendRequest( string location )
{
	if( Sock == none )
	{
		Sock = Spawn( class'HttpSock', self );
	}
	
	Sock.OnComplete = OnGetComplete;
	//Level.Game.Broadcast( self, "Get:"@location );
	Sock.Get( location );
}

final function VerifySerial( string serial )
{	
	local string verifyLocation;
	
	verifyLocation = Repl( Host, "%ACTION%", Repl( VerifySerialAction, "%SERIAL%", serial ) );
	PerformedGet = "VerifySerial";
	SendRequest( verifyLocation );
}

final function ConsumeSerial()
{
	local string consumeLocation;
	local string parsedAction;
	
	parsedAction = Repl( ConsumeSerialAction, "%ID%", Serial.Id );
	parsedAction = Repl( parsedAction, "%TOKEN%", Serial.Token );
	parsedAction = Repl( parsedAction, "%GUID%", Requester.GetPlayerIdHash() );
	
	consumeLocation = Repl( Host, "%ACTION%", parsedAction );
	PerformedGet = "ConsumeSerial";
	SendRequest( consumeLocation );
}

function OnGetComplete( HttpSock sender )
{
	local string result;		
	
	//Level.Game.Broadcast( self, "OnGetComplete" );
	result = FixReturnData( sender );
	//Level.Game.Broadcast( self, "Result:"@result );
	switch( PerformedGet )
	{
		case "VerifySerial":
			//Log( "Get:VerifySerial" );
			SetPropertyText( "Serial", result );
			//Log( "ParsedResult:"@GetPropertyText("Serial") );
			MutBestTimes(Owner).KeyVerified( self );
			break;
			
		case "ConsumeSerial":
			MutBestTimes(Owner).KeyConsumed( self, result );
			break;
	}
}

final static function string FixReturnData( HttpSock socket )
{
	local int i;
	local string result;
	
	for( i = 0; i < socket.ReturnData.Length; ++ i )
	{
		result $= socket.ReturnData[i];
	}
	return result;
}

event Destroyed()
{
	super.Destroyed();
	if( Sock != none )
	{
		Sock.Destroy();
	}
}

defaultproperties
{	
	//Host="http://localhost/Eliot/apps/%ACTION%"
	Host="http://eliotvu.com/apps/%ACTION%"
	VerifySerialAction="verifyserial/%SERIAL%"
	ConsumeSerialAction="consumeserial/%ID%/%TOKEN%/%GUID%"
}
