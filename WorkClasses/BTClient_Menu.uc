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
	var() GUIStyles Style;
};

var array<sBTTab> BTTabs;

event Free()
{
	local int i;
	
	for( i = 0; i < BTTabs.Length; ++ i )
	{
		BTTabs[i].Style = none;
	}
	
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
		
		//if( BTTabs[i].Style != none )
		//{
			//BTTabs[i].Style.Initialize();
			//tab.MyButton.Style = BTTabs[i].Style;
		//} 
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
	
	begin object name=oStoreStyle class=STY2TabButton
		ImgColors(0)=(R=255,G=255,B=0,A=255)
		ImgColors(1)=(R=255,G=255,B=0,A=255)
		ImgColors(2)=(R=255,G=255,B=0,A=255)
		ImgColors(3)=(R=255,G=255,B=0,A=255)
	end object

	BTTabs(0)=(Caption="Account",TabClass=class'BTGUI_Account',Hint="")
	BTTabs(1)=(Caption="Settings",TabClass=class'BTGUI_Settings',Hint="Edit your BestTimes settings!")
	BTTabs(2)=(Caption="Commands",TabClass=class'BTGUI_Commands',Hint="Execute useful BestTimes commands!")
	BTTabs(3)=(Caption="Store",TabClass=class'BTGUI_Store',Hint="Buy nice visual items for your character!",Style=oStoreStyle)
	BTTabs(4)=(Caption="Gimmicks",TabClass=class'BTGUI_Gimmicks',Hint="View achievements, challenges, trophies and perks!")

	Begin Object class=GUITabControl name=oPageTabs
		WinWidth=0.98
		WinLeft=0.01
		WinTop=0.01
		WinHeight=0.05
		TabHeight=0.04
		bFillBackground=true
		bFillSpace=true
		bAcceptsInput=true
		bDockPanels=true
		OnChange=InternalOnChange
		BackgroundStyleName="TabBackground"
	End Object
	c_Tabs=oPageTabs
}
