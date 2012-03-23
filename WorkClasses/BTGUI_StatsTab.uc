class BTGUI_StatsTab extends BTGUI_TabBase;

var automated GUIImage Region;

var automated GUIScrollTextBox Summary;
var private string SummaryText;

var() editinline protected BTClient_ClientReplication ClientData;

const RegionHeight = 128;
const IconSize = 64;

var editconst protected int CurPos;

#exec texture import name=regionBackground file=Images/Background.tga group="icons" mips=off DXT=5 alpha=1

var() texture RegionImage;

event Free()
{
	ClientData = none;
	super.Free();
}

function PostInitPanel()
{
	ClientData = MyMenu.MyInteraction.MRI.CR;
}

function InitComponent( GUIController InController, GUIComponent InOwner )
{
	super.InitComponent( InController, InOwner );
	Summary.MyScrollText.NewText = SummaryText;
	Summary.MyScrollBar.AlignThumb();
	Summary.MyScrollBar.UpdateGripPosition( 0 );
}

function bool InternalOnDraw( Canvas C )
{
	return false;
}

defaultproperties
{
	RegionImage=Material'InterfaceContent.Menu.EditBox' // Texture'regionBackground'

	Begin Object Class=GUIScrollTextBox Name=oSummary
		bBoundToParent=False
		bScaleToParent=False
		WinWidth=1.0
		WinHeight=0.06
		WinLeft=0.0
		WinTop=0.0
		StyleName="NoBackground"
		bNoTeletype=true
		bNeverFocus=true
	End Object
	Summary=oSummary

	Begin Object class=GUIImage name=oRegion
		bScaleToParent=True
		bBoundToParent=True
		WinWidth=1.0
		WinHeight=0.84
		WinLeft=0.0
		WinTop=0.06
		Image=None
		ImageColor=(R=255,G=255,B=255,A=128)
		ImageRenderStyle=MSTY_Alpha
		ImageStyle=ISTY_Stretched
		OnDraw=InternalOnDraw
	End Object
	Region=oRegion
}
