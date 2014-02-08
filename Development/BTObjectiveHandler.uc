class BTObjectiveHandler extends Actor;

var GameObjective Target;

function Initialize( GameObjective obj )
{
    local Actor fagTrigger;

    if( obj == none )
    {
        Log( "Error, failed to mimic an ProximityObjective!", Name );
        Destroy();
        return;
    }

    Target = obj;
    Target.SetCollision( false, false, false );

    SetCollisionSize( Target.CollisionRadius, Target.CollisionHeight );

    // FAG MAPPER ALERT!
    if( TriggeredObjective(obj) != none )
    {
        // Hopefully fagtrigger isnt a ScriptedTrigger.
        fagTrigger = TriggeredObjective(obj).FindTrigger();
        if( fagTrigger == none )
        {
            // fagMapper doesnt know how to use TriggeredObjectives -__-
            return; // game will be broken but who cares!
        }

        // Hijack the Event =D!
        fagTrigger.Event = 'OBJECTIVEHACK';
        Tag = 'OBJECTIVEHACK';

        Log( "Initialized BTObjectiveHandler to handle TriggeredObjectives!", Name );
    }
}

event Trigger( Actor other, Pawn eventInstigator )
{
    if( eventInstigator == none )
    {
        // WHAT THE FUCK HE CHEATS!
        return;
    }

    // Simulate touch!
    Touch( eventInstigator );
}

event Touch( Actor actor )
{
    if( Pawn(actor) == none )
        return;

    if( IsRelevant( Pawn(actor), true ) )
    {
        Target.DisableObjective( Pawn(actor) );
    }
}

// Copy of the ProximityObjective relevant check, except this one does not care about the instigators team.
function bool IsRelevant( Pawn P, bool bAliveCheck )
{
    if ( !Target.IsActive() || !UnrealMPGameInfo(Level.Game).CanDisableObjective( Target ) )
        return false;

    if( ProximityObjective(Target) != none )
    {
        if( !ClassIsChildOf(P.Class, ProximityObjective(Target).ConstraintPawnClass) )
            return false;

        Target.Instigator = ProximityObjective(Target).FindInstigator( P );

        if ( bAliveCheck )
        {
            if ( Target.Instigator.Health < 1 || Target.Instigator.bDeleteMe || !Target.Instigator.IsPlayerPawn() )
                return false;
        }

        if ( Target.bBotOnlyObjective && (PlayerController(Target.Instigator.Controller) != None) )
            return false;
    }

    return true;
}

defaultproperties
{
    // Mimic the collision settings of an actual ProximityObjective
    bCollideActors=true
    bShouldBaseAtStartup=false
    bIgnoreEncroachers=true
    bCollideWhenPlacing=false
    bOnlyAffectPawns=true

    bHidden=true
}
