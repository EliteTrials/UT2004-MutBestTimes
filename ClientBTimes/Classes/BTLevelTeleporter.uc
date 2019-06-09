class BTLevelTeleporter extends Teleporter;

simulated function bool Accept( actor incoming, Actor source )
{
	local xPawn other;
	local BTClient_ClientReplication rep;

	if( !super.Accept( incoming, source ) )
	{
		return false;
	}

	other = xPawn(incoming);
	if( other != none )
	{
		if( Role == ROLE_Authority )
		{
			rep = class'BTClient_ClientReplication'.static.GetRep( PlayerController(other.Controller) );
			if( rep != none ) // not a bt player
			{
				BTClient_LevelReplication(Owner).PlayerEnterLevel( rep );
			}
		}
		return true;
	}
	return false;
}

defaultproperties
{
	bAlwaysRelevant=true
    RemoteRole=ROLE_DumbProxy
	bNoDelete=false
	bStatic=false
	bChangesYaw=false

    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=false
}