class BTClient_GhostMarker extends Actor;

var int MoveIndex;
var Vector LastRenderScr;
var float LastRenderTimeX;
var float LastRecordTimeDelta;

replication
{
    reliable if( bNetInitial )
        MoveIndex;
}

defaultproperties
{
    // bHidden=true
    bStatic=false
    bNoDelete=false
    Texture=none

    bMovable=false
    RemoteRole=ROLE_DumbProxy
    bReplicateMovement=true
    bNetInitialRotation=true
    NetUpdateFrequency=1
    NetPriority=0.5
	bOnlyDirtyReplication=true

    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=false
}

