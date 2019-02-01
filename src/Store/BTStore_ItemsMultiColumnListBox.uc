//=============================================================================
// Copyright 2011-2019 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTStore_ItemsMultiColumnListBox extends GUIMultiColumnListBox;

event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	DefaultListClass = string(class'BTStore_ItemsMultiColumnList');
    super.InitComponent( MyController, MyOwner );
}

defaultproperties
{
    DefaultListClass="" // Manually initialized in InitComponent.
    bDisplayHeader=true

    Begin Object Class=BTClient_MultiColumnListHeader Name=MyHeader
    End Object
    Header=MyHeader

    Begin Object Class=GUIContextMenu Name=oContextMenu
        ContextItems(0)="Buy this item"
    End Object
    ContextMenu=oContextMenu
}
