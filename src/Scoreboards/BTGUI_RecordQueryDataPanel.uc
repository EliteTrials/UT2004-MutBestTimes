class BTGUI_RecordQueryDataPanel extends BTGUI_QueryDataPanel;

var automated GUILabel ObjectivesLabel, ObjectivesValue;

function ApplyData( BTQueryDataReplicationInfo queryRI )
{
	local BTRecordReplicationInfo recordRI;

	recordRI = BTRecordReplicationInfo(queryRI);
	ObjectivesValue.Caption = string( recordRI.Completed );
}

defaultproperties
{
    begin object class=GUILabel name=oObjectivesLabel
        WinTop=0.0
        WinHeight=0.045
        WinWidth=0.5
        WinLeft=0.0
        bScaleToParent=True
        bBoundToParent=True
        Caption="Completed Objectives"
        bTransparent=false
        TextColor=(R=255,G=255,B=255,A=255)
        TextAlign=TXTA_Left
        FontScale=FNS_Small
        StyleName="BTHeader"
    end object
    ObjectivesLabel=oObjectivesLabel

    begin object class=GUILabel name=oObjectivesValue
        WinTop=0.0
        WinHeight=0.045
        WinWidth=0.5
        WinLeft=0.5
        bScaleToParent=True
        bBoundToParent=True
        bTransparent=false
        TextColor=(R=255,G=255,B=255,A=255)
        TextAlign=TXTA_Right
        FontScale=FNS_Small
    end object
    ObjectivesValue=oObjectivesValue
}