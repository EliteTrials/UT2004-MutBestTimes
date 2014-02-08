//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTServer_GroupMode extends BTServer_SoloMode;

static function bool DetectMode( MutBestTimes M )
{
    return super.DetectMode( M ) && (M.GroupManager != none || IsGroup( M.CurrentMapName ));
}

static function bool IsGroup( string mapName )
{
    return Left( Mid( mapName, 3 ), 5 ) ~= default.ModeName || Left( mapName, 3 ) ~= default.ModePrefix;
}

protected function InitializeMode()
{
    super.InitializeMode();
    foreach DynamicActors( Class'GroupManager', GroupManager )
        break;

    bGroupMap = true;
}

function bool ChatCommandExecuted( PlayerController sender, string command, string value )
{
    local bool bmissed;

    switch( command )
    {
        case "group":
            if( value == "" )
            {
                sender.ConsoleCommand("mutate leavegroup");
            }
            else
            {
                sender.ConsoleCommand("mutate joingroup" @ value);
            }
            break;

        case "countdown":
            sender.ConsoleCommand("mutate GroupCountDown" @ value);
            break;

        default:
            bmissed = true;
            break;
    }

    if( !bmissed )
        return true;

    return super.ChatCommandExecuted( sender, command, value );
}

// Yet to implement.
/*function FinalObjectiveCompleted( PlayerController PC )
{
    local BTClient_ClientReplication CR;
    local int i;
    local array<Controller> GroupMembers;

    CR = GetRep( PC );
    if( CR == None )
    {
        FullLog( "No ClientReplicationInfo found for player" @ PC.GetHumanReadableName() );
        return;
    }

    CurrentPlaySeconds = GetFixedTime( Level.TimeSeconds - CR.LastSpawnTime );
    GetGroupMembersByController( PC, GroupMembers );
    for( i = 0; i < GroupMembers.Length; ++ i )
    {
        if( GroupMembers[i] != PC )
        {
            super.FinalObjectiveCompleted( PlayerController(GroupMembers[i]) );
        }
    }
    super.FinalObjectiveCompleted( PC );
}*/

defaultproperties
{
    ModeName="Group"
    ModePrefix="GTR"

    ExperienceBonus=20
    DropChanceBonus=0.5
}
