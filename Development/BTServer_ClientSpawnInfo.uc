//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_ClientSpawnInfo extends Info;

#include DEC_Structs.uc

var BTimesMute M;

// Don't notify mutators, no need and happens too much because players die so often
event PreBeginPlay();

event Tick( float dt )
{
	local GameObjective Obj;
	local Triggers T;
	local int i, j;

	if( xPawn(Owner) == None )
	{
		Destroy();
		return;
	}

	j = M.Objectives.Length;
	for( i = 0; i < j; ++ i )
	{
		if( xPawn(Owner) == None )	// Secure
		{
			Destroy();
			return;
		}

		Obj = M.Objectives[i];
		if( Obj != None && Obj.bActive )
		{
			if( VSize( Owner.Location - Obj.Location ) <= (Obj.CollisionRadius + Owner.CollisionRadius)*4
			&& Obj.Location.Z - Owner.Location.Z <= (Obj.CollisionHeight + Owner.CollisionHeight)*4 )
			{
				xPawn(Owner).ClientMessage( "You were killed by this Objective. Delete your 'Client Spawn' to continue" );
				xPawn(Owner).Suicide();
				break;
			}
		}
	}

	if( M.bTriggersKillClientSpawnPlayers || M.bAlwaysKillClientSpawnPlayersNearTriggers )
	{
		j = M.Triggers.Length;
		for( i = 0; i < j; ++ i )
		{
			if( xPawn(Owner) == None )	// Secure
			{
				Destroy();
				return;
			}

			T = M.Triggers[i];
			if( T != None && T.bBlockNonZeroExtentTraces )
			{
				if( VSize( Owner.Location - T.Location ) <= (T.CollisionRadius + Owner.CollisionRadius)*4
				&& T.Location.Z - Owner.Location.Z <= (T.CollisionHeight + Owner.CollisionHeight)*4 )
				{
					xPawn(Owner).ClientMessage( "You were killed by this Trigger. Delete your 'Client Spawn' to continue" );
					xPawn(Owner).Suicide();
					break;
				}
			}
		}
	}
}
