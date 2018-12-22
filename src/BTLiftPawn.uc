class BTLiftPawn extends ReplicationInfo;

event PostBeginPlay()
{
    Instigator = xPawn(Owner);
    if (Instigator != none) {
        Instigator.LifeSpan = xPawn(Instigator).DeResTime;
    }
}

simulated event PostNetBeginPlay()
{
    StartLifting(xPawn(Instigator));
}

private simulated function StartLifting(xPawn pawn)
{
    if (pawn == none) {
        Destroy();
        return;
    }
    Pawn.SetPhysics(PHYS_KarmaRagdoll);
    Pawn.bSkeletized = true; // Set true so that PlayDying will not trigger a death sound.
    Pawn.PlayDying(class'BTDamTypeLiftPawn', vect(0,0,0));
    Pawn.StartDeRes();
    Pawn.Gasp();
    Destroy(); // I am no longer needed.
}

defaultproperties
{
    LifeSpan=5
    bNetTemporary=true
    bReplicateInstigator=true
}