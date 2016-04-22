class BTGUI_ComboBox extends GUIComboBox;

event InitComponent( GUIController myController, GUIComponent myOwner )
{
	Edit.bAlwaysNotify = true;
	Edit.StyleName = "BTEditBox";
	MyShowListBtn.StyleName = "BTButton";
	MyShowListBtn.Caption = ":";
	MyShowListBtn.bCheckBox = true;
	super.InitComponent( myController, myOwner );
    List.Style = myController.GetStyle( "BTMultiColumnList", List.FontScale );
    List.SelectedStyle = myController.GetStyle( "BTMultiColumnList", List.FontScale );
}

defaultproperties
{
}