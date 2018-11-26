class BTRecordsDataManager extends Info;

var const noexport string RecordsDataFileName;

var private BTServer_RecordsData RDat;
var private MutBestTimes BT;

final function BTServer_RecordsData Init()
{
    BT = MutBestTimes(Owner);
    RDat = Level.Game.LoadDataObject( class'BTServer_RecordsData', RecordsDataFileName, RecordsDataFileName );
    if( RDat == none )
    {
        RDat = Level.Game.CreateDataObject( class'BTServer_RecordsData', RecordsDataFileName, RecordsDataFileName );
    }
    RDat.Init( BT );
    return RDat;
}

final function Save()
{
    if( RDat != None )
    {
        Level.Game.SavePackage( RecordsDataFileName );
    }
}

defaultproperties
{
    RecordsDataFileName="BestTimes_RecordsData"
}