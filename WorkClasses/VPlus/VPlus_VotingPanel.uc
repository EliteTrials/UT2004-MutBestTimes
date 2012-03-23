/**
 * A voting panel that implements the base functionality for a voting panel.
 *
 * Copyright 2010 Eliot Van Uytfanghe. All Rights Reserved.
 */
class VPlus_VotingPanel extends GUITabPanel;

var automated VPlus_VotingMultiColumnListBox lb_VotingListBox;
var automated GUIButton b_Vote;

var protected editconst noexport class<VPlus_VotingMultiColumnList> ColumnListClass;

var private string Filter;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	super.InitComponent( MyController, MyOwner );
	lb_VotingListBox.InitListClass( string(ColumnListClass), self );
}

final function SetFilter( coerce string text )
{
	local string oldfilter;

	oldfilter = Filter;
	Filter = text;
	FilterChanged( oldfilter, Filter );
}

final function string GetFilter()
{
	return Filter;
}

protected singular function FilterChanged( string oldFilter, string newFilter )
{
}

defaultproperties
{
	begin object Class=GUIButton Name=oVote
		Caption="Vote"
		WinLeft=0.6
		WinTop=0.8
		WinWidth=0.4
		WinHeight=0.2
	end object
	b_Vote=oVote

	begin object Class=VPlus_VotingMultiColumnListBox Name=oVotingListBox
		WinWidth=1.0
		WinHeight=0.3
		WinLeft=0.0
		WinTop=0.5
        bVisibleWhenEmpty=true
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
	end object
	lb_VotingListBox=oVotingListBox

	ColumnListClass=Class'VPlus_VotingMultiColumnList'
}
