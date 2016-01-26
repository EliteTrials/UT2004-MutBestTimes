class BTServer_ModeConfig extends Info
    config(MutBestTimes);

var() config bool bAllowClientSpawn;
var() const string ConfigGroupName;

var array<BTStructs.sConfigProperty> ConfigProperties;

static function FillPlayInfo( PlayInfo info )
{
    local int i;
    local BTStructs.sConfigProperty prop;

    for( i = 0; i < default.ConfigProperties.Length; ++ i )
    {
        prop = default.ConfigProperties[i];
        if( prop.Category == "" )
        {
            prop.Category = default.ConfigGroupName;
        }

        if( prop.Type == "" )
        {
            switch( prop.Property.Class )
            {
                case class'BoolProperty':
                    prop.Type = "Check";
                    break;

                default:
                    prop.Type = "Text";
                    break;
            }
        }
        info.AddSetting(
            prop.Category,
            string(prop.Property.Name),
            prop.Description,
            prop.AccessLevel,
            prop.Weight,
            prop.Type,
            prop.Rules,
            prop.Privileges,
            prop.bMultiPlayerOnly,
            prop.bAdvanced
        );
    }
}

static function string GetDescriptionText( string propertyName )
{
    local int i;

    for( i = 0; i < default.ConfigProperties.Length; ++ i )
    {
        if( string(default.ConfigProperties[i].Property.Name) == propertyName )
        {
            if( default.ConfigProperties[i].Hint == "" )
            {
                return default.ConfigProperties[i].Description;
            }
            return default.ConfigProperties[i].Hint;
        }
    }
    return "";
}

defaultproperties
{
    bAllowClientSpawn=false
}