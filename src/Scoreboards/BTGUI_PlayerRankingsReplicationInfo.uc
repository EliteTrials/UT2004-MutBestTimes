class BTGUI_PlayerRankingsReplicationInfo extends BTGUI_ScoreboardReplicationInfo;

var int CurrentPageIndex;
var name CurrentCategoryName;

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

defaultproperties
{
	MenuClass=class'BTGUI_PlayerRankingsScoreboard'
	CurrentPageIndex=-1
	CurrentCategoryName="All"
}