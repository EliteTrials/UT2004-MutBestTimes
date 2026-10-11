// Independent HTTP request: record notifications never interrupt auth polling.
class BTDiscordRecordNotifier extends Info;

var private HttpSock Sock;
var private string Body, Reply;
var private bool bBusy, bHasReply;
var private float StartedAt;
var private byte Attempts;

final function Begin(string recordBody)
{
    Body = recordBody;
    SetTimer(1.0, true);
    Send();
}

private final function Send()
{
    if (!class'BTDiscordAuth'.static.IsConfigured())
    {
        Destroy();
        return;
    }

    if (Sock != none)
        Sock.Destroy();

    Sock = Spawn(class'HttpSock', self);
    if (Sock == none)
    {
        Destroy();
        return;
    }

    Sock.iVerbose = 0;
    Sock.bUseProxy = false;
    Sock.bFollowRedirect = false;
    Sock.bSendCookies = false;
    Sock.bProcCookies = false;
    Sock.fConnectTimout = 5.0;
    Sock.OnComplete = OnComplete;
    Sock.OnError = OnError;
    Sock.OnConnectError = OnConnectError;
    Sock.OnConnectionTimeout = OnConnectError;
    Sock.OnResolveFailed = OnResolveFailed;
    Sock.OnResponseBody = OnResponseBody;
    Sock.AddHeader("Authorization", "Bearer " $ class'BTDiscordAuth'.default.ApiKey);

    bBusy = true;
    bHasReply = false;
    Reply = "";
    StartedAt = Level.TimeSeconds;
    ++Attempts;

    if (!Sock.Post(class'BTDiscordAuth'.default.Host $ "/record", Body))
        Retry();
}

function bool OnResponseBody(HttpSock sender, string line)
{
    if (bBusy && sender == Sock && !bHasReply && line != "")
    {
        Reply = line;
        bHasReply = true;
    }

    return false;
}

function OnComplete(HttpSock sender)
{
    if (!bBusy || sender != Sock)
        return;

    bBusy = false;
    if ((sender.LastStatus == 200 || sender.LastStatus == 202)
        && (Reply == "queued" || Reply == "duplicate" || Reply == "skipped"))
    {
        Destroy();
        return;
    }

    if (sender.LastStatus >= 500 || sender.LastStatus == 0)
        Retry();
    else
    {
        Log("Discord record notification rejected: HTTP " $ sender.LastStatus, 'DiscordRecords');

        Destroy();
    }
}

private final function Retry()
{
    bBusy = false;
    bHasReply = false;
    StartedAt = Level.TimeSeconds;
    if (Attempts >= 3)
    {
        Log("Could not queue a Discord record notification. Check the local bot.", 'DiscordRecords');
        Destroy();
    }
}

function OnError(HttpSock sender, string errorMessage, optional string param1, optional string param2)
{
    if (bBusy && sender == Sock)
        Retry();
}

function OnConnectError(HttpSock sender)
{
    if (bBusy && sender == Sock)
        Retry();
}

function OnResolveFailed(HttpSock sender, string hostname)
{
    OnConnectError(sender);
}

event Timer()
{
    if (bBusy)
    {
        if (bHasReply)
            OnComplete(Sock);
        else if (Level.TimeSeconds - StartedAt > 10.0)
            Retry();
    }
    else if (Level.TimeSeconds - StartedAt >= 2.0)
        Send();
}

event Destroyed()
{
    if (Sock != none)
        Sock.Destroy();

    super.Destroyed();
}

defaultproperties
{
    RemoteRole=ROLE_None
}
