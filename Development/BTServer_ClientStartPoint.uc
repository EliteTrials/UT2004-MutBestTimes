//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_ClientStartPoint extends PlayerStart
	notplaceable;

function Reset()
{
	Destroy();
}

defaultproperties
{
	bEnabled=False
	bStatic=False
	bNoDelete=False
}
