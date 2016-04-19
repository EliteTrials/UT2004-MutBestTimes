class BTGUI_RecordRankingsReplicationInfo extends BTGUI_ScoreboardReplicationInfo;

struct sRecordRank
{
    var int PlayerId;
    var string Name;
    var float Points;
    var float Time;
    var int Date;
    var int Flags;
};

var() array<sRecordRank> RecordRanks;

var private editconst int CurrentPageIndex;
var editconst string RecordsMapName;
var editconst int RecordsMapId;

replication
{
	reliable if( Role == ROLE_Authority )
		RecordsMapName, RecordsMapId,
		ClientClearRecordRanks,
		ClientDoneRecordRanks,
		ClientAddRecordRank,
		ClientUpdateRecordRank;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if( CRI != none )
	{
		CRI.RecordsPRI = self;
	}
}

// UI hooks
delegate OnRecordRankReceived( int index, BTGUI_RecordRankingsReplicationInfo source );
delegate OnRecordRankUpdated( int index, BTGUI_RecordRankingsReplicationInfo source );
delegate OnRecordRanksDone( BTGUI_RecordRankingsReplicationInfo source, bool bAll );
delegate OnRecordRanksCleared( BTGUI_RecordRankingsReplicationInfo source );

simulated function QueryRecordRanks( int pageIndex )
{
	CRI.ServerRequestRecordRanks( pageIndex, RecordsMapName );
}

simulated function QueryNextRecordRanks( optional bool bReset )
{
	if( bReset )
	{
		CurrentPageIndex = -1;
	}
	QueryRecordRanks( ++ CurrentPageIndex );
}

simulated function ClientClearRecordRanks()
{
    RecordRanks.Length = 0;
    OnRecordRanksCleared( self );
}

simulated function ClientDoneRecordRanks( optional bool bAll )
{
	OnRecordRanksDone( self, bAll );
}

simulated function ClientAddRecordRank( sRecordRank RecordRank )
{
    RecordRanks[RecordRanks.Length] = RecordRank;
    OnRecordRankReceived( RecordRanks.Length - 1, self );
}

simulated function ClientUpdateRecordRank( sRecordRank RecordRank, byte index )
{
    RecordRanks[index] = RecordRank;
    OnRecordRankUpdated( index, self );
}

defaultproperties
{
	CurrentPageIndex=-1
}