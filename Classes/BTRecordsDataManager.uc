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

final function GetTopPlayerGhostIds( int mapIndex, out array<string> outIds )
{
    local int i;

    for( i = 0; i < Min(RDat.Rec[mapIndex].PSRL.Length, 3); ++ i )
    {
        if ((RDat.Rec[mapIndex].PSRL[i].Flags & 0x08/* RFLAG_GHOST */) != 0)
        {
            outIds[outIds.Length] = BT.PDat.Player[RDat.Rec[mapIndex].PSRL[i].PLs-1].PLID;
        }
    }
}

defaultproperties
{
    RecordsDataFileName="BestTimes_RecordsData"
}