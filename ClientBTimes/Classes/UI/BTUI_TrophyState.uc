//==============================================================================
// BTUI_TrophyState.uc (C) 2005-2014 Eliot All Rights Reserved
//==============================================================================
class BTUI_TrophyState extends BTClient_LocalMessage;

var() Texture TrophyDefaultIcon;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
)
{
    return BTClient_ClientReplication(OptionalObject).LastTrophyEvent.Title;
}

static function RenderComplexMessage(
    Canvas Canvas,
    out float XL,
    out float YL,
    optional String MessageString,
    optional int Switch,
    optional PlayerReplicationInfo MessageReceiver,
    optional PlayerReplicationInfo MessageInstigator,
    optional Object ReceiverClientReplication
    )
{
    local byte  Alpha;
    local float IconSize;

    Canvas.DrawTextClipped( MessageString, false );

    IconSize = YL*2;
    Alpha = Canvas.DrawColor.A;

    Canvas.SetPos( Canvas.CurX - IconSize - YL*0.33, Canvas.CurY + YL*0.5 - IconSize*0.5 );
    Canvas.DrawColor = Canvas.MakeColor(255, 255, 255);
    Canvas.DrawColor.A  = Alpha;
    Canvas.DrawTile( default.TrophyDefaultIcon, IconSize, IconSize, 0, 0, 128, 128);
}

defaultproperties
{
    Lifetime=8
    bComplexString=true
    DrawColor=(B=10,G=10,R=10,A=200)
    PosY=0.1
    StackMode=SM_Down
    TrophyDefaultIcon=Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Final'
}