class BTGUI_RecordQueryDataPanel extends BTGUI_QueryDataPanel;

var automated GUIButton ViewPlayerButton, ViewGhostButton;
var private string PlayerId, MapId;

final function string Format( coerce string value )
{
    if( value == "" || float(value) == 0.00 )
        return "N/A";
    return value;
}

function ApplyData( BTQueryDataReplicationInfo queryRI )
{
	local BTRecordReplicationInfo recordRI;

	recordRI = BTRecordReplicationInfo(queryRI);
    // Completed Objectives
    DataRows[0].Value = Format(recordRI.Completed);
    DataRows[1].Value = Format(recordRI.AverageDodgeTiming);
    DataRows[2].Value = Format(recordRI.BestDodgeTiming);
    DataRows[3].Value = Format(recordRI.WorstDodgeTiming);

    if( recordRI.GhostId > 0 )
        ViewGhostButton.EnableMe();
    else ViewGhostButton.DisableMe();

    PlayerId = recordRI.PlayerId;
    MapId = recordRI.MapId;
    if( PlayerId == "" || PlayerId == "0" )
    {
        ViewPlayerButton.DisableMe();
    }
}

function bool InternalOnClick( GUIComponent sender )
{
    switch( sender )
    {
        case ViewPlayerButton:
            OnQueryRequest( "player:"$PlayerId );
            return true;

        case ViewGhostButton:
            return true;
    }
    return false;
}

defaultproperties
{
    DataRows(0)=(Caption="Objectives")
    DataRows(1)=(Caption="Average Dodge")
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
        OnClick=InternalOnClick
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
        OnClick=InternalOnClick
    end object
    ViewGhostButton=oViewGhostButton
}