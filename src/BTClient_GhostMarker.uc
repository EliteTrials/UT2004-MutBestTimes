class BTClient_GhostMarker extends Actor;

var int MoveIndex;

replication
{
    reliable if( bNetInitial )
        MoveIndex;
}

defaultproperties
{
    RemoteRole=ROLE_DumbProxy
    bStatic=false
    bNoDelete=false
    Texture=none
    // bAlwaysRelevant=true
    bReplicateMovement=true

    NetUpdateFrequency=0.3
    NetPriority=0.5
}

