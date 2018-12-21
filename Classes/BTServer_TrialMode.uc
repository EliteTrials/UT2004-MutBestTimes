//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_TrialMode extends BTServer_Mode;

#exec obj load file="AnnouncerSexy.uax"

var() float MinRecordTime;
var() float MaxRecordTime;
var() float PointsPenalty;

protected function InitializeMode()
{
    super.InitializeMode();

    UsedSlot = RDat.FindRecord( CurrentMapName );
    if( UsedSlot == -1 )
    {
        UsedSlot = RDat.CreateRecord( CurrentMapName, RDat.MakeCompactDate( Level ) );
    }

    FullLog( "Found map index:"$UsedSlot$" for "$CurrentMapName );
    RDat.Rec[UsedSlot].LastPlayedDate = RDat.MakeCompactDate( Level );
}

function ModeMatchStarting()
{
    local array<string> inGhostIds;

    super.ModeMatchStarting();

    if( bSpawnGhost && GhostManager == none )
    {
        FullLog( "Loading Ghost Playback data" );
        GhostManager = Spawn( class'BTGhostManager', Outer );
        if (MRI.MapLevel != none) {
            RDatManager.GetTopPlayerGhostIds( MRI.MapLevel.MapIndex, inGhostIds );
            GhostManager.SpawnGhosts( MRI.MapLevel, inGhostIds );
        }
    }
}

function ModeReset()
{
    super.ModeReset();
    RecordByTeam = RT_None;
}

function bool ModeValidatePlayerStart( Controller player, PlayerStart start )
{
    local int i, j;
    local string newPawn;
    local byte teamIndex;

    if( player.PlayerReplicationInfo.Team != none )
    {
        teamIndex = player.PlayerReplicationInfo.Team.TeamIndex;
    }
    else
    {
        teamIndex = 255;
    }
    if( ASGameInfo(Level.Game) != none )
    {
        if( !start.bEnabled )
        {
            return false;
        }

        j = ASGameInfo(Level.Game).SpawnManagers.Length;
        for( i = 0; i < j; ++ i )
        {
            if( ASGameInfo(Level.Game).SpawnManagers[i] == none )
                continue;

            if( ASGameInfo(Level.Game).SpawnManagers[i].ApprovePlayerStart( start, teamIndex, player ) )
            {
                newPawn = ASGameInfo(Level.Game).SpawnManagers[i].PawnClassOverride( player, start, teamIndex );
                if( newPawn != "" )
                    ASPlayerReplicationInfo(player.PlayerReplicationInfo).PawnOverrideClass = newPawn;

                return true;
            }
        }
        return j == 0;
    }
    else
    {
        if( start.TeamNumber == teamIndex )
        {
            return true;
        }
    }
    return false;
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
    local int i;

    super.ModeModifyPlayer( other, c, CRI );
    other.SetCollision( true, false, false );

    //other.GiveWeapon( string(class'BTClient_SpawnWeapon') );
    i = GetClientSpawnIndex( c );
    if( i != -1 )
    {
        PimpClientSpawn( i, other );
        CRI.ClientSpawnPawn = other;
    }
    else
    {
        // Keys are lost after a dead!, except not if your're using a CheckPoint!
        if( bKeyMap && ASPlayerReplicationInfo(other.PlayerReplicationInfo) != none && !other.LastStartSpot.IsA( CheckPointNavigationClass.Name ) )
        {
            ASPlayerReplicationInfo(other.PlayerReplicationInfo).DisabledObjectivesCount = 0;
            ASPlayerReplicationInfo(other.PlayerReplicationInfo).DisabledFinalObjective = 0;
        }
    }
}

function PostRestartRound()
{
    super.PostRestartRound();
    ClearClientStarts();
}

function PlayerMadeRecord( PlayerController player, int rankSlot, int rankUps )
{
    super.PlayerMadeRecord( player, rankSlot, rankUps );
    PerformItemDrop( player, float(rankUps) );
}

function PlayerCompletedObjective( PlayerController player, BTClient_ClientReplication LRI, float score )
{
    super.PlayerCompletedObjective( player, LRI, score );
    // FullLog( "Objective accomplished" );
    if( Level.TimeSeconds - LRI.LastDropChanceTime >= DropChanceCooldown )
    {
        // FullLog( "Performing drop chance" );
        PerformItemDrop( player, score/10 );
        LRI.LastDropChanceTime = Level.TimeSeconds;
    }
}

function ProcessPlayerRecord( PlayerController player, BTClient_ClientReplication CRI, BTClient_LevelReplication myLevel, float playTime )
{
    super.ProcessPlayerRecord( player, CRI, myLevel, playTime );

    NotifyNewRecord( CRI.myPlayerSlot, myLevel.MapIndex, playTime );
}

function PerformItemDrop( PlayerController player, float bonus )
{
    local int itemIndex;
    local float chance, resalcePrice;
    local string itemName;
    local BTClient_ClientReplication LRI;
    local string s;

    LRI = GetRep( player );
    if( LRI == none )
    {
        return;
    }

    itemIndex = Store.GetRandomItem();
    if( itemIndex == -1 )
    {
        return;
    }
    chance = GetItemDropChance( LRI, itemIndex, bonus );
    if( chance >= FRand()*100 )
    {
        itemName = Store.Items[itemIndex].Name;
        if( PDat.HasItem( LRI.myPlayerSlot, Store.Items[itemIndex].ID ) )
        {
            resalcePrice = Store.GetResalePrice( itemIndex );
            PDat.GiveCurrencyPoints( Outer, LRI.myPlayerSlot, resalcePrice );
            SendSucceedMessage( player, "You found" @ resalcePrice$"$" );
            s = "%PLAYER% found" @ resalcePrice$"$";
        }
        else
        {
            PDatManager.GiveItem( LRI, Store.Items[itemIndex].ID );
            SendSucceedMessage( player, "You found an item" @ Store.Items[itemIndex].Name$"!" );
            s = "%PLAYER% has found an item" @ itemName$"!";
        }
        BroadcastLocalMessage( player, class'BTClient_RewardLocalMessage', s );
        BroadcastSound( Sound'AnnouncerSEXY.GodLike', SLOT_Misc );
    }
}

function float GetItemDropChance( BTClient_ClientReplication LRI, int itemIndex, float bonus )
{
    local float dropChance;

    dropChance = DropChanceBonus + Store.GetItemDropChance( itemIndex );
    if( LRI.bIsPremiumMember )
    {
        dropChance += 0.05;
    }
    if( PDat.HasItem( LRI.myPlayerSlot, "drop_bonus_1" ) )
    {
        dropChance += 0.05;
    }
    return dropChance;
}

function bool ChatCommandExecuted( PlayerController sender, string command, string value )
{
    local bool bmissed;

    switch( command )
    {
        case "cp":
            Mutate( "clientspawn", sender );
            break;

        case "setcp":
            Mutate( "setclientspawn", sender );
            break;

        case "nocp":
            Mutate( "deleteclientspawn", sender );
            break;

        default:
            bmissed = true;
            break;
    }

    if( !bmissed )
        return true;

    return super.ChatCommandExecuted( sender, command, value );
}

defaultproperties
{
    ConfigClass=class'BTServer_TrialModeConfig'
    PointsPenalty=0.25
}