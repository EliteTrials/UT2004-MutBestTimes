class BTGUI_RankingsMenu extends BTGUI_ScoreboardBase;

var automated GUITabControl Tabs;
var automated BTGUI_QueryPanel QueryPanel;
var private BTGUI_PlayerRankingsScoreboard PlayersScoreboard;
var private BTGUI_RecordRankingsScoreboard RecordsScoreboard;

event Free()
{
    super.Free();
    PlayersScoreboard = none;
    RecordsScoreboard = none;
}

event bool NotifyLevelChange()
{
    bPersistent = false;
    return super.NotifyLevelChange();
}

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	super.InitComponent(MyController,MyOwner);

    // To prevent ShowPanel being called before we can assign our scoreboards.
    Tabs.AddTab(
        "Top Players",
        string(class'BTGUI_PlayerRankingsScoreboard'),
        PlayersScoreboard,
        "View the highest ranked players",
        false
    );
    Tabs.AddTab(
        "Top Records",
        string(class'BTGUI_RecordRankingsScoreboard'),
        RecordsScoreboard,
        "View the fastest map records",
        true
    );
}

function ReplicationReady( BTGUI_ScoreboardReplicationInfo repSource )
{
    // Log("ReplicationReady", Name);
    PlayersScoreboard.RepReady( repSource );
    RecordsScoreboard.RepReady( repSource );
}

function PassQueryReceived( BTQueryDataReplicationInfo queryRI )
{
    QueryPanel.OnQueryReceived( queryRi );
}

function InternalOnQueryPlayerRecord( int mapId, int playerId )
{
    local string query;

    if( mapId == 0 || playerId == 0 )
    {
        Warn("Received request with invalid data");
        return;
    }

    query = "player:" $ playerId @ "map:" $ mapId;
    QueryPanel.SetQuery( query );
}

function InternalOnQueryPlayer( int playerId )
{
    local string query;

    if( playerId == 0 )
    {
        Warn("Received request with invalid data");
        return;
    }

    query = "player:" $ playerId;
    QueryPanel.SetQuery( query );
}

final static function BTGUI_RankingsMenu GetMenu( PlayerController localPC )
{
    local GUIController myController;

    myController = GUIController(localPC.Player.GUIController);
    return BTGUI_RankingsMenu(myController.FindPersistentMenuByClass( default.Class ));
}

defaultproperties
{
	WindowName="BTimes Leaderboards"
	bPersistent=true
	bAllowedAsLast=true

	WinLeft=0.1
	WinTop=0.1085
	WinWidth=0.8
	WinHeight=0.817
    FadeTime=1.0
    MinPageHeight=0.4
    MinPageWidth=0.8

    Begin Object class=GUITabControl name=oRankPages
        WinWidth=0.59
        WinLeft=0.005
        WinTop=0.065
        WinHeight=0.925
        TabHeight=0.045
        bDockPanels=true
        // BackgroundStyleName="BTHUD"
    End Object
    Tabs=oRankPages

    Begin Object class=BTGUI_PlayerRankingsScoreboard name=oPlayersPanel
        OnQueryPlayer=InternalOnQueryPlayer
    End Object
    PlayersScoreboard=oPlayersPanel

    Begin Object class=BTGUI_RecordRankingsScoreboard name=oRecordsPanel
        OnQueryPlayer=InternalOnQueryPlayer
        OnQueryPlayerRecord=InternalOnQueryPlayerRecord
    End Object
    RecordsScoreboard=oRecordsPanel

    Begin Object class=BTGUI_QueryPanel name=oQueryPanel
        WinWidth=0.395
        WinHeight=0.925
        WinTop=0.065
        WinLeft=0.6
    End Object
    QueryPanel=oQueryPanel
}