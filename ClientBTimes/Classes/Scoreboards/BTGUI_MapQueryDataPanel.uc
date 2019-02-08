class BTGUI_MapQueryDataPanel extends BTGUI_QueryDataPanel;

defaultproperties
{
    DataRows(0)=(Caption="First Played On",Bind=RegisterDate,Format=F_Date)
    DataRows(1)=(Caption="Last Played On",Bind=LastPlayedDate,Format=F_Date)
    DataRows(2)=(Caption="Is Ranked",Bind=bIsRanked,Format=F_Bool)
    DataRows(3)=(Caption="Is Available",Bind=bMapIsActive,Format=F_Bool)
    DataRows(4)=(Caption="Rating",Bind=Rating)
    DataRows(5)=(Caption="Mean Record Time",Bind=AverageRecordTime,Format=F_Time)
    DataRows(6)=(Caption="Played Time",Bind=PlayHours,Format=F_Hours)
    DataRows(7)=(Caption="Completed",Bind=CompletedCount,Format=F_Numeric)
    DataRows(8)=(Caption="Hijacked",Bind=HijackedCount,Format=F_Numeric)
    DataRows(9)=(Caption="Fails",Bind=FailedCount,Format=F_Numeric)
}