// Server-only authentication state for one player connection.
class BTDiscordAuth extends Info
    config(MutBestTimes);

var() globalconfig bool bEnabled;
var() globalconfig bool bNotifyRecords;
var() globalconfig string Host;
var() globalconfig string ApiKey;

var PlayerController Requester;
var string PlayerGuid, Handle, DiscordId, DiscordName;
var BTClient_ClientReplication.sDiscordProfile Profile;
var bool bAuthenticated;
var private bool bApproved, bBusy, bEnding;
var private string Action;
var private string LoginTicket;
var private bool bKeepLoginTicket;
var private bool bCopyCode;
var private string LinkCode;
var private float RequestStarted, NextPoll, ExpiresAt, LastVerified;
var private HttpSock Sock;
var private string ConnectionStage;
var private string ResponseLine;
var private bool bHasResponse;

private final function Message(string text)
{
    class'BTDiscordUtils'.static.SendMessage(MutBestTimes(Owner), Requester, text);
}

private final function UpdateAccountUI(byte state, string text, optional string code)
{
    local BTClient_ClientReplication rep;

    rep = MutBestTimes(Owner).GetRep(Requester);
    if (rep != none)
        rep.ClientDiscordLinkState(state, text, code, Max(0, int(ExpiresAt - Level.TimeSeconds)));
}

private final function bool ReadProfile(array<string> fields, int start)
{
    if (fields.Length != start + 5 || !IsDigits(fields[start])
        || Len(fields[start]) < 15 || Len(fields[start]) > 22
        || !IsDigits(fields[start+4]) || Len(fields[start+4]) > 10)
        return false;

    Profile.UserId = fields[start];
    Profile.Username = Left(fields[start+1], 32);
    Profile.DisplayName = Left(fields[start+2], 32);
    Profile.AvatarHash = Left(fields[start+3], 34);
    Profile.LinkedAt = int(fields[start+4]);
    DiscordId = Profile.UserId;
    DiscordName = Profile.Username;

    return true;
}

private final function Authenticated(optional bool shouldAnnounce)
{
    bApproved = true;
    bAuthenticated = true;
    LastVerified = Level.TimeSeconds;
    LinkCode = "";

    class'BTDiscordUtils'.static.SetProfile(MutBestTimes(Owner), Requester, Profile);
    UpdateAccountUI(4, "Linked to " $ Profile.DisplayName $ " (@" $ Profile.Username $ ").");

    if (shouldAnnounce)
        ShowStatus();
}

static final function bool IsHex(string value, int size)
{
    local int i;

    if (Len(value) != size)
        return false;

    for (i = 0; i < Len(value); ++i)
        if (InStr("0123456789ABCDEF", Caps(Mid(value, i, 1))) == -1)
            return false;

    return true;
}

static final function bool IsDigits(string value)
{
    local int i;

    if (value == "")
        return false;

    for (i = 0; i < Len(value); ++i)
        if (InStr("0123456789", Mid(value, i, 1)) == -1)
            return false;

    return true;
}

static final function bool IsConfigured()
{
    local string port;

    port = Mid(default.Host, 17);

    return default.bEnabled
        && IsHex(default.ApiKey, 64)
        && Left(default.Host, 17) == "http://127.0.0.1:"
        && IsDigits(port)
        && int(port) >= 1 && int(port) <= 65535;
}

final function Begin(PlayerController player, optional string ticket, optional bool shouldRestore, optional bool isGUIRequest)
{
    Requester = player;
    bCopyCode = !isGUIRequest;
    PlayerGuid = player.GetPlayerIDHash();

    if (!IsConfigured())
    {
        Fail("Discord authentication is not configured. Ask the server administrator.");
        return;
    }
    if (!IsHex(PlayerGuid, 32))
    {
        Fail("Your player GUID is not ready. Try again after joining.");
        return;
    }

    ExpiresAt = Level.TimeSeconds + 180.0;
    SetTimer(1.0, true);
    UpdateAccountUI(1, "Waiting for the Discord bot...");

    if (ticket != "")
    {
        if (!IsHex(ticket, 48))
        {
            Fail("Invalid Discord login link. Run mutate discordlink again.");
            return;
        }

        LoginTicket = ticket;
        Message("Discord: authenticating your join link...");
        SendRequest("redeem");
    }
    else if (shouldRestore)
        SendRequest("restore");
    else
    {
        Message("Discord: requesting a code from the local bot...");
        SendRequest("challenge");
    }
}

final function bool IsAuthenticated()
{
    return bAuthenticated && Requester != none && !Requester.bDeleteMe
        && Requester.GetPlayerIDHash() == PlayerGuid
        && Level.TimeSeconds - LastVerified < 30.0;
}

final function bool IsEnding()
{
    return bEnding;
}

final function ShowStatus()
{
    if (IsAuthenticated())
        Message("Discord authenticated: " $ DiscordName $ " (" $ DiscordId $ ").");
    else if (bApproved)
        Message("Discord approved: " $ DiscordName $ " (" $ DiscordId $ "). Run mutate discordconfirm or mutate discordcancel.");
    else
        Message("Waiting for Discord approval. Use /link with your code in Discord, or mutate discordcancel.");
}

final function Confirm()
{
    if (bBusy)
        Message("Discord request in progress. Try again in a moment.");
    else if (IsAuthenticated())
        ShowStatus();
    else if (!bApproved)
        Message("Use /link with your code in Discord and wait for the approval message first.");
    else
        SendRequest("confirm");
}

final function Cancel(optional bool isDisconnecting)
{
    bAuthenticated = false;
    bEnding = true;
    bKeepLoginTicket = isDisconnecting;

    if (!isDisconnecting)
        UpdateAccountUI(0, "Link request cancelled. A saved account link can be removed using /unlink in Discord.");
    if (Handle != "")
        SendRequest("cancel");
    else
        Destroy();
}

private final function SendRequest(string operation)
{
    local string body;
    local BTClient_ClientReplication rep;

    if (Sock != none)
        Sock.Destroy();

    Sock = Spawn(class'HttpSock', self);
    if (Sock == none)
    {
        Fail("Discord authentication service unavailable.");
        return;
    }

    // Do not expose the API key to redirects, proxies, cookies, or verbose logs.
    Sock.iVerbose = 0;
    Sock.bUseProxy = false;
    Sock.bFollowRedirect = false;
    Sock.bSendCookies = false;
    Sock.bProcCookies = false;
    Sock.fConnectTimout = 5.0;
    Sock.OnComplete = OnComplete;
    Sock.OnError = OnError;
    Sock.OnConnectError = OnConnectError;
    Sock.OnConnectionTimeout = OnConnectionTimeout;
    Sock.OnResolveFailed = OnResolveFailed;
    Sock.OnPreConnect = OnPreConnect;
    Sock.OnReturnCode = OnReturnCode;
    Sock.OnResponseBody = OnResponseBody;
    Sock.AddHeader("Authorization", "Bearer " $ ApiKey);

    Action = operation;
    ResponseLine = "";
    bHasResponse = false;
    ConnectionStage = "resolving local bot address";

    body = "guid=" $ PlayerGuid;
    if (Handle != "")
        body $= "&handle=" $ Handle;
    if (operation == "redeem")
        body $= "&token=" $ LoginTicket;
    if (operation == "cancel" && bKeepLoginTicket)
        body $= "&keep_ticket=1";

    if (operation == "challenge")
    {
        rep = MutBestTimes(Owner).GetRep(Requester);
        if (rep != none && rep.DiscordServerAddress != "")
            body $= "&server_address=" $ class'HttpUtil'.static.RawUrlEncode(rep.DiscordServerAddress);
        else
            body $= "&server_address=" $ class'HttpUtil'.static.RawUrlEncode(Level.GetAddressURL());
    }

    bBusy = true;
    RequestStarted = Level.TimeSeconds;

    if (operation != "status")
        Log("Starting " $ operation $ " request to " $ Host, 'DiscordAuth');

    if (!Sock.Post(Host $ "/" $ operation, body))
        Fail("Discord authentication service unavailable.");
}

function OnComplete(HttpSock sender)
{
    local string result;
    local array<string> fields;
    local BTClient_ClientReplication rep;

    if (!bBusy || sender != Sock)
        return;

    bBusy = false;
    if (Action != "status" || sender.LastStatus != 200)
        Log(Action $ " response: HTTP " $ sender.LastStatus, 'DiscordAuth');

    if (bEnding)
    {
        Destroy();
        return;
    }

    if (Requester == none || Requester.bDeleteMe || Requester.GetPlayerIDHash() != PlayerGuid)
    {
        Cancel(true);
        return;
    }

    if (bHasResponse)
        result = ResponseLine;
    else
        result = class'BTActivateKey'.static.FixReturnData(Sender);

    bHasResponse = false;
    Split(result, "|", fields);
    if (fields.Length < 1 || sender.LastStatus != 200)
    {
        if (sender.LastStatus == 401)
            Fail("Discord API key mismatch. Match ApiKey in MutBestTimes.ini to api_key in DiscordBot/config.json, then restart the server.");
        else if (fields.Length == 2 && fields[0] == "error")
            Fail(fields[1]);
        else
            Fail("Discord authentication service unavailable.");

        return;
    }

    if (Action == "challenge" && fields.Length == 4 && fields[0] == "created"
        && IsHex(fields[1], 48) && Len(fields[2]) == 10 && fields[3] == "180")
    {
        Handle = fields[1];
        ExpiresAt = Level.TimeSeconds + 180.0;
        LinkCode = fields[2];
        UpdateAccountUI(2, "Paste this command into Discord, then choose Confirm after approval.", LinkCode);
        rep = MutBestTimes(Owner).GetRep(Requester);
        if (rep != none && bCopyCode)
        {
            rep.ClientCopyDiscordCommand("/link code:" $ fields[2]);
            Message("Copied to clipboard: /link code:" $ fields[2] $ ". Paste into Discord within 3 minutes. Keep this code private.");
        }
        else
            Message("Enter /link code:" $ fields[2] $ " in Discord within 3 minutes. Keep this code private.");
    }
    else if (Action == "status" && fields.Length == 1 && fields[0] == "pending" && !bApproved && !bAuthenticated)
    {
        // Poll until the Discord user approves this connection's challenge.
    }
    else if (fields.Length == 1 && fields[0] == "unlinked" && (Action == "restore" || Action == "status"))
    {
        class'BTDiscordUtils'.static.ClearProfile(MutBestTimes(Owner), Requester, true);
        UpdateAccountUI(0, "Discord account not linked. Choose Link Discord to start.");
        if (bAuthenticated)
            Message("Your Discord account link has been removed.");

        Destroy();

        return;
    }
    else if (Action == "status" && fields.Length == 6 && fields[0] == "approved" && !bAuthenticated)
    {
        if (bApproved && DiscordId != fields[1])
        {
            Fail("Discord approval changed. Start a new authentication request.");
            return;
        }

        if (!ReadProfile(fields, 1))
        {
            Fail("Invalid Discord profile response.");
            return;
        }

        if (!bApproved)
        {
            DiscordId = fields[1];
            DiscordName = fields[2];
            bApproved = true;

            UpdateAccountUI(3, "Approved: " $ Profile.DisplayName $ " (@" $ Profile.Username $ "). Choose Confirm to finish.");
            ShowStatus();
        }
    }
    else if ((Action == "redeem" || Action == "restore") && fields.Length == 7
        && fields[0] == "authenticated" && IsHex(fields[1], 48))
    {
        if (!ReadProfile(fields, 2))
        {
            Fail("Invalid Discord profile response.");
            return;
        }

        LoginTicket = "";
        Handle = fields[1];
        Authenticated(true);
    }
    else if (fields.Length == 6 && fields[0] == "authenticated"
        && (Action == "confirm" || (Action == "status" && bAuthenticated))
        && bApproved && fields[1] == DiscordId)
    {
        if (!ReadProfile(fields, 1))
        {
            Fail("Invalid Discord profile response.");
            return;
        }

        Authenticated(Action == "confirm");
    }
    else
    {
        Fail("Unexpected Discord authentication response. Start a new request.");
        return;
    }

    if (bAuthenticated)
        NextPoll = Level.TimeSeconds + 15.0;
    else
        NextPoll = Level.TimeSeconds + 3.0;
}

function OnError(HttpSock sender, string errorMessage, optional string param1, optional string param2)
{
    Fail("Discord authentication service unavailable. Run mutate discordlink to retry.");
}

function OnPreConnect(HttpSock sender)
{
    ConnectionStage = "connecting to local bot";
}

function OnReturnCode(HttpSock sender, int returnCode, string returnMessage, string httpVer)
{
    ConnectionStage = "reading local bot response";
}

function bool OnResponseBody(HttpSock sender, string line)
{
    // Do not destroy a socket inside its receive callback. Process the complete line on the next timer tick.
    if (bBusy && sender == Sock && !bHasResponse && line != "")
    {
        ResponseLine = line;
        bHasResponse = true;
    }

    return false;
}

function OnConnectError(HttpSock sender)
{
    Fail("Cannot connect to the Discord bot at " $ Host $ ". Start DiscordBot/bot.py on the game server machine.");
}

function OnConnectionTimeout(HttpSock sender)
{
    OnConnectError(sender);
}

function OnResolveFailed(HttpSock sender, string hostName)
{
    Fail("Cannot resolve the local Discord bot address.");
}

private final function Fail(string message)
{
    bAuthenticated = false;
    Log(message, 'DiscordAuth');

    if (!bEnding && Requester != none && !Requester.bDeleteMe)
    {
        UpdateAccountUI(5, message);
        class'BTDiscordUtils'.static.SendMessage(MutBestTimes(Owner), Requester, Message);
    }

    Destroy();
}

event Timer()
{
    if (bEnding)
    {
        if (Level.TimeSeconds - RequestStarted > 10.0)
            Destroy();

        return;
    }

    if (Requester == none ||
        Requester.bDeleteMe ||
        Requester.GetPlayerIDHash() != PlayerGuid)
    {
        Cancel(true);
        return;
    }

    if (bBusy)
    {
        if (bHasResponse)
        {
            OnComplete(Sock);
            return;
        }

        if (Level.TimeSeconds - RequestStarted > 10.0)
            Fail("Discord authentication timed out while " $ ConnectionStage $ ". Run mutate discordlink to retry.");

        return;
    }

    if (!bAuthenticated && Level.TimeSeconds >= ExpiresAt)
    {
        Fail("Discord authentication expired. Run mutate discordlink for a new code.");
        return;
    }

    if (Handle != "" && Level.TimeSeconds >= NextPoll)
        SendRequest("status");
}

event Destroyed()
{
    local BTDiscordAuth auth;

    bAuthenticated = false;
    if (Requester != none && !Requester.bDeleteMe)
    {
        auth = class'BTDiscordUtils'.static.FindAuth(MutBestTimes(Owner), Requester);
        if (auth == none || auth == self)
            class'BTDiscordUtils'.static.ClearProfile(MutBestTimes(Owner), Requester);
    }

    if (Sock != none)
        Sock.Destroy();

    super.Destroyed();
}

defaultproperties
{
    bEnabled=false
    bNotifyRecords=true
    Host="http://127.0.0.1:8765"
    RemoteRole=ROLE_None
}
