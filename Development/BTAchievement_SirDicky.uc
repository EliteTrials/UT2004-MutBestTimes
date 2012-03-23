class BTAchievement_SirDicky extends Triggers;

event Touch( Actor A )
{
	super.Touch( A );

	if( xPawn(A) == none )
		return;

 	MutBestTimes(Owner).ProcessSirDickyAchievement( Pawn(A) );
}

defaultproperties
{
	CollisionHeight=64
	CollisionRadius=64
}
