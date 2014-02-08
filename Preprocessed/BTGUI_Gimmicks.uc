class BTGUI_Gimmicks extends BTGUI_TabBase;

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
        tab.MyMenu = MyMenu;
        tab.PostInitPanel();

        //if( BTTabs[i].Style != none )
        //{
            //BTTabs[i].Style.Initialize();
            //tab.MyButton.Style = BTTabs[i].Style;
        //}
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

    begin object name=oChallengesStyle class=STY2TabButton
        KeyName="ChallengeStyle"
        ImgColors(0)=(R=226,G=38,B=53,A=255)
        ImgColors(1)=(R=226,G=38,B=53,A=255)
        ImgColors(2)=(R=226,G=38,B=53,A=255)
        ImgColors(3)=(R=226,G=38,B=53,A=255)
    end object

    begin object name=oAchievementsStyle class=STY2TabButton
        KeyName="AchievementStyle"
        ImgColors(0)=(R=60,G=100,B=150,A=255)
        ImgColors(1)=(R=60,G=100,B=150,A=255)
        ImgColors(2)=(R=60,G=100,B=150,A=255)
        ImgColors(3)=(R=60,G=100,B=150,A=255)
    end object

    BTTabs(0)=(Caption="Trophies",TabClass=class'BTGUI_Trophies',Hint="View your earned BestTimes trophies!",Style=oTrophiesStyle)
    BTTabs(1)=(Caption="Challenges",TabClass=class'BTGUI_Challenges',Hint="View available BestTimes challenges!",Style=oChallengesStyle)
    BTTabs(2)=(Caption="Achievements",TabClass=class'BTGUI_Achievements',Hint="View your BestTimes achievements!",Style=oAchievementsStyle)

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
        BackgroundStyleName="TabBackground"

        FillColor=(R=100,G=100,B=100,A=200)
    End Object
    c_Tabs=oPageTabs
}