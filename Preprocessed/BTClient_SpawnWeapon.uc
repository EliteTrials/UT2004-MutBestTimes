class BTClient_SpawnWeapon extends Weapon
    hidedropdown;

simulated function Fire( float F )
{
    if( Level.NetMode != NM_DedicatedServer )
    {
        Instigator.Controller.ConsoleCommand( "mutate SetClientSpawn" );
    }
}

simulated function AltFire( float F )
{
    if( Level.NetMode != NM_DedicatedServer )
    {
        Instigator.Controller.ConsoleCommand( "mutate DeleteClientSpawn" );
    }
}

simulated function bool ConsumeAmmo( int Mode, float load, optional bool bAmountNeededIsMax )
{
    return false;
}

simulated function bool HasAmmo()
{
    return true;
}

defaultproperties
{
    InventoryGroup=10
    bCanThrow=false

    FireModeClass(0)=class'SniperZoom'
    FireModeClass(1)=class'SniperZoom'

    IconMaterial=Material'HudContent.Generic.HUD'
    IconCoords=(X1=0,Y1=0,X2=2,Y2=2)

    Mesh=mesh'NewWeapons2004.NewTransLauncher_1st'
    AttachmentClass=class'TransAttachment'
    DrawScale=0.8
    BobDamping=1.8

    DisplayFOV=60.0

    IdleAnimRate=0.25
    PutDownAnim=PutDown
    SelectAnim=Select

    PlayerViewOffset=(X=28.5,Y=12,Z=-12)
    SmallViewOffset=(X=38,Y=16,Z=-16)
    PlayerViewPivot=(Pitch=1000,Roll=0,Yaw=400)
    SelectSound=Sound'WeaponSounds.Translocator_change'
    SelectForce="Translocator_change"
    CenteredOffsetY=0

    HudColor=(r=0,g=0,b=255,a=255)

    Priority=1
    CustomCrosshair=2
    CustomCrosshairTextureName="Crosshairs.Hud.Crosshair_Cross3"
    CustomCrosshairColor=(r=0,g=0,b=255,a=255)
    CustomCrosshairScale=1.0

    CenteredRoll=0
    Skins(0)=FinalBlend'EpicParticles.NewTransLaunBoltFB'
    Skins(1)=Material'WeaponSkins.NEWTranslocatorTEX'
    Skins(2)=Material'WeaponSkins.NEWTranslocatorPUCK'
    Skins(3)=FinalBlend'WeaponSkins.NEWTransGlassFB'

    ItemName="Spawn Manager"
}
