class BTQueryMapDataReplicationInfo extends BTQueryDataReplicationInfo;

var string MapId;
var float AverageRecordTime, PlayHours;
var int CompletedCount, HijackedCount, FailedCount;
var bool bIsRanked, bMapIsActive;
var int RegisterDate, LastPlayedDate;
var float Rating;

replication
{
	reliable if( bNetInitial )
		MapId, AverageRecordTime, PlayHours,
        CompletedCount, HijackedCount, FailedCount,
		bIsRanked, bMapIsActive,
		RegisterDate, LastPlayedDate,
		Rating;
}

defaultproperties
{
	DataPanelClass=class'BTGUI_MapQueryDataPanel'
}