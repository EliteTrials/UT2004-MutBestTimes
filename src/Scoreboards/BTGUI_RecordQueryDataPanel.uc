class BTGUI_RecordQueryDataPanel extends BTGUI_QueryDataPanel;

var automated GUIButton ViewMapButton, ViewPlayerButton, ViewGhostButton;

var private string PlayerId, MapId;
var private int GhostId;

function ApplyData( BTQueryDataReplicationInfo queryRI )
{
	local BTRecordReplicationInfo myQueryRI;

	myQueryRI = BTRecordReplicationInfo(queryRI);
    // Completed Objectives
    DataRows[0].Value = Format(myQueryRI.Completed);
    DataRows[1].Value = Format(myQueryRI.AverageDodgeTiming);
    DataRows[2].Value = Format(myQueryRI.BestDodgeTiming);
    DataRows[3].Value = Format(myQueryRI.WorstDodgeTiming);

    if( myQueryRI.GhostId > 0 && myQueryRI.bIsCurrentMap )
        ViewGhostButton.EnableMe();
    else ViewGhostButton.DisableMe();

    GhostId = myQueryRI.GhostId;
    PlayerId = myQueryRI.PlayerId;
    MapId = myQueryRI.MapId;
    if( PlayerId == "" || PlayerId == "0" )
    {
        ViewPlayerButton.DisableMe();
    }
}

function bool InternalOnClick( GUIComponent sender )
{
    switch( sender )
    {
        case ViewMapButton:
            OnQueryRequest("map:"$MapId);
            return true;

        case ViewPlayerButton:
            OnQueryRequest("player:"$PlayerId);
            return true;

        case ViewGhostButton:
            PlayerOwner().ConsoleCommand("say" @ "!"$"ghost" @ GhostId);
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

    begin object class=GUIButton name=oViewMapButton
        WinTop=0.80
        WinHeight=0.09
        WinWidth=0.48
        WinLeft=0.01
        FontScale=FNS_Small
        StyleName="BTButton"
        Caption="Map Profile"
        OnClick=InternalOnClick
    end object
    ViewMapButton=oViewMapButton

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
        Caption="Spawn Ghost"
        OnClick=InternalOnClick
    end object
    ViewGhostButton=oViewGhostButton
}