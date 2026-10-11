class BTClient_DiscordLinkReplication extends LinkedReplicationInfo;

// Recorded on the server from the owning client's actual connection address.
var string DiscordServerAddress;
var private bool bDiscordURLChecked;
var private bool bDiscordLoginReceived;

struct sDiscordProfile
{
    var string UserId, Username, DisplayName, AvatarHash;
    var int LinkedAt; // UTC Unix timestamp of the original link.
};
var sDiscordProfile DiscordProfile;
var bool bDiscordAuthenticated;
var bool bDiscordAvailable;

// Private account UI state, delivered only through the owning connection.
// 0=unlinked, 1=requesting, 2=code ready, 3=approved, 4=authenticated, 5=error.
var byte DiscordLinkState;
var string DiscordLinkMessage, DiscordLinkCode;
var float DiscordCodeExpiresAt;

delegate OnDiscordLogin(PlayerController requester, string ticket);

replication
{
    reliable if (Role == ROLE_Authority)
        DiscordProfile, bDiscordAuthenticated;

    reliable if (bNetOwner && bNetInitial)
        bDiscordAvailable;

    // unreliable
    reliable if (Role == ROLE_Authority)
        ClientCopyDiscordCommand,
        ClientReadDiscordLogin,
        ClientDiscordLinkState;

    reliable if (Role < ROLE_Authority)
        ServerDiscordLogin;
}

simulated function ClientCopyDiscordCommand(string cmd)
{
    local PlayerController player;

    player = PlayerController(Owner);
    if (player != none && player == Level.GetLocalPlayerController())
        player.CopyToClipboard(cmd);
}

simulated function ClientDiscordLinkState(byte state, string message, optional string code, optional int seconds)
{
    DiscordLinkState = state;
    DiscordLinkMessage = message;
    DiscordLinkCode = code;
    DiscordCodeExpiresAt = Level.TimeSeconds + seconds;
}

simulated function ClientReadDiscordLogin()
{
    local PlayerController player;
    local string ticket, address;

    player = PlayerController(Owner);
    if (player == none || player != Level.GetLocalPlayerController() || bDiscordURLChecked)
        return;

    bDiscordURLChecked = true;
    ticket = player.GetUrlOption("BTDiscord=");

    address = player.GetServerNetworkAddress();
    if (address == "")
        address = Level.GetAddressURL();

    // Do not save or carry a consumed login token through subsequent travel.
    player.UpdateURL("BTDiscord", "", false);
    ServerDiscordLogin(ticket, address);
}

function ServerDiscordLogin(string Ticket, string Address)
{
    // RPC ownership supplies the requester; the client never chooses another PC.
    if (bDiscordLoginReceived)
        return;

    bDiscordLoginReceived = true;
    DiscordServerAddress = Address;
    OnDiscordLogin(PlayerController(Owner), Ticket);
}