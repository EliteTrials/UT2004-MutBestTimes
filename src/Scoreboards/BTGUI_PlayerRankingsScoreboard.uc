class BTGUI_PlayerRankingsScoreboard extends BTGUI_ScoreboardBase;

var BTClient_Interaction Inter;

event Free()
{
	super.Free();
	Inter = none;
}

event InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	super.InitComponent( MyController, MyOwner );

    BackgroundColor = class'BTClient_Config'.default.CTable;
    // t_WindowTitle

    Inter = GetInter();
}

function bool InternalOnBackgroundDraw( Canvas C )
{
    C.DrawColor = class'BTClient_Config'.default.CTable;
    C.DrawTile( i_FrameBG.Image, i_FrameBG.ActualWidth(), i_FrameBG.ActualHeight(), 0, 0, 256, 256 );
    return true;
}

function bool InternalOnDraw( Canvas C )
{
	// C.OrgX = ActualLeft();
	// C.OrgY = ActualTop();
	// C.ClipX = ActualWidth();
	// C.ClipY = ActualHeight();
	Inter.RenderRankingsTable( C );
	return false;
}

defaultproperties
{
	WinLeft=0.00
	WinTop=0.50
	WinWidth=0.2
	WinHeight=0.60
	WindowName="Player Ranks"
	OnDraw=InternalOnDraw

	Begin Object Class=FloatingImage Name=FloatingFrameBackground
		Image=Texture'BTScoreBoardBG'
		ImageRenderStyle=MSTY_Normal
		ImageStyle=ISTY_Stretched
		ImageColor=(R=255,G=255,B=255,A=255)
		DropShadow=None
		OnDraw=InternalOnBackgroundDraw
		RenderWeight=0.000003
		bBoundToParent=True
		bScaleToParent=True
		WinWidth=1.0
		WinHeight=1.0
		WinLeft=0.0
		WinTop=0.0
	End Object
	i_FrameBG=FloatingFrameBackground

    Begin Object Class=GUIHeader Name=TitleBar
        WinWidth=0.980000
        WinHeight=0.034286
        WinLeft=0.010000
        WinTop=0.010000
        RenderWeight=0.1
        FontScale=FNS_Small
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