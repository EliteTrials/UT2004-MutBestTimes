//==============================================================================
// BTClient_TrialScoreBoard.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
			Dynamic F1 Scoreboard
*/
//	Coded by Eliot
//	Updated @ 14/09/2009
//	Updated @ 18/09/2011
//==============================================================================
Class BTClient_TrialScoreBoard Extends ScoreBoard;

//Warning: BTClient_TrialScoreBoard STR-TechChallenge-11.BTClient_TrialScoreBoard (function ClientBTimesV3K.BTClient_TrialScoreBoard.UpdateScoreBoard:0233) Accessed None 'GRI'
//Warning: BTClient_TrialScoreBoard STR-TechChallenge-11.BTClient_TrialScoreBoard (Function ClientBTimesV3K.BTClient_TrialScoreBoard.UpdateScoreBoard:1685) Accessed None 'A1233320'

var() string
	Header_Name,
	Header_Objectives,
	Header_Score,
	Header_Deaths,
	Header_Time,
	Header_Ping,
	Header_PacketLoss,
	Header_Players,
	Header_Spectators,
	Header_ElapsedTime;

var() float XClipOffset;
var() float YClipOffset;

var BTClient_Interaction myInter;

var const color GrayColor;
var const color BGColor;
var const color OrangeColor;

var int SavedElapsedTime;

Replication
{
	reliable if( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) )
		XClipOffset;
}

Simulated Function string GetCName( PlayerReplicationInfo PRI )
{
	local LinkedReplicationInfo LRI;
	local string N;

	for( LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
	{
		if( LRI.IsA('UTComp_PRI') )
		{
			N = LRI.GetPropertyText( "ColoredName" );
			if( Len( N ) == 0 )
				return PRI.PlayerName;

			return N;
		}
	}
	return PRI.PlayerName;
}

Simulated Function BTClient_ClientReplication GetCRI( PlayerReplicationInfo PRI )
{
	local LinkedReplicationInfo LRI;

	for( LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
	{
		if( BTClient_ClientReplication(LRI) != None )
		{
			return BTClient_ClientReplication(LRI);
		}
	}
	return none;
}

Simulated Function UpdateScoreBoard( Canvas C )
{
	local float
				X,
				Y,
				XL,
				YL,
				YOffset,
				NX,
				OX,
				OSize,
				DX,
				TX,
				PX,
				ETX,
				HX,
				NXL,
				OXL,
				DXL,
				TXL,
				TY,
				PTime,
				PredictedPY,
				PredictedSY;

	local int i, j;
	local array<PlayerReplicationInfo> SortedPlayers, SortedSpectators;
	local bool bSkipSpectators;
	local string NextText;
	local BTClient_ClientReplication CRI;

	goto 'F';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	F:

	if( GRI == none || myInter == none )
		return; // Still receiving server state...

	j = GRI.PRIArray.Length;
	// <Sort Players>

	// RED
	for( i = 0; i < j; ++ i )
	{
		if( GRI.PRIArray[i] == None || ((GRI.PRIArray[i].bOnlySpectator || GRI.PRIArray[i].bIsSpectator) && !GRI.PRIArray[i].bWaitingPlayer)
			|| (GRI.PRIArray[i].Team == none || GRI.PRIArray[i].Team.TeamIndex != 0) )
			continue;

		SortedPlayers[SortedPlayers.Length] = GRI.PRIArray[i];
	}

	// BLUE
	for( i = 0; i < j; ++ i )
	{
		if( GRI.PRIArray[i] == None || ((GRI.PRIArray[i].bOnlySpectator || GRI.PRIArray[i].bIsSpectator) && !GRI.PRIArray[i].bWaitingPlayer)
			|| (GRI.PRIArray[i].Team == none || GRI.PRIArray[i].Team.TeamIndex != 1) )
			continue;

		SortedPlayers[SortedPlayers.Length] = GRI.PRIArray[i];
	}

	// OTHER
	for( i = 0; i < j; ++ i )
	{
		if( GRI.PRIArray[i] == None || ((GRI.PRIArray[i].bOnlySpectator || GRI.PRIArray[i].bIsSpectator) && !GRI.PRIArray[i].bWaitingPlayer)
			|| (GRI.PRIArray[i].Team != none && GRI.PRIArray[i].Team.TeamIndex <= 1) )
			continue;

		SortedPlayers[SortedPlayers.Length] = GRI.PRIArray[i];
	}
	// </Sort Players>

	// Sort Spectators
	for( i = 0; i < j; ++ i )
	{
		if( GRI.PRIArray[i] == None || ((!GRI.PRIArray[i].bOnlySpectator && !GRI.PRIArray[i].bIsSpectator) || GRI.PRIArray[i].bWaitingPlayer) )
			continue;

		SortedSpectators[SortedSpectators.Length] = GRI.PRIArray[i];
	}

	//C.Font = HUDClass.static.GetConsoleFont( C );
	C.Font = class'BTClient_Interaction'.static.GetScreenFont( C );
	C.StrLen( "T", XL, YL );

	if( SortedPlayers.Length != 0 )
		PredictedPY = ((SortedPlayers.Length*(YL+4))+8+YL);

	if( SortedSpectators.Length != 0 )
	{
		PredictedSY = ((SortedSpectators.Length*(YL+4))+36+YL);
		if( SortedPlayers.Length == 0 )
			PredictedSY += YL;
	}

	// Draw Level Title
	NextText = "Trials in"@Outer.Name@"by"@Level.Author;
	C.StrLen( NextText, XL, YL );
	C.SetPos( ((C.ClipX*0.5)-(XL*0.5))-4, (YClipOffset*0.5)-(YL*0.5)-4 );
	C.Style = 1;
	C.DrawColor = Class'BTClient_Config'.Static.FindSavedData().CTable;
	C.DrawTile( Class'BTClient_Interaction'.Default.Layer, XL+8, YL+8, 0, 0, 256, 256 );

	// Border
	C.DrawColor = Class'HUD'.Default.GrayColor;
	C.DrawColor.A = 100;

	C.CurX = ((C.ClipX*0.5)-(XL*0.5))-4;
	C.CurY = (YClipOffset*0.5)-(YL*0.5)-4;
	// Parms: CurY, XLength
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, XL+8 );
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+YL+8, XL+8 );

	C.CurY -= 2;
	// Parms: CurX, YLength
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, YL+12 );
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+XL+8, YL+12 );
	// ...

	C.Style = 3;
	C.DrawColor = HUDClass.Default.GoldColor;
	C.SetPos( ((C.ClipX*0.5)-(XL*0.5)), (YClipOffset*0.5)-(YL*0.5) );
	C.DrawText( NextText, True );

	// Draw Scoreboard Table, Fill whole screen except X/Y ClipOffset pixels on each side
	X = C.ClipX-(XClipOffset*2);
	Y = Min( PredictedPY+PredictedSY+(YL*2), C.ClipY-(YClipOffset*2) );
	C.SetPos( XClipOffset, YClipOffset );
	C.Style = 1;
	C.DrawColor = Class'BTClient_Config'.Static.FindSavedData().CTable;
	C.DrawTile( Class'BTClient_Interaction'.Default.Layer, X, Y, 0, 0, 256, 256 );

	/*if( Level.Screenshot != none )
	{
		C.SetPos( XClipOffset, YClipOffset );
		C.DrawColor = Class'HUD'.Default.WhiteColor;
		C.DrawTileJustified( Level.Screenshot, 0, X, Y );
	}*/

	// Border
	C.DrawColor = Class'HUD'.Default.GrayColor;
	C.DrawColor.A = 100;

	C.CurX = XClipOffset;
	C.CurY = YClipOffset;
	// Parms: CurY, XLength
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY-2 /* Start 2pixels before */, X );
	Class'BTClient_SoloFinish'.Static.DrawHorizontal( C, C.CurY+Y, X );

	C.CurY -= 2;
	// Parms: CurX, YLength
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX-2, Y+4 );
	Class'BTClient_SoloFinish'.Static.DrawVertical( C, C.CurX+X, Y+4 );
	// ...

	C.Style = 3;

	// Draw Players Title
	C.StrLen( Header_Players, XL, YL );
	C.SetPos( ((C.ClipX*0.5)-(XL*0.5)), YClipOffset+4 );
	//C.SetPos( (XClipOffset*0.5)+((X*0.5)-(XL*0.5)), YClipOffset+4 );
	TY = YClipOffset+8+YL;
	C.DrawColor = HUDClass.Default.WhiteColor;
	C.DrawText( Header_Players, True );

	// Pre-Header
	// Calc Name
	HX = XClipOffset+26;
	//C.StrLen( Header_Name, XL, YL );
	NX = HX;

	C.StrLen( "WWWWWWWWWWWWWWWWWWWW", NXL, YL ); 	// Name Width

	// Calc Objectives
	HX += 26+NXL;
	C.StrLen( class'ScoreBoardDeathMatch'.default.PointsText, XL, YL );
	OX = HX;

	C.StrLen( "00000", OXL, YL );	// Obj Width

	if( myInter.MRI.bCompetitiveMode )
	{
		// Calc Deaths
		HX += XL+OXL;
		C.StrLen( class'ScoreBoardDeathMatch'.default.DeathsText, XL, YL );
		DX = HX;

		C.StrLen( "000", DXL, YL );	// Deaths Width
	}
	else DXL = OXL;

	// Calc Time
	HX += XL+DXL;
	C.StrLen( Header_Time, XL, YL );
	TX = HX;

	C.StrLen( "00:00", TXL, YL );	// Time Width

	goto 'Ff';
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	if( bool( int( bool( int( bool( int( bool( int( bool( int( bool( int( False ) ) ) ) ) ) ) ) ) ) ) ) )
	Ff:

	// Calc Start Time
	HX += XL+TXL;
	ETX = HX;

	if( myInter.MRI.bSoloMap )
	{
		C.SetPos( TX, TY );
		C.DrawText( Header_Time, True );
	}

	// Draw Players Info Header
	C.SetPos( NX, TY );
	C.DrawText( Header_Name, True );

	C.SetPos( OX, TY );
	C.DrawText( class'ScoreBoardDeathMatch'.default.PointsText, True );

	if( myInter.MRI.bCompetitiveMode )
	{
		C.SetPos( DX, TY );
		C.DrawText( class'ScoreBoardDeathMatch'.default.DeathsText, True );
	}

	C.SetPos( ETX, TY );
	C.DrawText( Header_ElapsedTime, True );

	// Header done

	// Calc Ping
	if( Level.NetMode != NM_Standalone )
	{
		//C.StrLen( "00:00:00.00", TXL, YL );
		//HX += XL+TXL;
		C.StrLen( class'ScoreBoardDeathMatch'.default.NetText, XL, YL );
		//PX = HX;
		PX = ((XClipOffset+X)-XL);

		C.SetPos( PX, TY );
		C.DrawText( class'ScoreBoardDeathMatch'.default.NetText, True );
	}

	// Get Height of this font
	C.StrLen( "A", XL, YL );

	YOffset = TY;

	// Draw Players
	j = SortedPlayers.Length;
	for( i = 0; i < j; ++ i )
	{
		if( SortedPlayers[i] == None )
			continue;

		if( YOffset+YL+4+PredictedSY >= C.ClipY-YClipOffset )
			break;

		CRI = GetCRI( SortedPlayers[i] );

		YOffset += YL+4;

		// <BACKGROUND>
		if( SortedPlayers[i].bAdmin )
			C.DrawColor = HUDClass.Default.RedColor;
		else
		{
			if( SortedPlayers[i] != PlayerController(Owner).PlayerReplicationInfo )
				C.DrawColor = Default.GrayColor;
			else C.DrawColor = C.MakeColor( 128, 128, 0, 255 );
		}

		if( SortedPlayers[i].bOutOfLives )
		{
			C.DrawColor.A = 60;
		}

		C.Style = 3;
		C.SetPos( XClipOffset+20, YOffset );
		C.DrawTile( Class'BTClient_Interaction'.Default.Layer, X-20, YL, 0, 0, 256, 256 );
		// </BACKGROUND>

		// <TEAM>
		if( SortedPlayers[i].Team != none )
		{
			if( SortedPlayers[i].Team.TeamIndex == 0 )
				C.DrawColor = HUDClass.Default.RedColor;
			else if( SortedPlayers[i].Team.TeamIndex == 1 )
				C.DrawColor = HUDClass.Default.BlueColor;
			else C.DrawColor = HUDClass.Default.GreenColor;
		}
		else C.DrawColor = HUDClass.Default.GreenColor;

		C.SetPos( XClipOffset, YOffset );
		C.DrawTile( Class'BTClient_Interaction'.Default.Layer, 20, YL, 0, 0, 256, 256 );
		// </TEAM>

		// Draw Player Name
		C.SetPos( NX, YOffset );
		C.DrawColor = HUDClass.Default.WhiteColor;
		C.Style = 1;
		C.DrawText( GetCName( SortedPlayers[i] )$Eval( SortedPlayers[i].bReadyToPlay, " (" $ class'ScoreBoardDeathMatch'.default.ReadyText $ ")", "" ), True );

		if( SortedPlayers[i].bBot )
			continue;

		// Draw BTLevel
		if( CRI != none )
		{
			C.SetPos( XClipOffset, YOffset );
			C.DrawText( CRI.BTLevel, True );
		}

		if( ASPlayerReplicationInfo(SortedPlayers[i]).DisabledObjectivesCount+ASPlayerReplicationInfo(SortedPlayers[i]).DisabledFinalObjective > 0 )
		{
			OSize = YL * 1.5f;

			// Draw Objectives
			C.SetPos( OX, YOffset - ((OSize - YL) * 0.5f) );
			C.DrawTile( Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final', OSize, OSize, 0.0, 0.0, 128, 128 );

	        NextText = string(ASPlayerReplicationInfo(SortedPlayers[i]).DisabledObjectivesCount+ASPlayerReplicationInfo(SortedPlayers[i]).DisabledFinalObjective);
	        C.StrLen( NextText, XL, YL );
			C.SetPos( (OX + OSize * 0.5f) - XL * 0.5f, YOffset );
			C.Style = 3;
			C.DrawText( NextText, True );
	       	C.Style = 1;

		   	// HACK:To move the score slightly
	       	OSize += 8;
	    }

		// Draw Score
   		C.SetPos( OX + OSize, YOffset );
		C.DrawText( string(Min( int(SortedPlayers[i].Score), 9999 )), True );

		if( myInter.MRI.bCompetitiveMode )
		{
	        // Draw Deaths
			C.SetPos( DX, YOffset );
			C.DrawText( string(int(SortedPlayers[i].Deaths)), True );
		}

		// Draw Time
		if( CRI != none && myInter.MRI.bSoloMap )
		{
			PTime = CRI.PersonalTime;
			if( PTime > 0 )
			{
				C.SetPos( TX, YOffset );
				C.DrawText( Class'BTClient_Interaction'.Static.Strl( PTime ), True );
			}
		}

		if( (GRI.ElapsedTime > 0 && GRI.Winner == None) || SavedElapsedTime == 0 )
			SavedElapsedTime = GRI.ElapsedTime;

		C.SetPos( ETX, YOffset );
		C.DrawText( Class'BTClient_Interaction'.Static.StrlNoMS( Max( 0, SavedElapsedTime-SortedPlayers[i].StartTime ) ), True );

		if( Level.NetMode != NM_Standalone )
		{
			NextText = Min( 999, 4*SortedPlayers[i].Ping ) $ Eval( SortedPlayers[i].PacketLoss > 0, "/" $ SortedPlayers[i].PacketLoss, "" );
			C.StrLen( NextText, XL, YL );
			C.SetPos( XClipOffset + X - XL, YOffset );
			C.DrawText( NextText, True );
		}
	}

	if( bSkipSpectators || SortedSpectators.Length == 0 )
		return;

	// Draw Spectators Title
	YOffset += 32;
	C.StrLen( Header_Spectators, XL, YL );
	C.SetPos( ((C.ClipX*0.5)-(XL*0.5)), YOffset );
	//C.SetPos( (XClipOffset*0.5)+((X*0.5)-(XL*0.5)), YOffset );
	C.DrawColor = HUDClass.Default.WhiteColor;
	C.DrawText( Header_Spectators, True );
	YOffset += 4+YL;

	// Draw Spectator Info
	C.SetPos( NX, YOffset );
	C.DrawText( Header_Name, True );

	if( myInter.MRI.bSoloMap )
	{
		C.SetPos( TX, YOffset );
		C.DrawText( Header_Time, True );
	}

	C.SetPos( ETX, YOffset );
	C.DrawText( Header_ElapsedTime, True );

	if( Level.NetMode != NM_Standalone )
	{
		C.SetPos( PX, YOffset );
		C.DrawText( class'ScoreBoardDeathMatch'.default.NetText, True );
	}

	// Draw Spectators
	j = SortedSpectators.Length;
	for( i = 0; i < j; ++ i )
	{
		if( SortedSpectators[i] == None )
			continue;

		if( YOffset+YL+4 >= C.ClipY-YClipOffset )
			break;

		CRI = GetCRI( SortedSpectators[i] );

		YOffset += YL+4;

		// Draw background for this player
		C.SetPos( XClipOffset, YOffset );
		if( SortedSpectators[i].bAdmin )
			C.DrawColor = HUDClass.Default.RedColor;
		else
		{
			if( SortedSpectators[i] != PlayerController(Owner).PlayerReplicationInfo )
				C.DrawColor = Default.GrayColor;
			else C.DrawColor = C.MakeColor( 128, 128, 0, 255 );
		}
		C.Style = 3;
		C.DrawTile( Class'BTClient_Interaction'.Default.Layer, X, YL, 0, 0, 256, 256 );
		C.Style = 1;

		// Draw Player Name
		C.SetPos( NX, YOffset );
		C.DrawColor = HUDClass.Default.WhiteColor;
		C.DrawText( GetCName( SortedSpectators[i] ), True );

		if( SortedSpectators[i].bBot )
			continue;

		// Draw Time
		if( CRI != none && myInter.MRI.bSoloMap )
		{
			PTime = CRI.PersonalTime;
			if( PTime > 0 )
			{
				C.SetPos( TX, YOffset );
				C.DrawText( Class'BTClient_Interaction'.Static.Strl( PTime ), True );
			}
		}

		if( (GRI.ElapsedTime > 0 && GRI.Winner == None) || SavedElapsedTime == 0 )
			SavedElapsedTime = GRI.ElapsedTime;

		C.SetPos( ETX, YOffset );
		C.DrawText(	Class'BTClient_Interaction'.Static.StrlNoMS( Max( 0, SavedElapsedTime-SortedSpectators[i].StartTime ) ), True );

		if( Level.NetMode != NM_Standalone )
		{
			NextText = Min( 999, 4*SortedSpectators[i].Ping ) $ Eval( SortedSpectators[i].PacketLoss > 0, "/" $ SortedSpectators[i].PacketLoss, "" );
			C.StrLen( NextText, XL, YL );
			C.SetPos( XClipOffset + X - XL, YOffset );
			C.DrawText( NextText, True );
		}
	}
}

DefaultProperties
{
	XClipOffset=64
	YClipOffset=64

	Header_Name="NAME"
	Header_Time="PERSONAL TIME"
	Header_Spectators="Spectators"
	Header_Players="Players"
	Header_ElapsedTime="TIME"

	HUDClass=Class'HudBase'

	GrayColor=(R=100,G=100,B=100,A=255)
	BGColor=(R=0,G=0,B=0,A=150)
	OrangeColor=(R=255,G=128,A=255)
}
