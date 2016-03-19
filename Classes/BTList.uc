class BTList extends Object
	abstract;

/** A sorted list of indexes to an external array. */
var array<int> Items;

function Sort();
function bool SortElement( int index, int prevIndex );

defaultproperties
{
}