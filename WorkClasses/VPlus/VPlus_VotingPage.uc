/**
 * The main voting page that contains all the voting tabs.
 *
 * Copyright 2010 Eliot Van Uytfanghe. All Rights Reserved.
 */
class VPlus_VotingPage extends UT2K4GUIPage;

var automated GUITabControl Tabs;
var automated GUITabPanel p_MapVote, p_PlayerVote;

var() localized string lzMapVotingCaption, 		lzPlayerVotingCaption;
var() localized string lzVoteAMapHint, 			lzVoteAPlayerHint;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	super.InitComponent( MyController, MyOwner );
	p_MapVote = Tabs.AddTab( lzMapVotingCaption, string(Class'VPlus_MapVotingPanel'),, lzVoteAMapHint );
	p_PlayerVote = Tabs.AddTab( lzPlayerVotingCaption, string(Class'VPlus_PlayerVotingPanel'),, lzVoteAPlayerHint );
	Tabs.ActivateTabByPanel( p_MapVote, true );
}

/*event Free()
{
}*/

defaultproperties
{
	lzMapVotingCaption="Map Voting"
	lzPlayerVotingCaption="Player Voting"

	lzVoteAMapHint="Vote a map"
	lzVoteAPlayerHint="Vote a player"

	//bPersistent=true
	bRenderWorld=true
	bAllowedAsLast=false

	begin object Class=GUITabControl Name=oTabs
	    bDockPanels=true
		WinWidth=1.0
		WinHeight=0.2
		WinLeft=0.0
	    WinTop=0.0
	    bScaleToParent=true
		bAcceptsInput=true
	end object
	Tabs=oTabs
}
