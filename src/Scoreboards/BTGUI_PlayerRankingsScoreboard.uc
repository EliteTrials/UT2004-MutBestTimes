class BTGUI_PlayerRankingsScoreboard extends BTGUI_ScoreboardBase;

var BTClient_Interaction Inter;
var automated BTGUI_PlayerRankingsMultiColumnListBox RankingsListBox;

event Free()
{
	super.Free();
	Inter = none;
}

event InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	local BTClient_ClientReplication CRI;

	super.InitComponent( MyController, MyOwner );

    BackgroundColor = class'BTClient_Config'.default.CTable;
    Inter = GetInter();

    CRI = GetCRI( PlayerOwner().PlayerReplicationInfo );
	if( CRI == none )
	{
		Warn("Couldn't find a CRI for the current local player!");
		return;
	}

	CRI.OnPlayerRankReceived = InternalOnPlayerRankReceived;
}

function InternalOnPlayerRankReceived( int index, name categoryName )
{
	RankingsListBox.List.AddedItem( index );
	RankingsListBox.List.Sort();
}

defaultproperties
{
	WinLeft=0.00
	WinTop=0.50
	WinWidth=0.2
	WinHeight=0.60
	WindowName="Player Ranks"

    Begin Object Class=BTGUI_PlayerRankingsMultiColumnListBox Name=ItemsListBox
        WinWidth=0.98
        WinHeight=0.90
        WinLeft=0.01
        WinTop=0.065
        bVisibleWhenEmpty=true
        bScaleToParent=True
        bBoundToParent=True
        FontScale=FNS_Small
    End Object
    RankingsListBox=ItemsListBox
}