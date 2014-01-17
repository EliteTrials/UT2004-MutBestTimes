//==============================================================================
// Coded by Eliot aka Eliot van uytfanghe.
// Copyright (C) 2007-2008.
//==============================================================================
class BTClient_MapVotingPage extends MapVotingPage;

var automated GUIButton b_Random;

function OnOkButtonClick(byte bButton)
{
	if( bButton != QBTN_OK )
		Controller.CloseMenu( True );
}

function InternalOnOpen()
{
	// >> Ugly copy from MapVotingPage, necessary to add a few specific modifications to it!.

	local int i, d;

	BackgroundRStyle = MSTY_None;
	i_FrameBG.Image = Texture(DynamicLoadObject( "2k4Menus.NewControls.Display99", Class'Texture', True ));

    if( MVRI == none || (MVRI != none && !MVRI.bMapVote) )
    {
		Controller.OpenMenu("GUI2K4.GUI2K4QuestionPage");
		GUIQuestionPage(Controller.TopPage()).SetupQuestion(lmsgMapVotingDisabled, QBTN_Ok, QBTN_Ok);
		GUIQuestionPage(Controller.TopPage()).OnButtonClick = OnOkButtonClick;
		return;
    }

    if( MVRI.GameConfig.Length < MVRI.GameConfigCount || MVRI.MapList.Length < MVRI.MapCount )
    {
		Controller.OpenMenu("GUI2K4.GUI2K4QuestionPage");
		GUIQuestionPage( Controller.TopPage() ).SetupQuestion( lmsgReplicationNotFinished@string( MVRI.MapList.Length / MVRI.MapCount * 100 )$"% Completed", QBTN_Ok, QBTN_Ok );
		GUIQuestionPage( Controller.TopPage() ).OnButtonClick = OnOkButtonClick;
		return;
    }

    for( i=0; i<MVRI.GameConfig.Length; i++ )
    	co_GameType.AddItem( MVRI.GameConfig[i].GameName, none, string(i));
    co_GameType.MyComboBox.List.SortList();

	t_WindowTitle.Caption = t_WindowTitle.Caption@"("$lmsgMode[MVRI.Mode]$")";

   	lb_MapListBox.LoadList(MVRI);

   	MapVoteCountMultiColumnList(lb_VoteCountListBox.List).LoadList(MVRI);

    lb_VoteCountListBox.List.OnDblClick = MapListDblClick;
    lb_VoteCountListBox.List.bDropTarget = True;

    lb_MapListBox.List.OnDblClick = MapListDblClick;
    lb_MaplistBox.List.bDropSource = True;
    co_GameType.OnChange = GameTypeChanged;
    f_Chat.OnSubmit = Submit;

    // set starting gametype to current
    d = co_GameType.MyComboBox.List.FindExtra(string(MVRI.CurrentGameConfig));
    if( d > -1 )
	   	co_GameType.SetIndex(d);

   	VotingOpened();
}

function VotingOpened()
{
	local BTClient_MapVoteFooter footer;

	footer = BTClient_MapVoteFooter(f_Chat);
	footer.OnRandom = RandomClicked;
}

function RandomClicked()
{
	local int GameConfigIndex;
	local int randomMapIndex;
	local int generationAttempts;

	rng:
	randomMapIndex = Rand( MVRI.MapList.Length );
	if( !MVRI.MapList[randomMapIndex].bEnabled )
	{
		if( generationAttempts >= 10 )
		{
			PlayerOwner().ClientMessage(lmsgMapDisabled);
			return;
		}

		++ generationAttempts;
		goto rng;
	}

	GameConfigIndex = int(co_GameType.GetExtra());
	MVRI.SendMapVote( randomMapIndex, GameConfigIndex );
}

defaultproperties
{
    WinLeft=0.05
    WinTop=0.05
    WinWidth=0.9
    WinHeight=0.9

     Begin Object class=moComboBox Name=GameTypeCombo
		WinWidth=0.48
		WinHeight=0.037500
		WinLeft=0.5
		WinTop=0.04
		Caption="Filter Game Type:"
        CaptionWidth=0.35
		bScaleToParent=True
		bBoundToParent=true
    End Object
    co_GameType=GameTypeCombo

    Begin Object Class=BTClient_MapVoteMultiColumnListBox Name=MapListBox
		WinWidth=0.96
		WinHeight=0.60
		WinLeft=0.02
		WinTop=0.08
        bVisibleWhenEmpty=true
        StyleName="NoBackground"
        //StyleName="ServerBrowserGrid"
        bScaleToParent=True
        bBoundToParent=True
        FontScale=FNS_Small
        HeaderColumnPerc(0)=0.40
        HeaderColumnPerc(1)=0.20
        HeaderColumnPerc(2)=0.20
        HeaderColumnPerc(3)=0.10
        HeaderColumnPerc(4)=0.10
    End Object
    lb_MapListBox = MapListBox

    Begin Object Class=MapVoteCountMultiColumnListBox Name=VoteCountListBox
    	WinWidth=0.42
		WinHeight=0.291406
		WinLeft=0.02
		WinTop=0.686457
        bVisibleWhenEmpty=true
        StyleName="NoBackground"
        bScaleToParent=True
        bBoundToParent=True
        FontScale=FNS_Small
        HeaderColumnPerc(0)=0.30
        HeaderColumnPerc(1)=0.40
        HeaderColumnPerc(2)=0.30
    End Object
    lb_VoteCountListBox = VoteCountListBox

	Begin Object Class=BTClient_MapVoteFooter Name=MatchSetupFooter
		WinWidth=0.530000
		WinHeight=0.291406
		WinLeft=0.450000
		WinTop=0.686457
		TabOrder=10
		RenderWeight=0.5
		bBoundToParent=True
		bScaleToParent=True
	End Object
	f_Chat=MatchSetupFooter

	Begin Object Class=GUIImage Name=MapCountListBackground
		WinWidth=0.98
		WinHeight=0.223770
		WinLeft=0.01
		WinTop=0.052930
		Image=none
		ImageStyle=ISTY_Stretched
        OnDraw=AlignBK
	End Object
	i_MapCountListBackground=MapCountListBackground

   	Begin Object Class=GUIImage Name=MapListBackground
		WinWidth=0.98
		WinHeight=0.316542
		WinLeft=0.01
		WinTop=0.371020
		Image=none
		ImageStyle=ISTY_Stretched
	End Object
	i_MapListBackground=MapListBackground
}
