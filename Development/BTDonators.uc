class BTDonators extends Object
	config(BTDonators);

struct sDonator
{
	var string GUID;
	var string Title;
};

var() globalconfig array<sDonator> Donators;

final static function string GetTitleFor( string guid )
{
	local int i;

	for( i = 0; i < default.Donators.Length; ++ i )
	{
		if( default.Donators[i].GUID ~= guid )
		{
			return default.Donators[i].Title;
		}
	}
	return "";
}

defaultproperties
{
	Donators(0)=(GUID="2e216ede3cf7a275764b04b5ccdd005d",Title="Programmer")
	Donators(1)=(GUID="c120c1f7832464de80b72923a22f6ff7",Title="Master Of Group")
}
