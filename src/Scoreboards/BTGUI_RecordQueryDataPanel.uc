class BTGUI_RecordQueryDataPanel extends BTGUI_QueryDataPanel;

function ApplyData( BTQueryDataReplicationInfo queryRI )
{
	local BTRecordReplicationInfo recordRI;

	recordRI = BTRecordReplicationInfo(queryRI);
    // Completed Objectives
    DataRows[0].Value.Caption = string(recordRI.Completed);
    DataRows[1].Value.Caption = string(recordRI.AverageDodgeTiming);
    DataRows[2].Value.Caption = string(recordRI.BestDodgeTiming);
    DataRows[3].Value.Caption = string(recordRI.WorstDodgeTiming);
}

defaultproperties
{
    DataRows(0)=(Caption="Completed Objectives")
    DataRows(1)=(Caption="Average Dodge Timing")
    DataRows(2)=(Caption="Best Dodge")
    DataRows(3)=(Caption="Worst Dodge")
}