//==============================================================================
// BTClient_SoloFinish.uc (C) 2005-2009 Eliot and .:..:. All Rights Reserved
/* Tasks:
            Display a complex message to all clients about a new solo record
*/
//  Coded by Eliot
//  Updated @ 19/11/2009
//  Updated @ 16/01/2014
//==============================================================================
class BTLevelCompletedMessage extends BTClient_LocalMessage;

var Color RecordStateColor[3];

/** Returns color A as a color tag. */
static final preoperator string $( Color A )
{
    return (Chr( 0x1B ) $ (Chr( Max( A.R, 1 )  ) $ Chr( Max( A.G, 1 ) ) $ Chr( Max( A.B, 1 ) )));
}

/** Strips all color tags from A. */
static final preoperator string %( string A )
{
    local int i;

    while( true )
    {
        i = InStr( A, Chr( 0x1B ) );
        if( i != -1 )
        {
            A = Left( A, i ) $ Mid( A, i + 4 );
            continue;
        }
        break;
    }
    return A;
}

static function color GetColor(
    optional int RecordState,
    optional PlayerReplicationInfo MessageReceiver,
    optional PlayerReplicationInfo MessageInstigator
    )
{
    return default.RecordStateColor[RecordState];
}

// Make a copy of the temporary ClientMessage
static function string GetString( optional int RecordState,
    optional PlayerReplicationInfo MessageReceiver, optional PlayerReplicationInfo MessageInstigator,
    optional Object ReceiverClientReplication )
{
    return Repl(
        super.GetString(RecordState, MessageReceiver, MessageInstigator, ReceiverClientReplication),
        "%PLAYER%",
        $class'HUD'.default.WhiteColor $ class'BTClient_TrialScoreBoard'.static.GetCName(MessageInstigator) $ $GetColor(RecordState, MessageReceiver, MessageInstigator)
    );
}

static function RenderComplexMessage(
    Canvas Canvas,
    out float XL,
    out float YL,
    optional String MessageString,
    optional int RecordState,
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
    if( RecordState == 1 )
    {
        Canvas.DrawColor = Canvas.MakeColor(255, 255, 255);
        Canvas.DrawColor.A  = Alpha;
        // AS_FX_TX.Icons.ScoreBoard_Objective_Final
        Canvas.DrawTile( Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Single', IconSize, IconSize, 0, 0, 128, 128);
    }
    else if( RecordState == 0 || RecordState == 2 )
    {
        Canvas.DrawColor = Canvas.MakeColor(255, 0, 0);
        Canvas.DrawColor.A  = Alpha;
        Canvas.DrawTile( Texture'AS_FX_TX.Icons.ScoreBoard_Objective_Single', IconSize, IconSize, 0, 0, 128, 128);
        // Canvas.DrawTile( Texture'AS_FX_TX.Emitter.HoldArrow', IconSize, IconSize, 0, 0, 128, 128);
    }
}

// Taken from the canvas class. Changed to a different texture
final static function DrawHorizontal( Canvas C, float Y, float width)
{
    local float cx,cy;

    CX = C.CurX; CY = C.CurY;
    C.CurY = Y;
    C.DrawTile(Texture'ucgeneric.solidcolours.Black', width, 2, 0, 0, 2, 2);
    C.CurX = CX; C.CurY = CY;
}

// Taken from the canvas class. Changed to a different texture
final static function DrawVertical( Canvas C, float X, float height)
{
    local float cX,cY;

    CX = C.CurX; CY = C.CurY;
    C.CurX = X;
    C.DrawTile(Texture'ucgeneric.solidcolours.Black', 2, height, 0, 0, 2, 2);
    C.CurX = CX; C.CurY = CY;
}

DefaultProperties
{
    Lifetime=6
    bComplexString=True

    DrawColor=(R=255,G=128,B=0,A=255)
    // Fail
    RecordStateColor(0)=(R=255,G=0,B=0,A=255)
    // Success
    RecordStateColor(1)=(R=255,G=255,B=0,A=255)
    // Tie
    RecordStateColor(2)=(R=20,G=20,B=20,A=255)
    FontSize=-2

    StackMode=SM_Down
    PosY=0.35
}
