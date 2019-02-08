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
    local Pawn other;
    local TeamInfo team;
    local int oldTeamIndex;

    other = Pawn(actor);
    if( other == none )
        return;

    team = other.GetTeam();
    if( team == none )
        return;

    oldTeamIndex = Target.DefenderTeamIndex;
    Target.DefenderTeamIndex = 1 - team.TeamIndex;
    if( ProximityObjective(Target) != none && ProximityObjective(Target).IsRelevant( other, true ) )
    {
        if( Target.IsA('LCA_KeyObjective') || Target.IsA('LCAKeyObjective') )
        {
            Target.UsedBy( other );
        }
        else
        {
            Target.DisableObjective( other );
        }
    }
    else
    {
        Target.DisableObjective( other );
    }
    // Let's just keep the defender index, it may be nice to see it swap colors :)
    // Target.DefenderTeamIndex = oldTeamIndex;
    Target.Reset();
    Target.DefenderTeamIndex = team.TeamIndex;

    if( ASGameInfo(Level.Game) != none )
    {
        ASGameInfo(Level.Game).LastDisabledObjective = none;
    }
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
