class BTPlayerProfileReplicationInfo extends BTQueryDataReplicationInfo;

// Account variables
var string PlayerId;
var string CountryCode;
var int RegisterDate, LastPlayedDate;

// Record variables
var float RankedELORating;
var int
	NumStars, NumRankedRecords, NumRecords,
	NumObjectives, NumRounds, NumHijacks, NumFinishes,
	AchievementPoints;
var float PlayTime;

replication
{
	reliable if( bNetInitial )
		PlayerId,
		CountryCode,
		RegisterDate, LastPlayedDate,
		RankedELORating,
		NumStars, NumRankedRecords, NumRecords,
		NumObjectives, NumRounds,  NumHijacks, NumFinishes,
		AchievementPoints,
		PlayTime;
}

defaultproperties
{
	DataPanelClass=class'BTGUI_PlayerQueryDataPanel'
}