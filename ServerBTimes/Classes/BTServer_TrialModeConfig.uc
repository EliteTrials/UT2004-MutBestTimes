class BTServer_TrialModeConfig extends BTServer_ModeConfig;

defaultproperties
{
    ConfigProperties(0)=(Property=BoolProperty'bAllowClientSpawn',Description="Allow ClientSpawn Use",Weight=1,Hint="If Checked, players may use the !CP command to set a checkpoint.")
    ConfigProperties(1)=(Property=BoolProperty'bDisableWeaponBoosting',Description="Disable Weapon Boosting",AccessLevel=0,Weight=1,Hint="If checked, boosting will be disabled for all players.")
	ConfigGroupName="BestTimes - Trials"

    bAllowClientSpawn=true
    bDisableWeaponBoosting=false
}