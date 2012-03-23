/**
 * A list box that can be initialized with a specified listclass on runtime.
 *
 * Copyright 2010 Eliot Van Uytfanghe. All Rights Reserved.
 */
class VPlus_VotingMultiColumnListBox extends GUIMultiColumnListBox;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	super(GUIListBoxBase).InitComponent( MyController, MyOwner );
}

final function InitListClass( string listClass, VPlus_VotingPanel votingPanel )
{
	if( listClass == "" )
	{
		Warn( "No listClass Specified!" );
		return;
	}
	else if( votingPanel == none )
	{
		Warn( "No votingPanel specified!" );
		return;
	}

	List = VPlus_VotingMultiColumnList( AddComponent( listClass ) );
	VPlus_VotingMultiColumnList(List).VPanel = votingPanel;
	//VPlus_VotingMultiColumnList(List).VRI = votingPanel.
	InitBaseList( List );

	if( bFullHeightStyle )
	{
		List.Style = none;
	}
}
