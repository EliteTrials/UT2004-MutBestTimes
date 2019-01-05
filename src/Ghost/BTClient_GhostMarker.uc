class BTClient_GhostMarker extends Actor;

var int MoveIndex;

replication
{
    reliable if( bNetInitial )
        MoveIndex;
}

defaultproperties
{
    bStatic=false
    bNoDelete=false
    Texture=none
    bReplicateMovement=true
    bNetInitialRotation=true
    RemoteRole=ROLE_DumbProxy
    NetUpdateFrequency=0.3
    NetPriority=0.5
}

