Class SMovDat extends Object
    PerObjectConfig
    Config(BTMoveData);

var config float LoginTime;
var config array<BTServer_GhostData.sMovesDataType> MO;
var config string PlID;
var config bool bHasStoredData;
var config int UsedGhostFPS;

Static function SMovDat CreateMapData( string MapName )
{
    Return new(None,MapName) Default.Class;
}

function ClearMapData()
{
    MO.Length = 0;
    PLID = "";
    LoginTime = 0;
    bHasStoredData = False;
    UsedGhostFPS = 0;
    SaveConfig();
}
