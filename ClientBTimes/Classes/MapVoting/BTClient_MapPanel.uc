class BTClient_MapPanel extends GUIPanel;

var automated GUIImage MapScreenshot;
var automated GUILabel MapLabel;
var automated GUIMultiColumnListBox MapData;
// var automated GUITextBox MapDescription;

var private array<struct sMapKey
{
	var string Key;
	var string Value;
}> MapKeys;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	super.Initcomponent(MyController, MyOwner);
	MapData.List.Style = Controller.GetStyle( "BTMultiColumnList", MapData.List.FontScale );
	MapData.List.GetItemHeight = InternalGetItemHeight;
	MapData.List.OnDrawItem = InternalOnDrawMapValue;
	MapData.List.OnDblClick = InternalOnViewMapValue;
}

function float InternalGetItemHeight( Canvas C )
{
    local float xl, yl;

    MapData.List.Style.TextSize( C, MapData.List.MenuState, "T", xl, yl, MapData.List.FontScale );
    return yl + 8;
}

delegate OnMapSelected( GUIComponent sender, string mapName );

function InternalOnMapSelected( GUIComponent sender, string mapName )
{
	local LevelInfo mapInfo;
	local CacheManager.MapRecord mapRecord;
	local string mapTitle;

	Clear();
	mapRecord = class'CacheManager'.static.GetMapRecord( mapName );
	if( mapRecord.MapName == "" )
	{
		mapInfo = LevelInfo(DynamicLoadObject(mapName$".LevelInfo0", class'LevelInfo', true));
		if( mapInfo == none )
		{
			MapLabel.Caption = "N/A";
			MapScreenshot.Image = none;
			return;
		}

		mapTitle = mapInfo.Title;
		MapScreenshot.Image = mapInfo.Screenshot;
		AddValue( "Author", mapInfo.Author );
		AddValue( "Desc", mapInfo.Description );
		AddValue( "LCA", Eval(Actor(DynamicLoadObject(mapName$".LevelConfigActor0", class'Actor', true)) != none, "True", "False"));
	}
	else
	{
		mapTitle = mapRecord.FriendlyName;
		MapScreenshot.Image = Material(DynamicLoadObject(mapRecord.ScreenShotRef, class'Material', true));
		AddValue( "Author", mapRecord.Author );
		AddValue( "Desc", mapRecord.Description );
		AddValue( "Scale", mapRecord.PlayerCountMin @ "-" @ mapRecord.PlayerCountMax );
		AddValue( "Extra", mapRecord.ExtraInfo );
	}
	MapLabel.Caption = mapTitle;
}

function InternalOnDrawMapValue( Canvas C, int i, float X, float Y, float W, float H, bool bSelected, bool bPending )
{
	local GUIStyles drawStyle;
	local float CellLeft, CellWidth;

    Y += 2;
    H -= 2;

    C.Style = 1;
    C.SetPos( X, Y );
    if( bSelected )
    {
        C.DrawColor = #0x33333394;
    }
    else
    {
        C.DrawColor = #0x22222282;
    }

    C.DrawTile( Texture'BTScoreBoardBG', W, H, 0, 0, 256, 256 );

	drawStyle = MapData.List.Style;
	MenuState = MSAT_Blurry;
	if( bSelected )
	{
		MenuState = MSAT_Focused;
	}

    MapData.List.GetCellLeftWidth( 0, CellLeft, CellWidth );
    drawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        MapKeys[i].Key, MapData.List.FontScale );

    MapData.List.GetCellLeftWidth( 1, CellLeft, CellWidth );
    drawStyle.DrawText( C, MenuState, CellLeft, Y, CellWidth, H, TXTA_Left,
        MapKeys[i].Value, MapData.List.FontScale );
}

function bool InternalOnViewMapValue( GUIComponent sender )
{
	local string value;

	if( MapData.List.Index == -1 )
		return false;

	value = MapKeys[MapData.List.Index].Value;
	if( value == "" )
		return false;

    Controller.OpenMenu("GUI2K4.GUI2K4QuestionPage");
 	GUIQuestionPage(Controller.TopPage()).SetPosition( 0.05, 0.1, 0.9, 0.8, true );
    GUIQuestionPage(Controller.TopPage()).SetupQuestion(value, QBTN_Ok, QBTN_Ok);
    return true;
}

final function Clear()
{
	MapData.List.Clear();
	MapKeys.Length = 0;
}

final function AddValue( coerce string key, coerce string value )
{
	local int i;

	i = MapKeys.Length;
	MapKeys.Length = i + 1;
	MapKeys[i].Key = key;
	MapKeys[i].Value = value;
	MapData.List.AddedItem();
}

defaultproperties
{
	StyleName="BTHUD"
	OnMapSelected=InternalOnMapSelected

	begin object class=GUIImage name=oMapScreenshot
		WinWidth=0.5
		WinHeight=1.0
		WinLeft=0.0
		WinTop=0.0
        ImageColor=(R=255,G=255,B=255,A=255)
        ImageStyle=ISTY_Scaled
        ImageRenderStyle=MSTY_Normal
        RenderWeight=0.2
		bScaleToParent=true
		bBoundToParent=true
	end object
	MapScreenshot=oMapScreenshot

	begin object class=GUILabel name=oMapLabel
		Caption="N/A"
		TextAlign=TXTA_Center
		TextColor=(R=255,G=255,B=255,A=255)
		WinWidth=0.5
		WinHeight=0.2
		WinLeft=0.0
		WinTop=0.01
		bScaleToParent=true
		bBoundToParent=true
	end object
	MapLabel=oMapLabel

    begin object class=BTClient_MultiColumnListHeader name=oHeader
        BarStyleName=""
    end object
    begin object class=GUIMultiColumnListBox Name=oGUIMultiColumnListBox
        WinWidth=0.48
        WinHeight=0.99
        WinLeft=0.52
        WinTop=0.0
        bVisibleWhenEmpty=true
        bScaleToParent=true
        bBoundToParent=true
        FontScale=FNS_Small
        HeaderColumnPerc(0)=0.28
        HeaderColumnPerc(1)=0.72
        ColumnHeadings(0)="Key"
        ColumnHeadings(1)="Value"
        Header=oHeader
    end object
    MapData=oGUIMultiColumnListBox
}

#include classes/BTColorHashUtil.uci