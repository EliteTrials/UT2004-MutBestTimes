//=============================================================================
// Copyright 2005-2010 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
Class BTServer_GlobalDataSocket Extends Info;

/*
#Exec obj load file="LibHTTP4.u" Package="ServerBTimes"

var config string GlobalHost, GlobalHostPW;

var BTServer_GlobalData GDat;

var int CurrentGlobalRecordIndex;

Function PostBeginPlay()
{
    local int i, j;
    local bool bFound;

    DownloadGlobalData();
    if( GDat != None )
    {
        j = GDat.GRL.Length;
        for( i = 0; i < j; i ++ )
        {
            if( GDat.GRL[i].GRN == MutBestTimes(Owner).CurrentMapName )
            {
                CurrentGlobalRecordIndex = i;
                bFound = True;
                break;
            }
        }
    }

    if( !bFound )
        CreateGlobalRecord();
}

// Called after download!
Function LoadGlobalData()
{
    GDat = Level.Game.LoadDataObject( Class'BTServer_GlobalData', "BestTimes_GlobalData", "BestTimes_GlobalData" );

    // No Global Data yet? create one and upload to the host!
    if( GDat == None )
    {
        GDat = Level.Game.CreateDataObject( Class'BTServer_GlobalData', "BestTimes_GlobalData", "BestTimes_GlobalData" );
        UploadGlobalData();
    }
}

Function SaveGlobalData()
{
    Level.Game.SavePackage( "BestTimes_GlobalData" );
    UploadGlobalData();
}

Function CreateGlobalRecord()
{
    local int j;

    MutBestTimes(Owner).FullLog( "GlobalData:CreateGlobalRecord" );

    j = GDat.GRL.Length;
    GDat.GRL.Length = j + 1;
    GDat.GRL[j].GRT = -1;
    GDat.GRL[j].GRN = MutBestTimes(Owner).CurrentMapName;
}

Function float GetGlobalRecordTime()
{
    return GDat.GRL[CurrentGlobalRecordIndex].GRT;
}

Function int GetGlobalRecordOwner( string Map )
{
    return GDat.GRL[CurrentGlobalRecordIndex].GRA;
}

Function SetGlobalRecord( float Time, string Owner )
{
    GDat.GRL[CurrentGlobalRecordIndex].GRT = Time;
    GDat.GRL[CurrentGlobalRecordIndex].GRA = Owner;
    SaveGlobalData();
}

// download GlobalData.uvx from the host
Function DownloadGlobalData()
{
    local HttpSock Socket;

    Socket = Spawn( Class'HttpSock' );
    Socket.OnComplete = DownloadComplete;
    Socket.OnError = DownloadError;
    Socket.SetFormData( "GlobalData", "Download" );
    Socket.SetFormData( "Pass", GlobalHostPW );
    Socket.Post( GlobalHost );
}

Function DownloadComplete( HttpSock Sender )
{
    if( Sender == None )
        return;

    MutBestTimes(Owner).FullLog( "GlobalData:DownloadComplete, Re-Loading GlobalData" );
    LoadGlobalData();
    Sender.Destroy();
}

Function DownloadError( HttSock Sender )
{
    if( Sender == None )
        return;

    MutBestTimes(Owner).FullLog( "GlobalData:DownloadError, Reason:Perhaps no GlobalData found!" );
    if( GDat == None )
        LoadGlobalData();
    Sender.Destroy();
}

// upload GlobalData.uvx to the host
Function UploadGlobalData()
{
    local HttpSock Socket;

    Socket = Spawn( Class'HttpSock' );
    Socket.OnComplete = UploadComplete;
    Socket.OnError = UploadError;
    Socket.SetFormData( "GlobalData", "Upload" );
    Socket.SetFormData( "Pass", GlobalHostPW );
    Socket.Post( GlobalHost );
}

Function UploadComplete( HttpSock Sender )
{
    if( Sender == None )
        return;

    MutBestTimes(Owner).FullLog( "GlobalData:UploadComplete" );
    Sender.Destroy();
}

Function UploadError( HttSock Sender )
{
    if( Sender == None )
        return;

    MutBestTimes(Owner).FullLog( "GlobalData:UploadError, Reason:Unknown" );
    Sender.Destroy();
}

DefaultProperties
{
}
*/
