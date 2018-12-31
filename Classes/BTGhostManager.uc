//=============================================================================
// Copyright 2005-2016 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGhostManager extends Info
    dependson(BTGhostSaver);

const GHOST_OBJECT_NAME = "BTGhost";

var() const int MaxGhosts;
var() const string GhostTag;
var() const string GhostDataPackagePrefix;
var() const class<BTGhostData> GhostDataClass;
var() const class<BTGhostPlayback> GhostPlaybackClass;

// The ghosts that we are currently playing, if a ghost is missing from this array, then it will be deleted from the package on the next save.
var array<BTGhostPlayback> Ghosts, CustomGhosts;
var BTGhostSaver Saver;

// Pending packages that have became dirty and need to be saved.
var private array<string> DirtyPackageNames;
var private MutBestTimes BT;

event PreBeginPlay()
{
    BT = MutBestTimes(Owner);
    Saver = Spawn( class'BTGhostSaver', Owner );
    Saver.Manager = self;
}

private function string GetPackageNameFor( string mapName, optional string ghostId )
{
    return Eval(ghostId != "", GhostDataPackagePrefix $ mapName $ "_" $ ghostId, GhostDataPackagePrefix $ mapName);
}

// Remove obsolete ghosts from the loaded ghost packages.
final function SqueezeGhosts( optional bool byRank )
{
    local int i, ghostRank;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        // Only erase low ranked ghosts!
        if( byRank )
        {
            ghostRank = GetGhostRank( Ghosts[i] );
            if( ghostRank != 0 && ghostRank <= MaxGhosts )
            {
                continue;
            }
        }

        BT.FullLog( "Removed old ghost data from map" @ Ghosts[i].GhostMapName @ "belonging to" @ Ghosts[i].GhostData.PLID );
        Ghosts[i].Destroy();
        Ghosts.Remove( i --, 1 ); // This ghost's data will be deleted on the next saving event.
    }
}

// 0 = no rank
private function int GetGhostRank( BTGhostPlayback playback )
{
    local int ghostRank, mapIndex;

    mapIndex = BT.RDat.FindRecord( playback.GhostMapName );
    if( mapIndex == -1 ) // To delete or keep for nostalgie?
        return 0;

    ghostRank = BT.RDat.GetPlayerRank( mapIndex, playback.GhostSlot );
    return ghostRank;
}

private function ConvertGhosts( BTClient_LevelReplication myLevel, string packageName )
{
    local Object data;
    local BTGhostData ghostData, newGhostData;
    local string mapName, newPackageName;
    local int playerIndex, recordIndex;
    local bool isDirty;

    mapName = BT.RDat.Rec[myLevel.MapIndex].TMN;

    // Dirty hack to prevent the engine from crashing in case the package is nonexistent!
    Level.Game.CreateDataObject( class'Object', "ConvertGhosts", packageName );
    foreach Level.Game.AllDataObjects( GhostDataClass, data, packageName )
    {
        ghostData = BTGhostData(data);
        if( ghostData == none || ghostData.MO.Length == 0 || ghostData.PLID == "" )
            continue;

        newPackageName = GetPackageNameFor( mapName, ghostData.PLID );
        newGhostData = Level.Game.CreateDataObject( class'BTGhostData', GHOST_OBJECT_NAME, newPackageName );
        newGhostData.MO = ghostData.MO;
        newGhostData.UsedGhostFPS = ghostData.UsedGhostFPS;
        newGhostData.DataVersion = ghostData.DataVersion;
        newGhostData.PLID = ghostData.PLID;
        newGhostData.RelativeStartTime = ghostData.RelativeStartTime;

        playerIndex = BT.PDat.FindPlayerByID(newGhostData.PLID);
        if (playerIndex != -1) {
            recordIndex = BT.RDat.FindRecordSlot(myLevel.MapIndex, playerIndex+1);
            if (recordIndex != -1) {
                BT.RDat.Rec[myLevel.MapIndex].PSRL[recordIndex].Flags = BT.RDat.Rec[myLevel.MapIndex].PSRL[recordIndex].Flags | 0x08/*RFLAG_GHOST*/;

                Level.Game.SavePackage( newPackageName );
                isDirty = true;
            }
            AddGhost( CreateGhostPlayback( newGhostData, mapName ) );
        }
    }

    if (isDirty) {
        Level.Game.DeletePackage( packageName );
        BT.SaveRecords();
    }
}

/**
 *  Loads and spawns all ghosts for the specified map.
 *  Can load multiple map instances.
 */
final function SpawnGhosts( BTClient_LevelReplication myLevel, array<string> ghostNames )
{
    local int i;
    local BTGhostData ghostData;
    local string mapName;
    local string ghostPackageName;
    local Manifest manifest;

    mapName = BT.RDat.Rec[myLevel.MapIndex].TMN;
    if (MapHasGhosts(mapName)) {
        // Don't spawn the ghosts multiple times.
        return;
    }

    // Lookup a manifest of old ghost files for conversion.
    manifest = Level.Game.GetSavedGames();
    if (manifest != none) {
        ghostPackageName = GetPackageNameFor( mapName );
        for (i = 0; i < manifest.ManifestEntries.Length; ++ i) {
            if (manifest.ManifestEntries[i] ~= ghostPackageName) {
                ConvertGhosts(myLevel, ghostPackageName);
            }
        }
    }

    for (i = 0; i < ghostNames.Length; ++ i) {
        ghostPackageName = GetPackageNameFor( mapName, ghostNames[i] );
        ghostData = Level.Game.LoadDataObject( GhostDataClass, GHOST_OBJECT_NAME, ghostPackageName );
        AddGhost( CreateGhostPlayback( ghostData, mapName, true ) );
    }
}

private function bool MapHasGhosts( string mapName )
{
    local int i;

    for (i = 0; i < Ghosts.Length; ++ i) {
        if (Ghosts[i].GhostMapName == mapName) {
            return true;
        }
    }
    return false;
}

private function AddGhost( BTGhostPlayback playback )
{
    Ghosts[Ghosts.Length] = playback;
}

private function BTGhostPlayback CreateGhostPlayback( BTGhostData data, string mapName, optional bool instantPlay, optional bool isCustom )
{
    local int playerSlot;
    local int ghostRank;
    local BTGhostPlayback playback;

    playerSlot = BT.FindPlayerSlot( data.PLID );

    playback = Spawn( GhostPlaybackClass, Owner );
    playback.GhostMapName = mapName;
    playback.GhostPackageName = GetPackageNameFor( mapName, data.PLID );
    playback.GhostData = data;
    playback.GhostSlot = playerSlot;
    if( playback.GhostSlot != -1 )
    {
        playback.GhostName = BT.PDat.Player[playerSlot-1].PLName $ GhostTag @ "in" @ mapName;
        playback.GhostChar = BT.PDat.Player[playerSlot-1].PLChar;
    }
    else
    {
        playback.GhostName = "Unknown" $ GhostTag;
    }

    if( isCustom )
    {
        return playback;
    }

    BT.FullLog( "Loaded ghost" @ playback.GhostData.PLID @ "for" @ mapName @ "with" @ data.MO.Length @ "frames" );
    ghostRank = GetGhostRank( playback );
    if( ghostRank == 1 )
    {
        playback.InstallMarkers( instantPlay/**replace old*/ );
    }
    playback.OnGhostEndPlay = InternalOnGhostEndPlay;
    if( instantPlay )
    {
        playback.StartPlay();
    }
    return playback;
}

private function AddDirtyPackage( string packageName )
{
    local int i;

    for( i = 0; i < DirtyPackageNames.Length; ++ i )
    {
        if( DirtyPackageNames[i] == packageName )
            return;
    }
    DirtyPackageNames[DirtyPackageNames.Length] = packageName;
}

/** Returns an active BTGhostData object or will load one when not found. */
final function BTGhostData GetGhostData( string mapName, string ghostId, optional bool bNew )
{
    local int i;
    local BTGhostData ghostData;
    local string ghostPackageName;

    ghostPackageName = GetPackageNameFor( mapName, ghostId );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostPackageName == ghostPackageName
            && Ghosts[i].GhostData != none
            && Ghosts[i].GhostData.PLID == ghostId )
        {
            return Ghosts[i].GhostData;
        }
    }

    ghostData = Level.Game.LoadDataObject( GhostDataClass, GHOST_OBJECT_NAME, ghostPackageName );
    if (bNew) {
        if (ghostData == none) {
            return CreateGhostData(mapName, ghostId);
        } else {
			ghostData.Init(); // new version
			ghostData.MO.Length = 0;
			ghostData.bIsDirty = true;
        }
    }
    return ghostData;
}

private function BTGhostData CreateGhostData( string mapName, string ghostId )
{
    local BTGhostData data;
    local string ghostPackageName;

    ghostPackageName = GetPackageNameFor( mapName, ghostId );
    data = Level.Game.CreateDataObject( GhostDataClass, GHOST_OBJECT_NAME, ghostPackageName );
    if( data != none )
    {
        data.Init();
        data.bIsDirty = true;
        AddDirtyPackage( ghostPackageName );
    }
    return data;
}

final function bool DeleteGhostsPackage( string mapName, string ghostId )
{
    local string ghostPackageName;

    ghostPackageName = GetPackageNameFor( mapName, ghostId );
    return Level.Game.DeletePackage( ghostPackageName );
}

// Note: CustomGhosts array doesn't require updates because such ghosts are non spectatable!
final function UpdateGhostsName( int playerSlot, string newName )
{
    local int i;

    // BT.FullLog( "Ghost::UpdateGhostsName" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        // Ghost owner??
        if( Ghosts[i].GhostSlot-1 != playerSlot )
        {
            continue;
        }

        Ghosts[i].GhostName = newName $ GhostTag @ "in" @ Ghosts[i].GhostMapName;
        if( Ghosts[i].Controller != none )
        {
            Ghosts[i].Controller.PlayerReplicationInfo.PlayerName = Ghosts[i].GhostName;
        }
    }
}

final function ClearGhostsData( string mapName, optional bool bCurrentMap )
{
    local int i;
    local string ghostPackageName;
    local Manifest manifest;

    BT.FullLog( "Deleting all ghost data files for" @ mapName );
    if( bCurrentMap )
    {
        for( i = 0; i < Ghosts.Length; ++ i )
        {
            if( Ghosts[i].GhostMapName != mapName )
            {
                continue;
            }
            Ghosts[i].Destroy();
            Ghosts.Remove( i --, 1 );
        }
    }

    manifest = Level.Game.GetSavedGames();
    if (manifest != none) {
        ghostPackageName = GetPackageNameFor( mapName );
        for (i = 0; i < manifest.ManifestEntries.Length; ++ i) {
            if (Left(manifest.ManifestEntries[i], Len(ghostPackageName)) ~= ghostPackageName) {
                Level.Game.DeletePackage( manifest.ManifestEntries[i] );
            }
        }
    }
}

final function BTGhostPlayback SpawnCustomGhostFor( string mapName, string ghostId, PlayerController c )
{
    local int i;
    local BTGhostData data;
    local BTGhostPlayback playback;

    for( i = 0; i < CustomGhosts.Length; ++ i )
    {
        if( CustomGhosts[i].CustomController == c )
        {
            return CustomGhosts[i];
        }
    }

    data = GetGhostData( mapName, ghostId );
    if( data == none )
        return none;

    playback = CreateGhostPlayback( data, mapName, true, true );
    if( playback == none )
        return none;

    playback.CustomController = c;
    playback.RestartPlay();
    CustomGhosts[CustomGhosts.Length] = playback;
    return playback;
}

final function RestartGhostFor( Controller c )
{
    local int i;

    for( i = 0; i < CustomGhosts.Length; ++ i )
    {
        if( CustomGhosts[i].CustomController == c )
        {
            CustomGhosts[i].RestartPlay();
            break;
        }
    }
}

final function bool KillGhostFor( Controller c )
{
    local int i;

    for( i = 0; i < CustomGhosts.Length; ++ i )
    {
        if( CustomGhosts[i].CustomController == c )
        {
            CustomGhosts[i].Destroy();
            CustomGhosts.Remove( i, 1 );
            return true;
        }
    }
    return false;
}

// Respawn all ghosts once the ghosts have reached the end of their playback.
final function InternalOnGhostEndPlay( BTGhostPlayback playback )
{
    local int i;

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostMapName == playback.GhostMapName && !Ghosts[i].GhostDisabled )
            return;
    }

    for( i = 0; i < Ghosts.Length; ++ i )
    {
        if( Ghosts[i].GhostMapName != playback.GhostMapName )
            continue;

        Ghosts[i].RestartPlay();
    }
}

final function SaveDirtyPackages()
{
    local int i;

    for(i = 0; i < DirtyPackageNames.Length; ++ i) {
        Level.Game.SavePackage( DirtyPackageNames[i] );
    }
    DirtyPackageNames.Length = 0;
}

final function OnGhostSaved( BTGhostSaver.sGhostInfo ghostInfo )
{
    local int i;
    local int ghostRank, mapIndex;

    AddDirtyPackage( GetPackageNameFor( ghostInfo.MapName, ghostInfo.GhostId ) );
    if( ghostInfo.ExistingData )
    {
        for( i = 0; i < Ghosts.Length; ++ i )
        {
            if( Ghosts[i].GhostData == ghostInfo.Data )
            {
                // Install our new markers
                if( GetGhostRank( Ghosts[i] ) == 1 )
                {
                    Ghosts[i].InstallMarkers( true );
                }
                Ghosts[i].RestartPlay();
                break;
            }
        }
        return;
    }

    // Spawn this ghost immediately if owner is ranked top 3
    mapIndex = BT.RDat.FindRecord( ghostInfo.MapName );
    ghostRank = BT.RDat.GetPlayerRank( mapIndex, ghostInfo.PlayerIndex + 1 );
    if( ghostRank <= MaxGhosts )
    {
        SqueezeGhosts( true );
        AddGhost( CreateGhostPlayback( ghostInfo.Data, ghostInfo.MapName, true ) );
    }
}

function Reset()
{
    local int i;

    super.Reset();

    // BT.FullLog( "Ghost::GhostsRespawn" );
    for( i = 0; i < Ghosts.Length; ++ i )
    {
        Ghosts[i].RestartPlay();
    }
}

defaultproperties
{
    MaxGhosts=3
    GhostTag="' ghost"
    GhostDataPackagePrefix="BTGhost_"
    GhostDataClass=class'BTGhostData'
    GhostPlaybackClass=class'BTGhostPlayback'
}
