class BTGUI_ComboBox extends GUIComboBox;

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	Edit.bAlwaysNotify = true;
	Edit.StyleName = "BTEditBox";
	MyShowListBtn.StyleName = "BTButton";
	MyShowListBtn.Caption = ":";
	MyShowListBtn.bCheckBox = true;
	super.InitComponent( myController, myOwner );
    List.StyleName = "BTMultiColumnList";
    List.Style = myController.GetStyle( List.StyleName, List.FontScale );
    List.SelectedStyleName = "BTListSelection";
    List.SelectedStyle = myController.GetStyle( List.SelectedStyleName, List.FontScale );
    List.GetItemHeight = InternalGetItemHeight;
}

function float InternalGetItemHeight( Canvas C )
{
    local float xl, yl;

    List.Style.TextSize( C, List.MenuState, "T", xl, yl, List.FontScale );
    return yl + 8;
}

defaultproperties
{
}