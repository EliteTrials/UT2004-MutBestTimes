class BTGUI_TabBase extends UT2K4TabPanel;

function PostInitPanel();

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if( bShow && PlayerOwner().Level.NetMode == NM_Standalone )
    {
        PlayerOwner().SetPause( false );
    }
}