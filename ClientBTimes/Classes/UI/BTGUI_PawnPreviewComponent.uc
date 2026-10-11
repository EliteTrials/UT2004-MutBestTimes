//=============================================================================
// Copyright 2018 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGUI_PawnPreviewComponent extends GUIComponent;

var() editinline BTGUI_Pawn Pawn3D;
var() Vector Pawn3DPivot;

event Free()
{
    DestroyPawn3D();
    super.Free();
}

function InitPawn3D()
{
    if (Pawn3D != none) {
        return;
    }

    Pawn3D = PlayerOwner().Spawn(class'BTGUI_Pawn', PlayerOwner());
    if (Pawn3D != none) {
        Pawn3D.SetupPreview(PlayerOwner().Pawn);
    }
    else {
        Warn("Could not spawn BTGUI_Pawn!!!");
    }
}

function DestroyPawn3D()
{
    if (Pawn3D != none) {
        Pawn3D.Destroy();
    }
    Pawn3D = none;
}

function OnInternalRender( Canvas C )
{
    local Vector camLoc, x, y, z;
    local Rotator camRot;

    if (Pawn3D == none) {
        return;
    }

    C.GetCameraLocation( camLoc, camRot );
    GetAxes(camRot, x, y, z);
    Pawn3D.PrePivot = Pawn3DPivot.X*x + Pawn3DPivot.Y*y + Pawn3DPivot.Z*z;
    Pawn3D.SetLocation( camLoc );

    C.SetOrigin(ActualLeft(), ActualTop());
    C.SetPos( 0, 0 );
    C.SetClip(ActualWidth(), ActualHeight());
    C.DrawActorClipped( Pawn3D, false, C.OrgX, C.OrgY, C.ClipX, C.ClipY, true, 90 );
    return;
}

function ApplyPlayerItem( BTClient_ClientReplication.sPlayerItemClient item )
{
    local Actor previewActor;
    local Class<Actor> previewClass;

    if (item.itemClass == "") {
        return;
    }

    Pawn3D.ClearPreview();
    if (item.itemClass == "Engine.Pawn") {
        Pawn3D.SetOverlayMaterial( item.IconTexture, 999999, true );
    } else {
        previewClass = class<Actor>(DynamicLoadObject(item.itemClass, class'class', true));
        if (previewClass != none) {
            previewActor = Pawn3D.Spawn(previewClass, Pawn3D);
            if (previewActor != none) {
                Pawn3D.AttachToBone(previewActor, 'head');
            }
        }
    }
}

defaultproperties
{
	Pawn3DPivot=(X=80,Y=0,Z=0)
    OnRender=OnInternalRender
}
