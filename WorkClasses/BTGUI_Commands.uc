class BTGUI_Commands extends BTGUI_TabBase;

var automated GUIButton b_ShowMapInfo, b_ShowPlayerInfo, b_ShowMissingRecords, b_ShowBadRecords, b_SetClientSpawn, b_DeleteClientSpawn;
var automated GUIEditBox eb_ShowMapInfo, eb_ShowPlayerInfo;

function bool InternalOnClick( GUIComponent sender )
{
	PlayerOwner().ConsoleCommand( "CloseDialog" );
	if( sender == b_ShowMapInfo )
	{
		PlayerOwner().ConsoleCommand( "ShowMapInfo" @ eb_ShowMapInfo.GetText() );
		return true;
	}
	else if( sender == b_ShowPlayerInfo )
	{
		PlayerOwner().ConsoleCommand( "ShowPlayerInfo" @ eb_ShowPlayerInfo.GetText() );
		return true;
	}
	else if( sender == b_ShowMissingRecords )
	{
		PlayerOwner().ConsoleCommand( "ShowMissingRecords" );
		return true;
	}
	else if( sender == b_ShowBadRecords )
	{
		PlayerOwner().ConsoleCommand( "ShowBadRecords" );
		return true;
	}
	else if( sender == b_SetClientSpawn )
	{
		PlayerOwner().ConsoleCommand( "SetClientSpawn" );
		return true;
	}
	else if( sender == b_DeleteClientSpawn )
	{
		PlayerOwner().ConsoleCommand( "DeleteClientSpawn" );
		return true;
	}
	return false;
}

defaultproperties
{
	Begin Object class=GUIButton name=oShowPlayerInfo
		Caption="Show Player Info"
		WinTop=0.01
		WinLeft=0.0
		WinWidth=0.25
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Shows a dialog with info of the inputted player"
	End Object
	b_ShowPlayerInfo=oShowPlayerInfo

	Begin Object class=GUIEditBox name=oPlayerName
		bScaleToParent=True
		bBoundToParent=True
		WinTop=0.01
		WinLeft=0.26
		WinWidth=0.25
		WinHeight=0.05
		Hint="Player Name"
	End Object
	eb_ShowPlayerInfo=oPlayerName

	Begin Object class=GUIButton name=oShowMapInfo
		Caption="Show Map Info"
		WinTop=0.07
		WinLeft=0.0
		WinWidth=0.25
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Shows a dialog with info of the inputted map"
	End Object
	b_ShowMapInfo=oShowMapInfo

	Begin Object class=GUIEditBox name=oMapName
		bScaleToParent=True
		bBoundToParent=True
		WinTop=0.07
		WinLeft=0.26
		WinWidth=0.25
		WinHeight=0.05
		Hint="Map Name"
	End Object
	eb_ShowMapInfo=oMapName

	Begin Object class=GUIButton name=oShowMissingRecords
		Caption="Show Available Records"
		WinTop=0.13
		WinLeft=0.0
		WinWidth=0.25
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Shows a dialog with info of what solo records you haven't yet recorded"
	End Object
	b_ShowMissingRecords=oShowMissingRecords

	Begin Object class=GUIButton name=oShowBadRecords
		Caption="Show Bad Records"
		WinTop=0.19
		WinLeft=0.0
		WinWidth=0.25
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Shows a dialog with info of what solo records you are not in the top 3"
	End Object
	b_ShowBadRecords=oShowBadRecords

	Begin Object class=GUIButton name=oSetClientSpawn
		Caption="Set Client Spawn"
		WinTop=0.25
		WinLeft=0.0
		WinWidth=0.25
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Sets you a new client spawn point at your present position"
	End Object
	b_SetClientSpawn=oSetClientSpawn

	Begin Object class=GUIButton name=oDeleteClientSpawn
		Caption="Delete Client Spawn"
		WinTop=0.31
		WinLeft=0.0
		WinWidth=0.25
		WinHeight=0.05
		OnClick=InternalOnClick
		Hint="Deletes your client spawn point"
	End Object
	b_DeleteClientSpawn=oDeleteClientSpawn
}