class BTGUI_RankingsMenu extends BTGUI_ScoreboardBase;

var automated GUITabControl Tabs;
var automated BTGUI_PlayerRankingsPlayerProfile PlayerInfoPanel;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	super.InitComponent(MyController,MyOwner);

	Tabs.AddTab( "Top Players", string(class'BTGUI_PlayerRankingsScoreboard'),, "View the highest ranked players", true  );
	Tabs.AddTab( "Top Records", string(class'BTGUI_RecordRankingsScoreboard'),, "View the fastest map records", true  );
}

defaultproperties
{
	WindowName="BTimes Rankings"
	bPersistent=true
	bAllowedAsLast=true

	WinLeft=0.1
	WinTop=0.1
	WinWidth=0.8
	WinHeight=0.8

    Begin Object class=GUITabControl name=oRankPages
        WinWidth=0.59
        WinLeft=0.005
        // WinTop=0.075
        WinTop=0.01
        // WinHeight=0.89
        WinHeight=0.98
        // TabHeight=0.04
        TabHeight=0.045
        bAcceptsInput=true
        bDockPanels=true
        bFillSpace=true
        // BackgroundStyleName="BTHUD"
    End Object
    Tabs=oRankPages

    Begin Object class=BTGUI_PlayerRankingsPlayerProfile name=oPlayerInfoPanel
        WinWidth=0.395
        WinHeight=0.925
        WinTop=0.065
        WinLeft=0.6
    End Object
    PlayerInfoPanel=oPlayerInfoPanel
}