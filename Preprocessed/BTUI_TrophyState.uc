//==============================================================================
// BTUI_TrophyState.uc (C) 2005-2011 Eliot and .:..:. All Rights Reserved
/* Tasks:
			---
*/
//	Coded by Eliot
//==============================================================================
class BTUI_TrophyState extends CriticalEventPlus;

var() Texture TrophyBackground;
var() Texture TrophyDefaultIcon;
var() byte BGStyle;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
)
{
	return BTClient_ClientReplication(OptionalObject).LastTrophyEvent.Title;
}

static function float GetLongest( float XL1, float XL2 )
{
 	if( XL1 > XL2 )
 		return XL1;
 	else return XL2;
}

static function RenderComplexMessage(
	Canvas C,
	out float XL,
	out float YL,
	optional String MessageString,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
)
{
	local float XL1, XL2, YL1, YL2;
	local float XWidth;
	local float XP, YP, icoWidth;
	local string S;
	local float backgroundYL;
	local Color lastColor;

	lastColor = C.DrawColor;

	S = "TROPHY EARNED!";
	C.StrLen( S, XL1, YL1 );
	C.StrLen( MessageString, XL2, YL2 );
	XWidth = GetLongest( XL1, XL2 ) + 8;

	backgroundYL = (YL1 * 2) + 8;
	icoWidth = backgroundYL;
	XWidth += icoWidth + 8;
	C.CurX = C.ClipX * 0.5 - XWidth * 0.5f;
	XP = C.CurX;
	YP = C.CurY;// - backgroundYL * 0.5;

	C.DrawColor = Class'HUD'.Default.GrayColor;
	C.DrawColor.A = lastColor.A;
	class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP - 2, XWidth );
	Class'BTClient_SoloFinish'.static.DrawHorizontal( C, YP + backgroundYL, XWidth );
	C.CurY -= 2;
	Class'BTClient_SoloFinish'.static.DrawVertical( C, XP, backgroundYL + 4 );
	Class'BTClient_SoloFinish'.static.DrawVertical( C, XP + XWidth, backgroundYL + 4 );

	 //=== TROPHY BACKGROUND
	C.Style = default.BGStyle;
	C.DrawColor = lastColor;
	C.SetPos( XP, YP );
	C.DrawTileStretched( default.TrophyBackground, XWidth, backgroundYL );

	XP += 4;

	//=== TROPHY ICON
	C.SetPos( XP, YP );
	lastColor = C.DrawColor;
	C.DrawColor = class'HUD'.default.GreenColor;
	C.DrawColor.A = lastColor.A;
	C.Style = 1;
	C.DrawTile( default.TrophyDefaultIcon, backgroundYL, backgroundYL, 0.0, 0.0, 128, 128 );
	XP += icoWidth;   // Ico width
	C.DrawColor = lastColor;

	XP += 4;
	YP += 4;

	//=== VERTICAL LINE
	C.SetPos( XP, YP );
	C.Style = 3;
	C.DrawTileStretched( default.TrophyBackground, 1, backgroundYL - 8 );

	XP += 4;

	//=== TEXT
	C.DrawColor = C.MakeColor( 158, 195, 79 );
	C.DrawColor.A = lastColor.A;

	//=== MESSAGE
	C.Style = 1;
	XP += 4;    // Offset from ico
	C.SetPos( XP, YP );
	C.DrawText( S, true );

	//=== TROPHY TITLE
	C.StrLen( S, XWidth, YL1 );
	YP += YL1;
	C.SetPos( XP, YP );
	C.DrawText( MessageString, true );

	XL = XWidth;
	YL = backgroundYL;
}

defaultproperties
{
	BGStyle=3

	Lifetime=8
	bComplexString=true
	bIsSpecial=true

	DrawColor=(B=10,G=10,R=10,A=200)
	FontSize=-2

	StackMode=SM_None
	PosY=0.1

	TrophyBackground=Texture'BTScoreBoardBG'
	TrophyDefaultIcon=Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final'
}
