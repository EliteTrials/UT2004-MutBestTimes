class BTStatsReplicator extends Info;

var private int i, j;

var protected BTClient_ClientReplication CR;
var protected MutBestTimes P;

/** Returns int A as a color tag. */
static final preoperator string $( int A )
{
    return (Chr( 0x1B ) $ (Chr( Max( byte(A & 0xFF000000), 1 )  ) $ Chr( Max( byte(A & 0x00FF0000), 1 ) ) $ Chr( Max( byte(A & 0x0000FF00), 1 ) )));
}

final function Initialize( BTClient_ClientReplication client )
{
    if( client == none )
        return;

    CR = client;
    P = MutBestTimes(Owner);
}

final function BeginReplication()
{
    GotoState( 'ReplicateOverallTop' );
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
    local int pSlot;

    pSlot = P.SortedOverallTop[index].PLSlot;

    if( pSlot == CR.myPlayerSlot )
        GP.Name = $0xFFFFFF00 $ P.PDat.Player[pSlot].PLName;
    else GP.Name = P.PDat.Player[pSlot].PLName;

    GP.Points       = P.SortedOverallTop[index].PLPoints;
    GP.AP           = P.PDat.Player[pSlot].PLAchiev;
    GP.Objectives   = P.PDat.Player[pSlot].PLObjectives;
    GP.Hijacks      = P.PDat.Player[pSlot].PLHijacks << 16 | P.SortedOverallTop[index].PLRecords;
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
    j = Min( P.SortedOverallTop.Length, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        if( P.SortedOverallTop[i].PLPoints == 0 )
        {
            break;
        }

        SendOverallTop( i );
        if( Level.NetMode != NM_Standalone && i % 6 == 0 )
        {
            Sleep( 0.4 );
        }
    }
    Sleep( 1 );
    SendAdditionalInfo();
    GotoState( 'ReplicateQuarterlyTop' );
}

final function SendQuarterlyTop( int index, optional out BTClient_ClientReplication.sQuarterlyPacket QP )
{
    local int pSlot;

    pSlot = P.SortedQuarterlyTop[index].PLSlot;

    if( pSlot == CR.myPlayerSlot )
        QP.Name = $0xFFFFFF00 $ P.PDat.Player[pSlot].PLName;
    else QP.Name = P.PDat.Player[pSlot].PLName;

    QP.Points       = P.SortedQuarterlyTop[index].PLPoints;
    QP.Records      = P.SortedQuarterlyTop[index].PLRecords;

    CR.ClientSendQuarterlyTop( QP );
}

state ReplicateQuarterlyTop
{
Begin:
    // Send QuarterlyTop players
    j = Min( P.SortedQuarterlyTop.Length, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        if( P.SortedQuarterlyTop[i].PLPoints == 0 )
        {
            break;
        }

        SendQuarterlyTop( i );
        if( Level.NetMode != NM_Standalone && i % 6 == 0 )
        {
            Sleep( 0.4 );
        }
    }
    Sleep( 1 );
    GotoState( 'ReplicateDailyTop' );
}

final function SendDailyTop( int index, optional out BTClient_ClientReplication.sDailyPacket DP )
{
    local int pSlot;

    pSlot = P.SortedDailyTop[index].PLSlot;

    if( pSlot == CR.myPlayerSlot )
        DP.Name = $0xFFFFFF00 $ P.PDat.Player[pSlot].PLName;
    else DP.Name = P.PDat.Player[pSlot].PLName;

    DP.Points       = P.SortedDailyTop[index].PLPoints;
    DP.Records      = P.SortedDailyTop[index].PLRecords;

    CR.ClientSendDailyTop( DP );
}

state ReplicateDailyTop
{
Begin:
    // Send DailyTop players
    j = Min( P.SortedDailyTop.Length, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        if( P.SortedDailyTop[i].PLPoints == 0 )
        {
            break;
        }

        SendDailyTop( i );
        if( Level.NetMode != NM_Standalone && i % 6 == 0 )
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
            if( P.RDat.Rec[P.UsedSlot].PSRL[i].SRT == 0.0f )
                break;

            // Owner of record?
            if( P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1 == CR.myPlayerSlot )
            {
                CR.ClientSetPersonalTime( P.RDat.Rec[P.UsedSlot].PSRL[i].SRT );

                SP.name = $0xFFFFFF00 $ P.PDat.Player[P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1].PLNAME;
                if( i >= P.MaxRankedPlayers )
                {
                    SP.Points = P.CalcRecordPoints( P.UsedSlot, i );
                    SP.Time = P.RDat.Rec[P.UsedSlot].PSRL[i].SRT;
                    SP.Date = P.FixDate( P.RDat.Rec[P.UsedSlot].PSRL[i].SRD );
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
                SP.Points = P.CalcRecordPoints( P.UsedSlot, i );
                SP.Time = P.RDat.Rec[P.UsedSlot].PSRL[i].SRT;
                SP.Date = P.FixDate( P.RDat.Rec[P.UsedSlot].PSRL[i].SRD );
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
    local string rewardedCommands;
    local BTClient_ClientReplication.sGlobalPacket GP;

    // Send rank < (MaxRankedPlayers) player his rank.
    i = GetOverallTopFor( CR.myPlayerSlot );
    if( i != -1 )
    {
        if( P.SortedOverallTop[i].PLPoints > 0 )
        {
            rewardedCommands = "SetClientSpawn, DeleteClientSpawn";
            CR.Rank = i+1;
            if( i > P.MaxRankedPlayers-1 )
            {
                InitGlobalPacket( i, GP );
                CR.ClientSendMyOverallTop( GP );
            }
            else if( i < P.MaxRewardedPlayers )
                rewardedCommands $= ", TrailerMenu";

            if( P.PDat.Player[P.SortedOverallTop[i].PLSlot].PLObjectives >= P.Objectives_GhostFollow )
            {
                rewardedCommands $= ", GhostFollow";
            }
            CR.UserState[0] = "Rewarded Commands";
            CR.UserState[1] = rewardedCommands;

            // We shall return here because this user has points. See the message below!
            return;
        }
    }
    CR.UserState[0] = "You are not ranked because you have no points!";
    CR.UserState[1] = "You can earn points by breaking records";
    CR.bReceivedRankings = true;
}

final function int GetOverallTopFor( int playerSlot )
{
    for( i = 0; i < P.SortedOverallTop.Length; ++ i )
    {
        if( P.SortedOverallTop[i].PLSlot == playerSlot )
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
