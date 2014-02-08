//==============================================================================
// BTClient_PlayerLoginMenu.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Add a tab for BestTimes into the Escape LoginMenu
*/
//  Coded by Eliot
//  Updated @ XX/XX/2009
//
//  OBSOLETE!
//==============================================================================
Class BTClient_PlayerLoginMenu Extends UT2K4PlayerLoginMenu;

Function AddPanels()
{
    local GUITabPanel Panel;

    Super.AddPanels();

    // Dynamicly get class cause i don't want to change the version number every update..
    Panel = c_Main.AddTab( "BestTimes", string( Class'BTClient_Menu' ), ,"BestTimes Configuration" );
    if( Panel != None )
    {
        c_Main.Controller.RegisterStyle( Class'BTClient_STY_BTButton', True );
        Panel.MyButton.StyleName = "BTButton";
        Panel.MyButton.Style = c_Main.Controller.GetStyle( "BTButton", Panel.FontScale );
    }
}

DefaultProperties
{
}
