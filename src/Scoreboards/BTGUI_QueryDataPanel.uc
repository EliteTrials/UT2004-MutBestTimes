class BTGUI_QueryDataPanel extends GUIPanel;

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	super.InitComponent( myController, myOwner );
}

function bool InternalOnPreDraw( Canvas C )
{
    C.SetPos( ActualLeft(), ActualTop() );
    C.DrawColor = class'BTClient_Config'.default.CTable;
    C.DrawTile( Texture'BTScoreBoardBG', ActualWidth(), ActualHeight(), 0, 0, 256, 256 );
    return true;
}

function ApplyData( BTQueryDataReplicationInfo queryRI );

defaultproperties
{
	OnPreDraw=InternalOnPreDraw
}