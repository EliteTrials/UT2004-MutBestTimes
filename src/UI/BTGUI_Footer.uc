class BTGUI_Footer extends GUIMultiComponent;

var automated GUILabel FooterLabel;

function SetText( coerce string newText )
{
	FooterLabel.Caption = newText;
}

defaultproperties
{
	begin object class=GUILabel name=oFooterLabel
		WinLeft=0.00
		WinWidth=1.0
		WinTop=0.0
		WinHeight=1.0
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        TextColor=(R=255,G=255,B=255,A=255)
        TextAlign=TXTA_Center
        bTransparent=false
        StyleName="BTFooter"
	end object
	FooterLabel=oFooterLabel
}