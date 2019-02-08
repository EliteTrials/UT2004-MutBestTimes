class BTClient_MapVoteMultiColumnListBox extends MapVoteMultiColumnListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    DefaultListClass = string(class'BTClient_MapVoteMultiColumnList');
    super.Initcomponent(MyController, MyOwner);
}

// Ugly copy to replace hardoced class.
function LoadList(VotingReplicationInfo LoadVRI)
{
    local int i,g;

    ListArray.Length = LoadVRI.GameConfig.Length;
    for( i=0; i<LoadVRI.GameConfig.Length; i++)
    {
        ListArray[i] = new class'BTClient_MapVoteMultiColumnList';
        ListArray[i].LoadList(LoadVRI,i);
        if( LoadVRI.GameConfig[i].GameClass ~= PlayerOwner().GameReplicationInfo.GameClass )
            g = i;
    }
    ChangeGameType(g);
}

defaultproperties
{
    DefaultListClass=""

    // Note: Removed view screenshot and map description
    Begin Object Class=GUIContextMenu Name=oRCMenu
        ContextItems(0)="Vote for this Map"
        OnSelect=InternalOnClick
        StyleName="BTContextMenu"
        SelectionStyleName="BTListSelection"
    End Object
    ContextMenu=oRCMenu
    StyleName="NoBackground"
}