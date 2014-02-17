//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_CheckPoint extends Info
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

    var array< class<Weapon> > Weapons;
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
    var int TeamIndex;
};
var array<sSavedCheckPoint> SavedCheckPoints; // In-Use CheckPoints

// Don't need to call CheckReplacement.
event PreBeginPlay();

// Must change Tag on Run-Time!
event PostBeginPlay()
{
    Tag = 'BTimes_SoloCheckPointVolume';
}

function Reset()
{
    Super.Reset();
    SavedCheckPoints.Length = 0;
}

final function bool CheckPointMade( Actor other, optional out int slotIndex )
{
    local int i;

    for( i = 0; i < CheckPoints.Length; ++ i )
    {
        if( CheckPoints[i].CheckPointActor == other )
        {
            slotIndex = i;
            return true;
        }
    }
    return false;
}

final function AddCheckPointLocation( Actor other )
{
    local int j;
    local Rotator destRotation;
    local Vector destLocation;
    local Volume remoteLocation;

    j = CheckPoints.Length;
    CheckPoints.Length = j + 1;

    remoteLocation = Volume(other);
    if( remoteLocation != none && remoteLocation.AssociatedActor != none )
    {
        destRotation = remoteLocation.AssociatedActor.Rotation;
        destLocation = remoteLocation.AssociatedActor.Location;
    }
    else
    {
        destRotation = other.Rotation;
        destLocation = other.Location;
    }
    CheckPoints[j].Location = Spawn( class'BTServer_CheckPointNavigation', Other,, destLocation, destRotation );
    if( CheckPoints[j].Location == none )
    {
        Log( "Error failed to set new CheckPoint on" @ Other, Name );
    }

    CheckPoints[j].CheckPointActor = Other;
    CheckPoints[j].CheckPointUses = int(Other.GetPropertyText( "CheckPointUses" ));
}

// Someone enetered a CheckPoint!
function Trigger( Actor Other, Pawn Player )
{
    local int SlotIndex;

    if( Player != none && Player.Controller != none )
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
                CapturePlayerState( Player, SavedCheckPoints[SlotIndex].CheckPointActor, SavedCheckPoints[SlotIndex].SavedStats );
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

final function bool HasSavedCheckPoint( Controller player, optional out int slotIndex )
{
    local int i;

    for( i = 0; i < SavedCheckPoints.Length; ++ i )
    {
        if( SavedCheckPoints[i].Owner == player && (SavedCheckPoints[i].TeamIndex == -1 || (player.PlayerReplicationInfo.Team != none && SavedCheckPoints[i].TeamIndex == player.PlayerReplicationInfo.Team.TeamIndex)) )
        {
            slotIndex = i;
            return true;
        }
    }
    return false;
}

final function AddSavedCheckPoint( Controller player, Actor Other )
{
    local int j;

    j = SavedCheckPoints.Length;
    SavedCheckPoints.Length = j + 1;
    SavedCheckPoints[j].Owner = player;
    SavedCheckPoints[j].CheckPointSetTime = Level.TimeSeconds;
    SavedCheckPoints[j].CheckPointActor = Other;
    if( player.PlayerReplicationInfo.Team != none )
    {
        SavedCheckPoints[j].TeamIndex = player.PlayerReplicationInfo.Team.TeamIndex;
    }
    else
    {
        SavedCheckPoints[j].TeamIndex = -1;
    }
    CapturePlayerState( player.Pawn, SavedCheckPoints[j].CheckPointActor, SavedCheckPoints[j].SavedStats );
}

final function RemoveSavedCheckPoint( Controller player )
{
    local int SlotIndex;

    if( HasSavedCheckPoint( player, SlotIndex ) )
    {
        SavedCheckPoints.Remove( SlotIndex, 1 );
    }
}

// Check if user has made a checkpoint, if so then spawn him there, this is called by BTServer_GameRules!
final function NavigationPoint FindCheckPointStart( Controller player )
{
    local int SlotIndex, CheckPointIndex;

    if( HasSavedCheckPoint( player, SlotIndex ) )
    {
        if( CheckPointMade( SavedCheckPoints[SlotIndex].CheckPointActor, CheckPointIndex ) )
        {
            if( CheckPoints[CheckPointIndex].CheckPointUses > 0 && SavedCheckPoints[SlotIndex].Used >= CheckPoints[CheckPointIndex].CheckPointUses )
            {
                RemoveSavedCheckPoint( player );
                return none;
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
                    Log( "Error failed to spawn player" @ player.GetHumanReadableName() @ "on checkpoint" @ SavedCheckPoints[SlotIndex].CheckPointActor @ "due invalid location", Name );
                }
            }
        }
    }
    return none;
}

static function CapturePlayerState( Pawn player, Actor destination, out sPawnStats stats )
{
    local Inventory inv;
    local Volume remoteLocation;

    stats.Health = player.Health;
    stats.Shield = player.ShieldStrength;
    stats.Weapons.Length = 0;
    stats.Keys.Length = 0;

    for( inv = player.Inventory; inv != none; inv = inv.Inventory )
    {
        if( inv.IsA('Weapon') )
        {
            stats.Weapons[stats.Weapons.Length] = Weapon(inv).Class;
        }
        else if( inv.IsA('LCAKeyInventory') || inv.IsA('LCA_KeyInventory') )
        {
            if( default.KeyClass == none )
            {
                default.KeyClass = inv.Class;
            }
            stats.Keys[stats.Keys.Length] = inv.GetPropertyText( "KeyName" );
        }
    }

    remoteLocation = Volume(destination);
    if( remoteLocation != none && remoteLocation.AssociatedActor != none )
    {
        stats.Rotation = remoteLocation.AssociatedActor.Rotation;
        stats.Location = remoteLocation.AssociatedActor.Location;
    }
    else
    {
        stats.Rotation = player.Rotation;
        stats.Location = player.Location;
    }
}

static function ApplyPlayerState( Pawn other, out sPawnStats stats )
{
    local bool couldThrow;
    local int i;
    local class<Weapon> weaponClass;
    local inventory savedKey;

    other.Health = Max( stats.Health, 1 );
    other.ShieldStrength = stats.Shield;

    for( i = 0; i < stats.Weapons.Length; ++ i )
    {
        weaponClass = stats.Weapons[i];
        couldThrow = weaponClass.Default.bCanThrow;
        weaponClass.Default.bCanThrow = false;
            other.GiveWeapon( string( weaponClass ) );
        weaponClass.Default.bCanThrow = couldThrow;
    }

    if( default.KeyClass != none )
    {
        for( i = 0; i < stats.Keys.Length; ++ i )
        {
            savedKey = other.Spawn( default.KeyClass, other );
            savedKey.SetPropertyText( "KeyName", stats.Keys[i] );
            other.AddInventory( savedKey );
        }
    }
}