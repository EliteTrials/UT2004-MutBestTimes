class BTGUI_PlayerRankingsReplicationInfo extends BTGUI_ScoreboardReplicationInfo;

struct sPlayerRank
{
    var int PlayerId;
    var int AP;
    var float Points;
    var string Name;
    var int Hijacks;
};

var() array<sPlayerRank> PlayerRanks;

var editconst int CurrentPageIndex;
var() const byte RanksId;

replication
{
	reliable if( Role == ROLE_Authority )
		ClientCleanPlayerRanks,
		ClientDonePlayerRanks,
		ClientAddPlayerRank,
		ClientUpdatePlayerRank;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if( CRI != none )
	{
		CRI.Rankings[RanksId] = self;
	}
}

// UI hooks
delegate OnPlayerRankReceived( int index, BTGUI_PlayerRankingsReplicationInfo source );
delegate OnPlayerRankUpdated( int index, BTGUI_PlayerRankingsReplicationInfo source );
delegate OnPlayerRanksDone( BTGUI_PlayerRankingsReplicationInfo source, bool bAll );

simulated function QueryPlayerRanks( int pageIndex )
{
	CRI.ServerRequestPlayerRanks( pageIndex, RanksId );
}

simulated function QueryNextPlayerRanks()
{
	QueryPlayerRanks( ++ CurrentPageIndex );
}

simulated function ClientCleanPlayerRanks()
{
    PlayerRanks.Length = 0;
}

simulated function ClientDonePlayerRanks( optional bool bAll )
{
	OnPlayerRanksDone( self, bAll );
}

simulated function ClientAddPlayerRank( sPlayerRank playerRank )
{
    PlayerRanks[PlayerRanks.Length] = playerRank;
    OnPlayerRankReceived( PlayerRanks.Length - 1, self );
}

simulated function ClientUpdatePlayerRank( sPlayerRank playerRank, byte index )
{
    PlayerRanks[index] = playerRank;
    OnPlayerRankUpdated( index, self );
}

defaultproperties
{
	CurrentPageIndex=-1
	RanksId=0
}