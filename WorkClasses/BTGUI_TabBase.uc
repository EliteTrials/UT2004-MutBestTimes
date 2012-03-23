class BTGUI_TabBase extends UT2K4TabPanel;

var() editinline BTClient_Menu MyMenu;

event Free()
{
	MyMenu = none;
	super.Free();
}

function PostInitPanel()
{
}

function ShowPanel( bool bShow )
{
	super.ShowPanel( bShow );

	if( bShow && PlayerOwner().Level.NetMode == NM_Standalone )
	{
		PlayerOwner().SetPause( false );
	}
}