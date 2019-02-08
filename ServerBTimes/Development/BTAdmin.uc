class BTAdmin extends WebApplication;

/* Usage:
This is a sample web application, to demonstrate how to program for the web server.


[UWeb.WebServer]
Applications[0]="ServerBTimes.BTServer_BTAdmin"
ApplicationPaths[0]="/BTAdmin"
bEnabled=True

http://http://192.168.1.2/BTAdmin/index.htm

*/

var string Title;

var MutBestTimes BT;

function CleanupApp()
{
    BT = none;
    super.CleanupApp();
}

event Query( WebRequest request, WebResponse response )
{
    local int i;
    local string content;

    if( request.UserName != "BTAdmin" || request.Password != class'BTServer_HttpNotificator'.default.SecurityHash )
    {
        response.FailAuthentication( "BTAdmin" );
        return;
    }

    if( BT == none )
    {
        FindBT();
    }

    if( request.URI == "/" )
    {
        request.URI = "/index.htm";
    }
    response.Subst( "Title", Title @ Mid( request.URI, 1 ) );

    content = response.LoadParsedUHTM( "BTAdmin/page_template.htm" );
    response.SendText( Left( content, InStr( content, "<page/>" ) ) );

    if( request.URI == "/recordspanel.htm" )
    {
        response.SendText( "<table><tr><th>MapName</th><th>Records</th><th>Play Hours</th></tr>" );
        for( i = 0; i < BT.RDat.Rec.Length; ++ i )
        {
            response.SendText( "<tr><td><a href='" $ BT.RDat.Rec[i].TMN $ ".rec'>" $ BT.RDat.Rec[i].TMN $
            "</td><td>" $ BT.RDat.Rec[i].PSRL.Length $
            "</td><td>" $ BT.RDat.Rec[i].PlayHours $
            "</td></tr>" );
        }
        response.SendText( "</table>" );
    }
    else if( request.URI == "/playerspanel.htm" )
    {
        response.SendText( "<table><tr><th>PlayerName</th><th>PlayerGUID</th><th>Play Hours</th></tr>" );
        for( i = 0; i < BT.PDat.Player.Length; ++ i )
        {
            response.SendText( "<tr><td><a href='" $ BT.PDat.Player[i].PLID $ ".acc'>" $ %BT.PDat.Player[i].PLNAME $
            "</td><td>" $ BT.PDat.Player[i].PLID $
            "</td><td>" $ BT.PDat.Player[i].PlayHours $
            "</td></tr>" );
        }
        response.SendText( "</table>" );
    }

    if( InStr( request.URI, ".rec" ) != -1 )
    {
        GenerateRec( request, response );
    }
    else if( InStr( request.URI, ".acc" ) != -1 )
    {
        GenerateAcc( request, response );
    }
    else response.SendCachedFile( "BTAdmin" $ request.URI );

    if( request.RequestType == Request_POST )
    {
        //BT.FullLog( "submit:" $ request.GetVariable( "submit" ) );

        if( request.GetVariable( "submit" ) ~= "perform" )
        {
            Perform( response, request.GetVariable( "method" ), request.GetVariable( "mapname" ) );
        }
        else if( request.GetVariable( "submit" ) ~= "save" )
        {
            if( InStr( request.URI, ".rec" ) != -1 )
            {
                SaveRec( request );
            }
            else if( InStr( request.URI, ".acc" ) != -1 )
            {
                SaveAcc( request );
            }
        }
    }
    response.SendText( Mid( content, InStr( content, "<page/>" ) + 7 ) );
}

function SaveRec( WebRequest request )
{
    local int recSlot;
    local string mapName;
    local bool bdisabled;

    mapName = Mid( Left( request.URI, InStr( request.URI, ".rec" ) ), 1 );

    recSlot = BT.RDat.FindRecord( mapName );
    if( recSlot == -1 )
    {
        return;
    }

    bdisabled = request.GetVariable( "ghostdisabled" ) ~= "true";
    if( BT.RDat.Rec[recSlot].TMGhostDisabled != bdisabled )
    {
        BT.RDat.Rec[recSlot].TMGhostDisabled = bdisabled;
        BT.SaveRecords();
    }
}

function SaveAcc( WebRequest request )
{
    local int accSlot;
    local string playerID;

    playerID = Mid( Left( request.URI, InStr( request.URI, ".acc" ) ), 1 );

    accSlot = BT.PDat.FindPlayerByID( playerID );
    if( accSlot == -1 )
    {
        return;
    }

    if( BT.PDat.Player[accSlot].PLID != request.GetVariable( "playerid" ) )
    {
        BT.PDat.Player[accSlot].PLID = request.GetVariable( "playerid" );
        BT.SavePlayers();
    }
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

function GenerateAcc( WebRequest request, WebResponse response )
{
    local int accSlot;
    local string playerName, playerID;

    playerID = Mid( Left( request.URI, InStr( request.URI, ".acc" ) ), 1 );

    accSlot = BT.PDat.FindPlayerByID( playerID );
    if( accSlot == -1 )
    {
        response.SendText( "Couldn't find account for this player!" );
        return;
    }

    playerName = %BT.PDat.Player[accSlot].PLNAME;
    response.SendText( "<h1>" $ playerName $ "</h1>" );

    response.SendText( "<table><tr><th>Option</th><th>Value</th></tr>" );
    response.SendText( CreateTextBox( response, "Player GUID", "playerid", playerID ) );
    //response.SendText( CreateCheckBox( response, "Ghost Disabled?", "ghostdisabled", BT.RDat.Rec[recSlot].TMGhostDisabled ) );
    response.SendText( "</table>" );
}

function GenerateRec( WebRequest request, WebResponse response )
{
    local int i, recSlot;
    local string mapName;

    mapName = Mid( Left( request.URI, InStr( request.URI, ".rec" ) ), 1 );
    response.SendText( "<h1>" $ mapName $ "</h1>" );

    recSlot = BT.RDat.FindRecord( mapName );
    if( recSlot == -1 )
    {
        response.SendText( "Couldn't find record for this map!" );
        return;
    }

    response.SendText( "<table><tr><th>Option</th><th>Value</th></tr>" );
    response.SendText( CreateCheckBox( response, "Ghost Disabled?", "ghostdisabled", BT.RDat.Rec[recSlot].TMGhostDisabled ) );
    response.SendText( "</table>" );

    if( BT.RDat.Rec[recSlot].PSRL.Length > 0 )
    {
        response.SendText( "<table><tr><th>Records</th></tr>" );
        for( i = 0; i < BT.RDat.Rec[recSlot].PSRL.Length; ++ i )
        {
            response.SendText( "<tr><td>" $ %BT.PDat.Player[BT.RDat.Rec[recSlot].PSRL[i].PLs].PLName $ "</tr></td>" );
        }
        response.SendText( "</table>" );
    }
}

function string CreateCheckBox( WebResponse response, string title, string name, optional bool bchecked )
{
    response.Subst( "Type", "checkbox" );
    response.Subst( "Option", title );
    response.Subst( "Name", name );
    response.Subst( "Value", "true" );
    response.Subst( "Checked", Eval( bchecked, "checked", "" ) );
    return response.LoadParsedUHTM( "BTAdmin/input_template.htm" );
}

function string CreateTextBox( WebResponse response, string title, string name, optional string value )
{
    response.Subst( "Type", "textbox" );
    response.Subst( "Option", title );
    response.Subst( "Name", name );
    response.Subst( "Value", value );
    response.Subst( "Checked", "" );
    return response.LoadParsedUHTM( "BTAdmin/input_template.htm" );
}

function Perform( WebResponse response, string method, string mapName )
{
    local int recSlot;

    recSlot = BT.RDat.FindRecord( mapName );
    if( recSlot != -1 )
    {
        if( recSlot == BT.UsedSlot )
        {
            response.SendText( "<p>Sorry" @ mapName @ " is currently being played!</p>" );
            return;
        }
        BT.DeleteRecordBySlot( recSlot );
        response.SendText( "<p>Successfully deleted the record for" @ mapName $ "</p>" );
    }
    else
    {
        response.SendText( "<p>Couldn't find" @ mapName @ "</p>" );
    }
}

final function FindBT()
{
    local Mutator m;

    for( m = Level.Game.BaseMutator; m != none; m = m.NextMutator )
    {
        if( MutBestTimes(m) != none )
        {
            BT = MutBestTimes(m);
            break;
        }
    }
}

defaultproperties
{
    Title="WebBTimes Admin:"
}