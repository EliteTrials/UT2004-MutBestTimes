/**
 * A base list.
 *
 * Copyright 2010 Eliot Van Uytfanghe. All Rights Reserved.
 */
class VPlus_VotingMultiColumnList extends GUIMultiColumnList;

var editconst noexport VPlus_VotingPanel VPanel;
var editconst noexport VPlus_VotingReplicationInfo VRI;

event Free()
{
	super.Free();
	VPanel = none;
	VRI = none;
}

defaultproperties
{
	SortColumn=0
	SortDescending=false
}
