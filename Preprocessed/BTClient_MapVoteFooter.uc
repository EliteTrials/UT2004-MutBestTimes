class BTClient_MapVoteFooter extends MapVoteFooter;

var automated GUIButton b_Random;

delegate OnRandom();

function bool InternalOnClick(GUIComponent Sender)
{
	if( super.InternalOnClick(sender) ){
		return true;
	}

	if( Sender == b_Random )
	{
		OnRandom();
		return true;
	}
}

function bool MyOnDraw(canvas C);

DefaultProperties
{
	Begin Object Class=AltSectionBackground Name=MapvoteFooterBackground
		Caption="Chat"
		WinWidth=1
		WinHeight=1.0
		WinLeft=0
		WinTop=0
		bBoundToParent=True
		bScaleToParent=True
		bFillClient=true
		LeftPadding=0.01
		RightPadding=0.01
	End Object
	sb_Background=MapvoteFooterBackground

	Begin Object Class=GUIScrollTextBox Name=ChatScrollBox
		WinWidth=0.918970
		WinHeight=0.582534
		WinLeft=0.043845
		WinTop=0.273580
		CharDelay=0.0025
		EOLDelay=0
        bBoundToParent=true
        bScaleToParent=true
		bVisibleWhenEmpty=true
        bNoTeletype=true
        bNeverFocus=true
		bStripColors=false
//		StyleName="NoBackground"
		StyleName="ServerBrowserGrid"
		TabOrder=2
	End Object
	lb_Chat=ChatScrollBox

	Begin Object Class=GUIButton Name=RandomButton
		Caption="Random"
		WinWidth=0.20
		WinHeight=0.18
		WinLeft=0.10
		WinTop=0.0
		OnClick=InternalOnClick
		TabOrder=1
		bStandardized=true
		bBoundToParent=true
		bScaleToParent=true
	End Object
	b_Random=RandomButton

	Begin Object class=moEditBox Name=ChatEditbox
		WinWidth=0.60
		WinHeight=0.18
		WinLeft=0.1
		WinTop=0.85
		Caption="Say"
		CaptionWidth=0.15
		OnKeyEvent=InternalOnKeyEvent
		TabOrder=0
		bStandardized=true
		bBoundToParent=true
		bScaleToParent=true
	End Object
	ed_Chat=ChatEditbox

	Begin Object Class=GUIButton Name=AcceptButton
		Caption="Accept"
		Hint="Click once you are satisfied with all settings and wish to offer no further modifications"
		WinWidth=0.20
		WinHeight=0.18
		WinLeft=0.30
		WinTop=0.0
		OnClick=InternalOnClick
		TabOrder=1
		bStandardized=true
		bBoundToParent=true
		bScaleToParent=true
		bVisible=false
	End Object
	b_Accept=AcceptButton

	Begin Object Class=GUIButton Name=SubmitButton
		Caption="Submit"
		WinWidth=0.20
		WinHeight=0.18
		WinLeft=0.70
		WinTop=0.0
		OnClick=InternalOnClick
		TabOrder=1
		bStandardized=true
		bBoundToParent=true
		bScaleToParent=true
	End Object
	b_Submit=SubmitButton

	Begin Object class=GUIButton Name=CloseButton
		Caption="Close"
		WinWidth=0.20
		WinHeight=0.18
		WinLeft=0.70
		WinTop=0.83
		OnClick=InternalOnClick
		TabOrder=1
		bStandardized=true
		bBoundToParent=true
		bScaleToParent=true
	End Object
	b_Close=CloseButton
}