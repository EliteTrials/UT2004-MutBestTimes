//==============================================================================
// Coded by Eliot aka Eliot van uytfanghe.
// Copyright (C) 2007-2008.
//==============================================================================
Class BTClient_MapVotingPage Extends MapVotingPage;

var automated GUIButton b_Random;

function OnOkButtonClick(byte bButton)
{
	if( bButton != QBTN_OK )
		Controller.CloseMenu( True );
}

function InternalOnOpen()
{
	local int i, d;

    if( MVRI == none || (MVRI != none && !MVRI.bMapVote) )
    {
		Controller.OpenMenu("GUI2K4.GUI2K4QuestionPage");
		GUIQuestionPage(Controller.TopPage()).SetupQuestion(lmsgMapVotingDisabled, QBTN_Ok, QBTN_Ok);
		GUIQuestionPage(Controller.TopPage()).OnButtonClick = OnOkButtonClick;
		return;
    }

    //if( MVRI.GameConfig.Length < MVRI.GameConfigCount || MVRI.MapList.Length < MVRI.MapCount )
    //{
		Controller.OpenMenu("GUI2K4.GUI2K4QuestionPage");
		GUIQuestionPage( Controller.TopPage() ).SetupQuestion( lmsgReplicationNotFinished@string( MVRI.MapList.Length / MVRI.MapCount * 100 )$"% Completed", QBTN_Ok | QBTN_Cancel, QBTN_Ok );
		GUIQuestionPage( Controller.TopPage() ).OnButtonClick = OnOkButtonClick;
    //}

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
}

Function bool InternalOnClick( GUIComponent Sender )
{
	local int GameConfigIndex;

	if( Sender == b_Random )
	{
		GameConfigIndex = int(co_GameType.GetExtra());
		MVRI.SendMapVote( 0, GameConfigIndex );
		return True;
	}
	return False;;
}

DefaultProperties
{
	Begin Object Class=GUIButton Name=RandomButton
		Caption="Random"
		WinWidth=0.114700
		WinHeight=0.161200
		WinLeft=0.50700
		WinTop=0.841000
		OnClick=InternalOnClick
		bStandardized=True
		bBoundToParent=True
		bScaleToParent=True
	End Object
	b_Random=RandomButton
}
