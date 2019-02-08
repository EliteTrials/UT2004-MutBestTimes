class BTGUI_ColorDialog extends FloatingWindow;

var automated GUILabel l_PreferedColor, l_Red, l_Green, l_Blue, l_Alpha;
var automated GUISlider s_Red, s_Green, s_Blue, s_Alpha;
var editconst ColorModifier SlideColor[4];

final static function Color GetPreferedColor( PlayerController PC )
{
    local LinkedReplicationInfo LRI;

    for( LRI = PC.PlayerReplicationInfo.CustomReplicationInfo; LRI != none; LRI = LRI.NextReplicationInfo )
    {
        if( LRI.IsA('BTClient_ClientReplication') )
        {
            return BTClient_ClientReplication(LRI).PreferedColor;
        }
    }
    return class'HUD'.default.WhiteColor;
}

function Free()
{
    local int i;

    for( i = 0; i < arraycount(SlideColor); ++ i )
    {
        SlideColor[i].Material = none;
        SlideColor[i].Color.R = 0;
        SlideColor[i].Color.G = 0;
        SlideColor[i].Color.B = 0;
        SlideColor[i].Color.A = 0;
        PlayerOwner().Level.ObjectPool.FreeObject( SlideColor[i] );
    }
    super.Free();
}

function Opened( GUIComponent sender )
{
    SlideColor[0] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
    SlideColor[0].Material = s_Red.FillImage;
    SlideColor[0].Color.R = 255;
    SlideColor[0].Color.G = 0;
    SlideColor[0].Color.B = 0;
    s_Red.FillImage = SlideColor[0];

    SlideColor[1] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
    SlideColor[1].Material = s_Green.FillImage;
    SlideColor[1].Color.R = 0;
    SlideColor[1].Color.G = 255;
    SlideColor[1].Color.B = 0;
    s_Green.FillImage = SlideColor[1];

    SlideColor[2] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
    SlideColor[2].Material = s_Blue.FillImage;
    SlideColor[2].Color.R = 0;
    SlideColor[2].Color.G = 0;
    SlideColor[2].Color.B = 255;
    s_Blue.FillImage = SlideColor[2];

    SlideColor[3] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
    SlideColor[3].Material = s_Alpha.FillImage;
    SlideColor[3].Color.R = 255;
    SlideColor[3].Color.G = 255;
    SlideColor[3].Color.B = 255;
    s_Alpha.FillImage = SlideColor[3];

    UpdateSliderValues( class'BTClient_Config'.static.FindSavedData().PreferedColor /*GetPreferedColor( PlayerOwner() )*/ );
}

function UpdateSliderValues( Color newValue )
{
    s_Red.SetValue( newValue.R );
    s_Green.SetValue( newValue.G );
    s_Blue.SetValue( newValue.B );
    s_Alpha.SetValue( newValue.A );
    l_PreferedColor.TextColor = newValue;
}

function bool InternalOnClick( GUIComponent sender )
{
    if( sender == s_Alpha )
    {
        SlideColor[3].Color.A = byte(s_Alpha.GetValueString());
        class'BTClient_Config'.static.FindSavedData().PreferedColor.A = SlideColor[3].Color.A;
        l_PreferedColor.TextColor.A = SlideColor[3].Color.A;
        return true;
    }
    else if( sender == s_Red )
    {
        class'BTClient_Config'.static.FindSavedData().PreferedColor.R = byte(s_Red.GetValueString());
        l_PreferedColor.TextColor.R = byte(s_Red.GetValueString());
        return true;
    }
    else if( sender == s_Green)
    {
        class'BTClient_Config'.static.FindSavedData().PreferedColor.G = byte(s_Green.GetValueString());
        l_PreferedColor.TextColor.G = byte(s_Green.GetValueString());
        return true;
    }
    else if( sender == s_Blue )
    {
        class'BTClient_Config'.static.FindSavedData().PreferedColor.B = byte(s_Blue.GetValueString());
        l_PreferedColor.TextColor.B = byte(s_Blue.GetValueString());
        return true;
    }
    return false;
}

function Closed( GUIComponent sender, bool bCancelled )
{
    local int i;

    PlayerOwner().ConsoleCommand( "UpdatePreferedColor" );

    for( i = 0; i < arraycount(SlideColor); i ++ )
    {
        if( SlideColor[i] != None )
        {
            SlideColor[i].Material = SlideColor[i].default.Material;
            SlideColor[i].Color = SlideColor[i].default.Color;
            PlayerOwner().Level.ObjectPool.FreeObject( SlideColor[i] );
            SlideColor[i] = none;
        }
    }
    super.Closed( sender, bCancelled );
}

defaultproperties
{
    WinLeft=0.6
    WinTop=0.6
    WinWidth=0.2
    WinHeight=0.2

    WindowName="Prefered Color Dialog"
    bAllowedAsLast=true

    // Text for colors...
    Begin Object class=GUILabel name=ColorTitle
        Caption="Prefered Color"
        TextColor=(R=255,G=255,B=255,A=255)
        WinHeight=0.06
        Winleft=0.02
        WinTop=0.05
        WinWidth=0.96
    End Object
    l_PreferedColor=ColorTitle

    Begin Object class=GUILabel name=redLabel
        Caption="Red:"
        TextColor=(R=255,G=0,B=0,A=255)
        WinHeight=0.06
        WinTop=0.2
        WinLeft=0.02
        WinWidth=0.2
    End Object
    l_Red=redLabel

    Begin Object class=GUISlider name=Red
        Value=50
        WinTop=0.2
        WinLeft=0.22
        WinWidth=0.76
        MinValue=0
        MaxValue=255
        bIntSlider=True
        bShowCaption=True
        OnClick=InternalOnClick
    End Object
    s_Red=Red

    Begin Object class=GUILabel name=greenLabel
        Caption="Green:"
        TextColor=(R=0,G=255,B=0,A=255)
        WinHeight=0.06
        WinTop=0.4
        WinLeft=0.02
        WinWidth=0.2
    End Object
    l_Green=greenLabel

    Begin Object class=GUISlider name=Green
        Value=255
        WinTop=0.4
        WinLeft=0.22
        WinWidth=0.76
        MinValue=0
        MaxValue=255
        bIntSlider=True
        bShowCaption=True
        OnClick=InternalOnClick
    End Object
    s_Green=Green

    Begin Object class=GUILabel name=blueLabel
        Caption="Blue:"
        TextColor=(R=0,G=0,B=255,A=255)
        WinHeight=0.06
        WinTop=0.6
        WinLeft=0.02
        WinWidth=0.2
    End Object
    l_Blue=blueLabel

    Begin Object class=GUISlider name=Blue
        Value=50
        WinTop=0.6
        WinLeft=0.22
        WinWidth=0.76
        MinValue=0
        MaxValue=255
        bIntSlider=True
        bShowCaption=True
        bShowValueTooltip=True
        OnClick=InternalOnClick
    End Object
    s_Blue=Blue

    Begin Object class=GUILabel name=alphaLabel
        Caption="Alpha:"
        TextColor=(R=255,G=255,B=255,A=128)
        WinHeight=0.06
        WinTop=0.8
        WinLeft=0.02
        WinWidth=0.2
    End Object
    l_alpha=alphaLabel

    Begin Object class=GUISlider name=Alpha
        Value=255
        WinTop=0.8
        WinLeft=0.22
        WinWidth=0.76
        MinValue=0
        MaxValue=255
        bIntSlider=True
        bShowCaption=True
        bShowValueTooltip=True
        OnClick=InternalOnClick
    End Object
    s_Alpha=Alpha
}
