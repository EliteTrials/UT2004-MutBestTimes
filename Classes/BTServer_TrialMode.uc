//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_TrialMode extends BTServer_Mode;

#exec obj load file="AnnouncerSexy.uax"

var() float MinRecordTime;
var() float MaxRecordTime;
var() float PointsPenalty;

function ModeReset()
{
    super.ModeReset();
    RecordByTeam = RT_None;
}

function ModePostBeginPlay()
{
    RDat.Rec[UsedSlot].AverageRecordTIme = GetAverageRecordTime( UsedSlot );
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
    super.ModeModifyPlayer( other, c, CRI );
    other.SetCollision( true, false, false );
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
            PDat.GiveCurrencyPoints( LRI.myPlayerSlot, resalcePrice );
            SendSucceedMessage( player, "You found" @ resalcePrice$"$" );
            s = "%PLAYER% found" @ resalcePrice$"$";
        }
        else
        {
            PDat.GiveItem( LRI, Store.Items[itemIndex].ID );
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