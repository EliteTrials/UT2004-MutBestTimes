//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class BTStore extends Object
	config(BTStore);

enum ETarget
{
	T_Pawn,
	T_Vehicle,
	T_Player
};

struct sItem
{
	var() string Name;
	var() string ID;
	var() string Type;
	var() string ItemClass;
	var() int Cost;
	var() string Desc;
	var() string IMG;
	var() bool bAdminGiven;
	var() bool bPassive;
	var() string Conditions;
	var() array<string> Vars;

	/** Additional dropchance added on top of the default dropchance. */
	var() private float DropChance;
	
	var() enum EAccess
	{
		/** Default. Standard buying. */
		Buy,
		
		/** Has zero cost. */
		Free,
		
		/** Requires admin activation or anything below this. */
		Admin,
		
		/** The item is for premium players only. */
		Premium,
		
		/** The item is exclusive. */
		Private,

		/** The item can only be found as a drop. */
		Drop,
	} Access;

	var() ETarget ApplyOn;

	var transient Material CachedIMG;
	var transient string CachedCategory;
	var transient class<Actor> CachedClass;
};

var() array<sItem> Items;
var() globalconfig array<sItem> CustomItems;
var() globalconfig float DefaultDropChance;

struct sCategory
{
	/** Name of the category. */
	var string Name;

	/** All types that belong in the category. */
	var array<string> Types;
};

var() globalconfig array<sCategory> Categories;

struct sMapLocker
{
	var string ItemID;
	var string MapName;
};

var() globalconfig array<sMapLocker> LockedMaps;

final function bool Evaluate( MutBestTimes BT, int itemSlot )
{
	local array<string> conditions;
	local string prop, val;
	local int i, colon, not;
	local bool breverse;

	if( Items[itemSlot].Conditions == "" )
	{
		return true;
	}

	Split( Items[itemSlot].Conditions, "?", conditions );
	if( conditions.Length == 0 )
	{
		conditions[conditions.Length] = Items[itemSlot].Conditions;
	}

	for( i = 0; i < conditions.Length; ++ i )
	{
		colon = InStr( conditions[i], ":" );
		if( colon == -1 )
		{
			not = InStr( conditions[i], "!" );
			if( not == -1 )
			{
				continue;
			}

			colon = not;
		}

		breverse = not != -1;

		prop = Left( conditions[i], colon );
		val = Mid( conditions[i], colon );
		switch( prop )
		{
			case "game":
           		if( (breverse && BT.Level.Game.GameName ~= val) || (!breverse && !(BT.Level.Game.GameName ~= val)) )
           		{
					return false;
           		}
           		break;

           	case "map":
           		if( (breverse && BT.CurrentMapName ~= val) || (!breverse && !(BT.CurrentMapName ~= val)) )
           		{
					return false;
           		}
           		break;
		}
	}
	return true;
}

final static function BTStore Load()
{
	local BTStore this;
	local int i, j;

	StaticSaveConfig();
	this = new(none) default.Class;

	if( this.CustomItems.Length > 0 )
	{
		j = this.Items.Length;
		this.Items.Insert( j, this.CustomItems.Length );
		for( i = 0; i < this.CustomItems.Length; ++ i )
		{
			this.Items[j + i] = this.CustomItems[i];
			this.Items[j + i].CachedIMG = Material(DynamicLoadObject( this.Items[j + i].IMG, class'Material', true ));
		}
	}
	return this;
}

final function Cache()
{
	local int i, j;
	local string outCategoryName;
	
	for( i = 0; i < Items.Length; ++ i )
	{
		Items[i].CachedIMG = Material(DynamicLoadObject( Items[i].IMG, class'Material', true ));
		// Cache the cateogry in which each item resists.
		// (This operation is quite expensive, takes about 100ms per request(300+ items).
		for( j = 0; j < Categories.Length; ++ j )
		{
			outCategoryName = Categories[j].Name; 
			if( ItemIsInCategory( Items[i].Type, outCategoryName ) )
			{				
				Items[i].CachedCategory $= "&"$Categories[j].Name;
			}			
		}		

		if( Items[i].bAdminGiven )
		{
			Items[i].Access = Admin;
		}
	}	
}

final function int FindCategory( string categoryName )
{
	local int i;

	for( i = 0; i < Categories.Length; ++ i )
	{
		if( Categories[i].Name ~= categoryName )
		{
			return i;
		}
	}
	return -1;
}

final function bool ItemIsInCategory( string itemType, out string categoryName )
{
	local int categoryIndex, i;
	local int asterik;

	categoryIndex = FindCategory( categoryName );
	if( categoryIndex == -1 )
		return false;
		
	if( categoryName == "" || (categoryName ~= "All" || categoryName ~= "Admin") )
	{
		return true;
	}
	else if( ((itemType == "" || !HasCategory( itemType )) && categoryName ~= "Other") )
	{
		categoryName = "Other";
		return true;
	}

	for( i = 0; i < Categories[categoryIndex].Types.Length; ++ i )
	{
		asterik = InStr( Categories[categoryIndex].Types[i], "*" );
		if( 
			Categories[categoryIndex].Types[i] ~= itemType 
			|| 
			(
				asterik != -1 
				&& 
				Left( Categories[categoryIndex].Types[i], asterik ) ~= Left( itemType, asterik )
			) 
		)
		{
			return true;
		}
	}
	return false;
}

final function bool HasCategory( string itemType )
{
	local int i, j;
	local int asterik;

	for( i = 0; i < Categories.Length; ++ i )
	{
		for( j = 0; j < Categories[i].Types.Length; ++ j )
		{
			asterik = InStr( Categories[i].Types[j], "*" );
			if( Categories[i].Types[j] ~= itemType || 
				(asterik != -1 && Left( Categories[i].Types[j], asterik ) ~= Left( itemType, asterik )) )
				return true;
		}
	}
}

final function int FindItemByID( string id )
{
	local int i;

	for( i = 0; i < Items.Length; ++ i )
	{
		if( Items[i].ID ~= id )
		{
			return i;
		}
	}
	return -1;
}

final function float GetItemDropChance( int itemIndex )
{
	return DefaultDropChance + Items[itemIndex].DropChance;
}

final function int GetRandomItem()
{
	local int randomIndex, tries;

tryagain:
	randomIndex = Rand(Items.Length);
	if( Items[randomIndex].Access != Buy || Items[randomIndex].Access == Drop )
	{
		if( tries >= Items.Length )
		{
			return -1;
		}
		++ tries;
		goto tryagain;
	}
	return randomIndex;
}

final function ModifyPawn( Pawn other, BTServer_PlayersData data, BTClient_ClientReplication CRI )
{
	ApplyOwnedItems( data, other, CRI.myPlayerSlot, ETarget.T_Pawn );
}

final function ModifyVehicle( Vehicle other, BTServer_PlayersData data, BTClient_ClientReplication CRI )
{
	ApplyOwnedItems( data, other, CRI.myPlayerSlot, ETarget.T_Vehicle );
}

final function ModifyPlayer( PlayerController other, BTServer_PlayersData data, BTClient_ClientReplication CRI )
{
	local LinkedReplicationInfo customRep;

	ApplyOwnedItems( data, other, CRI.myPlayerSlot, ETarget.T_Player );
	// Is active?
	if( data.UseItem( CRI.myPlayerSlot, "MNAFAccess" ) )
	{
		for( customRep = other.PlayerReplicationInfo.CustomReplicationInfo; customRep != none; customRep = customRep.NextReplicationInfo )
		{
			if( customRep.IsA('MNAFLinkedRep') )
			{
				customRep.SetPropertyText( "bIsUnique", "1" );
				break;
			}
		}
	}
}

private final function ApplyOwnedItems( BTServer_PlayersData data, Actor other, int playerSlot, ETarget target )
{
	local int i, j, itemSlot, curType;
	local bool bIsKnown;
	local array<string> addedTypes;

 	j = data.Player[playerSlot].Inventory.BoughtItems.Length;
 	for( i = 0; i < j; ++ i )
 	{
 		if( !data.Player[playerSlot].Inventory.BoughtItems[i].bEnabled )
 		{
 			continue;
 		}

  		itemSlot = FindItemByID( data.Player[playerSlot].Inventory.BoughtItems[i].ID );
 		if( itemSlot != -1 && Items[itemSlot].ApplyOn == target )
 		{
 			if( Items[itemSlot].Type != "" )
			{
	        	for( curType = 0; curType < addedTypes.Length; ++ curType )
	        	{
			  		if( addedTypes[curType] == Items[itemSlot].Type )
			  		{
						bIsKnown = true;
			  			break;
			  		}
	        	}

	        	if( bIsKnown )
	        	{
	        		bIsKnown = false;
	        		continue;
	        	}
	        	addedTypes[addedTypes.Length] = Items[itemSlot].Type;
	        }
	        ActivateItem( other, itemSlot, playerSlot );
		}
	}
}

private final function ActivateItem( Actor other, int itemSlot, int playerSlot )
{
	local class<Actor> itemClass;
	local Actor itemObject;

	//FullLog( "ActivateItem(" $ other $ "," $ itemSlot $ "," $ playerSlot $")" );
	if( Items[itemSlot].ItemClass != "" )
	{
		if( Items[itemSlot].CachedClass == none )
		{
			Items[itemSlot].CachedClass = class<Actor>(DynamicLoadObject( Items[itemSlot].ItemClass, class'Class', true ));
		}
		
		itemClass = Items[itemSlot].CachedClass;
		if( itemClass == none )
		{
			Log( "Failed to load ItemClass" @ Items[itemSlot].ItemClass @ "for" @ Items[itemSlot].ID );
			return;
		}
		
		// Apply the vars on the pawn's instance if the item's class is a pawn(HACK)
		if( itemClass == class'Pawn' )
		{
			itemObject = other;
		}
		else
		{
			itemObject = other.Spawn( itemClass, other,, other.Location, other.Rotation );
			// Failed to spawn or it destroyed itself in BeginPlay.
			if( itemObject == none )
			{
				return;
			}
		}
		SetVarsFor( itemObject, itemSlot );
	}
}

private final function SetVarsFor( Actor other, int itemSlot )
{
	local array<string> s;
	local int i;
	
	for( i = 0; i < Items[itemSlot].Vars.Length; ++ i )
	{
		Split( Items[itemSlot].Vars[i], ":", s );	
		switch( Locs(s[0]) )
		{
			case "overlaymat":
				other.SetOverlayMaterial( Material(DynamicLoadObject( s[1], class'Material', true )), 9999.00, true );
				break;
				
			default:
				other.SetPropertyText( s[0], s[1] );
				break;
		}	
	}
}

final function bool CanBuyItem( BTServer_PlayersData data, BTClient_ClientReplication CR, int itemSlot, out string msg )
{
	if( data.HasItem( CR.myPlayerSlot, Items[itemSlot].Id ) )
	{
		msg = "You already own" @ Items[itemSlot].Name;
		return false;
	}
		   		
	if( PlayerReplicationInfo(CR.Owner).bAdmin /*|| CR.Level.NetMode == NM_Standalone*/ )
		return true;
		
	switch( Items[itemSlot].Access )
	{
		case Buy:	
			if( !data.HasCurrencyPoints( CR.myPlayerSlot, Items[itemSlot].Cost ) )
			{
				msg = "You do not have enough currency points to buy" @ Items[itemSlot].Name;
				return false;
			}		
			break;
			
		case Free:
			break;
			
		case Admin:
			msg = "Sorry" @ Items[itemSlot].Name @ "can only be given by admins!";
			return false;
			break;
			
		case Premium:
			if( !data.Player[CR.myPlayerSlot].bHasPremium )
			{
				msg = "Sorry" @ Items[itemSlot].Name @ "is only for admins and premium players!";
				return false;
			}
			break;
			
		case Private:
			msg = "Sorry" @ Items[itemSlot].Name @ "is an exclusive item!";
			return false;
			break;

		case Drop:
			msg = "Sorry" @ Items[itemSlot].Name @ "is drop only item!";
			return false;
			break;
	}
	return true;
}

defaultproperties
{
	DefaultDropChance=0.5

	/** All items. */
	//Categories(0)=(Name="All")

	/** Any item with no type. */
	Categories(1)=(Name="Other")

	/** Any adminonly item. */
	Categories(2)=(Name="Admin")
	Categories(3)=(Name="Premium")

	/** Any item type of Trailer. */
	Categories(4)=(Name="Trailers",Types=("Trailer","FeetTrailer"))

	/** Any item that is an upgrade e.g. EXP boost etc. */
	Categories(5)=(Name="Upgrades",Types=("UP_*"))

	Items(0)=(Name="Trailer",ID="Trailer",Access=Premium,Type="FeetTrailer",Desc="Customizable(Colors,Texture) trailer")
	Items(1)=(Name="MNAF Plus",ID="MNAFAccess",Type="UP_MNAF",Access=Premium,Desc="Gives you access to MNAF member options",ApplyOn=T_Player)
	Items(2)=(Name="+100% EXP Bonus",ID="exp_bonus_1",Type="UP_EXPBonus",Cost=200,Desc="Get +100% EXP bonus for the next 4 play hours!",bPassive=true,IMG="TextureBTimes.StoreIcons.EXPBOOST_IMAGE",DropChance=0.3,ApplyOn=T_Player)
	Items(3)=(Name="+200% EXP Bonus",ID="exp_bonus_2",Type="UP_EXPBonus",Access=Premium,Desc="Get +200% EXP bonus for the next 24 play hours!",bPassive=true,IMG="TextureBTimes.StoreIcons.EXPBOOST_IMAGE2",ApplyOn=T_Player)
	Items(4)=(Name="+200% Currency Bonus",ID="cur_bonus_1",Type="UP_CURBonus",Access=Premium,Desc="Get +200% Currency bonus for the next 24 play hours!",bPassive=true,IMG="TextureBTimes.StoreIcons.CURBOOST_IMAGE",ApplyOn=T_Player)
	Items(5)=(Name="+100% Dropchance Bonus",ID="drop_bonus_1",Type="UP_DROPBonus",Desc="Get +100% Dropchance bonus for the next 24 play hours!",bPassive=true,Dropchance=1.0,Cost=400,ApplyOn=T_Player)
	
	Items(6)=(Name="Grade F Skin",Id="skin_grade_f",Type="Skin",itemClass="Engine.Pawn",cost=300,Desc="Official Wire Skin F",img="TextureBTimes.GradeF_FB",Vars=("OverlayMat:TextureBTimes.GradeF_FB"))
	Items(7)=(Name="Grade E Skin",Id="skin_grade_e",Type="Skin",itemClass="Engine.Pawn",cost=600,Desc="Official Wire Skin E",img="TextureBTimes.GradeE_FB",Vars=("OverlayMat:TextureBTimes.GradeE_FB"))
	Items(8)=(Name="Grade D Skin",Id="skin_grade_d",Type="Skin",itemClass="Engine.Pawn",cost=900,Desc="Official Wire Skin D",img="TextureBTimes.GradeD",Vars=("OverlayMat:TextureBTimes.GradeD"))
}
