class BTRecordReplicationInfo extends BTQueryDataReplicationInfo;

var string PlayerId, MapId;

var int Completed;
var float AverageDodgeTiming, BestDodgeTiming, WorstDodgeTiming;
var int GhostId;
var bool bIsCurrentMap;

replication
{
	reliable if( bNetInitial )
		PlayerId, MapId,
		Completed,
		AverageDodgeTiming, BestDodgeTiming, WorstDodgeTiming,
		GhostId, bIsCurrentMap;
}

defaultproperties
{
	DataPanelClass=class'BTGUI_RecordQueryDataPanel'
	Completed=1
	AverageDodgeTiming=0.43
	BestDodgeTiming=0.40
	WorstDodgeTiming=0.47
}