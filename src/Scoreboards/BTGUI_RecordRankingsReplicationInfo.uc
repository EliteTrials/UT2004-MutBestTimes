class BTGUI_RecordRankingsReplicationInfo extends BTGUI_ScoreboardReplicationInfo;

struct sRecordRank
{
	// sPlayerItem; extending sPlayerItem causes crashes on runtime :(
    var int PlayerId;
    var string CountryCode;
    var transient Texture CountryFlag;
    var string Name;
    var float Points;

    var int RankId; // Rank starting at 1, 0 if not set
    var float Time;
    var int Date;
    var int Flags;
};

var() array<sRecordRank> RecordRanks;

var private editconst int CurrentPageIndex;

// Client only.
var editconst string RecordsSource;

// Set by server. Holds an id of either a map or record, depending on @RecordsSource.
var editconst int RecordsSourceId;

// Set by client and server.
var editconst string RecordsQuery;

replication
{
	reliable if( Role == ROLE_Authority )
		RecordsSource, RecordsQuery, RecordsSourceId,
		ClientClearRecordRanks, ClientRemoveRecordRank,
		ClientDoneRecordRanks,
		ClientAddRecordRank,
		ClientUpdateRecordRank;
}

simulated event PostNetBeginPlay()
{
	if( CRI != none && (bNetOwner || Role == ROLE_Authority) )
	{
		CRI.RecordsPRI = self;
	}
	super.PostNetBeginPlay();
}

// UI hooks
delegate OnRecordRankReceived( int index, BTGUI_RecordRankingsReplicationInfo source );
delegate OnRecordRankUpdated( int index, BTGUI_RecordRankingsReplicationInfo source, optional bool bRemoved );
delegate OnRecordRanksDone( BTGUI_RecordRankingsReplicationInfo source, bool bAll );
delegate OnRecordRanksCleared( BTGUI_RecordRankingsReplicationInfo source );

simulated function QueryRecordRanks( int pageIndex, optional string querySource )
{
	if( querySource != "" )
		RecordsSource = querySource;

	CRI.ServerRequestRecordRanks( pageIndex, RecordsSource$":"$RecordsQuery );
}

simulated function QueryNextRecordRanks( optional bool bReset )
{
	if( bReset )
	{
		CurrentPageIndex = -1;
	}
	QueryRecordRanks( ++ CurrentPageIndex );
}

simulated function ClientAddRecordRank( sRecordRank RecordRank )
{
    RecordRanks[RecordRanks.Length] = RecordRank;
    OnRecordRankReceived( RecordRanks.Length - 1, self );
}

simulated function ClientUpdateRecordRank( sRecordRank RecordRank, int index )
{
	// We didn't receive this record yet, no need to perform any updates.
	if( index >= RecordRanks.Length )
	{
		return;
	}

    RecordRanks[index] = RecordRank;
    OnRecordRankUpdated( index, self );
}

simulated function ClientRemoveRecordRank( int index )
{
	// We didn't receive this record yet, no need to perform any updates.
	if( index >= RecordRanks.Length )
	{
		return;
	}

	OnRecordRankUpdated( index, self, true );
	RecordRanks.Remove( index, 1 );
}

simulated function ClientDoneRecordRanks( optional bool bAll )
{
	OnRecordRanksDone( self, bAll );
}

simulated function ClientClearRecordRanks()
{
    RecordRanks.Length = 0;
    OnRecordRanksCleared( self );
}

defaultproperties
{
	RecordsSource="Map"
	CurrentPageIndex=-1
}