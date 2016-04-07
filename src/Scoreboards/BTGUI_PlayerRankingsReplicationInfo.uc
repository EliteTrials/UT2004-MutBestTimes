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

var() editconst int CurrentPageIndex;
var() editconst name CurrentCategoryName;

var private BTClient_ClientReplication CRI;

replication
{
	reliable if( Role == ROLE_Authority )
		ClientCleanPlayerRanks,
		ClientAddPlayerRank,
		ClientUpdatePlayerRank;
}

simulated event PostBeginPlay()
{
	if( Level.NetMode != NM_DedicatedServer )
	{
		CRI = class'BTClient_ClientReplication'.static.GetRep( Level.GetLocalPlayerController() );
	}
	else
	{
		CRI = class'BTClient_ClientReplication'.static.GetRep( PlayerController(Owner) );
	}

	if( CRI != none )
	{
		CRI.PRRI = self;
	}
	super.PostBeginPlay();
}

// UI hooks
delegate OnPlayerRankReceived( int index, name categoryName );
delegate OnPlayerRankUpdated( int index, name categoryName );

simulated function QueryPlayerRanks( int pageIndex, name categoryName )
{
	local BTClient_ClientReplication CRI;

	CRI = class'BTClient_TrialScoreBoard'.static.GetCRI( Level.GetLocalPlayerController().PlayerReplicationInfo );
	CRI.ServerRequestPlayerRanks( pageIndex, string(categoryName) );
	CurrentPageIndex = pageIndex;
	CurrentCategoryName = categoryName;
}

simulated function QueryNextPlayerRanks()
{
	QueryPlayerRanks( CurrentPageIndex + 1, CurrentCategoryName );
}

simulated function ClientCleanPlayerRanks()
{
    PlayerRanks.Length = 0;
}

simulated function ClientAddPlayerRank( sPlayerRank playerRank )
{
    PlayerRanks[PlayerRanks.Length] = playerRank;
    OnPlayerRankReceived( PlayerRanks.Length - 1, 'All' );
}

simulated function ClientUpdatePlayerRank( sPlayerRank playerRank, byte index )
{
    PlayerRanks[index] = playerRank;
    OnPlayerRankUpdated( index, 'All' );
}

defaultproperties
{
	MenuClass=class'BTGUI_PlayerRankingsScoreboard'
	CurrentPageIndex=-1
	CurrentCategoryName="All"
}