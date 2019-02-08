class BTClient_TrialScoreBoard extends ScoreBoard;

var() const string
    Header_Rank,
    Header_Name,
    Header_Objectives,
    Header_Score,
    Header_Deaths,
    SubHeader_Time,
    Header_Ping,
    Header_PacketLoss,
    Header_Players,
    Header_Spectators,
    Header_ElapsedTime;

var protected const Texture BackgroundTexture;
var protected const color GrayColor;
var protected const color PrimaryColor, SecondaryColor;

var() protected const float XClipOffset;
var() protected const float YClipOffset;

var protected BTClient_Config BTConfig; // Cached instance, see Init()
var protected const class<BTClient_Interaction> BTInterClass;

var protected transient string
    AdminSubText,
    ReadySubText,
    PremiumSubText;

var protected transient color TempColor;
var protected int SavedElapsedTime;
var protected float YOffset,
                NX, NXL,
                OX, OXL, OSize,
                DX, DXL,
                TX, TXL,
                PX, ETX, HX,
                LX, LXL,
                OTHERX, OTHERXL;

var protected array<PlayerReplicationInfo> SortedPlayers, SortedSpectators;

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

private static function LinkedReplicationInfo GetGRI( PlayerReplicationInfo PRI )
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

simulated function Init()
{
    super.Init();

    AdminSubText = #0xFF0000FF$"[Admin] "$SecondaryColor;
    ReadySubText = #0xFF8800FF$"[" $ class'ScoreBoardDeathMatch'.default.ReadyText $ "] "$SecondaryColor;
    PremiumSubText = #0x00FFFFFF$"[Premium] "$SecondaryColor;

    BTConfig = class'BTClient_Config'.static.FindSavedData();
}

simulated event DrawScoreboard(Canvas C)
{
	if(!UpdateGRI()) {
        return;
    }
    UpdateScoreBoard(C);
}

function bool UpdateGRI()
{
    local int i, j;

    if (!super.UpdateGRI()) {
        return false;
    }

    SortedPlayers.Length = 0;
    SortedSpectators.Length = 0;

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

        // Hide spectator bots!
        if( GRI.PRIArray[i].bBot )
        {
            continue;
        }

        SortedSpectators[SortedSpectators.Length] = GRI.PRIArray[i];
    }
    return true;
}

simulated function UpdateScoreBoard(Canvas C)
{
    local int i, j;
    local string s;

    local float X, Y, XL, YL, TY;
    local float PredictedPY, PredictedSY;
    local float rowTileX, rowTextX, rowWidth, rowHeight, rowMargin, rowSegmentHeight;

    if( GRI == none )
        return; // Still receiving server state...

    C.Font = BTInterClass.static.GetScreenFont( C );
    C.StrLen( "T", XL, YL );
    rowMargin = 2;
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
    Y = Min( PredictedPY + PredictedSY + 8, C.ClipY-(YClipOffset*2) + 4 ); // 4 = spacing
    C.SetPos( XClipOffset, YClipOffset );
    C.DrawColor = BTConfig.CTable;
    C.DrawTile( BackgroundTexture, X, Y, 0, 0, 256, 256 );

    // Draw Level Title
    s = "Playing" @ Outer.Name;
    C.StrLen( s, XL, YL );
    C.SetPos( XClipOffset, YClipOffset - YL-8-4 );
    C.DrawColor = BTConfig.CTable;
    C.DrawTile( BackgroundTexture, XL+8+8, YL+8+4, 0, 0, 256, 256 );

    C.DrawColor = #0x0072C688;
    BTInterClass.static.DrawColumnTile( C, XClipOffset+4, YClipOffset - YL-4-4, XL + /**COLUMN_PADDING_X*/4*2, YL+4/**COLUMN_PADDING_Y*/ );
    BTInterClass.static.DrawHeaderText( C, XClipOffset+4, YClipOffset - YL-4-4, s );

    // Draw Level Author
    s = "Map by" @ Level.Author;
    C.StrLen( s, XL, YL );
    C.SetPos( XClipOffset+X-XL-4*2-8, YClipOffset + Y );
    C.DrawColor = BTConfig.CTable;
    C.DrawTile( BackgroundTexture, XL+8+8, YL+8+4, 0, 0, 256, 256 );

    C.DrawColor = #0x00529688;
    BTInterClass.static.DrawColumnTile( C, XClipOffset+X-XL-12, YClipOffset + Y+4, XL + /**COLUMN_PADDING_X*/4*2, YL+4/**COLUMN_PADDING_Y*/ );
    BTInterClass.static.DrawHeaderText( C, XClipOffset+X-XL-12, YClipOffset + Y+4, s );

    TY = YClipOffset+8;

    // Pre-Header

    // Calc Level
    HX = XClipOffset+4;   // 4 = table offset, 2 = text X offset
    LX = HX;
    C.StrLen( Header_Rank, LXL, YL );    // Level Width

    // Calc Name
    HX += 8+LXL;
    NX = HX;
    C.StrLen( "WWWWWWWWWWWWWWWWWWWW", NXL, YL );    // Name Width

    // Calc Objectives
    HX += 8+NXL;
    // C.StrLen( class'ScoreBoardDeathMatch'.default.PointsText, XL, YL );
    OX = HX;
    C.StrLen( "000000000", OXL, YL );   // Obj Width

    // Calc Deaths
    HX += 8+OXL;
    // C.StrLen( class'ScoreBoardDeathMatch'.default.DeathsText, XL, YL );
    DX = HX;

    C.StrLen( "0000000", DXL, YL ); // Deaths Width

    // Calc Time
    HX += 8+DXL;
    // C.StrLen( SubHeader_Time, XL, YL );
    TX = HX;
    C.StrLen( "00:00:00.00", TXL, YL ); // Time Width

    // Calc Other
    HX += 60+TXL;
    // C.StrLen( "Other", XL, YL );
    OTHERX = HX;
    C.StrLen( "WWWWWWWWWWWWWWWWWWWW", OTHERXL, YL );

    // Fits screen?
    if( X+XClipOffset <= OTHERX + OTHERXL )
    {
        OTHERX = 0;
    }

    C.SetPos( LX, TY );
    BTInterClass.static.DrawHeaderTile( C, LX, TY, LXL+4, YL );
    BTInterClass.static.DrawHeaderText( C, LX, TY, Header_Rank );

    // Draw Players Info Header
    C.SetPos( NX, TY );
    BTInterClass.static.DrawHeaderTile( C, NX, TY, NXL+4, YL );
    BTInterClass.static.DrawHeaderText( C, NX, TY, Header_Name );

    C.SetPos( NX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( "Region" );

    C.SetPos( OX, TY );
    BTInterClass.static.DrawHeaderTile( C, OX, TY, OXL+4, YL );
    BTInterClass.static.DrawHeaderText( C, OX, TY, class'ScoreBoardDeathMatch'.default.PointsText );

    C.SetPos( OX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( "Objectives" );

    C.SetPos( DX, TY );
    BTInterClass.static.DrawHeaderTile( C, DX, TY, DXL+4, YL );
    BTInterClass.static.DrawHeaderText( C, DX, TY, class'ScoreBoardDeathMatch'.default.DeathsText );

    C.SetPos( TX, TY );
    BTInterClass.static.DrawHeaderTile( C, TX, TY, TXL+4, YL );
    BTInterClass.static.DrawHeaderText( C, TX, TY, Header_ElapsedTime );

    C.SetPos( TX, TY+YL+2 );
    C.DrawColor = SecondaryColor;
    C.DrawText( SubHeader_Time );

    // if( OTHERX != 0 )
    // {
    //     C.SetPos( OTHERX, TY );
    //     BTInterClass.static.DrawHeaderTile( C, OTHERX, TY, OTHERXL+4, YL );
    //     BTInterClass.static.DrawHeaderText( C, OTHERX, TY, "Other" );
    // }

    // Header done

    // Calc Ping
    if( Level.NetMode != NM_Standalone )
    {
        C.StrLen( class'ScoreBoardDeathMatch'.default.NetText, XL, YL );
        PX = ((XClipOffset+X)-XL);

        C.SetPos( PX - 4, TY );
        BTInterClass.static.DrawHeaderTile( C, PX-8, TY, XL+4, YL );
        BTInterClass.static.DrawHeaderText( C, PX-8, TY, class'ScoreBoardDeathMatch'.default.NetText );

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

    if( SortedSpectators.Length == 0 )
        return;

    YOffset += 8;

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

protected function RenderPlayerRow(Canvas C, PlayerReplicationInfo player, float x, float y, float rowWidth, float rowHeight)
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

    CRI = class'BTClient_ClientReplication'.static.GetCRI( player );
    // <BACKGROUND>
    if( player != Controller(Owner).PlayerReplicationInfo )
        C.DrawColor = #0x22222282;
    else C.DrawColor = #0x4E4E3382;

    if( player.bOutOfLives )
    {
        C.DrawColor.A = 20;
    }

    // C.DrawColor = C.DrawColor + (GetPlayerTeamColor( player )*0.05f);

    C.SetPos( rowTileX, rowTileY );
    C.DrawTile( BackgroundTexture, rowWidth, rowHeight, 0, 0, 256, 256 );
    // </BACKGROUND>

    // Draw Player Name
    C.SetPos( NX, rowTextY );
    C.DrawColor = PrimaryColor;
    C.DrawText( GetCName( player ) );

    // Draw Player Region
    C.SetPos( NX, rowTextY+rowSegmentHeight );
    s = "";
    if( player.bAdmin )
    {
        s = AdminSubText;
    }
    if( player.bReadyToPlay && !isSpectator )
    {
        s $= ReadySubText;
    }
    if( CRI != none && CRI.bIsPremiumMember )
    {
        s $= PremiumSubText;
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
        C.DrawText( Eval(CRI.Rank != 0, CRI.Rank, "N/A"), true );
    }

    // Draw Score
    if( !isSpectator )
    {
        C.SetPos( OX, rowTextY );
        C.DrawColor = PrimaryColor;
        C.DrawText( string(Min( int(player.Score), 9999 )), true );

        if( ASPlayerReplicationInfo(player) != none && ASPlayerReplicationInfo(player).DisabledObjectivesCount+ASPlayerReplicationInfo(player).DisabledFinalObjective > 0 )
        {
            OSize = rowSegmentHeight*1.5f;

            // Draw Objectives
            C.SetPos( OX, rowTextY - (OSize - rowSegmentHeight)*0.5f + rowSegmentHeight );
            C.DrawTile( Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final', OSize-4, OSize-4, 0.0, 0.0, 128, 128 );

            s = string(ASPlayerReplicationInfo(player).DisabledObjectivesCount+ASPlayerReplicationInfo(player).DisabledFinalObjective);
            C.StrLen( s, XL, YL );
            C.SetPos( OX + OSize*0.5-XL*0.5, rowTextY + rowSegmentHeight-1 );
            C.DrawColor = HUDClass.default.GoldColor;
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
    if( CRI != none && CRI.PersonalTime > 0 )
    {
        C.SetPos( TX, rowTextY+rowSegmentHeight );
        C.DrawColor = SecondaryColor;
        C.DrawText( class'BTClient_Interaction'.static.Strl( CRI.PersonalTime ) );
    }

    if( (GRI.ElapsedTime > 0 && GRI.Winner == none) || SavedElapsedTime == 0 )
        SavedElapsedTime = GRI.ElapsedTime;

    C.SetPos( TX, rowTextY+2 );
    C.DrawColor = PrimaryColor;
    C.DrawText( class'BTClient_Interaction'.static.StrlNoMS( Max( 0, SavedElapsedTime-player.StartTime ) ) );

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

protected static function Color GetPlayerTeamColor(PlayerReplicationInfo player)
{
    local Color c;

    if( player.Team != none )
    {
        if( player.Team.TeamIndex == 0 )
            c = default.HUDClass.default.RedColor;
        else if( player.Team.TeamIndex == 1 )
            c = default.HUDClass.default.BlueColor;
        else c = default.HUDClass.default.GreenColor;
    }
    else if( player.bIsSpectator || player.bOnlySpectator )
    {
        c = default.HUDClass.default.GoldColor;
    }
    else
    {
        c = default.HUDClass.default.GreenColor;
    }
    return c;
}

defaultproperties
{
    XClipOffset=64
    YClipOffset=64

    Header_Spectators="Spectators"
    Header_Players="Players"

    Header_Rank="RANK"
    Header_Name="NAME"
    Header_ElapsedTime="TIME"

    SubHeader_Time="Record"

    HUDClass=class'HudBase'
    BTInterClass=class'BTClient_Interaction'
    BackgroundTexture=Texture'Engine.WhiteSquareTexture'

    GrayColor=(R=100,G=100,B=100,A=255)
    PrimaryColor=(R=255,G=255,B=255,A=255)
    SecondaryColor=(R=182,G=182,B=182,A=255)
}

#include classes/BTColorHashUtil.uci
#include classes/BTStringColorUtils.uci