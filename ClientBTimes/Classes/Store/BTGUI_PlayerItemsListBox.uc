//=============================================================================
// Copyright 2018 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGUI_PlayerItemsListBox extends GUIVertImageListBox;

defaultproperties
{
    begin object class=GUIContextMenu name=oContextMenu
        ContextItems(0)="Equip/Unequip Item"
        ContextItems(1)="Edit Item (if available)"
        ContextItems(2)="Sell Item to Vendor"
        ContextItems(3)="Destroy Item"
    end object
    ContextMenu=oContextMenu
}