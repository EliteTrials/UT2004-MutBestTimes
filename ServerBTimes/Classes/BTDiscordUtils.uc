// Server-side Discord integration. Static entry points keep gameplay hooks small.
// Connection state and HTTP requests remain in their dedicated actors.
class BTDiscordUtils extends Object;

static final function SendMessage(MutBestTimes mutator, PlayerController player, string message)
{
    local BTClient_ClientReplication rep;

    if (mutator == none || player == none || player.bDeleteMe)
        return;

    rep = mutator.GetRep(player);
    if (rep != none)
        rep.ClientSendMessage(class'BTClient_LocalMessage', message);
    else
        player.ClientMessage(message, 'CriticalEvent');
}

static final function OnLogin(MutBestTimes mutator, PlayerController player, string ticket)
{
    local BTDiscordAuth auth;

    if (mutator == none || !class'BTDiscordAuth'.default.bEnabled || player == none || player.bDeleteMe)
        return;

    if ((ticket != "" && !class'BTDiscordAuth'.static.IsHex(ticket, 48)) || FindAuth(Mutator, player) != none)
        return;

    auth = mutator.Spawn(class'BTDiscordAuth', mutator);
    if (auth != none)
        auth.Begin(player, ticket, ticket == "");
}

static final function SetProfile(MutBestTimes mutator, PlayerController player, BTClient_ClientReplication.sDiscordProfile profile)
{
    local BTClient_ClientReplication rep;

    if (mutator == none || player == none || player.bDeleteMe)
        return;

    if (mutator.PDat.SetDiscordAccount(player.GetPlayerIDHash(), profile))
        mutator.SavePlayers();

    rep = mutator.GetRep(player);
    if (rep != none)
    {
        rep.DiscordProfile = profile;
        rep.bDiscordAuthenticated = true;
        rep.NetUpdateTime = mutator.Level.TimeSeconds - 1;
    }
}

static final function ClearProfile(MutBestTimes mutator, PlayerController player, optional bool isUnlinked)
{
    local BTClient_ClientReplication rep;
    local BTClient_ClientReplication.sDiscordProfile emptyProfile;

    if (mutator == none || player == none || player.bDeleteMe)
        return;

    if (isUnlinked && mutator.PDat.RemoveDiscordAccount(player.GetPlayerIDHash()))
        mutator.SavePlayers();

    rep = mutator.GetRep(player);
    if (rep != none)
    {
        rep.bDiscordAuthenticated = false;

        if (isUnlinked)
            rep.DiscordProfile = emptyProfile;

        rep.NetUpdateTime = mutator.Level.TimeSeconds - 1;
    }
}

static final function BTDiscordAuth FindAuth(MutBestTimes mutator, PlayerController player)
{
    local BTDiscordAuth auth;

    if (mutator == none || player == none)
        return none;

    foreach mutator.DynamicActors(class'BTDiscordAuth', auth)
        if (auth.Owner == mutator && auth.Requester == player && !auth.bDeleteMe && !auth.IsEnding())
            return auth;

    return none;
}

// A saved GUID/account link does not authenticate a new connection.
static final function bool IsAuthenticated(MutBestTimes mutator, PlayerController player)
{
    local BTDiscordAuth auth;

    auth = FindAuth(mutator, player);
    return auth != none && auth.IsAuthenticated();
}

static final function string GetUserId(MutBestTimes mutator, PlayerController player)
{
    local BTDiscordAuth auth;

    auth = FindAuth(mutator, player);
    if (auth != none && auth.IsAuthenticated())
        return auth.DiscordId;

    return "";
}

// True means the command belongs to Discord and has been handled.
static final function bool HandleMutate(MutBestTimes mutator, string cmd, PlayerController sender)
{
    local BTDiscordAuth auth;

    if (mutator == none || sender == none)
        return false;

    if (!(cmd ~= "discordlink" || cmd ~= "discordlinkui" || cmd ~= "discordconfirm"
        || cmd ~= "discordcancel" || cmd ~= "discordstatus"))
        return false;

    if (!class'BTDiscordAuth'.default.bEnabled)
    {
        SendMessage(Mutator, Sender, "Discord authentication is disabled on this server.");
        return true;
    }

    auth = FindAuth(mutator, sender);
    if (cmd ~= "discordlink" || cmd ~= "discordlinkui")
    {
        if (auth != none)
        {
            auth.ShowStatus();
            SendMessage(mutator, sender, "Run mutate discordcancel before requesting another code.");
        }
        else
        {
            auth = mutator.Spawn(class'BTDiscordAuth', Mutator);
            if (auth != none)
                auth.Begin(sender, "", false, cmd ~= "discordlinkui");
        }
    }
    else if (auth == none)
        SendMessage(mutator, sender, "No Discord authentication session. Run mutate discordlink first.");
    else if (cmd ~= "discordconfirm")
        auth.Confirm();
    else if (cmd ~= "discordcancel")
    {
        auth.Cancel();
        SendMessage(mutator, sender, "Discord authentication cancelled for this connection.");
    }
    else auth.ShowStatus();

    return true;
}

static final function NotifyLogout(MutBestTimes mutator, PlayerController player)
{
    local BTDiscordAuth auth;

    auth = FindAuth(mutator, player);
    if (auth != none)
        auth.Cancel(true);
}

static final function InitReplication(MutBestTimes mutator, PlayerController player, BTClient_ClientReplication rep)
{
    local int slot;

    if (mutator == none || player == none || rep == none)
        return;

    rep.bDiscordAvailable = class'BTDiscordAuth'.default.bEnabled;
    if (rep.bDiscordAvailable)
    {
        slot = mutator.PDat.FindDiscordAccount(player.GetPlayerIDHash());
        if (slot != -1)
            rep.DiscordProfile = mutator.PDat.DiscordAccounts[slot].Profile;

        rep.ClientReadDiscordLogin();
    }
}

// Capture before record insertion/reordering, including disconnected holders.
static final function GetPreviousRecordOwner(
    BTServer_PlayersData players,
    BTServer_RecordsData records,
    int mapIndex,
    out string guid, out float time)
{
    local int slot;

    guid = "";
    time = 0;

    if (players == none || records == none || mapIndex < 0 || mapIndex >= records.Rec.Length
        || records.Rec[mapIndex].PSRL.Length == 0)
        return;

    slot = records.Rec[mapIndex].PSRL[0].PLs - 1;
    if (slot >= 0 && slot < players.Player.Length)
        guid = players.Player[slot].PLID;

    time = class'MutBestTimes'.static.GetFixedTime(Records.Rec[MapIndex].PSRL[0].SRT);
}

static final function NotifyRecord(MutBestTimes mutator, PlayerController player, int mapIndex, int recordIndex,
    float newTime, float previousTime, string previousOwnerGuid, float previousTopTime)
{
    local string body, guid, eventId;
    local BTDiscordRecordNotifier request;

    if (mutator == none || !class'BTDiscordAuth'.default.bNotifyRecords || !class'BTDiscordAuth'.static.IsConfigured()
        || Player == none || Player.bDeleteMe)
        return;

    guid = player.GetPlayerIDHash();

    // Stable for retries, distinct for each accepted update and player.
    eventId = guid $ ":"
        $ mutator.Level.Year $ "-"
        $ mutator.Level.Month $ "-"
        $ mutator.Level.Day
        $ ":" $ mutator.Level.TimeSeconds
        $ ":" $ mapIndex
        $ ":" $ newTime;

    body = "&map=" $ class'HttpUtil'.static.RawUrlEncode(mutator.RDat.Rec[mapIndex].TMN)
        $ "&player=" $ class'HttpUtil'.static.RawUrlEncode(Left(mutator.Level.Game.StripColor(player.GetHumanReadableName()), 64))
        $ "&server=" $ class'HttpUtil'.static.RawUrlEncode(Left(mutator.Level.Game.StripColor(mutator.Level.Game.GameReplicationInfo.ServerName), 128))
        $ "&mode=" $ class'HttpUtil'.static.RawUrlEncode(mutator.CurMode.ModeName)
        $ "&time=" $ newTime
        $ "&rank=" $ (recordIndex + 1) $ "&total=" $ mutator.RDat.Rec[mapIndex].PSRL.Length
        $ "&checkpoint=" $ int((mutator.RDat.Rec[mapIndex].PSRL[recordIndex].Flags & 0x01) != 0);

    // The bot independently selects private DMs and channel posts.
    request = mutator.Spawn(class'BTDiscordRecordNotifier', Mutator);
    if (request != none) {
        request.Begin("guid=" $ guid
            $ "&event_id=" $ class'HttpUtil'.static.RawUrlEncode(eventId)
            $ "&previous_time=" $ previousTime $ body
        );
    }

    if (recordIndex == 0 && previousTopTime > newTime && previousOwnerGuid != "" && previousOwnerGuid != guid
        && mutator.PDat.FindDiscordAccount(previousOwnerGuid) != -1)
    {
        request = mutator.Spawn(class'BTDiscordRecordNotifier', Mutator);
        if (request != none) {
            request.Begin("guid=" $ previousOwnerGuid
                $ "&event_id=" $ class'HttpUtil'.static.RawUrlEncode(eventId $ ":lost")
                $ "&kind=lost&setter_guid=" $ guid
                $ "&previous_time=" $ previousTopTime
                $ body
            );
        }
    }
}
