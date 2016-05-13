//==============================================================================
// BTClient_VRI.uc (C) 2007-2008 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Replace MapVotingPage
            Faster replication
*/
//  Coded by Eliot
//  Updated @ XX/XX/2008
//==============================================================================
class BTClient_VRI extends VotingReplicationInfo;

const MapVotingPageClass = class'BTClient_MapVotingPage';

simulated function string GetMapNameString(int Index)
{
    if(Index >= MapList.Length)
        return "";
    else
        return class'BTClient_MapVoteMultiColumnList'.static.ParseMapName(MapList[Index].MapName);
}

simulated function OpenWindow()
{
    local GUIController controller;

    controller = GetController();
    if( controller.FindMenuByClass( MapVotingPageClass ) != none )
        return;

    controller.OpenMenu( string(MapVotingPageClass) );
}

// Hooked by BTServer_VotingHandler.
delegate string InjectMapNameData(VotingReplicationInfo VRI, int mapIndex);
delegate OnReceiveMapInfo(VotingHandler.MapVoteMapList MapInfo);

// Ugly copy from parent, modified to, inject data into the MapName variable.
function TickedReplication_MapList(int Index, bool bDedicated)
{
    local VotingHandler.MapVoteMapList MapInfo;
    local string data;

    MapInfo = VH.GetMapList(Index);
    DebugLog("___Sending " $ Index $ " - " $ MapInfo.MapName);

    data = InjectMapNameData(self, index);
    if( data != "" )
    {
        MapInfo.MapName $= "$$" $ data;
    }

    if( bDedicated )
    {
        ReceiveMapInfo(MapInfo);  // replicate one map each tick until all maps are replicated.
        bWaitingForReply = True;
    }
    else
        MapList[MapList.Length] = MapInfo;
}

simulated function ReceiveMapInfo(VotingHandler.MapVoteMapList MapInfo)
{
   super.ReceiveMapInfo(MapInfo);
   OnReceiveMapInfo(MapInfo);
}

defaultproperties
{
    NetPriority=1.5
    NetUpdateFrequency=2
}

