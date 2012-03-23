class BTClient_GhostMarker extends Actor;

var int MoveIndex;

replication
{
	reliable if( bNetInitial )
		MoveIndex;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bStatic=false
	bNoDelete=false
	Texture=none
	bAlwaysRelevant=false
	bReplicateMovement=true

	NetUpdateFrequency=1
	NetPriority=0.5
}

