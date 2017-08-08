class BTGUI_Help extends BTGUI_StatsTab;

var() editconstarray array<BTGUI_HelpTopic> Topics;

var automated GUITreeListBox        CategoriesListBox;
var automated GUISectionBackground  ContentBackground, CategoriesBackground;
var automated GUIScrollTextBox 		InfoTextBox;

function InitComponent( GUIController InController, GUIComponent InOwner )
{
	super.InitComponent(InController,InOwner);
	InitTopics();
}

private function InitTopics()
{
	local int i;

	for( i = 0; i < Topics.Length; ++ i )
	{
		Topics[i].ParseVariable = InternalOnParseVariable;
        CategoriesListBox.List.AddItem( Topics[i].Caption, Topics[i].Caption, Topics[i].ParentCaption, true );
	}
	CategoriesListBox.List.SetIndex( 0 );
}

final function int GetTopicIndex( string topicCaption )
{
	local int i;

	for( i = 0; i < Topics.Length; ++ i )
	{
		if( Topics[i].Caption == topicCaption )
		{
			return i;
		}
	}
	return -1;
}

function InternalOnCategoryChange( GUIComponent sender )
{
    local int i, topicIdx;
    local string val;

    val = CategoriesListBox.List.GetValue();
    topicIdx = GetTopicIndex( val );
    if( topicIdx == -1 || Topics[topicIdx].Contents.Length == 0 )
    {
    	return;
    }

    val = Topics[topicIdx].GetContent();
	InfoTextBox.MyScrollText.SetContent( val );
	InfoTextBox.MyScrollBar.AlignThumb();
	InfoTextBox.MyScrollBar.UpdateGripPosition( 0 );
    ContentBackground.Caption = CategoriesListBox.List.GetCaption();
}

function string InternalOnParseVariable( string varContext, string varName )
{
	switch( varContext )
	{
		case "BT":
			switch( varName )
			{
				case "MaxRankedPlayers":
					return "20";
			}
			break;
	}
	return "";
}

defaultproperties
{
	begin object class=BTGUI_HelpTopic name=oTopicBasic
		Caption="Basics"
		Contents(0)="Please read the info here thoroughly before playing!"
		Contents(1)="||{55,116,180}Checkpoints"
		Contents(2)="---------------------|"
		Contents(3)="ïïïIf you are new to Trials, then the most important thing to do, is to take advantage of ClientSpawns, one can set a ClientSpawn a.k.a Checkpoint by typing in the public chat ÿ!CPïïï, this creates a new spawn point for you at your current location, the next time you die, you will be respawned exactly where you set your ClientSpawn. However be aware that restrictions are applied to ClientSpawn users! You can undo your ClientSpawn anytime by typing the ÿ!CPïïï command again. Please see more about this command in the Commands topic."
	end object
	Topics(0)=oTopicBasic

	begin object class=BTGUI_HelpTopic name=oTopicTrialModes
		Caption="Modes"
		ParentCaption="Basics"
		Contents(0)="{55,116,180}Solo Trials"
		Contents(1)="---------------------|"
		Contents(2)="ïïïSolo maps are those with only 1 useable objective. If you complete a solo map, you will set a ÿ'personal best time'ïïï. Each solo map has a ÿtop {BT.MaxRankedPlayers} times scoreboardïïï - showing the {BT.MaxRankedPlayers} players who have achieved the fastest times on that map. If you achieve a top {BT.MaxRankedPlayers} time for a solo map, you are given ÿpointsïïï - slower times will receive less points than faster ones.||To view the BTimes ÿtop {BT.MaxRankedPlayers}ïïï scoreboard, use the [ÿF12ïïï] key. This key can be used to ÿtoggleïïï the scoreboard between the OVERALL top {BT.MaxRankedPlayers} ranking, and the top {BT.MaxRankedPlayers} times for the CURRENT MAP. When the scoreboard is open, press the [ÿTABïïï] key to switch between the all time, monthly, and daily scoreboards.||IMPORTANT: You can also use the commands 7tÃŽSetClientSpawnïïï and 7tÃŽDeleteClientSpawnïïï (this applies for all trial maps but Group maps). These allow you to set spawns for yourself to practice hard jumps. However, you won't be able to press an objective until you go back to the original spawn."
		Contents(3)="|{55,116,180}Regular Trials"
		Contents(4)="---------------------|"
		Contents(5)=""
		Contents(6)="|{55,116,180}Group Trials"
		Contents(7)="---------------------|"
		Contents(8)=""
	end object
	Topics(1)=oTopicTrialModes

	begin object class=BTGUI_HelpTopic name=oTopicCommands
		Caption="Commands"
		ParentCaption="Basics"
		Contents(0)="This section will explain you all the things there are to know about commands."
	end object
	Topics(2)=oTopicCommands

/**
	Topics(2)=(Name="Best Times",Content="{55,116,140}Best Times Mutator|---------------------||ïïïThis is a mutator created by ÿEliotïïï which records time speed records for each map, and keeps track of the records which each player has. Each map is either a ÿTEAMïïï map or a ÿSOLOïïï map. Solo maps are those with only 1 useable objective. (see solo tab!)||If you manage to set a new record for a regular map, the ÿ3 playersïïï who completed the most objectives will be made record holders,and will be awarded points. On solo maps you will be avoided points for achieving a top 20 time for the map!||The 3 players with the highest scores on the scoreboard are given a ÿtrailerïïï (similar to a speed trailer). This is just a special effect and does not affect their speed/gameplay at all!||You can also use the following console commands: 7tÃŽrecentrecordsïïï, 7tÃŽshowmapinfo ÿ<mapname>ïïï, 7tÃŽshowplayerinfo ÿ<playername>ïïï, 7tÃŽvotemapseq ÿ<number>ïïï, 7tÃŽvotemap ÿ<mapname>ïïï||Press ÿESCïïï and click on the ÿAdvancedïïï tab to quickly access any of the BestTimes commands.")
	Topics(3)=(TopicParent="Best Times",Name="Commands",Content="SetTimer, PauseTimer, StopTimer")
	Topics(4)=(Name="Clan Manager Mutator",Content="ïïïYou can access the clan manager menu using the ÿF8ïïï key.||This mutator enables ÿin-game specïïï - meaning you can spectate other players from within the game while you are playing.||You can also use the ÿspam-blockerïïï, to block text/chat from another player if necessary.||CM also provides us with an anti-cheat system, with added protection against uscript hacks.")
	Topics(5)=(Name="Customization Options",Content="ïïïUsing UTComp, you can change the colour of your player name. Just use the ÿF5ïïï key to open the UTComp menu andthen pick the Colored Names menu.||MutNoAutofire allows you to change the colour of your shieldgun. You can do this by mixing ÿredïïï, ÿgreenïïï and 7tÃŽblueïïï using the console command 7tÃŽSetShieldColor(r=x,g=x,b=x)ïïï where x is a value between ÿ0ïïï and ÿ255ïïï.||You can also set a custom death/suicide message. You can set a suicide keybind with the command 7tÃŽset input ÿ<key>7tÃŽ mutatesuicideïïï - and then you can set a custom suicide message using 7tÃŽsetsuicidemessage %o ÿ<suicide message>ïïï (%o represents your playername).||Note: Bind the command 7tÃŽmutate suicideïïï to one of your keys. This will give you the ability to fast suicide.")*/

    begin object class=GUISectionBackground name=oCategoriesBackground
        WinWidth=0.19
        WinHeight=0.92
        WinLeft=0.0
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
        Caption="Topics"
        HeaderBase=Material'2K4Menus.NewControls.Display99'
    end object
    CategoriesBackground=oCategoriesBackground

    begin object class=GUITreeListBox name=oCategoriesListBox
        WinWidth=0.15
        WinHeight=0.80
        WinLeft=0.02
        WinTop=0.07
        OnChange=InternalOnCategoryChange
    end object
    CategoriesListBox=oCategoriesListBox

    begin object class=GUISectionBackground name=oContentBackground
        WinWidth=0.80
        WinHeight=0.92
        WinLeft=0.20
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
        Caption="Info"
        HeaderBase=Material'2K4Menus.NewControls.Display99'
    end object
    ContentBackground=oContentBackground

    begin object class=GUIScrollTextBox name=oInfoTextBox
        WinWidth=0.73
        WinHeight=0.80
        WinLeft=0.22
        WinTop=0.07
        bBoundToParent=true
        bScaleToParent=true
		StyleName="NoBackground"
		bNoTeletype=false
        bNeverFocus=true
    end object
    InfoTextBox=oInfoTextBox
}