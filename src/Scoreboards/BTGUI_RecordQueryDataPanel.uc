class BTGUI_RecordQueryDataPanel extends BTGUI_QueryDataPanel;

var automated GUIButton ViewPlayerButton, ViewGhostButton;

function ApplyData( BTQueryDataReplicationInfo queryRI )
{
	local BTRecordReplicationInfo recordRI;

	recordRI = BTRecordReplicationInfo(queryRI);
    // Completed Objectives
    DataRows[0].Value = string(recordRI.Completed);
    DataRows[1].Value = string(recordRI.AverageDodgeTiming);
    DataRows[2].Value = string(recordRI.BestDodgeTiming);
    DataRows[3].Value = string(recordRI.WorstDodgeTiming);

    if( recordRI.GhostId > 0 )
        ViewGhostButton.EnableMe();
    else ViewGhostButton.DisableMe();
}

defaultproperties
{
    DataRows(0)=(Caption="Completed Objectives")
    DataRows(1)=(Caption="Average Dodge Timing")
    DataRows(2)=(Caption="Best Dodge")
    DataRows(3)=(Caption="Worst Dodge")

    begin object class=GUIButton name=oViewPlayerButton
        WinTop=0.9
        WinHeight=0.09
        WinWidth=0.48
        WinLeft=0.01
        FontScale=FNS_Small
        StyleName="BTButton"
        Caption="Player Profile"
    end object
    ViewPlayerButton=oViewPlayerButton

    begin object class=GUIButton name=oViewGhostButton
        WinTop=0.9
        WinHeight=0.09
        WinWidth=0.48
        WinLeft=0.51
        FontScale=FNS_Small
        StyleName="BTButton"
        Caption="Watch Ghost"
    end object
    ViewGhostButton=oViewGhostButton
}