//==============================================================================
// (C) 2005-2014 Eliot All Rights Reserved
//==============================================================================
class BTClient_PremLocalMessage extends BTClient_LocalMessage;

/** Returns color A as a color tag. */
static final preoperator string $( Color A )
{
	return (Chr( 0x1B ) $ (Chr( Max( A.R, 1 )  ) $ Chr( Max( A.G, 1 ) ) $ Chr( Max( A.B, 1 ) )));
}

/** Strips all color tags from A. */
static final preoperator string %( string A )
{
	local int i;

	while( true )
	{
		i = InStr( A, Chr( 0x1B ) );
		if( i != -1 )
		{
			A = Left( A, i ) $ Mid( A, i + 4 );
			continue;
		}
		break;
	}
	return A;
}

// Make a copy of the temporary ClientMessage
static function string GetString( optional int switch, 
	optional PlayerReplicationInfo MessageReceiver, optional PlayerReplicationInfo MessageInstigator,
	optional Object ReceiverClientReplication )
{
	return Repl( 
		super.GetString(0, MessageReceiver, MessageInstigator, ReceiverClientReplication), 
		"%PLAYER%", 
		$class'HUD'.default.WhiteColor $ class'BTClient_TrialScoreBoard'.static.GetCName(MessageInstigator) $ $GetColor(0, MessageReceiver, MessageInstigator) 
	);
}

DefaultProperties
{
	Lifetime=8

	DrawColor=(R=0,G=255,B=255,A=255)
	FontSize=0

	StackMode=SM_Down
	PosY=0.15
}
