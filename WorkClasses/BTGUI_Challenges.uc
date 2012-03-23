class BTGUI_Challenges extends BTGUI_StatsTab;

function ShowPanel( bool bShow )
{
	super.ShowPanel( bShow );

	if( bShow && ClientData != none && PlayerOwner().Level.TimeSeconds > 5 )
	{
		if( ClientData.Challenges.Length > 0 )
			return;

		PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestChallenges" );
	}
}

function bool InternalOnDraw( Canvas C )
{
	local int i;
	local float YPos, XPos, XL, YL;

	if( ClientData == none )
		return false;

	C.Font = Font'UT2003Fonts.jFontSmallText800x600';
	YPos = Region.ActualTop() + 8;
	XPos = Region.ActualLeft();
	C.DrawColor = class'HUD'.default.WhiteColor;
	for( i = CurPos; i < ClientData.Challenges.Length; ++ i )
	{
		// Icon
		C.SetPos( XPos + 16, YPos - 8);
		C.Style = 1;
		C.DrawColor.A = 164;
		C.DrawTile( class'BTUI_TrophyState'.default.TrophyDefaultIcon, IconSize, IconSize, 0.0, 0.0, 128, 128 );
		C.DrawColor = class'HUD'.default.WhiteColor;
		C.Style = 3;

		C.Font = Font'UT2003Fonts.FontMono800x600';
		C.StrLen( ClientData.Challenges[i].Points, XL, YL );

		C.SetPos( XPos + 16 + (IconSize * 0.5f - XL * 0.5f), YPos + (IconSize * 0.5f - YL * 0.5f) - 8 );
		C.DrawTextClipped( ClientData.Challenges[i].Points );
		C.Font = Font'UT2003Fonts.jFontSmallText800x600';

		// Title
		C.SetPos( XPos + IconSize + 32, YPos );
		C.DrawTextClipped( ClientData.Challenges[i].Title );

		// Description
		YPos += YL;
		C.SetPos( XPos + IconSize + 32, YPos );
		C.DrawTextClipped( ClientData.Challenges[i].Description );

		YPos += YL + 16;

		if( YPos + YL*2 >= Region.ActualTop() + Region.ActualHeight() )
			break;
	}
	return true;
}

function bool OnKeyEvent( out byte Key, out byte State, float delta )
{
	if( State == 0x01 )
	{
		if( Key == 0xEC )
		{
			CurPos = Max( CurPos - 1, 0 );
			return true;
		}
		else if( Key == 0xED )
		{
			CurPos = Min( CurPos + 1, ClientData.Challenges.Length - 1 );
			return true;
		}
	}
	return false;
}

defaultproperties
{
	SummaryText="Below here are challenges that you can complete."

	OnKeyEvent=OnKeyEvent
}
