class BTGUI_ScoreboardBase extends FloatingWindow;

function AddSystemMenu()
{
	local eFontScale tFontScale;

	b_ExitButton = GUIButton(t_WindowTitle.AddComponent( "XInterface.GUIButton" ));
	b_ExitButton.Style = Controller.GetStyle("BTCloseButton",tFontScale);
	b_ExitButton.OnClick = XButtonClicked;
	b_ExitButton.bNeverFocus=true;
	b_ExitButton.FocusInstead = t_WindowTitle;
	b_ExitButton.RenderWeight=1;
	b_ExitButton.bScaleToParent=false;
	b_ExitButton.bStandardized=false;
	b_ExitButton.OnPreDraw = SystemMenuPreDraw;
	b_ExitButton.Caption = "X";

	// Do not want OnClick() called from MousePressed()
	b_ExitButton.bRepeatClick = False;
	BackgroundColor = class'BTClient_Config'.default.CTable;
}

function bool SystemMenuPreDraw(canvas Canvas)
{
	b_ExitButton.SetPosition( t_WindowTitle.ActualLeft() + t_WindowTitle.ActualWidth() - b_ExitButton.ActualWidth(), t_WindowTitle.ActualTop(), 24, 24, true);
	b_ExitButton.ActualWidth( t_WindowTitle.ActualHeight(), true );
	b_ExitButton.ActualHeight( t_WindowTitle.ActualHeight(), true );
	return true;
}

defaultproperties
{
	i_FrameBG=none
	Background=Texture'BTScoreBoardBG'
	BackgroundRStyle=MSTY_Normal

    Begin Object Class=GUIHeader Name=TitleBar
        WinLeft=0.6
        WinWidth=0.395
        WinTop=0.01
        WinHeight=0.034286
        RenderWeight=0.1
        FontScale=FNS_Small
        Justification=TXTA_Left
        TextIndent=4
        bUseTextHeight=True
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