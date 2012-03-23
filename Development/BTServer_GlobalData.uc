//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_GlobalData Extends Object;

struct sGlobalRecord
{
	var string GRN;																// Name
	var float GRT;																// Time (SECONDS.M'S)
	var string GRA;																// Author (GUID)
};

var array<sGlobalRecord> GRL;
