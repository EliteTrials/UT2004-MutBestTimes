//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe and Marco Hulden. All Rights Reserved.
//=============================================================================
class BTStore extends Object
	config(BTStore);

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

	var transient Material CachedIMG;
};

var() array<sItem> Items;
var() globalconfig array<sItem> CustomItems;

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

		/*for( i = 0; i < this.Items.Length; ++ i )
		{
			Log( i @ this.Items[i].Name );
		}*/
	}

	for( i = 0; i < this.Items.Length; ++ i )
	{
		this.Items[i].CachedIMG = Material(DynamicLoadObject( this.Items[i].IMG, class'Material', true ));
	}

	return this;
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

final function bool ItemIsInCategory( string itemType, string categoryName )
{
	local int categoryIndex, i;
	local int asterik;

	categoryIndex = FindCategory( categoryName );
	if( categoryIndex == -1 )
		return false;

	if( categoryName == "" || (categoryName ~= "All" || categoryName ~= "Admin")
	|| ((itemType == "" || !HasCategory( itemType )) && categoryName ~= "Other") )
		return true;

	for( i = 0; i < Categories[categoryIndex].Types.Length; ++ i )
	{
		asterik = InStr( Categories[categoryIndex].Types[i], "*" );
		if( Categories[categoryIndex].Types[i] ~= itemType || (asterik != -1 && Left( Categories[categoryIndex].Types[i], asterik ) ~= Left( itemType, asterik )) )
			return true;
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
			if( Categories[i].Types[j] ~= itemType || (asterik != -1 && Left( Categories[i].Types[j], asterik ) ~= Left( itemType, asterik )) )
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

defaultproperties
{
	/** All items. */
	//Categories(0)=(Name="All")

	/** Any item with no type. */
	Categories(1)=(Name="Other")

	/** Any adminonly item. */
	Categories(2)=(Name="Admin")

	/** Any item type of Trailer. */
	Categories(3)=(Name="Trailers",Types=("Trailer","FeetTrailer"))

	/** Any item that is an upgrade e.g. EXP boost etc. */
	Categories(4)=(Name="Upgrades",Types=("UP_*"))

	Items(0)=(Name="Trailer",ID="Trailer",Cost=50,Type="FeetTrailer",Desc="Customizable(Colors,Texture) trailer")
	Items(1)=(Name="MNAF Plus",ID="MNAFAccess",Type="UP_MNAF",Cost=30,Desc="Gives you access to MNAF member options")
	Items(2)=(Name="+100% EXP Bonus",ID="exp_bonus_1",Type="UP_EXPBonus",Cost=30,Desc="Get +100% EXP bonus for the next 4 play hours!",bPassive=true,IMG="TextureBTimes.StoreIcons.EXPBOOST_IMAGE")
	Items(3)=(Name="+200% EXP Bonus",ID="exp_bonus_2",Type="UP_EXPBonus",bAdminGiven=true,Desc="Get +200% EXP bonus for the next 24 play hours!",bPassive=true,IMG="TextureBTimes.StoreIcons.EXPBOOST_IMAGE2")
	Items(4)=(Name="+100% Currency Bonus",ID="cur_bonus_1",Type="UP_CURBonus",bAdminGiven=true,Desc="Get +100% Currency bonus for the next 24 play hours!",bPassive=true,IMG="TextureBTimes.StoreIcons.CURBOOST_IMAGE")
}
