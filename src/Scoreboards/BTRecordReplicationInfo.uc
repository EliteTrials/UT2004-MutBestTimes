class BTRecordReplicationInfo extends BTQueryDataReplicationInfo;

var int Completed;

replication
{
	reliable if( bNetInitial )
		Completed;
}

defaultproperties
{
}