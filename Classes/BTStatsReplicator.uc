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
    playerRank.CountryCode  = P.PDat.Player[playerIndex].IpCountry;
    playerRank.Points       = P.PDat.Player[playerIndex].PLPoints[RanksId];
    playerRank.AP           = P.PDat.Player[playerIndex].PLAchiev;
    playerRank.Hijacks      = P.PDat.Player[playerIndex].PLRankedRecords[RanksId] << 16 | P.PDat.Player[playerIndex].PLTopRecords[RanksId];

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
        Sleep(0);
    }
    CR.Rankings[RanksId].ClientDonePlayerRanks( j < P.MaxRankedPlayers );
}

event Tick( float deltaTime )
{
    if( P != none && CR == none )
    {
        Destroy();
    }
}
