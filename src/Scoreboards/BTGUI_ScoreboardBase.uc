class BTGUI_ScoreboardBase extends FloatingWindow;

final function BTClient_Interaction GetInter()
{
	local int i;

	for( i = 0; i < Controller.ViewportOwner.LocalInteractions.Length; ++ i )
	{
		if( Controller.ViewportOwner.LocalInteractions[i].Class == class'BTClient_Interaction' )
			return BTClient_Interaction(Controller.ViewportOwner.LocalInteractions[i]);
	}
	return none;
}

simulated static function BTClient_ClientReplication GetCRI( PlayerReplicationInfo PRI )
{
    local LinkedReplicationInfo LRI;

    for( LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
    {
        if( BTClient_ClientReplication(LRI) != None )
        {
            return BTClient_ClientReplication(LRI);
        }
    }
    return none;
}

final function BTGUI_ScoreboardReplicationInfo GetBoardRep()
{
	local BTGUI_ScoreboardReplicationInfo rep;

	foreach PlayerOwner().DynamicActors( class'BTGUI_ScoreboardReplicationInfo', rep )
	{
		if( rep.MenuClass == class )
		{
			return rep;
		}
	}
	return none;
}


function AddSystemMenu()
{
	local eFontScale tFontScale;

	b_ExitButton = GUIButton(t_WindowTitle.AddComponent( "XInterface.GUIButton" ));
	b_ExitButton.Style = Controller.GetStyle("BTButton",tFontScale);
	b_ExitButton.OnClick = XButtonClicked;
	b_ExitButton.bNeverFocus=true;
	b_ExitButton.FocusInstead = t_WindowTitle;
	b_ExitButton.RenderWeight=1;
	b_ExitButton.bScaleToParent=false;
	b_ExitButton.OnPreDraw = SystemMenuPreDraw;
	b_ExitButton.Caption = "X";

	// Do not want OnClick() called from MousePressed()
	b_ExitButton.bRepeatClick = False;
}

function bool SystemMenuPreDraw(canvas Canvas)
{
	b_ExitButton.SetPosition( t_WindowTitle.ActualLeft() + t_WindowTitle.ActualWidth() - b_ExitButton.ActualWidth(), t_WindowTitle.ActualTop(), 24, 24, true);
	b_ExitButton.ActualWidth( t_WindowTitle.ActualHeight(), true );
	b_ExitButton.ActualHeight( t_WindowTitle.ActualHeight(), true );
	return true;
}

function bool InternalOnBackgroundDraw( Canvas C )
{
    C.DrawColor = class'BTClient_Config'.default.CTable;
    C.DrawTile( i_FrameBG.Image, i_FrameBG.ActualWidth(), i_FrameBG.ActualHeight(), 0, 0, 256, 256 );
    return true;
}

defaultproperties
{
	bAllowedAsLast=true

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