//=============================================================================
// Copyright 2018 Eliot Van Uytfanghe. All Rights Reserved.
// A pawn to be used for rendering on a GUI.
//=============================================================================
class BTGUI_Pawn extends xPawn;

#exec obj load file="SkaarjAnims.ukx"

function SetupPreview(Pawn other)
{
    if (other != none) {
        LinkMesh(other.Mesh);
        Skins = other.Skins;
    }
    SetRotation(Owner.Rotation);
    LoopAnim('RunF', 1.0/Level.TimeDilation);
}

function ClearPreview()
{
    local int i;

    for (i = 0; i < Attached.Length; ++ i) {
        if (Attached[i] == none) continue;
        Attached[i].Destroy();
    }
}

event Tick(float Delta)
{
	local rotator NewRot;

	NewRot = Rotation;
	NewRot.Yaw += Delta * 20000/Level.TimeDilation;
	SetRotation(NewRot);
}

event Destroyed()
{
    super.Destroyed();
    ClearPreview();
}

defaultproperties
{
	bAlwaysTick=true

    bCanBeDamaged=false
    bCollideActors=false
    bCollideWorld=false
    bBlockActors=false
    bProjTarget=false
	RemoteRole=ROLE_None

    bOwnerNoSee=false
    bHidden=true
    bUnlit=true
    AmbientGlow=200
    DrawScale=1.0

    Mesh=SkeletalMesh'SkaarjAnims.Skaarj_Skel'

    Physics=PHYS_Rotating
    RotationRate=(Yaw=2048,Roll=0,Pitch=0)
    bServerMoveSetPawnRot=false
    bUseDynamicLights=false
    MaxLights=0

    GruntVolume=0.0
    FootstepVolume=0.0
}