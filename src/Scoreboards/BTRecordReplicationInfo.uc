class BTRecordReplicationInfo extends BTQueryDataReplicationInfo;

var int Completed;

replication
{
	reliable if( bNetInitial )
		Completed;
}

defaultproperties
{
	DataPanelClass=class'BTGUI_RecordQueryDataPanel'
}