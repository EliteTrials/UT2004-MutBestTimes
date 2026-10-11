class BTGUI_Trophies extends BTGUI_StatsTab
    dependson(Actor);

#exec obj load file="SkaarjAnims.ukx"

var const Texture TrophyIcon;

var automated GUIButton b_Exchange;
var automated GUIEditBox eb_Amount;

//var automated GUIImage i_ItemIcon;
var automated GUISectionBackground sb_Background;
var automated GUIScrollTextBox eb_Description;
var automated GUIImage i_Render;

var() editinline SpinnyWeap SpinnyDude;
var() const vector SpinnyDudeOffset;

event Free()
{
    if( SpinnyDude != none )
    {
        SpinnyDude.Destroy();
        SpinnyDude = none;
    }
    super.Free();
}

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if( bShow && CRI != none && PlayerOwner().Level.TimeSeconds > 5 )
    {
        LoadData();
    }
}

function InitComponent( GUIController InController, GUIComponent InOwner )
{
    super.InitComponent( InController, InOwner );
    eb_Description.MyScrollText.SetContent( "Minimum trophies necessary to exchange: 25|Maximum exchangeable trophies: 45" );
    eb_Description.MyScrollBar.AlignThumb();
    eb_Description.MyScrollBar.UpdateGripPosition( 0 );

    SpinnyDude = PlayerOwner().Spawn( class'SpinnySkel' );
    SpinnyDude.SetDrawType( DT_Mesh );
    SpinnyDude.bPlayRandomAnims = true;
    SpinnyDude.SetDrawScale( 0.3 );
    SpinnyDude.bHidden = true;

    SpinnyDude.LinkMesh( SkeletalMesh'SkaarjAnims.Skaarj_Skel' );
    SpinnyDude.LoopAnim( 'Idle_Rest', 1.0 );
}

private function LoadData()
{
    PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestTrophies" );
}

private function bool ExchangeTrophies()
{
    PlayerOwner().ConsoleCommand( "Mutate ExchangeTrophies" @ eb_Amount.GetText() );
    LoadData();
    return true;
}

function bool InternalOnClick( GUIComponent Sender )
{
    if( Sender == b_Exchange )
    {
        return ExchangeTrophies();
    }
}

function bool InternalOnDrawSpinnyDude( Canvas canvas )
{
    local vector CamPos, X, Y, Z;
    local rotator CamRot;

    canvas.GetCameraLocation( CamPos, CamRot );
    GetAxes( CamRot, X, Y, Z );

    SpinnyDude.SetLocation( CamPos + (SpinnyDudeOffset.X * X) + (SpinnyDudeOffset.Y * Y) + (SpinnyDudeOffset.Z * Z) );
    SpinnyDude.SetRotation( rotator(CamPos - SpinnyDude.Location) );

    canvas.DrawActor( SpinnyDude, false, true, 90.0 );
    return false;
}

function bool InternalOnDraw( Canvas C )
{
    local int i;
    local float YPos, XPos, XL, YL, orgCurY;

    if( CRI == none )
        return false;

    C.Font = Font'UT2003Fonts.jFontSmallText800x600';
    YPos = Region.ActualTop();
    C.StrLen( "T", XL, YL );
    for( i = CurPos; i < CRI.Trophies.Length; ++ i )
    {
        XPos = Region.ActualLeft();
        orgCurY = C.CurY;

        C.SetPos( XPos, YPos );
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.Style = 5;
        C.DrawTileStretched( RegionImage, Region.ActualWidth(), YL + 8 );

        XPos += 8;
        C.SetPos( XPos, YPos + 4 );
        C.DrawTileJustified( TrophyIcon, 1, YL, YL );

        // Title
        XPos += YL + 8;
        C.SetPos( XPos, YPos + 4 );
        C.Style = 3;
        C.DrawText( CRI.Trophies[i].Title );

        YPos += (YL + 8) + 8;

        if( YPos + (YL + 8) >= Region.ActualTop() + Region.ActualHeight() )
            break;
    }
    return true;
}

function bool InternalOnKeyEvent( out byte Key, out byte State, float delta )
{
    if( State == 0x01 )
    {
        if( Key == 0xEC )
        {
            CurPos = Max( CurPos - 1, 0 );
            return true;
        }
        else if( Key == 0xED )
        {
            CurPos = Min( CurPos + 1, CRI.Trophies.Length - 1 );
            return true;
        }
    }
    return false;
}

defaultproperties
{
    OnKeyEvent=InternalOnKeyEvent

    TrophyIcon=Texture'itemChecked'

    SpinnyDudeOffset=(X=150,Y=77,Z=20)

    Begin Object class=GUIImage name=oRegion
        bScaleToParent=true
        bBoundToParent=true
        WinWidth=0.70
        WinHeight=0.910000
        WinLeft=0.0
        WinTop=0.01
        Image=none
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        OnDraw=InternalOnDraw
    End Object
    Region=oRegion

    Begin Object class=GUISectionBackground name=render
        Caption="Currency Details"
        WinHeight=0.910000
        WinLeft=0.71
        WinTop=0.01
        WinWidth=0.29
        HeaderBase=Material'2K4Menus.NewControls.Display99'
    End Object
    sb_Background=render

    Begin Object class=GUIImage name=oRender
        bScaleToParent=true
        bBoundToParent=true
        WinHeight=0.25
        WinLeft=0.73
        WinTop=0.07
        WinWidth=0.25
        ImageColor=(R=255,G=255,B=255,A=128)
        ImageRenderStyle=MSTY_Alpha
        ImageStyle=ISTY_Stretched
        OnDraw=InternalOnDrawSpinnyDude
    End Object
    i_Render=oRender

    Begin Object Class=GUIScrollTextBox Name=Desc
        WinHeight=0.415
        WinLeft=0.725
        WinTop=0.38
        WinWidth=0.26
        bBoundToParent=true
        bScaleToParent=true
        bNoTeletype=true
        bVisibleWhenEmpty=true
    End Object
    eb_Description=Desc

    begin object class=GUIButton Name=oExchange
        Caption="Exchange for Currency"
        WinLeft=0.11
        WinTop=0.87
        WinWidth=0.30
        WinHeight=0.06
        OnClick=InternalOnClick
        Hint="Exchange all your trophies for Curreny points"
    end object
    b_Exchange=oExchange

    Begin Object class=GUIEditBox name=oAmount
        bScaleToParent=true
        bBoundToParent=true
        TextStr="All"
        WinLeft=0.0
        WinTop=0.875
        WinWidth=0.1
        WinHeight=0.05
        Hint="Amount of trophies to exchange"
    End Object
    eb_Amount=oAmount
}
