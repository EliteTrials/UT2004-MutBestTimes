//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_SecondsTest Extends Info;

Event Timer()
{
	if( MutBestTimes(Owner) == None )
	{
		Destroy();
		return;
	}

	MutBestTimes(Owner).SecondsTest += 1.0;
}
