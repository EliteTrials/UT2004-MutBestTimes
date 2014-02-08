//==============================================================================
// Last updated at: $wotgreal_dt: 19/10/2011 1:40:58 $
//==============================================================================
class BTGUI_Achievements extends BTGUI_StatsTab;

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if( bShow && ClientData != none && PlayerOwner().Level.TimeSeconds > 5 )
    {
        PlayerOwner().ConsoleCommand( "Mutate BTClient_RequestAchievementsStates" );
    }
}

function bool InternalOnDraw( Canvas C )
{
    local int i, achievementsEarned;
    local float YPos, XPos, XL, YL;//, oClipX, oClipY;

    if( ClientData == none )
        return false;

    C.Font = Font'UT2003Fonts.jFontSmallText800x600';
    YPos = Region.ActualTop();
    XPos = Region.ActualLeft();

    //oClipX = C.ClipX;
    //oClipY = C.ClipY;
    //C.ClipX = XPos + Region.ActualWidth();
    //C.ClipY = YPos + Region.ActualHeight();

    for( i = 0; i < ClientData.AchievementsStates.Length; ++ i )
    {
        if( ClientData.AchievementsStates[i].bEarned )
            ++ achievementsEarned;
    }

    // Achievements progress
    C.SetPos( XPos + 16, YPos );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.Style = 3;
    C.StrLen( "Achievements progress", XL, YL );
    C.DrawTextClipped( "Achievements progress" );

    YPos += YL;

    C.SetPos( XPos + 16, YPos );
    C.DrawColor = class'HUD'.default.BlackColor;
    C.Style = 1;
    C.DrawTile( MyMenu.MyInteraction.AlphaLayer, Region.ActualWidth() - 32, 16, 0, 0, 256, 256 );

    C.SetPos( XPos + 16, YPos );
    C.DrawColor = class'HUD'.default.GreenColor;
    C.DrawTile
    (
        MyMenu.MyInteraction.AlphaLayer,
        (Region.ActualWidth() - 32) * (float(achievementsEarned) / float(ClientData.AchievementsStates.Length)),
        16, 0, 0, 256, 256
    );

    C.StrLen( achievementsEarned $ "/" $ ClientData.AchievementsStates.Length, XL, YL );
    C.SetPos( (XPos + 32) + (((Region.ActualWidth() - 32) * 0.5) - (XL * 0.5)), YPos );
    C.DrawColor = class'HUD'.default.WhiteColor;
    C.Style = 3;
    C.DrawTextClipped( achievementsEarned $ "/" $ ClientData.AchievementsStates.Length );

    YPos += 16;

    for( i = CurPos; i < ClientData.AchievementsStates.Length; ++ i )
    {
        // Region background
        //C.SetPos( AchievementsRegion.ActualLeft(), YPos );

        // Icon
        YPos += 16;
        C.SetPos( XPos + 16, YPos );
        if( ClientData.AchievementsStates[i].bEarned )
        {
            C.DrawColor = class'HUD'.default.GreenColor;
        }
        else if( ClientData.AchievementsStates[i].Progress > 0 )
        {
            C.DrawColor = class'HUD'.default.WhiteColor;
        }
        else
        {
            C.DrawColor = class'HUD'.default.RedColor;
        }
        C.Style = 1;
        C.DrawTile( class'BTUI_AchievementState'.default.AchievementDefaultIcon, IconSize, IconSize, 0.0, 0.0, 128, 128 );
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.Style = 3;

        C.Font = Font'UT2003Fonts.FontMono800x600';
        C.StrLen( ClientData.AchievementsStates[i].Points, XL, YL );

        C.SetPos( XPos + 16 + (IconSize * 0.5f - XL * 0.5f), YPos + (IconSize * 0.5f - YL * 0.5f) );
        C.DrawTextClipped( ClientData.AchievementsStates[i].Points );
        C.Font = Font'UT2003Fonts.jFontSmallText800x600';

        // Title
        C.SetPos( XPos + IconSize + 32, YPos );
        C.DrawTextClipped( ClientData.AchievementsStates[i].Title );

        // Description
        YPos += YL;
        C.SetPos( XPos + IconSize + 32, YPos );
        C.DrawTextClipped( ClientData.AchievementsStates[i].Description );

        YPos += YL;
        if( ClientData.AchievementsStates[i].Count > 0 )
        {
            // Progress
            C.SetPos( XPos + IconSize + 32, YPos );
            C.DrawColor = class'HUD'.default.BlackColor;
            C.Style = 1;
            C.DrawTile( MyMenu.MyInteraction.AlphaLayer, Region.ActualWidth() - IconSize - 32, 16, 0, 0, 256, 256 );

            C.SetPos( XPos + IconSize + 32, YPos );
            C.DrawColor = class'HUD'.default.GreenColor;
            C.DrawTile
            (
                MyMenu.MyInteraction.AlphaLayer,
                (Region.ActualWidth() - IconSize - 32) * (float(Min( ClientData.AchievementsStates[i].Progress, ClientData.AchievementsStates[i].Count )) / float(ClientData.AchievementsStates[i].Count)),
                16, 0, 0, 256, 256
            );

            C.StrLen( ClientData.AchievementsStates[i].Progress $ "/" $ ClientData.AchievementsStates[i].Count, XL, YL );
            C.SetPos( (XPos + IconSize + 32) + (((Region.ActualWidth() - IconSize - 32) * 0.5) - (XL * 0.5)), YPos );
            C.DrawColor = class'HUD'.default.WhiteColor;
            C.Style = 3;
            C.DrawTextClipped( ClientData.AchievementsStates[i].Progress $ "/" $ ClientData.AchievementsStates[i].Count );

            //YPos += 16;
        }

        YPos += 16;

        // Check if the next one will fit within the Canvas.
        if( YPos + YL*2 + 16 >= Region.ActualTop() + Region.ActualHeight() )
            break;
    }

    //C.ClipX = oClipX;
    //C.ClipY = oClipY;

    return true;
}

function bool OnKeyEvent( out byte Key, out byte State, float delta )
{
    if( State == 0x01 && ClientData != none )
    {
        if( Key == 0xEC )
        {
            CurPos = Max( CurPos - 1, 0 );
            return true;
        }
        else if( Key == 0xED )
        {
            CurPos = Min( CurPos + 1, ClientData.AchievementsStates.Length - 1 );
            return true;
        }
    }
    return false;
}

defaultproperties
{
    OnKeyEvent=OnKeyEvent
}
