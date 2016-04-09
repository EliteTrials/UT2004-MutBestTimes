class BTStatsReplicator extends Info;

var private int i, j;

var private BTClient_ClientReplication CR;
var private MutBestTimes P;
var private int ItemsToSkip;
var private byte RanksId;
var private BTRanksList RanksList;

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

/** Returns int A as a color tag. */
static final preoperator string $( int A )
{
    return (Chr( 0x1B ) $ (Chr( Max( byte(A & 0xFF000000), 1 )  ) $ Chr( Max( byte(A & 0x00FF0000), 1 ) ) $ Chr( Max( byte(A & 0x0000FF00), 1 ) )));
}

final function Initialize( BTClient_ClientReplication client, optional int queriedPageIndex, optional byte queriedRanksId )
{
    if( client == none )
        return;

    CR = client;
    P = MutBestTimes(Owner);
    ItemsToSkip = queriedPageIndex*P.MaxRankedPlayers;
    RanksId = queriedRanksId;
    switch( RanksId )
    {
        case 0:
            RanksList = P.Ranks.OverallTopList;
            break;

        case 1:
            RanksList = P.Ranks.QuarterlyTopList;
            break;

        case 2:
            RanksList = P.Ranks.DailyTopList;
            break;
    }
}

final function BeginReplication()
{
    GotoState( 'ReplicateRanks' );
}

final function SendPlayerRank( int rankIndex )
{
    local int playerIndex;
    local BTGUI_PlayerRankingsReplicationInfo.sPlayerRank playerRank;

    playerIndex = RanksList.Items[rankIndex];
    if( playerIndex == CR.myPlayerSlot )
        playerRank.Name = $0xFFFFFF00 $ P.PDat.Player[playerIndex].PLName;
    else playerRank.Name = P.PDat.Player[playerIndex].PLName;

    playerRank.PlayerId     = playerIndex + 1;
    playerRank.Points       = P.PDat.Player[playerIndex].PLPoints[RanksId];
    playerRank.AP           = P.PDat.Player[playerIndex].PLAchiev;
    playerRank.Hijacks      = P.PDat.Player[playerIndex].RankedRecords.Length << 16 | P.PDat.Player[playerIndex].PLTopRecords[RanksId];

    CR.Rankings[RanksId].ClientAddPlayerRank( playerRank );
}

state ReplicateRanks
{
Begin:
    // Send OverallTop players
    j = Min( RanksList.Items.Length - ItemsToSkip, P.MaxRankedPlayers );
    for( i = 0; i < j; ++ i )
    {
        SendPlayerRank( ItemsToSkip + i );
        if( Level.NetMode != NM_Standalone && i % 6 == 0 )
        {
            Sleep( 0.4 );
        }
    }
    CR.Rankings[RanksId].ClientDonePlayerRanks( j < P.MaxRankedPlayers );
}

state ReplicateSoloTop
{
    final function SendSoloTops()
    {
        local BTClient_ClientReplication.sSoloPacket SP;
        local float highestPoints;

        // Send Map Top (MaxRankedPlayers) structure
        j = P.RDat.Rec[P.UsedSlot].PSRL.Length;
        if( j > 0 )
        {
            highestPoints = P.RDat.Rec[P.UsedSlot].PSRL[0].Points;
        }
        // Scan whole list, yes including people above <MaxRankedPlayer> cuz of PersonalOverallTop
        for( i = 0; i < j; ++ i )
        {
            SP.PlayerId = P.RDat.Rec[P.UsedSlot].PSRL[i].PLs;
            // Owner of record?
            if( P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1 == CR.myPlayerSlot )
            {
                CR.SoloRank = i+1;
                CR.ClientSetPersonalTime( P.RDat.Rec[P.UsedSlot].PSRL[i].SRT );

                SP.name = P.PDat.Player[P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1].PLNAME;
                if( i >= P.MaxRankedPlayers )
                {
                    SP.Points = P.RDat.Rec[P.UsedSlot].PSRL[i].Points/highestPoints*10.00;
                    SP.Time = P.RDat.Rec[P.UsedSlot].PSRL[i].SRT;
                    SP.Date = P.FixDate( P.RDat.Rec[P.UsedSlot].PSRL[i].SRD );
                    SP.Flags = P.RDat.Rec[P.UsedSlot].PSRL[i].Flags;
                    CR.ClientSendPersonalOverallTop( SP );
                }
            }
            else
            {
                if( i < P.MaxRankedPlayers )
                    SP.name = P.PDat.Player[P.RDat.Rec[P.UsedSlot].PSRL[i].PLs-1].PLNAME;
            }

            if( i < P.MaxRankedPlayers )
            {
                SP.Points = P.RDat.Rec[P.UsedSlot].PSRL[i].Points/highestPoints*10.00;
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

event Tick( float deltaTime )
{
    if( P != none && CR == none )
    {
        Destroy();
    }
}
