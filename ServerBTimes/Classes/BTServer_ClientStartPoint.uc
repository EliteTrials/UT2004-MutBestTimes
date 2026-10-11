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
    bEnabled=false
    bStatic=false
    bNoDelete=false

    CollisionRadius=1
    CollisionHeight=1
    bCollideWhenPlacing=false
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=false
    bMayCausePain=false
}
