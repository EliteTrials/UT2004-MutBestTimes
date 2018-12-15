class BTItem_ChoppedLeg extends ReplicationInfo;

var() const float BoneScale;
var() const name BoneName;

var protected Pawn Pawn;

replication
{
	reliable if (bNetInitial && (Role == ROLE_Authority))
		Pawn;
}

event PreBeginPlay()
{
	Pawn = Pawn(Owner);
	NetUpdateTime = Level.TimeSeconds - 1;
	if (Level.NetMode == NM_StandAlone)
	{
		PostNetReceive();
	}
}

simulated event PostNetReceive()
{
    if (Pawn == none) {
        Destroy();
        return;
    }

    if (Level.NetMode != NM_DedicatedServer) {
        ClientInitialize();
        Destroy();
    }
}

event Tick( float deltaTime )
{
    if (Pawn == none) {
        Destroy();
    }
}

simulated function ClientInitialize()
{
    Pawn.SetBoneScale( 0, BoneScale, BoneName );
}

defaultproperties
{
    BoneScale=0.0
    BoneName=rthigh
    bNetTemporary=true
}