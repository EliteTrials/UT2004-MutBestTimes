class BTGUI_QueryDataPanel extends GUIPanel;

var() editconstarray array<struct sMetaDataRow{
    var() editconst localized string Caption;
    var() editinline GUILabel Label;
    var() editinline GUILabel Value;
}> DataRows;

event Free()
{
    local int i;

    super.Free();
    for( i = 0; i < DataRows.Length; ++ i )
    {
        DataRows[i].Label = none;
        DataRows[i].Value = none;
    }
}

event InitComponent( GUIController myController, GUIComponent myOwner )
{
    super.InitComponent( myController, myOwner );
    CreateDataRows();
}

function CreateDataRows()
{
    local int i;
    local GUILabel lbl;

    for( i = 0; i < DataRows.Length; ++ i )
    {
        lbl = GUILabel(AddComponent(string(class'GUILabel')));
        lbl.WinTop = 0.045*i;
        lbl.WinHeight = 0.045;
        lbl.WinWidth = 0.5;
        lbl.WinLeft = 0.0;
        lbl.bScaleToParent = True;
        lbl.bBoundToParent = True;
        lbl.Caption = DataRows[i].Caption;
        lbl.bTransparent = false;
        lbl.TextColor.R = 255;
        lbl.TextColor.G = 255;
        lbl.TextColor.B = 255;
        lbl.TextColor.A = 255;
        lbl.TextAlign = TXTA_Center;
        lbl.FontScale = FNS_Small;
        lbl.StyleName = "BTLabel";
        lbl.Style = Controller.GetStyle( "BTLabel", lbl.FontScale );
        DataRows[i].Label = lbl;

        lbl = GUILabel(AddComponent(string(class'GUILabel')));
        lbl.WinTop = 0.045*i;
        lbl.WinHeight = 0.045;
        lbl.WinWidth = 0.5;
        lbl.WinLeft = 0.5;
        lbl.bScaleToParent = True;
        lbl.bBoundToParent = True;
        lbl.bTransparent = false;
        lbl.TextColor.R = 255;
        lbl.TextColor.G = 255;
        lbl.TextColor.B = 255;
        lbl.TextColor.A = 255;
        lbl.TextAlign = TXTA_Right;
        lbl.FontScale = FNS_Small;
        DataRows[i].Value = lbl;
    }
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