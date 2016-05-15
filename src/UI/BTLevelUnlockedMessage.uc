class BTLevelUnlockedMessage extends CriticalEventPlus;

var() const string MessageString;

static function string GetString( optional int switch,
    optional PlayerReplicationInfo MessageReceiver, optional PlayerReplicationInfo MessageInstigator,
    optional Object unlockedLevel )
{
    local string s;

	s = Repl( default.MessageString, "%LEVEL%", BTClient_LevelReplication(unlockedLevel).GetLevelName() );
    if( MessageReceiver.Level.GetLocalPlayerController().PlayerReplicationInfo == MessageReceiver )
        return Repl( s, "%PLAYER%", "You have" );
    return Repl( s, "%PLAYER%", " has" @ class'BTClient_TrialScoreBoard'.static.GetCName(MessageInstigator) );
}

static simulated function ClientReceive(
    PlayerController P,
    optional int switch,
    optional PlayerReplicationInfo MessageReceiver,
    optional PlayerReplicationInfo MessageInstigator,
    optional Object unlockedLevel
    )
{
    local BTClient_Config options;

    super.ClientReceive( P, switch, MessageReceiver, MessageInstigator, unlockedLevel );
    options = class'BTClient_Config'.static.FindSavedData();
    if( !options.bPlayCompletingSounds )
    {
        return;
    }
    P.ClientPlaySound( Sound'GameSounds.Fanfares.UT2K3Fanfare04', true, 2.0, SLOT_Talk );
}

defaultproperties
{
    bIsUnique=false
	MessageString="%PLAYER% unlocked %LEVEL%!"
    DrawColor=(R=255,G=255,B=0,A=255)
    FontSize=-1

    StackMode=SM_Down
    PosY=0.342
    LifeTime=8
}