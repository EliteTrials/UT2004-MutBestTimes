class BTGUI_PlayerRankingsPlayerProfile extends GUIPanel;

var automated GUIHeader Header;
var automated GUILabel QueryLabel;
var automated GUIEditBox QueryBox;
var automated GUIImage PanelImage;

delegate OnQueryReceived( BTQueryDataReplicationInfo queryRI );

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
	PanelImage.ImageColor = class'BTClient_Config'.default.CTable;
}

function InternalOnQueryChange( GUIComponent sender )
{
    local BTClient_ClientReplication CRI;

    CRI = class'BTClient_ClientReplication'.static.GetRep( PlayerOwner() );
    if( CRI == none )
    {
    	Warn("Attempt to query with no CRI");
    	return;
    }

    CRI.ServerPerformQuery( GetQuery() );
}

function InternalOnQueryReceived( BTQueryDataReplicationInfo queryRI )
{
	Log(queryRI);

	if( BTRecordReplicationInfo(queryRI) != none )
	{
		QueryBox.SetText( "COmpleted:" $ BTRecordReplicationInfo(queryRI).Completed );
	}
}

final function string GetQuery()
{
	return QueryBox.GetText();
}

defaultproperties
{
	OnQueryReceived=InternalOnQueryReceived

    begin object class=GUILabel name=oQueryLabel
        WinTop=0.0
        WinHeight=0.045
        WinWidth=0.2
        WinLeft=0.0
        bScaleToParent=True
        bBoundToParent=True
        Caption="Search"
        TextColor=(R=255,G=255,B=255,A=255)
        TextAlign=TXTA_Center
        bTransparent=false
        FontScale=FNS_Small
        StyleName="BTHeader"
    end object
    QueryLabel=oQueryLabel

    begin object class=GUIEditBox name=oQueryBox
        WinTop=0.0
        WinHeight=0.045
        WinWidth=0.8
        WinLeft=0.2
        bScaleToParent=True
        bBoundToParent=True
        OnChange=InternalOnQueryChange
        StyleName="BTEditBox"
    end object
    QueryBox=oQueryBox

	Begin Object class=GUIHeader name=oHeader
		Caption="Player Profile"
		WinWidth=1
		WinHeight=0.043750
		WinLeft=0
		WinTop=0.045
		RenderWeight=0.1
		FontScale=FNS_Small
		bUseTextHeight=true
		ScalingType=SCALE_X
		StyleName="BTHeader"
	End Object
	Header=oHeader

	Begin Object class=GUIImage name=oBackground
		WinWidth=1.0
		WinHeight=0.955
		WinTop=0.045
		WinLeft=0.0
        bScaleToParent=True
        bBoundToParent=True
		Image=Texture'BTScoreBoardBG'
	End Object
	PanelImage=oBackground
}