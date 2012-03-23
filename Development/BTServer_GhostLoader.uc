//=============================================================================
// TODO:
//	Support multi ghosts
//	Previous record ghost
//
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GhostLoader extends Info
	transient;

struct sGhostInfo
{
	var BTClient_Ghost 		GhostPawn;
	var string 				GhostName;
	var string 				GhostChar;
	var UnrealTeamInfo 		GhostTeam;
	var int 				GhostSlot;
	var BTServer_GhostData	GhostData;
	var float				GhostMoved;
	var bool				GhostDisabled;
};

var array<sGhostInfo> Ghosts;

var const int MaxGhosts;
var const string GhostTag;

/**
 *	Load all the ghosts from data objects and assign them to the Ghosts array.
 */
final function LoadGhosts( string mapName, string ghostDataName )
{
	local int i, j;
	local BTServer_GhostData data;

	Ghosts.Length = 0;
	for( i = 0; i < MaxGhosts; ++ i )
	{
		data = Level.Game.LoadDataObject( class'BTServer_GhostData', ghostDataName $ mapName $ Eval( i > 0, "("$i$")", "" ), ghostDataName $ mapName );
		if( data == none )
			break;

		data.PackageName = ghostDataName $ mapName;

		j = Ghosts.Length;
		Ghosts.Length = j + 1;
		Ghosts[j].GhostData = data;

		if( data.bHasStoredData )
		{
			Log( "GhostData" @ data.PackageName @ "with" @ data.MO.Length @ "frames loaded", Name );
		}
		else
		{
			Log( "GhostData" @ data.PackageName @ "is empty!", Name );
		}
	}

	UpdateGhostsInfo();

	Log( "Loaded" @ Ghosts.Length @ "ghosts", Name );
}

final function CreateGhostsData( string mapName, string ghostDataName, array<string> IDs, out array<BTServer_GhostData> dataObjects )
{
	local int i;

	dataObjects.Length = IDs.Length;
	for( i = 0; i < IDs.Length; ++ i )
	{
		dataObjects[i] = Level.Game.CreateDataObject( class'BTServer_GhostData', ghostDataName $ mapName $ Eval( i > 0, "("$i$")", "" ), ghostDataName $ mapName );
		dataObjects[i].SavePlayerMoves( IDs[i] );
	}
}

final function UpdateGhostsInfo()
{
	local int i;
	local BTClient_GhostMarker Marking;

	for( i = 0; i < Ghosts.Length; ++ i )
	{
		Ghosts[i].GhostSlot = MutBestTimes(Owner).FindPlayerSlot( Ghosts[i].GhostData.PLID );
		if( Ghosts[i].GhostSlot != -1 )
		{
			Ghosts[i].GhostName = MutBestTimes(Owner).PDat.Player[Ghosts[i].GhostSlot-1].PLName $ GhostTag;
			Ghosts[i].GhostChar = MutBestTimes(Owner).PDat.Player[Ghosts[i].GhostSlot-1].PLChar;
			Ghosts[i].GhostTeam = ASGameInfo(Level.Game).Teams[ASGameInfo(Level.Game).CurrentAttackingTeam];
		}
		else
		{
			Ghosts[i].GhostName = "Unknown" $ GhostTag;
		}
	}

	if( MutBestTimes(Owner).bAddGhostTimerPaths && MutBestTimes(Owner).bSoloMap && Ghosts.Length > 0 && Ghosts[0].GhostData.MO.Length < 2000 )
	{
		for( i = 0; i < Ghosts[0].GhostData.MO.Length; ++ i )
		{
	   		if( Marking == none || VSize( Marking.Location - Ghosts[0].GhostData.MO[i].P ) > 512 )
	   		{
				Marking = Spawn( class'BTClient_GhostMarker', self,, Ghosts[0].GhostData.MO[i].P );
				Marking.MoveIndex = i;
			}
		}

		MutBestTimes(Owner).MRI.MaxMoves = Ghosts[0].GhostData.MO.Length;
	}
}

final function UpdateGhostsName( int playerSlot, string newName )
{
	local int i;

	for( i = 0; i < Ghosts.Length; ++ i )
	{
		// Ghost owner??
		if( Ghosts[i].GhostSlot-1 != playerSlot )
		{
			continue;
		}

		Ghosts[i].GhostName = newName $ GhostTag;
		if( Ghosts[i].GhostPawn != none )
		{
			Ghosts[i].GhostPawn.PlayerReplicationInfo.PlayerName = Ghosts[i].GhostName;
		}
	}
}

final function ClearGhostsData( string mapName, string ghostDataName, optional bool bCurrentMap )
{
	local int i;
	local BTServer_GhostData data;
	local BTClient_GhostMarker Marking;

	if( bCurrentMap )
	{
		GhostsKill();
		Ghosts.Length = 0;

		foreach DynamicActors( class'BTClient_GhostMarker', Marking )
		{
			Marking.Destroy();
		}

		MutBestTimes(Owner).MRI.MaxMoves = 0;
	}

	data = Level.Game.LoadDataObject( class'BTServer_GhostData', ghostDataName $ mapName $ Eval( i > 0, "("$i$")", "" ), ghostDataName $ mapName );
	if( data == none )
		return;

	Level.Game.DeletePackage( data.PackageName );

	Log( "Deleted all ghost data files for" @ mapName, Name );
}

final function SaveGhosts( string mapName, string ghostDataName )
{
	Level.Game.SavePackage( ghostDataName $ mapName );
}

final function GhostsStart()
{
	local int i;

	if( Ghosts.Length == 0 )
		return;

	for( i = 0; i < Ghosts.Length; ++ i )
	{
		if( Ghosts[i].GhostData == none )
		{
			continue;
		}

		Ghosts[i].GhostData.TZERO = 0f;
		Ghosts[i].GhostData.TONE = 0f;

	}

	SetTimer( GhostFramesPerSecond( 0 ), true );
	Timer();
}

final function GhostsStop()
{
	SetTimer( 0f, false );
}

final function GhostsRespawn()
{
	local int i;

	GhostsStop();
	for( i = 0; i < Ghosts.Length; ++ i )
	{
		if( Ghosts[i].GhostData == none )
		{
			continue;
		}

		Ghosts[i].GhostData.CurrentMove = 0;

		Ghosts[i].GhostDisabled = false;
		Ghosts[i].GhostMoved = 0f;
	}
	GhostsStart();
}

final function GhostsSpawn()
{
	GhostsStart();
}

final function GhostsKill()
{
	local int i;

	GhostsStop();
	for( i = 0; i < Ghosts.Length; ++ i )
	{
		if( Ghosts[i].GhostPawn == none )
			continue;

		if( Ghosts[i].GhostPawn.PlayerReplicationInfo != none )
		{
			Ghosts[i].GhostPawn.PlayerReplicationInfo.Destroy();
		}

		if( Ghosts[i].GhostPawn.Controller != none )
		{
			Ghosts[i].GhostPawn.Controller.Destroy();
		}

		if( Ghosts[i].GhostPawn != none )
		{
			Ghosts[i].GhostPawn.Destroy();
		}

		Ghosts[i].GhostData.Ghost = none;
	}
}

final function float GhostFramesPerSecond( int ghostSlot )
{
	return 1f / Ghosts[ghostSlot].GhostData.UsedGhostFPS;
}

event Timer()
{
	local int i;

	for( i = 0; i < Ghosts.Length; ++ i )
	{
		if( Ghosts[i].GhostDisabled || Ghosts[i].GhostData == none )
		{
			continue;
		}

		if( Ghosts[i].GhostPawn == none )
		{
			Log( "Initializing ghost for" @ Ghosts[i].GhostName );
			if( Level.TimeSeconds - MutBestTimes(Owner).MRI.MatchStartTime >= Ghosts[i].GhostData.RelativeStartTime )
			{
				Ghosts[i].GhostData.InitializeGhost( self, i );
			}
		}

		// Not yet? spawnable
		if( Ghosts[i].GhostPawn == none )
		{
			continue;
		}

		if( !Ghosts[i].GhostData.LoadNextMoveData() )
		{
			if( MutBestTimes(Owner).bSoloMap )
			{
				Ghosts[i].GhostData.CurrentMove = 0;
			}
			else
			{
				Ghosts[i].GhostDisabled = true;
			}
		}
	}
}

/*event Tick( float deltaTime )
{
	local int i;
	for( i = 0; i < Ghosts.Length; ++ i )
	{
		if( Ghosts[i].GhostDisabled || Ghosts[i].GhostData == none || Ghosts[i].GhostPawn == none )
		{
			continue;
		}
		// Smooth the movement
		Ghosts[i].GhostData.InterpolateMove();
	}
}*/

function Reset()
{
	if( MutBestTimes(Owner).bSpawnGhost )
	{
		// Kill to undo NewRound modifications
		GhostsKill();

		GhostsRespawn();
	}
}

defaultproperties
{
	MaxGhosts=3
	GhostTag="' ghost"
}
