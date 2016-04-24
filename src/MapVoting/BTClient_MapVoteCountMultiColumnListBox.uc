class BTClient_MapVoteCountMultiColumnListBox extends MapVoteCountMultiColumnListBox;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(class'BTClient_MapVoteCountMultiColumnList');
	super.Initcomponent(MyController, MyOwner);
}

defaultproperties
{
    Begin Object Class=GUIContextMenu Name=RCMenu
		ContextItems(0)="Vote for this Map"
        OnSelect=InternalOnClick
        StyleName="BTContextMenu"
        SelectionStyleName="BTListSelection"
    End Object
    ContextMenu=RCMenu
    MapInfoPage=""

    DefaultListClass="BTClient_MapVoteCountMultiColumnList"
}