Class BTClient_Glow Extends BonusPack.MutantGlow;

Simulated Event Tick( float DeltaTime )
{
	Super.Tick(DeltaTime);
	
	if( xPawn(Owner) == None )
	{
		Kill();
		return;
	}
} 