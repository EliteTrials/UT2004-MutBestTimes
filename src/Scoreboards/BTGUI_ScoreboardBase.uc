class BTGUI_ScoreboardBase extends FloatingWindow;

// Removed i_FrameBG access
function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	super(PopupPageBase).InitComponent( MyController, MyOwner );
	t_WindowTitle.SetCaption(WindowName);
	if ( bMoveAllowed )
	{
		t_WindowTitle.bAcceptsInput = true;
		t_WindowTitle.MouseCursorIndex = HeaderMouseCursorIndex;
	}
	AddSystemMenu();
}

// Removed i_FrameBG access
function bool AlignFrame(Canvas C)
{
	return bInit;
}

function AddSystemMenu()
{
	b_ExitButton = GUIButton(t_WindowTitle.AddComponent( "XInterface.GUIButton" ));
	b_ExitButton.Style = Controller.GetStyle( "BTCloseButton", t_WindowTitle.FontScale );
	b_ExitButton.OnClick = XButtonClicked;
	b_ExitButton.bNeverFocus=true;
	b_ExitButton.FocusInstead = t_WindowTitle;
	b_ExitButton.RenderWeight=1.0;
	b_ExitButton.bScaleToParent=false;
	b_ExitButton.bAutoShrink=false;
	b_ExitButton.OnPreDraw = SystemMenuPreDraw;
	b_ExitButton.Caption = "X";

	// Do not want OnClick() called from MousePressed()
	b_ExitButton.bRepeatClick = False;
	BackgroundColor = class'BTClient_Config'.default.CTable;
}

function bool SystemMenuPreDraw(canvas Canvas)
{
	b_ExitButton.SetPosition( t_WindowTitle.ActualLeft() + t_WindowTitle.ActualWidth() - b_ExitButton.ActualWidth(), t_WindowTitle.ActualTop(), t_WindowTitle.ActualHeight(), t_WindowTitle.ActualHeight(), true);
	return true;
}

defaultproperties
{
	i_FrameBG=none
	Background=Texture'BTScoreBoardBG'
	BackgroundRStyle=MSTY_Normal

    Begin Object Class=GUIHeader Name=TitleBar
        WinLeft=0.0
        WinWidth=1.0
        WinTop=0.0
        WinHeight=0.04
        RenderWeight=0.1
        FontScale=FNS_Large
        Justification=TXTA_Left
        TextIndent=4
        bUseTextHeight=false
        bAcceptsInput=True
        bNeverFocus=False
        bBoundToParent=true
        bScaleToParent=true
        OnMousePressed=FloatingMousePressed
        OnMouseRelease=FloatingMouseRelease
        ScalingType=SCALE_X
        StyleName="BTHeader"
    End Object
    t_WindowTitle=TitleBar
}