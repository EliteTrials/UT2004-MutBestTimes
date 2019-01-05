/**
 * A list box that can be initialized with a specified listclass on runtime.
 *
 * Copyright 2011 Eliot Van Uytfanghe. All Rights Reserved.
 */
class BTStore_ItemsMultiColumnListBox extends GUIMultiColumnListBox;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
    super(GUIListBoxBase).InitComponent( MyController, MyOwner );
}

final function InitListClass( string listClass, BTClient_ClientReplication CRI )
{
    if( listClass == "" )
    {
        Warn( "No listClass Specified!" );
        return;
    }

    List = BTStore_ItemsMultiColumnList( AddComponent( listClass ) );
    BTStore_ItemsMultiColumnList(List).CRI = CRI;
    BTStore_ItemsMultiColumnList(List).UpdateList();
    InitBaseList( List );

    if( bFullHeightStyle )
    {
        List.Style = none;
    }
}

defaultproperties
{
    Begin Object Class=GUIContextMenu Name=oContextMenu
        ContextItems(0)="Buy this item"
    End Object
    ContextMenu=oContextMenu
}
