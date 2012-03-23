class VPlus_VotingReplicationInfo extends VotingReplicationInfoBase;

struct sMapItem extends MapVoteMapList
{
	var int Popularity;
};

var array<sMapItem> MapList;
var int MapCount;

replication
{
	reliable if( Role == ROLE_Authority )
		SendMapCount, SendMapItem;
}

final function float GetMapListPercent()
{
	return (float(MapList.Length) / float(MapCount)) * 100;
}

function SendMapCount( int mapCount )
{
	self.MapCount = mapCount;
}

function SendMapItem( sMapItem mapItem )
{
	MapList.Insert( 0, 1 );
	MapList[0] = mapItem;
}
