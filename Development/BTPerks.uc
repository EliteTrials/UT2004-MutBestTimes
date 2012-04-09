//=============================================================================
// Copyright 2005-2012 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTPerks extends Object within MutBestTimes
	config(BTPerks);
	
// A1233432 == myPlayerSlot
struct sPerk
{
	var string Name;
	var name ID;
	var float Points;
	var string Description;
	var class<Actor> PerkClass;
	var string Icon;
	var string On;
	
	var transient Texture CachedIcon;
};

var() globalconfig array<sPerk> Perks;

/** Necessary to load up the Perks collection. */
final static function BTPerks Load( MutBestTimes this )
{
	local BTPerks p;
	local int i;
	
	//StaticSaveConfig();
	p = new(this) default.Class;

	for( i = 0; i < p.Perks.Length; ++ i )
	{
		if( p.Perks[i].Icon != "" )
		{
			p.Perks[i].CachedIcon = Texture(DynamicLoadObject( p.Perks[i].Icon, class'Texture', true ));
		}
	}	
	return p;
}

final function bool HasPerk( BTClient_ClientReplication CRI, name perkID, optional out int perkSlot )
{
	local int rankSlot;
	
	rankSlot = GetRankSlot( CRI.A1233432 );
	if( rankSlot == -1 )
		return false;
		
	perkSlot = GetPerkSlotById( perkID );
	if( perkSlot == -1 )
		return false;
		
	if( SortedOverallTop[rankSlot].A123320 >= Perks[perkSlot].Points )
		return true;
		
	return false;
}

final function CheckPerk( BTClient_ClientReplication CRI, int perkSlot, optional Pawn other )
{
	//switch( Perks[perkSlot].ID )
	//{
		//case 'auto_press':
			//CRI.bAutoPress = true;
			//break;
	//}	
	
	if( other != none && Perks[perkSlot].PerkClass != none )
	{
		Spawn( Perks[perkSlot].PerkClass, other );
	}
}

final function CheckPlayer( BTClient_ClientReplication CRI, Pawn other )
{
	local int rankSlot;
	local int i;
	
	rankSlot = GetRankSlot( CRI.A1233432 );
	if( rankSlot == -1 )
		return;	// Not ranked
	
	for( i = 0; i < Perks.Length; ++ i )
	{
		if( Perks[i].On ~= "Spawn" )
		{
			CheckPerk( CRI, i, other );
		}
	}		
}

final function SendPerks( BTClient_ClientReplication CRI )
{
	local int i, rankSlot;
	local bool bHas;
	
	rankSlot = GetRankSlot( CRI.A1233432 );
	for( i = 0; i < Perks.Length; ++ i )
	{
		// Points
		if( rankSlot != -1 && SortedOverallTop[rankSlot].A123320 >= Perks[i].Points )
			bHas = true;
			
		CRI.ClientSendPerk( Perks[i].Name, Perks[i].Description, Perks[i].Points, Perks[i].CachedIcon, bHas );
	}
}

final function int GetPerkSlotById( name perkId )
{
	local int i;
	
	for( i = 0; i < Perks.Length; ++ i )
	{
		if( Perks[i].ID == perkId )
			return i;
	}
	return -1;
}

defaultproperties
{
	Perks(0)=(Name="AutoPress",ID=auto_press,Points=100,Description="This perks gives you AutoPress",Icon="TextureBTimes.PerkIcons.trollface")
	Perks(1)=(Name="Dodge Perks",ID=dodge_assist,Points=25,Description="This perk assists you with dodging(configurable)",Icon="TextureBTimes.PerkIcons.matrix")
}
