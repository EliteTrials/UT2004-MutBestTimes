//==============================================================================
// BTClient_Menu.uc (C) 2005-2010 Eliot and .:..:. All Rights Reserved
/* Tasks:
			User-Friendly configuration menu for BTClient_Config
*/
//	Coded by Eliot
//	Updated @ 24/08/2010
//==============================================================================
class BTClient_Menu extends MidGamePanel
	config(ClientBTimes);

var automated GUITabControl
	c_Tabs;

var BTClient_Interaction MyInteraction;

struct sBTTab
{
	var() string Caption;
	var() class<BTGUI_TabBase> TabClass;
	var() string Hint;
};

var array<sBTTab> BTTabs;

event Free()
{
	MyInteraction = none;
	super.Free();
}

function InternalOnChange( GUIComponent sender );

function PostInitPanel()
{
	local int i;
	local BTGUI_TabBase tab;

	for( i = 0; i < BTTabs.Length; ++ i )
	{
		tab = BTGUI_TabBase(c_Tabs.AddTab( BTTabs[i].Caption, string(BTTabs[i].TabClass),, BTTabs[i].Hint, true ));
		tab.MyMenu = self;
		tab.PostInitPanel();
	}
}

/*function Opened( GUIComponent sender )
{
	super.Opened( sender );


}*/

defaultproperties
{
	WinWidth=0.600000
	WinHeight=1.000000
	WinLeft=0.100000
	WinTop=0.100000

	BTTabs(6)=(Caption="Store",TabClass=class'BTGUI_Store',Hint="Buy nice visual items for your character!")
	BTTabs(0)=(Caption="Account",TabClass=class'BTGUI_Account',Hint="")
	BTTabs(1)=(Caption="Settings",TabClass=class'BTGUI_Settings',Hint="Edit your BestTimes settings!")
	BTTabs(3)=(Caption="Achievements",TabClass=class'BTGUI_Achievements',Hint="View your BestTimes achievements!")
	BTTabs(4)=(Caption="Trophies",TabClass=class'BTGUI_Trophies',Hint="View your earned BestTimes trophies!")
	BTTabs(5)=(Caption="Challenges",TabClass=class'BTGUI_Challenges',Hint="View available BestTimes challenges!")
	BTTabs(2)=(Caption="Commands",TabClass=class'BTGUI_Commands',Hint="Execute useful BestTimes commands!")

	Begin Object class=GUITabControl name=oPageTabs
		WinWidth=0.98
		WinLeft=0.01
		WinTop=0.01
		WinHeight=0.05
		TabHeight=0.04
		//RenderWeight=0.49
		bFillSpace=false
		bAcceptsInput=true
		bDockPanels=true
		OnChange=InternalOnChange
		BackgroundStyleName="TabBackground"
	End Object
	c_Tabs=oPageTabs
}
