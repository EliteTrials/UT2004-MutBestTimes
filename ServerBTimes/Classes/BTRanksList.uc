class BTRanksList extends BTList;

var() int RanksTable;

function Sort( MutBestTimes BT )
{
	local int i, z, y, tmp;
	local BTServer_PlayersData PDat;

	PDat = BT.PDat;
    for( i = 0; i < Items.Length - 1; ++ i )
    {
        // Log("Sorting item" @ i );
        z = i;
        for( y = i+1; y < Items.Length; ++ y )
            if( PDat.Player[Items[y]].PLPoints[RanksTable] > PDat.Player[Items[z]].PLPoints[RanksTable] )
                z = y;

        tmp = Items[z];
        Items[z] = Items[i];
        Items[i] = tmp;

        switch( RanksTable )
        {
        	case 0:
        		PDat.Player[tmp].PLARank = i+1;
        		break;

        	case 1:
        		PDat.Player[tmp].PLQRank = i+1;
        		break;

        	case 2:
        		PDat.Player[tmp].PLDRank = i+1;
        		break;
        }
    }
}

defaultproperties
{
	RanksTable=0
}
