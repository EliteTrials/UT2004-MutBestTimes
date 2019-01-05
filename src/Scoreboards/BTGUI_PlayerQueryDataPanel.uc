class BTGUI_PlayerQueryDataPanel extends BTGUI_QueryDataPanel;

var automated GUIButton ViewRankedRecordsButton;
var private string PlayerId;

function ApplyData( BTQueryDataReplicationInfo queryRI )
{
	local BTPlayerProfileReplicationInfo myRI;

    super.ApplyData( queryRI );
	myRI = BTPlayerProfileReplicationInfo(queryRI);
    PlayerId = myRI.PlayerId;
    ViewRankedRecordsButton.DisableMe();
}

function bool InternalOnClick( GUIComponent sender )
{
    switch( sender )
    {
        case ViewRankedRecordsButton:
            // OnQueryRequest( "player:"$PlayerId );
            return true;
    }
    return false;
}

defaultproperties
{
    DataRows(0)=(Caption="First Played On",Bind=RegisterDate,Format=F_Date)
    DataRows(1)=(Caption="Last Played On",Bind=LastPlayedDate,Format=F_Date)
    DataRows(2)=(Caption="Country",Bind=CountryCode)
    DataRows(3)=(Caption="Played Time",Bind=PlayTime,Format=F_Hours)
    DataRows(4)=(Caption="Ranked ELO",Bind=RankedELORating,Format=F_Numeric)
    DataRows(5)=(Caption="Ranked Stars",Bind=NumStars,Format=F_Numeric)
    DataRows(6)=(Caption="Ranked Records",Bind=NumRankedRecords,Format=F_Numeric)
    DataRows(7)=(Caption="Total Records",Bind=NumRecords,Format=F_Numeric)
    DataRows(8)=(Caption="Objectives Completed",Bind=NumObjectives,Format=F_Numeric)
    DataRows(9)=(Caption="Rounds Played",Bind=NumRounds,Format=F_Numeric)
    DataRows(10)=(Caption="Records Hijacked",Bind=NumHijacks,Format=F_Numeric)
    DataRows(11)=(Caption="Map Completions",Bind=NumFinishes,Format=F_Numeric)
    DataRows(12)=(Caption="Achievement Points",Bind=AchievementPoints)

    begin object class=GUIButton name=oViewRankedRecordsButton
        WinTop=0.9
        WinHeight=0.09
        WinWidth=0.48
        WinLeft=0.01
        FontScale=FNS_Small
        StyleName="BTButton"
        Caption="View Ranked Records"
        OnClick=InternalOnClick
    end object
    ViewRankedRecordsButton=oViewRankedRecordsButton
}