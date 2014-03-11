//=============================================================================
// Copyright 2011-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTGUI_Achievements extends BTGUI_StatsTab
    dependson(BTClient_ClientReplication);

var Texture TileMat;

var automated GUITreeListBox        CategoriesListBox;
var automated GUISectionBackground  AchievementsBackground, CategoriesBackground;
var automated GUIVertImageListBox   AchievementsListBox;

function ShowPanel( bool bShow )
{
    super.ShowPanel( bShow );

    if( CRI == none )
    {
        Log( "ShowPanel, CRI not found!" );
        return;
    }

    AchievementsListBox.List.OnDrawItem = InternalOnDrawItem;
    // AchievementsListBox.List.GetItemHeight = InternalGetItemHeight;

    if( bShow && CRI.AchievementCategories.Length == 0 )
    {
        CRI.OnAchievementCategoryReceived = InternalOnAchievementCategoryReceived;
        CRI.ServerRequestAchievementCategories();
    }
}

function InternalOnAchievementCategoryReceived( int index )
{
    local BTClient_ClientReplication.sAchievementCategory cat;
    local int parentIndex;
    local int i;

    cat = CRI.AchievementCategories[index];
    if( cat.ParentId != "" )
    {
        parentIndex = -1;
        for( i = 0; i < CRI.AchievementCategories.Length; ++ i )
        {
            if( CRI.AchievementCategories[i].Id == cat.ParentId )
            {
                parentIndex = i;
                break;
            }
        }

        if( parentIndex != -1 )
        {
            CategoriesListBox.List.AddItem( cat.Name, cat.ID, CRI.AchievementCategories[parentIndex].Name, true );
        }
    }
    else
    {
        CategoriesListBox.List.AddItem( cat.Name, cat.ID,, true );
    }
}

function bool InternalOnCategoryClicked( GUIComponent sender )
{
    local string val;

    // Clear achievements from previous category.
    AchievementsListBox.List.Clear();
    CRI.AchievementsStates.Length = 0;

    val = CategoriesListBox.List.GetValue();
    AchievementsBackground.Caption = CategoriesListBox.List.GetCaption();
    CRI.OnAchievementStateReceived = InternalOnAchievementStateReceived;
    CRI.ServerRequestAchievementsByCategory( val );
    return true;
}

function InternalOnAchievementStateReceived( int index )
{
    local BTClient_ClientReplication.sAchievementState achievement;
    local Material icon;

    icon = Material(DynamicLoadObject( achievement.Icon, class'Material', true ));
    if( icon == none )
    {
        icon = class'BTUI_AchievementState'.default.AchievementDefaultIcon;
    }

    achievement = CRI.AchievementsStates[index];
    AchievementsListBox.List.Add( icon, index, 1 - int(achievement.bEarned) );
}

// Ensure all items are squared.
function float InternalGetItemHeight( Canvas C )
{
    return AchievementsListBox.List.ItemWidth;
}

final static preoperator Color #( int rgbInt )
{
    local Color c;

    c.R = rgbInt >> 24;
    c.G = rgbInt >> 16;
    c.B = rgbInt >> 8;
    c.A = (rgbInt & 255);
    return c;
}

function InternalOnDrawItem( Canvas C, int Item, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
    local BTClient_ClientReplication.sAchievementState achievement;
    local float XL, YL;
    local GUIVertImageList list;
    local Texture icon;
    local float iconSize;
    local float oldClipX, oldClipY;
    local float footerHeight;

    list = AchievementsListBox.List;
    X += int((float(Item)%float(list.NoVisibleCols)))*(w+list.HorzBorder);
    Y += int(((float(Item)/float(list.NoVisibleCols)%float(list.NoVisibleRows))))*(h+list.VertBorder);
    w -= list.HorzBorder;
    h -= list.VertBorder;
    achievement = CRI.AchievementsStates[Item];

    oldClipX = C.ClipX;
    oldClipY = C.ClipY;
    C.ClipX = X + W;
    C.ClipY = Y + H;
    C.Font = Font'UT2003Fonts.jFontSmallText800x600';
    C.Style = 1;

    C.DrawColor = CRI.Options.CTable;
    if( bSelected || bPending )
    {
        C.DrawColor = #0x00529668;
    }
    C.SetPos( int(X), int(Y) );
    C.DrawTileClipped( TileMat, int(w), int(h), 0, 0, 256, 256 );

    if( achievement.bEarned )
    {
        C.OrgX = X;
        C.OrgY = Y;
        C.SetPos( -100, -64 );
        C.DrawColor = achievement.EffectColor;
        C.DrawTileClipped( Shader'Achievement_Effect', w + 100, h + 64, 0, 0, 110, 128 );
        C.OrgX = 0;
        C.OrgY = 0;
    }

    // RENDER: Icon
    C.DrawColor = class'HUD'.default.WhiteColor;
    if( !achievement.bEarned )
    {
        C.DrawColor.A = 70;
    }
    if( achievement.Icon == "" )
    {
        icon = class'BTUI_AchievementState'.default.AchievementDefaultIcon;
    }
    else
    {
        icon = Texture(DynamicLoadObject( achievement.Icon, class'Texture' ));
    }
    iconSize = w/3;
    C.SetPos( X + 4, Y + h*0.5 - iconSize*0.5 + 4 );
    C.DrawTileClipped( icon, iconSize - 8, iconSize - 8, 0.0, 0.0, 128, 128 );

    C.TextSize( string(achievement.Points), XL, YL );
    C.SetPos( X + iconSize*0.5 - XL*0.5, Y + h*0.5 - YL*0.5 );
    C.DrawTextClipped( string(achievement.Points) );

    // C.SetPos( X, Y );
    // C.DrawBox( C, iconSize, h );

    C.StrLen( "T", XL, YL );
    footerHeight = YL + 8;

    // RENDER: Progress
    if( achievement.Count > 0 )
    {
        C.TextSize( achievement.Progress $ "/" $ achievement.Count, XL, YL );

        C.SetPos( X + 4, Y + h - footerHeight - 6 );
        C.DrawColor = class'HUD'.default.BlackColor;
        C.DrawColor.A = 80;
        C.DrawTileClipped( TileMat, iconSize - 8, footerHeight, 0, 0, 256, 256 );

        C.SetPos( X + 4, Y + h - footerHeight - 6 );
        C.DrawColor = achievement.EffectColor;
        C.DrawColor.A = 80;
        C.DrawTileClipped
        (
            TileMat,
            iconSize * (float(Min( achievement.Progress, achievement.Count )) / float(achievement.Count)) - 8,
            footerHeight,
            0, 0, 256, 256
        );

        C.SetPos( X + iconSize*0.5 - XL*0.5 + 4, Y + h - footerHeight - 2 );
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.DrawTextClipped( achievement.Progress $ "/" $ achievement.Count );

        // RENDER: Title
        C.TextSize( achievement.Title, XL, YL );
        C.SetPos( (X + iconSize) + (w - iconSize)*0.5 - XL*0.5 + 4, Y + h - footerHeight - 2 );
        C.ClipX -= 8;
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.DrawTextClipped( achievement.Title );
        C.ClipX += 8;
    }
    else
    {
        // RENDER: Title
        C.TextSize( achievement.Title, XL, YL );
        C.OrgX = X + 8;
        C.OrgY = Y + h - footerHeight;
        C.ClipX = W - 16;
        C.SetPos( w*0.5 - XL*0.5, 0 );
        C.DrawColor = class'HUD'.default.WhiteColor;
        C.DrawTextClipped( achievement.Title );
        C.OrgX = X + W;
        C.OrgY = Y + H;

    }

    // RENDER: Description
    C.OrgX = X + iconSize + 8;
    C.OrgY = Y + 8;
    C.ClipX = W - (iconSize + 8) - 8;
    C.ClipY = H - 8 - 8;
    C.SetPos( 0, 0 );
    C.DrawColor = #0x22222266;
    C.StrLen( achievement.Description, XL, YL );
    C.DrawTileClipped( TileMat, XL + 8, YL + 8, 0, 0, 256, 256 );
    C.OrgX += 4;
    C.ClipX -= 8;
    C.OrgY += 4;
    C.ClipY -= 8;
    C.SetPos( 0, 0 );
    C.DrawColor = class'HUD'.default.WhiteColor; // reset
    C.DrawText( achievement.Description );
    C.OrgX = 0;
    C.OrgY = 0;
    C.ClipX = X + W;
    C.ClipY = Y + H;

    // C.SetPos( X + iconSize, Y + h - footerHeight );
    // C.DrawBox( C, w - iconSize, footerHeight );

    // C.SetPos( X, Y );
    // C.DrawBox( C, w, h );

    C.ClipX = oldClipX;
    C.ClipY = oldClipY;
}

defaultproperties
{
    OnKeyEvent=OnKeyEvent
    TileMat=Texture'BTScoreBoardBG'

    begin object class=GUISectionBackground name=oCategoriesBackground
        WinWidth=0.29
        WinHeight=0.92
        WinLeft=0.0
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
        Caption="Categories"
        HeaderBase=Material'2K4Menus.NewControls.Display99'
    end object
    CategoriesBackground=oCategoriesBackground

    begin object class=GUITreeListBox name=oCategoriesListBox
        WinWidth=0.250000
        WinHeight=0.800000
        WinLeft=0.020000
        WinTop=0.070000
        OnClick=InternalOnCategoryClicked
    end object
    CategoriesListBox=oCategoriesListBox

    begin object class=GUISectionBackground name=oAchievementsBackground
        WinWidth=0.700000
        WinHeight=0.92
        WinLeft=0.300000
        WinTop=0.01
        bBoundToParent=true
        bScaleToParent=true
        Caption="Achievements"
        HeaderBase=Material'2K4Menus.NewControls.Display99'
    end object
    AchievementsBackground=oAchievementsBackground

    begin object class=GUIVertImageListBox name=oAchievementsListBox
        WinWidth=0.660000
        WinHeight=0.790000
        WinLeft=0.320000
        WinTop=0.070000
        bBoundToParent=true
        bScaleToParent=true

        CellStyle=Cell_FixedCount
        NoVisibleRows=3
        NoVisibleCols=2
        TabOrder=0

        VertBorder=8
        HorzBorder=4
    end object
    AchievementsListBox=oAchievementsListBox
}
