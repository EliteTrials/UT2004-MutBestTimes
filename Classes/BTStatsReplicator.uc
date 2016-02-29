class BTStatsReplicator extends Info;

var private int i, j;

var protected BTClient_ClientReplication CR;
var protected MutBestTimes P;
var protected int ItemsToSkip;
var protected string RankingsCategory;

/** Returns int A as a color tag. */
static final preoperator string $( int A )
{
    return (Chr( 0x1B ) $ (Chr( Max( byte(A & 0xFF000000), 1 )  ) $ Chr( Max( byte(A & 0x00FF0000), 1 ) ) $ Chr( Max( byte(A & 0x0000FF00), 1 ) )));
}

final function Initialize( BTClient_ClientReplication client, optional int queriedPageIndex, optional string category )
{
    if( client == none )
        return;

    CR = client;
    P = MutBestTimes(Owner);
    ItemsToSkip = queriedPageIndex*P.MaxRankedPlayers;
    RankingsCategory = category;
}

final function BeginReplication()
{
    switch( RankingsCategory )
    {
        case "All":
            GotoState( 'ReplicateOverallTop' );
            break;

        case "Monthly":
            GotoState( 'ReplicateQuarterlyTop' );
            break;

        case "Daily":
            GotoState( 'ReplicateDailyTop' );
            break;
    }
}

/** Strips all color tags from A. */
static final preoperator string %( string A )
{
    local int i;

    while( true )
    {
        i = InStr( A, Chr( 0x1B ) );
        if( i != -1 )
        {
            A = Left( A, i ) $ Mid( A, i + 4 );
            continue;
        }
        break;
    }
    return A;
}

final function InitGlobalPacket( int index, optional out BTClient_ClientReplication.sGlobalPacket GP )
{
    local int playerSlot;

    playerSlot = P.OverallTopList.Items[index];
    if( playerSlot == CR.myPlayerSlot )
        GP.Name = $0xFFFFFF00 $ P.PDat.Player[playerSlot].PLName;
    else GP.Name = P.PDat.Player[playerSlot].PLName;

    GP.PlayerId     = playerSlot + 1;
    GP.Points       = P.PDat.Player[playerSlot].PLPoints[0];
    GP.AP           = P.PDat.Player[playerSlot].PLAchiev;
    GP.Objectives   = P.PDat.Player[playerSlot].PLObjectives;
    GP.Hijacks      = P.PDat.Player[playerSlot].PLHijacks << 16 | P.PDat.Player[playerSlot].PLPersonalRecords[0];
}

final function SendOverallTop( int index, optional out BTClient_ClientReplication.sGlobalPacket GP )
{
    InitGlobalPacket( index, GP );
    CR.ClientSendOverallTop( GP );
}

state ReplicateOverallTop
{
Begin:
    // Send OverallTop players
    j = Min( P.OverallTopList.Items.Length, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        SendOverallTop( i+ItemsToSkip );
        if( Level.NetMode != NM_Standalone && i % 6 == 0 )
        {
            Sleep( 0.4 );
        }
    }
    Sleep( 1 );
    SendAdditionalInfo();
}

final function SendQuarterlyTop( int index, optional out BTClient_ClientReplication.sQuarterlyPacket QP )
{
    local int playerSlot;

    playerSlot = P.QuarterlyTopList.Items[index];
    QP.PlayerId     = playerSlot + 1;
    if( playerSlot == CR.myPlayerSlot )
        QP.Name = $0xFFFFFF00 $ P.PDat.Player[playerSlot].PLName;
    else QP.Name = P.PDat.Player[playerSlot].PLName;

    QP.Points       = P.PDat.Player[playerSlot].PLPoints[1];
    QP.Records      = P.PDat.Player[playerSlot].PLPersonalRecords[1];
    CR.ClientSendQuarterlyTop( QP );
}

state ReplicateQuarterlyTop
{
Begin:
    // Send QuarterlyTop players
    j = Min( P.QuarterlyTopList.Items.Length, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        SendQuarterlyTop( i+ItemsToSkip );
        if( Level.NetMode != NM_Standalone && (i+ItemsToSkip) % 6 == 0 )
        {
            Sleep( 0.4 );
        }
    }
    Sleep( 1 );
}

final function SendDailyTop( int index, optional out BTClient_ClientReplication.sDailyPacket DP )
{
    local int playerSlot;

    playerSlot = P.DailyTopList.Items[index];
    DP.PlayerId     = playerSlot + 1;
    if( playerSlot == CR.myPlayerSlot )
        DP.Name = $0xFFFFFF00 $ P.PDat.Player[playerSlot].PLName;
    else DP.Name = P.PDat.Player[playerSlot].PLName;

    DP.Points       = P.PDat.Player[playerSlot].PLPoints[2];
    DP.Records      = P.PDat.Player[playerSlot].PLPersonalRecords[2];
    CR.ClientSendDailyTop( DP );
}

state ReplicateDailyTop
{
Begin:
    // Send DailyTop players
    j = Min( P.DailyTopList.Items.Length, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        SendDailyTop( i+ItemsToSkip );
        if( Level.NetMode != NM_Standalone && (i+ItemsToSkip) % 6 == 0 )
        {
            Sleep( 0.4 );
        }
    }
    Sleep( 1 );
    GotoState( 'ReplicateSoloTop' );
}

state ReplicateSoloTop
{
    final function SendSoloTops()
    {
        local BTClient_ClientReplication.sSoloPacket SP;

        // Send Map Top (MaxRankedPlayers) structure
        j = P.RDat.Rec[P.UsedSlot].PSRL.Length;
        // Scan whole list, yes including people above <MaxRankedPlayer> cuz of PersonalOverallTop
        for( i = 0; i < j; ++ i )
        {
            SP.PlayerId = P.RDat.Rec[P.UsedSlot].PSRL[i].PLs;
            // Owner of record?
            if( P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1 == CR.myPlayerSlot )
            {
                CR.ClientSetPersonalTime( P.RDat.Rec[P.UsedSlot].PSRL[i].SRT );

                SP.name = $0xFFFFFF00 $ P.PDat.Player[P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1].PLNAME;
                if( i >= P.MaxRankedPlayers )
                {
                    SP.Points = P.RDat.Rec[P.UsedSlot].PSRL[i].Points;
                    SP.Time = P.RDat.Rec[P.UsedSlot].PSRL[i].SRT;
                    SP.Date = P.FixDate( P.RDat.Rec[P.UsedSlot].PSRL[i].SRD );
                    SP.Flags = P.RDat.Rec[P.UsedSlot].PSRL[i].Flags;
                    CR.ClientSendPersonalOverallTop( SP );
                }
                CR.SoloRank = i+1;
            }
            else
            {
                if( i < P.MaxRankedPlayers )
                    SP.name = P.PDat.Player[P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1].PLNAME;
            }

            if( i < P.MaxRankedPlayers )
            {
                SP.Points = P.RDat.Rec[P.UsedSlot].PSRL[i].Points;
                SP.Time = P.RDat.Rec[P.UsedSlot].PSRL[i].SRT;
                SP.Date = P.FixDate( P.RDat.Rec[P.UsedSlot].PSRL[i].SRD );
                SP.Flags = P.RDat.Rec[P.UsedSlot].PSRL[i].Flags;
                CR.ClientSendSoloTop( SP );
            }
        }
    }

Begin:
    SendSoloTops();
    Destroy();
}

final function SendAdditionalInfo()
{
    local BTClient_ClientReplication.sGlobalPacket GP;

    // Send rank < (MaxRankedPlayers) player his rank.
    i = GetOverallTopFor( CR.myPlayerSlot );
    if( i != -1 )
    {
        if( P.PDat.Player[CR.myPlayerSlot].PLPoints[0] > 0 )
        {
            CR.Rank = i+1;
            if( i > P.MaxRankedPlayers-1 )
            {
                InitGlobalPacket( i, GP );
                CR.ClientSendMyOverallTop( GP );
            }
        }
    }
    CR.bReceivedRankings = true;
}

final function int GetOverallTopFor( int playerSlot )
{
    for( i = 0; i < P.OverallTopList.Items.Length; ++ i )
    {
        if( P.OverallTopList.Items[i] == playerSlot )
            return i;
    }
    return -1;
}

event Tick( float deltaTime )
{
    if( P != none && CR == none )
    {
        Destroy();
    }
}
