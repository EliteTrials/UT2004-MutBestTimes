class BTLevelPod extends Actor;

function UsedBy(Pawn other) {
    Log("Used by" @ other);
    if (other == none || PlayerController(other.Controller) == none) {
        return;
    }

    PlayerController(other.Controller).ClientOpenMenu(string(class'BTGUI_LevelMenu'), false);
}

simulated function RenderOverlays(Canvas c)
{
    // TODO: Render a USE ME overlay
}

defaultproperties
{
    bHidden=true
    CollisionRadius=80
    CollisionHeight=80
    bCollideActors=true
    RemoteRole=ROLE_None
}