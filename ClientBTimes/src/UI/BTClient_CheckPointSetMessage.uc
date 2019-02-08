class BTClient_CheckPointSetMessage extends CriticalEventPlus;

#exec audio import file="content/checkpoint.WAV" name="CheckPoint" group="Sounds"

var() const localized string ReceiveString;
var() const Sound ReceiveSound;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return default.ReceiveString;
}

static simulated function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	if( RelatedPRI_1 != P.PlayerReplicationInfo )
		return;

	super.ClientReceive( P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
	P.ClientPlaySound( default.ReceiveSound, true, 2.0, SLOT_Talk );
}

defaultproperties
{
	ReceiveString="Checkpoint!"
	ReceiveSound=Sound'Sounds.CheckPoint'

	// DrawColor=(R=173,G=216,B=230)
	PosY=0.43
}