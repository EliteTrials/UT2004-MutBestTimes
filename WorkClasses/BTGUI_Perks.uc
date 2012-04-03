//==============================================================================
// Last updated at: $wotgreal_dt: 19/10/2011 1:40:58 $
//==============================================================================
class BTGUI_Perks extends BTGUI_StatsTab;

function ShowPanel( bool bShow )
{
	super.ShowPanel( bShow );

	if( bShow && ClientData != none && ClientData.Perks.Length == 0 )
	{
		PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestPerks" );
	}
}

function bool InternalOnDraw( Canvas C )
{
	local int i;
	local float YPos, XPos, XL, YL;

	if( ClientData == none )
		return false;

	C.Font = Font'UT2003Fonts.jFontSmallText800x600';
	YPos = Region.ActualTop();
	XPos = Region.ActualLeft();
	
	C.SetPos( XPos, YPos );
	C.Style = 3;
	C.DrawColor = class'HUD'.default.WhiteColor;
	C.DrawText( "Reach the said points to earn the perk!(TEST)" );
	YPos += 16;

	for( i = CurPos; i < ClientData.Perks.Length; ++ i )
	{
		// Icon
		YPos += 16;
		C.SetPos( XPos + 16, YPos );
		if( ClientData.Perks[i].bActive )
		{
			C.DrawColor = class'HUD'.default.GreenColor;
		}
		else
		{
			C.DrawColor = class'HUD'.default.RedColor;
		}
		C.Style = 1;
		C.DrawIcon( Clientdata.Perks[i].Icon, 1.0 );
		C.Style = 3;

		// Points
		C.StrLen( ClientData.Perks[i].Points, XL, YL );
		C.SetPos( XPos + 16 + (IconSize * 0.5f - XL * 0.5f), YPos + (IconSize * 0.5f - YL * 0.5f) );
		C.DrawColor = class'HUD'.default.WhiteColor;
		C.DrawTextClipped( ClientData.Perks[i].Points );

		// Title
		C.SetPos( XPos + IconSize + 32, YPos );
		C.DrawTextClipped( ClientData.Perks[i].Name );

		// Description
		YPos += YL;
		C.SetPos( XPos + IconSize + 32, YPos );
		C.DrawTextClipped( ClientData.Perks[i].Description );

		YPos += YL;
		YPos += 16;

		// Check if the next one will fit within the Canvas.
		if( YPos + YL*2 + 16 >= Region.ActualTop() + Region.ActualHeight() )
			break;
	}
	return true;
}

function bool OnKeyEvent( out byte Key, out byte State, float delta )
{
	if( State == 0x01 && ClientData != none )
	{
		if( Key == 0xEC )
		{
			CurPos = Max( CurPos - 1, 0 );
			return true;
		}
		else if( Key == 0xED )
		{
			CurPos = Min( CurPos + 1, ClientData.Perks.Length - 1 );
			return true;
		}
	}
	return false;
}

defaultproperties
{
	OnKeyEvent=OnKeyEvent
}
