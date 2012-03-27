class BTItemsReplicator extends Info;

var private int repIndex;

var protected BTClient_ClientReplication CR;
var protected MutBestTimes P;

var string Filter;
var bool bIsAdmin;

final function Initialize( BTClient_ClientReplication client )
{
	if( client == none )
		return;

	CR = client;
	P = MutBestTimes(Owner);
}

final function BeginReplication()
{
	GotoState( 'Replicate' );
}

final private function SendRepData( int index )
{
	CR.ClientSendItem( 
		P.Store.Items[index].Name,
		P.Store.Items[index].ID,
		class'BTClient_ClientReplication'.static.CompressStoreData( 
			P.Store.Items[index].Cost, 
			P.PDat.HasItem( CR.myPlayerSlot, P.Store.Items[index].ID ), 
			P.PDat.ItemEnabled( CR.myPlayerSlot, P.Store.Items[index].ID ) 
		)
	);
}

state Replicate
{
Begin:
	for( repIndex = 0; repIndex < P.Store.Items.Length; ++ repIndex )
	{
		if( !P.Store.Items[repIndex].bAdminGiven || InStr( P.Store.Items[repIndex].CachedCategory, "&"$filter ) == -1 )
		{
			continue;
		}
		
		if( bIsAdmin || P.PDat.HasItem( CR.myPlayerSlot, P.Store.Items[repIndex].ID ) )
		{
			SendRepData( repIndex );
			if( Level.NetMode != NM_Standalone && repIndex % 10 == 0 )
			{
				Sleep( 0.1 );
			}
		}
	}
	
	if( !(filter ~= "Admin") )
	{	
		for( repIndex = 0; repIndex < P.Store.Items.Length; ++ repIndex )
		{
			if( P.Store.Items[repIndex].bAdminGiven || InStr( P.Store.Items[repIndex].CachedCategory, "&"$filter ) == -1 )
			{
				continue;
			}
	
			SendRepData( repIndex );
			if( Level.NetMode != NM_Standalone && repIndex % 10 == 0 )
			{
				Sleep( 0.1 );
			}	
		}
	}
	ReplicationFinished();
	Destroy();
}

final protected function ReplicationFinished()
{
	CR.ClientSendItemsCompleted();
}

event Tick( float deltaTime )
{
	if( P != none && CR == none )
	{
		Destroy();
	}
}
