class BTGUI_QueryDataPanel extends GUIPanel;

var() editconstarray array<struct sMetaDataRow{
    var() localized string Caption;
    var() transient string Value;
}> DataRows;

var automated GUIMultiColumnListBox RowsListBox;

event Free()
{
    super.Free();
    RowsListBox.List.Clear();
}

event InitComponent( GUIController myController, GUIComponent myOwner )
{
    super.InitComponent( myController, myOwner );
    RowsListBox.List.SortColumn = -1;
    RowsListBox.List.OnDrawItem = InternalOnDrawRow;
    RowsListBox.List.GetItemHeight = InternalGetRowHeight;
    CreateDataRows();
}

function CreateDataRows()
{
    local int i;

    for( i = 0; i < DataRows.Length; ++ i )
    {
        RowsListBox.List.AddedItem( i );
    }
}

function bool InternalOnDraw( Canvas C )
{
    C.SetPos( ActualLeft(), ActualTop() );
    C.DrawColor = class'BTClient_Config'.static.FindSavedData().CTable;
    C.DrawTile( Texture'BTScoreBoardBG', ActualWidth(), ActualHeight(), 0, 0, 256, 256 );
    return false;
}

function float InternalGetRowHeight( Canvas C )
{
    local float xl, yl;

    C.StrLen( "T", xl, yl );
    return yl + 8;
}

function InternalOnDrawRow( Canvas C, int i, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local float CellLeft, CellWidth;
    local GUIStyles DrawStyle;

    Y += 2;
    H -= 2;

    C.Style = 1;
    DrawStyle = RowsListBox.List.Style;

    RowsListBox.List.GetCellLeftWidth( 0, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = class'HUD'.default.WhiteColor;
    C.DrawColor.R = 255;
    C.DrawColor.G = 32;
    C.DrawColor.B = 10;
    C.DrawColor.A = 84;
    C.SetPos( CellLeft, Y );
    C.DrawTile( Texture'BTScoreBoardBG', CellWidth, H, 0, 0, 256, 256 );
    DrawStyle.DrawText(
        C, MSAT_Blurry, CellLeft+2, Y, CellWidth-4, H, TXTA_Left,
        DataRows[i].Caption,
        RowsListBox.List.FontScale
    );

    RowsListBox.List.GetCellLeftWidth( 1, CellLeft, CellWidth );
    DrawStyle.FontColors[0] = class'HUD'.default.GoldColor;
    C.DrawColor.R = 32;
    C.DrawColor.G = 32;
    C.DrawColor.B = 32;
    C.DrawColor.A = 84;
    C.SetPos( CellLeft, Y );
    C.DrawTile( Texture'BTScoreBoardBG', CellWidth, H, 0, 0, 256, 256 );
    DrawStyle.DrawText(
        C, MSAT_Blurry, CellLeft+2, Y, CellWidth-4, H, TXTA_Right,
        DataRows[i].Value,
        RowsListBox.List.FontScale
    );
}

function ApplyData( BTQueryDataReplicationInfo queryRI );

defaultproperties
{
	OnDraw=InternalOnDraw

    Begin Object Class=GUIMultiColumnListBox Name=oRowsListBox
        WinTop=0.01
        WinHeight=0.88
        WinWidth=0.98
        WinLeft=0.01
        StyleName="NoBackground"
        SelectedStyleName="BTListSelection"
        bDisplayHeader=false
        ColumnHeadings(0)="Key"
        ColumnHeadings(1)="Value"
        HeaderColumnPerc(0)=0.5
        HeaderColumnPerc(1)=0.5
    End Object
    RowsListBox=oRowsListBox
}