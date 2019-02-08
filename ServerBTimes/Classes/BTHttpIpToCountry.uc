class BTHttpIpToCountry extends Info
	config(MutBestTimes);

var() const config string Host;
var() config string AccessToken;

var int PlayerIndex;
var string PlayerIp;

var protected HttpSock Sock;

delegate OnCountryCodeReceived( BTHttpIpToCountry sender, string countryCode );

final function GetCountryFromIp( int pIndex, string pIp )
{
	local string query;

	PlayerIndex = pIndex;
	PlayerIp = pIp;
	query = Repl( Repl( Host, "%IP%", PlayerIp ), "%ACCESSTOKEN%", AccessToken );

	if( MutBestTimes(Owner).bDebugIpToCountry )
	{
		Log("Fetching country for ip" @ PlayerIp @ "at" @ query);
	}

	Sock = Spawn( class'HttpSock', self );
    Sock.OnComplete = InternalOnComplete;
    Sock.OnError = InternalOnError;
	Sock.Get( query );
}

function InternalOnComplete( HttpSock sender )
{
	local string result;

	result = class'BTActivateKey'.static.FixReturnData( sender );
	if( MutBestTimes(Owner).bDebugIpToCountry )
	{
		Log( "Result:" @ result );
	}
	if( result == "Please provide a valid IP address" || result == "undefined" )
	{
		InternalOnError( sender, result );
		return;
	}
    OnCountryCodeReceived( self, result );
    Destroy();
}

function InternalOnError( HttpSock sender, string errorMessage, optional string param1, optional string param2 )
{
    Log( "Error:" @ errorMessage @ PlayerIndex @ PlayerIp );
    Destroy();
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
	Host="http://ipinfo.io/%IP%/country?token=%ACCESSTOKEN%"
}