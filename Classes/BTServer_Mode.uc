//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_Mode extends Object within MutBestTimes
    config(MutBestTimes)
    abstract
    hidedropdown;

/** The human friendly name for this mode. */
var editconst const noexport string ModeName;

/** The Server-MapName state mapprefix to use for this mode. */
var editconst const noexport string ModePrefix;

// TODO: Move to config?
var() const int ExperienceBonus;
var() const float DropChanceBonus;
var() const class<BTServer_ModeConfig> ConfigClass;

var() private const globalconfig array<struct sChatMacro{
    var string Name;
    var string Command;
    var string Prot;
    var string Value;
}> ChatMacros;

function Free()
{
}

static function bool DetectMode( MutBestTimes M )
{
    return False;
}

protected function InitializeMode()
{
}

function ModePostBeginPlay()
{
}

function ModeMatchStarting()
{
}

function ModeReset()
{
}

function ModeModifyPlayer( Pawn other, Controller c, BTClient_ClientReplication CRI )
{
}

function ModePlayerKilled( Controller player )
{

}

function PreRestartRound()
{

}

function PostRestartRound()
{

}

/**
 * Called when a player sets a new best or persoanl record.
 * @rankUps not implemented!
 */
function PlayerMadeRecord( PlayerController player, int rankSlot, int rankUps )
{

}

function PlayerCompletedMap( PlayerController player, int playerSlot, float playSeconds )
{
    local name achievementID;

    if( AchievementsManager.TestMap( Level.Title, playSeconds, achievementID ) )
    {
        PDat.ProgressAchievementByID( playerSlot, achievementID );
    }
}

function PlayerCompletedObjective( PlayerController player, BTClient_ClientReplication LRI, float score )
{

}

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
    local string S, Color;

    if( InStr( ServerState.MapName, "AS-" ) != -1 )
    {
        // Catch color.
        Color = Left( ServerState.MapName, InStr( ServerState.MapName, "AS-" ) );
        // MapName without prefix.
        S = Mid( ServerState.MapName, InStr( ServerState.MapName, "-" ) );

        ServerState.MapName = Color $ ModePrefix $ S;
    }
}

function bool ChatCommandExecuted( PlayerController sender, string command, string value )
{
    local bool bmissed;

    switch( command )
    {
        case "like":
            InternalOnMapLike( sender );
            break;

        case "dislike":
            InternalOnMapDislike( sender );
            break;

        case "vote":
            if( VotingReplicationInfo(sender.VoteReplicationInfo) == none || !sender.VoteReplicationInfo.MapVoteEnabled() )
            {
                SendErrorMessage( sender, "Sorry voting is not possible at the moment!" );
                break;
            }

            if( value == "" )
            {
                VotingReplicationInfo(sender.VoteReplicationInfo).OpenWindow();
            }
            else
            {
                if( int(value) > 0 || value == "0" )
                {
                    ChatCommandExecuted( sender, "votemapseq", value );
                }
                else
                {
                    ChatCommandExecuted( sender, "votemap", value );
                }
            }
            break;

        case "revote":
            Mutate( "votemap" @ CurrentMapName, sender );
            break;

        case "votemap":
            Mutate( "votemap" @ value, sender );
            break;

        case "votemapseq":
            Mutate( "votemapseq" @ value, sender );
            break;

        case "spec":
            if( !sender.PlayerReplicationInfo.bOnlySpectator )
                sender.BecomeSpectator();
            break;

        case "join":
            if( sender.PlayerReplicationInfo.bOnlySpectator )
                sender.BecomeActivePlayer();
            break;

        case "title":
            sender.ConsoleCommand( "mutate SetTitle" @ value );
            break;

        case "exec":
            if( value == "" )
            {
                SendErrorMessage( sender, "Please specify a console command!" );
                break;
            }
            sender.ConsoleCommand( value );
            break;

        case "prot":
            if( value == "" )
            {
                SendErrorMessage( sender, "Please specify a protocol and value, for example: \"xfire:status?text=UT2004!\"" );
                break;
            }
            sender.ClientTravel( value, TRAVEL_Absolute, false );
            sender.ClientMessage( "Performed protocol: " $ value );
            break;

        default:
            bmissed = !ChatMacroCommandExecuted( sender, command, value );
            break;
    }

    if( !bmissed )
    {
        return true;
    }
    return false;
}

function bool ChatMacroCommandExecuted( PlayerController sender, string command, string input )
{
    local int i;
    local string s;

    for( i = 0; i < ChatMacros.Length; ++ i )
    {
        if( ChatMacros[i].Name ~= command )
        {
            if( ChatMacros[i].Prot != "" )
            {
                s = ChatMacros[i].Prot $ "://";
            }
            ChatCommandExecuted( sender, ChatMacros[i].Command, s$Repl( ChatMacros[i].Value, "%Input%", input ) );
            return true;
        }
    }
    return false;
}

private function InternalOnMapLike( PlayerController player )
{
    local BTClient_ClientReplication CRI;

    CRI = GetRep( player );
    if( RDat.PlayerLikeMap( UsedSlot, CRI.myPlayerSlot ) )
    {
        SendSucceedMessage( player, "You have liked this map! New map rating:" @ RDat.GetMapRating( UsedSlot ) );
    }
}

private function InternalOnMapDislike( PlayerController player )
{
    local BTClient_ClientReplication CRI;

    CRI = GetRep( player );
    if( RDat.PlayerDislikeMap( UsedSlot, CRI.myPlayerSlot ) )
    {
        SendSucceedMessage( player, "You have disliked this map! New map rating:" @ RDat.GetMapRating( UsedSlot ) );
    }
}

function bool ClientExecuted( PlayerController sender, string command, optional array<string> params )
{
    return false;
}

function bool AdminExecuted( PlayerController sender, string command, optional array<string> params )
{
    return false;
}

function FinalObjectiveCompleted( PlayerController PC )
{
}

final static function BTServer_Mode NewInstance( MutBestTimes M )
{
    local BTServer_Mode Mode;

    Mode = new(M) default.class;
    //Mode = M.Spawn( default.class, M );
    //Mode.Master = M;
    Mode.InitializeMode();
    return Mode;
}

function bool CanSetClientSpawn( optional PlayerController player )
{
    return ConfigClass.default.bAllowClientSpawn;
}

defaultproperties
{
    ConfigClass=class'BTServer_ModeConfig'

    ExperienceBonus=0

    // ChatMacros(0)=(Name="ts",Command="prot",Prot="TeamSpeak",Value="212.187.247.41:9103")
    // ChatMacros(1)=(Name="xfirestatus",Command="prot",Value="xfire:status?text=%Input%")
    ChatMacros(0)=(Name="donate",Command="prot",Prot="http",Value="www.paypal.com/cgi-bin/webscr?cmd=_donations&business=9KT3RZU8569N6&lc=BE&item_name=%Input%&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted")
}
