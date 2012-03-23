class BTItemsReplicator extends Info;

var private int repIndex;

var protected BTClient_ClientReplication CR;
var protected MutBestTimes P;

struct sRepItem
{
	var string Name;
	var string ID;
	var int Data;
};

var array<sRepItem> RepData;

final function Initialize( BTClient_ClientReplication client )
{
	if( client == none )
		return;

	CR = client;
	P = MutBestTimes(Owner);
}

final function AddData( string name, string ID, int data )
{
	local int j;

	j = RepData.Length;
	RepData.Length = j+1;
	RepData[j].Name = name;
	RepData[j].ID = ID;
	RepData[j].Data = data;
}

final function BeginReplication()
{
	GotoState( 'Replicate' );
}

final private function SendRepData( int index )
{
	CR.ClientSendItem( 
		RepData[index].Name,
		RepData[index].ID,
		RepData[index].Data
	);
}

state Replicate
{
Begin:
	for( repIndex = 0; repIndex < RepData.Length; ++ repIndex )
	{
		SendRepData( repIndex );
		if( Level.NetMode != NM_Standalone && repIndex % 10 == 0 )
		{
			Sleep( 0.1 );
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
