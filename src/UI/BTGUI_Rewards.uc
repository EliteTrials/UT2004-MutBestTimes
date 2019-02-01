class BTGUI_Rewards extends MidGamePanel
    config(ClientBTimes);

var automated GUITabControl
    c_Tabs;

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

    super.Free();
}

function PostInitPanel()
{
    local int i;
    local BTGUI_TabBase tab;

    for( i = 0; i < BTTabs.Length; ++ i )
    {
        tab = BTGUI_TabBase(c_Tabs.AddTab( BTTabs[i].Caption, string(BTTabs[i].TabClass),, BTTabs[i].Hint, true ));
        tab.PostInitPanel();
    }
}

defaultproperties
{
    WinWidth=0.600000
    WinHeight=1.000000
    WinLeft=0.100000
    WinTop=0.100000

    begin object name=oTrophiesStyle class=STY2TabButton
        KeyName="ThrophyStyle"
        ImgColors(0)=(R=255,G=191,B=0,A=255)
        ImgColors(1)=(R=255,G=191,B=0,A=255)
        ImgColors(2)=(R=255,G=191,B=0,A=255)
        ImgColors(3)=(R=255,G=191,B=0,A=255)
    end object

    begin object name=oAchievementsStyle class=STY2TabButton
        KeyName="AchievementStyle"
        ImgColors(0)=(R=60,G=100,B=150,A=255)
        ImgColors(1)=(R=60,G=100,B=150,A=255)
        ImgColors(2)=(R=60,G=100,B=150,A=255)
        ImgColors(3)=(R=60,G=100,B=150,A=255)
    end object

    BTTabs(0)=(Caption="Collected Trophies",TabClass=class'BTGUI_Trophies',Hint="View your earned trophies!",Style=oTrophiesStyle)
    BTTabs(1)=(Caption="Achievements",TabClass=class'BTGUI_Achievements',Hint="View your achievements!",Style=oAchievementsStyle)

    Begin Object class=GUITabControl name=oPageTabs
        WinWidth=0.98
        WinLeft=0.01
        WinTop=0.01
        WinHeight=0.05
        TabHeight=0.04
        bFillBackground=true
        bFillSpace=false
        bAcceptsInput=true
        bDockPanels=true
        // OnChange=InternalOnChange
        BackgroundStyleName="TabBackground"
    End Object
    c_Tabs=oPageTabs
}