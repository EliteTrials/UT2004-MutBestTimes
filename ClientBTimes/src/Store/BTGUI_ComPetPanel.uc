class BTGUI_ComPetPanel extends GUIPanel;

#exec obj load file="SkaarjAnims.ukx"

var() editinline SpinnyWeap SpinnyDude;
var() vector SpinnyDudeOffset;
var() rotator SpinnyDudeRot;

var automated GUIImage PetWorld;
var automated GUISectionBackground PetBox;

var BTGUI_PlayerInventory mInv;

event Free()
{
    if( SpinnyDude != none )
    {
        SpinnyDude.Destroy();
        SpinnyDude = none;
    }
    mInv = none;
    super.Free();
}

function InitComponent( GUIController InController, GUIComponent InOwner )
{
    super.InitComponent( InController, InOwner );
    SpinnyDude = PlayerOwner().Spawn( class'SpinnySkel' );
    SpinnyDude.SetDrawType( DT_Mesh );
    SpinnyDude.bPlayRandomAnims = true;
    SpinnyDude.SetDrawScale( 0.3 );
    SpinnyDude.bHidden = true;

    SpinnyDude.LinkMesh( SkeletalMesh'SkaarjAnims.Skaarj_Skel' );
    SpinnyDude.LoopAnim( 'Idle_Rest', 1.0 );
}

function bool DrawSpinnyDude( Canvas C )
{
    local vector CamPos, X, Y, Z;
    local rotator CamRot, rot;

    C.GetCameraLocation( CamPos, CamRot );
    GetAxes( CamRot, X, Y, Z );

    SpinnyDude.SetLocation( CamPos + (SpinnyDudeOffset.X * X) + (SpinnyDudeOffset.Y * Y) + (SpinnyDudeOffset.Z * Z) );
    rot = CamRot;
    rot.Pitch = -rot.Pitch;
    rot.Roll = -(rot.Pitch*0.5);
    rot = rot + SpinnyDudeRot;
    SpinnyDude.SetRotation( rot );

    C.DrawActor( SpinnyDude, false, true, 90.0 );
    return false;
}

defaultproperties
{
	SpinnyDudeOffset=(X=75,Y=-40,Z=-15)
	SpinnyDudeRot=(Yaw=25000)

    begin object class=GUISectionBackground name=oBox
        Caption="Yorick"
        bScaleToParent=true
        bBoundToParent=true
        WinHeight=1.0
        WinLeft=0.0
        WinTop=0.00
        WinWidth=1.0
        HeaderBar=none
        HeaderBase=none
    end object
    PetBox=oBox

    begin object class=GUIImage name=oRender
        bScaleToParent=true
        bBoundToParent=true
        WinHeight=1.0
        WinLeft=0
        WinTop=0
        WinWidth=1.0
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        OnDraw=DrawSpinnyDude
    end object
    PetWorld=oRender
}
