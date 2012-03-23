//==============================================================================
// BTClient_SoloFinish.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
			Display a complex message to all clients about a new solo record
*/
//	Coded by Eliot
//	Updated @ 19/11/2009
//==============================================================================
Class BTClient_SoloFinish Extends CriticalEventPlus;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	// Pass a non color code string so RenderComplexMessage receives the correct XL, YL
	return Class'GUIComponent'.Static.StripColorCodes( BTClient_ClientReplication(OptionalObject).SFMSG );
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
	local float CurX, CurY;
	local byte A;

	C.SetPos( C.CurX-8, C.CurY-8 );
	CurX = C.CurX;
	CurY = C.CurY;

	A = C.DrawColor.A*0.50;
	C.DrawColor = Class'BTClient_Config'.Static.FindSavedData().CTable;
	C.DrawColor.A = A;
	C.Style = 1;
	C.DrawTile( Class'BTClient_Interaction'.Default.Layer, XL+16, YL+16, 0, 0, 256, 256 );

	// Draw the lines
	C.DrawColor = Class'HUD'.Default.GrayColor;
	C.DrawColor.A = A;

	// 2 = addional pixel to fill corners
	C.SetPos( CurX-2, CurY );
	if( A > 20 )
	{
		DrawHorizontal( C, C.CurY, XL+18 );
		DrawHorizontal( C, C.CurY+YL+16, XL+18 );

		DrawVertical( C, C.CurX, YL+18 );
		DrawVertical( C, C.CurX+XL+18, YL+18 );
	}

	C.CurX += 8;
	C.CurY += 12;

	// Text
	C.SetPos( C.CurX, C.CurY );
	// Use SFMSG instead of MessageString because messagestring colours were stripped by GetString
	C.DrawTextClipped( BTClient_ClientReplication(OptionalObject).SFMSG, True );
}

// Taken from the canvas class. Changed to a different texture
final static function DrawHorizontal( Canvas C, float Y, float width)
{
	local float cx,cy;

	CX = C.CurX; CY = C.CurY;
	C.CurY = Y;
	C.DrawTile(Texture'ucgeneric.solidcolours.Black', width, 2, 0, 0, 2, 2);
	C.CurX = CX; C.CurY = CY;
}

// Taken from the canvas class. Changed to a different texture
final static function DrawVertical( Canvas C, float X, float height)
{
	local float cX,cY;

	CX = C.CurX; CY = C.CurY;
	C.CurX = X;
	C.DrawTile(Texture'ucgeneric.solidcolours.Black', 2, height, 0, 0, 2, 2);
	C.CurX = CX; C.CurY = CY;
}

DefaultProperties
{
	Lifetime=6
	bComplexString=True
	//bIsSpecial=False

	DrawColor=(R=255,G=128,B=0)
	FontSize=-2

	StackMode=SM_Down
	PosY=0.3
}
