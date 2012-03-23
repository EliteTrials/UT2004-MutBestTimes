//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_CheckPoint extends Actor
	notplaceable;

struct sCheckPoint
{
	var NavigationPoint Location;
	var Actor CheckPointActor;

	var int CheckPointUses;
};
var array<sCheckPoint> CheckPoints; // CheckPoint Volumes array

var private class<Inventory> KeyClass;

struct sPawnStats
{
	var int Health;
	var int Shield;

	var array< Class<Weapon> > Weapons;
	var array<string> Keys;

	var vector Location;
	var rotator Rotation;
};

struct sSavedCheckPoint
{
	var Controller Owner;
	var float CheckPointSetTime;
	var Actor CheckPointActor;

	var sPawnStats SavedStats;

	var int Used;
};
var array<sSavedCheckPoint> SavedCheckPoints; // In-Use CheckPoints

// Don't need to call CheckReplacement.
Event PreBeginPlay();

// Must change Tag on Run-Time!
Event PostBeginPlay()
{
	Tag = 'BTimes_SoloCheckPointVolume';
}

Function Reset()
{
	Super.Reset();
	SavedCheckPoints.Length = 0;
}

Final Function bool CheckPointMade( Actor Other, optional out int SlotIndex )
{
	local int CurCP;

	for( CurCP = 0; CurCP < CheckPoints.Length; ++ CurCP )
	{
		if( CheckPoints[CurCP].CheckPointActor == Other )
		{
			SlotIndex = CurCP;
			return True;
		}
	}
	return False;
}

Final Function AddCheckPointLocation( Actor Other )
{
	local int j;

	j = CheckPoints.Length;
	CheckPoints.Length = j + 1;
	CheckPoints[j].Location = Spawn( class'BTServer_CheckPointNavigation', Other,, Other.Location, Other.Rotation );
	if( CheckPoints[j].Location == none )
	{
		Log( "Error failed to set new CheckPoint on" @ Other, Name );
	}

	CheckPoints[j].CheckPointActor = Other;
	CheckPoints[j].CheckPointUses = int(Other.GetPropertyText( "CheckPointUses" ));
}

// Someone enetered a CheckPoint!
Function Trigger( Actor Other, Pawn Player )
{
	local int SlotIndex;

	// Don't allow fakers!
	if( (Other.IsA('LCA_BTSoloCheckPointVolume') || Other.IsA('LCA_CheckPointVolume')) && Player != None && Player.Controller != None )
	{
		// Look if the checkpoint location is created!
		if( !CheckPointMade( Other ) )
		{
			// Store that volume and create a location for it
			AddCheckPointLocation( Other );
		}

		// Players with a 'Client Spawn' and defenders should not be able to set checkpoints
		if( Player.LastStartSpot.IsA( 'BTServer_ClientStartPoint' ) || Player.GetTeamNum() != ASGameInfo(Level.Game).CurrentAttackingTeam )
		{
			xPawn(Player).ClientMessage( "'CheckPoint' Denied" );
			return;
		}

		// Player stuff...
		if( HasSavedCheckPoint( Player.Controller, SlotIndex ) )
		{
			// User made a new checkpoint?
			if( SavedCheckPoints[SlotIndex].CheckPointActor != Other )
			{
				xPawn(Player).ClientMessage( "'CheckPoint' Updated" );

				// Update!
				SavedCheckPoints[SlotIndex].CheckPointActor = Other;
				SavedCheckPoints[SlotIndex].CheckPointSetTime = Level.TimeSeconds;

				SaveStatsFor( Player, SlotIndex );

				MutBestTimes(Owner).NotifyCheckPointChange( Player.Controller );
			}
			return;
		}
		else
		{
			xPawn(Player).ClientMessage( "'CheckPoint' Set" );

			// Create a checkpoint for this player
			AddSavedCheckPoint( Player.Controller, Other );

			MutBestTimes(Owner).NotifyCheckPointChange( Player.Controller );
			return;
		}
	}
}

Final Function bool HasSavedCheckPoint( Controller C, optional out int SlotIndex )
{
	local int CurCP;

	for( CurCP = 0; CurCP < SavedCheckPoints.Length; ++ CurCP )
	{
		if( SavedCheckPoints[CurCP].Owner == C )
		{
			SlotIndex = CurCP;
			return True;
		}
	}
	return False;
}

Final Function AddSavedCheckPoint( Controller C, Actor Other )
{
	local int j;

	j = SavedCheckPoints.Length;
	SavedCheckPoints.Length = j + 1;
	SavedCheckPoints[j].Owner = C;
	SavedCheckPoints[j].CheckPointSetTime = Level.TimeSeconds;
	SavedCheckPoints[j].CheckPointActor = Other;

	SaveStatsFor( C.Pawn, j );
}

Final Function SaveStatsFor( Pawn Other, int SlotIndex )
{
	local inventory Inv;

	SavedCheckPoints[SlotIndex].SavedStats.Health = Other.Health;
	SavedCheckPoints[SlotIndex].SavedStats.Shield = Other.ShieldStrength;

	SavedCheckPoints[SlotIndex].SavedStats.Weapons.Length = 0;
	SavedCheckPoints[SlotIndex].SavedStats.Keys.Length = 0;

	for( Inv = Other.Inventory; Inv != None; Inv = Inv.Inventory )
	{
		if( Inv.IsA('Weapon') )
		{
			SavedCheckPoints[SlotIndex].SavedStats.Weapons[SavedCheckPoints[SlotIndex].SavedStats.Weapons.Length] = Weapon(Inv).Class;
		}
		else if( Inv.IsA('LCAKeyInventory') || Inv.IsA('LCA_KeyInventory') )
		{
			if( KeyClass == none )
			{
				KeyClass = Inv.Class;
			}
			SavedCheckPoints[SlotIndex].SavedStats.Keys[SavedCheckPoints[SlotIndex].SavedStats.Keys.Length] = Inv.GetPropertyText( "KeyName" );
		}
	}

	SavedCheckPoints[SlotIndex].SavedStats.Rotation = Other.Rotation;
	SavedCheckPoints[SlotIndex].SavedStats.Location = Other.Location;
}

Final Function RemoveSavedCheckPoint( Controller C )
{
	local int SlotIndex;

	if( HasSavedCheckPoint( C, SlotIndex ) )
	{
		SavedCheckPoints.Remove( SlotIndex, 1 );
	}
}

// Check if user has made a checkpoint, if so then spawn him there, this is called by BTServer_GameRules!
Final Function NavigationPoint FindCheckPointStart( Controller Player )
{
	local int SlotIndex, CheckPointIndex;

	if( HasSavedCheckPoint( Player, SlotIndex ) )
	{
		if( CheckPointMade( SavedCheckPoints[SlotIndex].CheckPointActor, CheckPointIndex ) )
		{
			if( CheckPoints[CheckPointIndex].CheckPointUses > 0 && SavedCheckPoints[SlotIndex].Used >= CheckPoints[CheckPointIndex].CheckPointUses )
			{
				RemoveSavedCheckPoint( Player );
				return None;
			}
			else
			{
				++ SavedCheckPoints[SlotIndex].Used;
				// Change the PlayerStart rotation, location instead of the pawn so that other scripts know where the user actually spawned
				// e.g. that playerspawn effect etc
				if( CheckPoints[CheckPointIndex].Location != none )
				{
					CheckPoints[CheckPointIndex].Location.SetRotation( SavedCheckPoints[SlotIndex].SavedStats.Rotation );
					CheckPoints[CheckPointIndex].Location.SetLocation( SavedCheckPoints[SlotIndex].SavedStats.Location );
					return CheckPoints[CheckPointIndex].Location;
				}
				else
				{
					Log( "Error failed to spawn player" @ Player.GetHumanReadableName() @ "on checkpoint" @ SavedCheckPoints[SlotIndex].CheckPointActor @ "due invalid location", Name );
				}
			}
		}
	}
	return None;
}

Final Function RestoreStats( Pawn Other, int SlotIndex )
{
	local bool b;
	local int CurWeap, NumWeaps;
	local class<Weapon> WeapClass;
	local inventory Key;

	Other.Health = SavedCheckPoints[SlotIndex].SavedStats.Health;
	Other.ShieldStrength = SavedCheckPoints[SlotIndex].SavedStats.Shield;

	NumWeaps = SavedCheckPoints[SlotIndex].SavedStats.Weapons.Length;
	for( CurWeap = 0; CurWeap < NumWeaps; ++ CurWeap )
	{
		// Reference shortcut
		WeapClass = SavedCheckPoints[SlotIndex].SavedStats.Weapons[CurWeap];

		// Backup
		b = WeapClass.Default.bCanThrow;
		WeapClass.Default.bCanThrow = False;

		Other.GiveWeapon( string( WeapClass ) );

		// Restore
		WeapClass.Default.bCanThrow = b;
	}

	if( KeyClass != None )
	{
		NumWeaps = SavedCheckPoints[SlotIndex].SavedStats.Keys.Length;
		for( CurWeap = 0; CurWeap < NumWeaps; ++ CurWeap )
		{
			Key = Spawn( KeyClass, Other );
			Key.SetPropertyText( "KeyName", SavedCheckPoints[SlotIndex].SavedStats.Keys[CurWeap] );
			Other.AddInventory( Key );
		}
	}
}

DefaultProperties
{
	bStatic=False
	bNoDelete=False
}
