//==============================================================================
// BTClient_TrialScoreBoard.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Dynamic F1 Scoreboard
*/
//  Coded by Eliot
//  Updated @ 14/09/2009
//  Updated @ 18/09/2011
//==============================================================================
Class BTClient_TrialScoreBoard Extends ScoreBoard;

//Warning: BTClient_TrialScoreBoard STR-TechChallenge-11.BTClient_TrialScoreBoard (function ClientBTimesV3K.BTClient_TrialScoreBoard.UpdateScoreBoard:0233) Accessed None 'GRI'
//Warning: BTClient_TrialScoreBoard STR-TechChallenge-11.BTClient_TrialScoreBoard (Function ClientBTimesV3K.BTClient_TrialScoreBoard.UpdateScoreBoard:1685) Accessed None 'A1233320'

var() string
    Header_Rank,
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
var const color PrimaryColor, SecondaryColor;
var transient color TempColor;

var int SavedElapsedTime;

var float       YOffset,
                NX,
                OX,
                OSize,
                DX,
                TX,
                PX,
                ETX,
                HX,
                LX,
                LXL,
                NXL,
                OXL,
                DXL,
                TXL, OTHERX, OTHERXL;

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

/** Returns color A as a color tag. */
static final preoperator string $( Color A )
{
    return (Chr( 0x1B ) $ (Chr( Max( A.R, 1 )  ) $ Chr( Max( A.G, 1 ) ) $ Chr( Max( A.B, 1 ) )));
}

/** Adds B as a color tag to the end of A. */
static final operator(40) string $( coerce string A, Color B )
{
    return A $ $B;
}

/** Adds A as a color tag to the begin of B. */
static final operator(40) string $( Color A, coerce string B )
{
    return $A $ B;
}

static function string GetCName( PlayerReplicationInfo PRI )
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

Simulated static Function BTClient_ClientReplication GetCRI( PlayerReplicationInfo PRI )
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

simulated static function LinkedReplicationInfo GetGRI( PlayerReplicationInfo PRI )
{
    local LinkedReplicationInfo LRI;

    for( LRI = PRI.CustomReplicationInfo; LRI != None; LRI = LRI.NextReplicationInfo )
    {
        if( LRI.IsA('GroupPlayerLinkedReplicationInfo') )
        {
            return LRI;
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
                TY,
                PTime,
                PredictedPY,
                PredictedSY,
                rowTileX, rowTextX,
                rowTileY, rowTextY,
                rowWidth, rowHeight, rowMargin, rowSegmentHeight;

    local int i, j;
    local array<PlayerReplicationInfo> SortedPlayers, SortedSpectators;
    local bool bSkipSpectators;
    local string NextText, s;
    local BTClient_ClientReplication CRI;

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

    C.Font = myInter.GetScreenFont( C );
    C.StrLen( "T", XL, YL );
    rowMargin = 4;
    rowHeight = YL*2 + 4;
    rowSegmentHeight = YL;

    if( SortedPlayers.Length != 0 )
    {
        PredictedPY = SortedPlayers.Length*(rowHeight + rowMargin);
    }
    PredictedPY += YL*3; // columns level 1&2

    if( SortedSpectators.Length != 0 )
    {
        PredictedSY = SortedSpectators.Length*(rowHeight + rowMargin);
        if( SortedPlayers.Length == 0 )
            PredictedSY += YL;
    }

    // Draw Scoreboard Table, Fill whole screen except X/Y ClipOffset pixels on each side
    X = C.ClipX-(XClipOffset*2);
    rowWidth = X - 8;
    Y = Min( PredictedPY + PredictedSY, C.ClipY-(YClipOffset*2) + 4 ); // 4 = spacing
    C.SetPos( XClipOffset, YClipOffset );
    C.DrawColor = myInter.Options.CTable;
    C.DrawTile( myInter.AlphaLayer, X, Y, 0, 0, 256, 256 );

    // Draw Level Title
    s = "Playing" @ Outer.Name;
    C.StrLen( s, XL, YL );
    C.SetPos( XClipOffset, YClipOffset - YL-8-4 );
    C.DrawColor = myInter.Options.CTable;
    C.DrawTile( myInter.AlphaLayer, XL+8+8, YL+8+4, 0, 0, 256, 256 );

    C.DrawColor = #0x0072C688;
    myInter.DrawColumnTile( C, XClipOffset+4, YClipOffset - YL-4-4, XL + /**COLUMN_PADDING_X*/4*2, YL+4/**COLUMN_PADDING_Y*/ );
    myInter.DrawHeaderText( C, XClipOffset+4, YClipOffset - YL-4-4, s );

    // C.DrawColor = HUDClass.Default.GoldColor;
    // C.SetPos( XClipOffset+4, YClipOffset - YL-4 );
    // C.DrawText( s );

    // Draw Level Author
    s = "Map by" @ Level.Author;
    C.StrLen( s, XL, YL );
    C.SetPos( XClipOffset+X-XL-4*2-8, YClipOffset + Y );
    C.DrawColor = myInter.Options.CTable;
    C.DrawTile( myInter.AlphaLayer, XL+8+8, YL+8+4, 0, 0, 256, 256 );

    C.DrawColor = #0x00529688;
    myInter.DrawColumnTile( C, XClipOffset+X-XL-12, YClipOffset + Y+4, XL + /**COLUMN_PADDING_X*/4*2, YL+4/**COLUMN_PADDING_Y*/ );
    myInter.DrawHeaderText( C, XClipOffset+X-XL-12, YClipOffset + Y+4, s );

    TY = YClipOffset+8;

    // Pre-Header

    // Calc Level
    HX = XClipOffset+4+2;   // 4 = table offset, 2 = text X offset
    LX = HX;
    C.StrLen( "Team", LXL, YL );    // Level Width
    LXL += 2;

    // Calc Name
    HX += 18+LXL+4;
    NX = HX;
    C.StrLen( "WWWWWWWWWWWWWWWWWWWW", NXL, YL );    // Name Width

    // Calc Objectives
    HX += 20+NXL;
    C.StrLen( class'ScoreBoardDeathMatch'.default.PointsText, XL, YL );
    OX = HX;
    C.StrLen( "000000000", OXL, YL );   // Obj Width

    // Calc Deaths
    HX += 18+OXL;
    C.StrLen( class'ScoreBoardDeathMatch'.default.DeathsText, XL, YL );
    DX = HX;

    C.StrLen( "0000000", DXL, YL ); // Deaths Width

    // Calc Time
    HX += 18+DXL;
    C.StrLen( Header_Time, XL, YL );
    TX = HX;
    C.StrLen( "00:00:00.00", TXL, YL ); // Time Width

    // Calc Other
    HX += 40+TXL;
    C.StrLen( "Other", XL, YL );
    OTHERX = HX;
    C.StrLen( "WWWWWWWWWWWWWWWWWWWW", OTHERXL, YL );

    // Fits screen?
    if( X+XClipOffset <= OTHERX + OTHERXL )
    {
        OTHERX = 0;
    }

    // DrawHeaderTile( C, drawX + COLUMN_MARGIN, drawY, columns[columnIdx].W - COLUMN_MARGIN*2, columns[columnIdx].H );
    // DrawHeaderText( C, drawX, drawY + COLUMN_PADDING_Y, PlayersRankingColumns[columnIdx].Title );

    C.SetPos( TX, TY );
    myInter.DrawHeaderTile( C, TX, TY, TXL+4, YL );
    myInter.DrawHeaderText( C, TX, TY, Header_ElapsedTime );

    C.SetPos( TX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( "Personal Record" );

    C.SetPos( LX, TY );
    myInter.DrawHeaderTile( C, LX, TY, LXL+4, YL );
    myInter.DrawHeaderText( C, LX, TY, "Team" );

    C.SetPos( LX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( Header_Rank );

    // Draw Players Info Header
    C.SetPos( NX, TY );
    myInter.DrawHeaderTile( C, NX, TY, NXL+4, YL );
    myInter.DrawHeaderText( C, NX, TY, Header_Name );

    C.SetPos( NX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( "Region" );

    C.SetPos( OX, TY );
    myInter.DrawHeaderTile( C, OX, TY, OXL+4, YL );
    myInter.DrawHeaderText( C, OX, TY, class'ScoreBoardDeathMatch'.default.PointsText );

    C.SetPos( OX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( "Objectives" );

    C.SetPos( DX, TY );
    myInter.DrawHeaderTile( C, DX, TY, DXL+4, YL );
    myInter.DrawHeaderText( C, DX, TY, class'ScoreBoardDeathMatch'.default.DeathsText );

    if( OTHERX != 0 )
    {
        C.SetPos( OTHERX, TY );
        myInter.DrawHeaderTile( C, OTHERX, TY, OTHERXL+4, YL );
        myInter.DrawHeaderText( C, OTHERX, TY, "Other" );
    }

    // Header done

    // Calc Ping
    if( Level.NetMode != NM_Standalone )
    {
        C.StrLen( class'ScoreBoardDeathMatch'.default.NetText, XL, YL );
        PX = ((XClipOffset+X)-XL);

        C.SetPos( PX - 4, TY );
        myInter.DrawHeaderTile( C, PX-8, TY, XL+4, YL );
        myInter.DrawHeaderText( C, PX-8, TY, class'ScoreBoardDeathMatch'.default.NetText );

        C.SetPos( PX - 4, TY+YL+2 );
        C.DrawColor = SecondaryColor;
        C.DrawText( "P/L" );
    }

    // Get Height of this font
    C.StrLen( "A", XL, YL );
    // 4 = offset from table
    rowTileX = XClipOffset + 4;
    rowTextX = rowTileX + 4;

    YOffset = TY-4;

    // Draw Players
    j = SortedPlayers.Length;
    for( i = 0; i < j; ++ i )
    {
        if( SortedPlayers[i] == None )
            continue;

        if( YOffset+YL*2+rowMargin+4 >= C.ClipY-YClipOffset )
            break;

        YOffset += YL*2+rowMargin+4;
        RenderPlayerRow( C, SortedPlayers[i], rowTileX, YOffset, rowWidth, rowHeight );
    }

    if( bSkipSpectators || SortedSpectators.Length == 0 )
        return;

    // Draw Spectators
    j = SortedSpectators.Length;
    for( i = 0; i < j; ++ i )
    {
        if( SortedSpectators[i] == None )
            continue;

        if( YOffset+YL*2+rowMargin+4 >= C.ClipY-YClipOffset )
            break;

        YOffset += YL*2+rowMargin+4;
        RenderPlayerRow( C, SortedSpectators[i], rowTileX, YOffset, rowWidth, rowHeight );
    }
}

function RenderPlayerRow( Canvas C, PlayerReplicationInfo player, float x, float y, float rowWidth, float rowHeight )
{
    local float rowTileX, rowTileY, rowTextY, xl, yl;
    local float rowSegmentHeight;
    local string s;
    local bool isSpectator;
    local int i;

    local BTClient_ClientReplication CRI;
    local LinkedReplicationInfo GLRI;
    local ReplicationInfo other;

    rowTileX = x;
    rowTileY = y;
    rowTextY = rowTileY + 2;
    rowSegmentHeight = rowHeight*0.5;
    isSpectator = player.bIsSpectator || player.bOnlySpectator;

    CRI = GetCRI( player );
    // <BACKGROUND>
    if( player != PlayerController(Owner).PlayerReplicationInfo )
        C.DrawColor = #0x22222244;
    else C.DrawColor = #0x222222BB;

    if( CRI != none && CRI.bIsPremiumMember )
    {
        C.DrawColor.G = 200;
        C.DrawColor.B = 200;
        C.DrawColor.A -= 30;
    }

    if( player.bOutOfLives )
    {
        C.DrawColor.A = 20;
    }

    C.SetPos( rowTileX, rowTileY );
    C.DrawTile( myInter.AlphaLayer, rowWidth, rowHeight, 0, 0, 256, 256 );
    // </BACKGROUND>

    // <TEAM>
    C.DrawColor = GetPlayerTeamColor( player );
    C.DrawColor.A = 0x44;

    C.SetPos( rowTileX, rowTileY + rowSegmentHeight-2 );
    C.DrawTile( Texture'Engine.WhiteSquareTexture', 2, rowSegmentHeight, 0, 0, 1, 1 );

    C.SetPos( rowTileX, rowTileY + rowHeight-2 );
    C.DrawTile( Texture'Engine.WhiteSquareTexture', rowSegmentHeight, 2, 0, 0, 1, 1 );
    // </TEAM>

    // Draw Player Name
    C.SetPos( NX, rowTextY );
    C.DrawColor = PrimaryColor;
    C.DrawText( GetCName( player ) );

    // Draw Player Region
    C.SetPos( NX, rowTextY+rowSegmentHeight );
    s = "";
    if( player.bAdmin )
    {
        s = #0xFF0000FF$"[Admin] "$SecondaryColor;
    }
    if( player.bReadyToPlay && !isSpectator )
    {
        s $= #0xFF8800FF$"[" $ class'ScoreBoardDeathMatch'.default.ReadyText $ "] "$SecondaryColor;
    }
    if( CRI != none && CRI.bIsPremiumMember )
    {
        s $= #0x00FFFFFF$"[Premium] "$SecondaryColor;
    }

    if( isSpectator )
    {
        s $= #0xFFFF00FF$"";
    }
    else
    {
        s $= SecondaryColor$"";
    }
    s $= player.GetLocationName();
    C.DrawText( s );

    // Draw Rank
    if( CRI != none )
    {
        C.SetPos( LX+4, rowTextY );
        C.DrawColor = PrimaryColor;
        C.DrawText( CRI.Rank, True );
    }

    // Draw Score
    if( !isSpectator )
    {
        C.SetPos( OX, rowTextY );
        C.DrawColor = PrimaryColor;
        C.DrawText( string(Min( int(player.Score), 9999 )), True );

        if( ASPlayerReplicationInfo(player) != none && ASPlayerReplicationInfo(player).DisabledObjectivesCount+ASPlayerReplicationInfo(player).DisabledFinalObjective > 0 )
        {
            OSize = rowSegmentHeight*1.5f;

            // Draw Objectives
            C.SetPos( OX, rowTextY - (OSize - rowSegmentHeight)*0.5f + rowSegmentHeight );
            C.DrawTile( Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final', OSize-4, OSize-4, 0.0, 0.0, 128, 128 );

            s = string(ASPlayerReplicationInfo(player).DisabledObjectivesCount+ASPlayerReplicationInfo(player).DisabledFinalObjective);
            C.StrLen( s, XL, YL );
            C.SetPos( OX + OSize*0.5-5, rowTextY + rowSegmentHeight-1 );
            C.DrawColor = #0x009900FF;
            C.DrawText( s );
        }
    }

    if( !isSpectator )
    {
        // Draw Deaths
        C.SetPos( DX, rowTextY );
        C.DrawColor = PrimaryColor;
        C.DrawText( string(int(player.Deaths)) );
    }

    // Draw Time
    if( CRI != none && myInter.MRI.bSoloMap )
    {
        if( CRI.PersonalTime > 0 )
        {
            C.SetPos( TX, rowTextY+rowSegmentHeight );
            C.DrawColor = SecondaryColor;
            C.DrawText( Class'BTClient_Interaction'.Static.Strl( CRI.PersonalTime ) );
        }
    }

    if( (GRI.ElapsedTime > 0 && GRI.Winner == None) || SavedElapsedTime == 0 )
        SavedElapsedTime = GRI.ElapsedTime;

    C.SetPos( TX, rowTextY+2 );
    C.DrawColor = PrimaryColor;
    C.DrawText( Class'BTClient_Interaction'.Static.StrlNoMS( Max( 0, SavedElapsedTime-player.StartTime ) ) );

    if( OTHERX != 0 )
    {
        GLRI = GetGRI( player );
        if( GLRI != none )
        {
            i = int(GLRI.GetPropertyText("PlayerGroupId"));
            if( i != -1 )
            {
                foreach DynamicActors( class'ReplicationInfo', other )
                {
                    if( other.IsA('GroupInstance') && int(other.GetPropertyText("GroupId")) == i )
                    {
                        // Draw Other
                        C.SetPos( OTHERX, rowTextY );
                        SetPropertyText( string(Property'TempColor'.Name), other.GetPropertyText("GroupColor") );
                        C.DrawColor = TempColor;
                        C.DrawText( other.GetPropertyText("GroupName") );
                        break;
                    }
                }
            }
        }
    }

    if( Level.NetMode != NM_Standalone && !player.bBot )
    {
        s = string(Min( 999, 4*player.Ping ));
        C.StrLen( s, XL, YL );
        C.SetPos( rowTileX + rowWidth - XL - 4, rowTextY );
        C.DrawColor = PrimaryColor;
        C.DrawText( s );

        if( player.PacketLoss > 0 )
        {
            s = string(player.PacketLoss);
            C.StrLen( s, XL, YL );
            C.SetPos( rowTileX + rowWidth - XL - 4, rowTextY+rowSegmentHeight );
            C.DrawColor = SecondaryColor;
            C.DrawText( s );
        }
    }
}

final function Color GetPlayerTeamColor( PlayerReplicationInfo player )
{
    local Color c;

    if( player.Team != none )
    {
        if( player.Team.TeamIndex == 0 )
            c = HUDClass.Default.RedColor;
        else if( player.Team.TeamIndex == 1 )
            c = HUDClass.Default.BlueColor;
        else c = HUDClass.Default.GreenColor;
    }
    else if( player.bIsSpectator || player.bOnlySpectator )
    {
        c = HUDClass.default.GoldColor;
    }
    else
    {
        c = HUDClass.Default.GreenColor;
    }
    return c;
}

DefaultProperties
{
    XClipOffset=64
    YClipOffset=64

    Header_Rank="Rank"
    Header_Name="NAME"
    Header_Time="PERSONAL TIME"
    Header_Spectators="Spectators"
    Header_Players="Players"
    Header_ElapsedTime="TIME"

    HUDClass=Class'HudBase'

    GrayColor=(R=100,G=100,B=100,A=255)
    BGColor=(R=0,G=0,B=0,A=150)
    OrangeColor=(R=255,G=128,A=255)
    PrimaryColor=(R=255,G=255,B=255,A=255)
    SecondaryColor=(R=182,G=182,B=182,A=255)
}
