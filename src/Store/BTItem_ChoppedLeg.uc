class BTItem_ChoppedLeg extends ReplicationInfo;

var float BoneScale;
var name BoneName;

simulated event PostNetBeginPlay()
{
    local xPawn Pawn;
    local emitter fx;

    Pawn = xPawn(Owner);
    if (Pawn == none) {
        Destroy();
        return;
    }

    if (Level.NetMode != NM_DedicatedServer) {
        Pawn.SetBoneScale( 0, BoneScale, BoneName );
        fx = Spawn(class'xEffects.Spiral', Owner,, Pawn.Location, Pawn.Rotation);
        fx.AttachToBone(Owner, 'rcalf');
        Destroy();
    }
}

event Tick( float deltaTime )
{
    if (Owner == none) {
        Destroy();
    }
}

defaultproperties
{
    BoneScale=0.0
    BoneName=rthigh
    bNetTemporary=true
    bSkipActorPropertyReplication=false
    bReplicateMovement=false
}