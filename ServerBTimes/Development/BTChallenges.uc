//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTChallenges extends Object
    config(BTChallenges);

struct sChallenge
{
    var() string Title;
    var() string Description;
    var() string ID;
    var() int Points;

    /** If accomplished then reward the store item(with this ItemID) */
    //var() string ItemID;

    /** If not "" then use this as the map completion logic. */
    //var() string LevelTitle;
};

var() globalconfig array<sChallenge> Challenges;
var() globalconfig sChallenge DailyChallenge;
var() globalconfig byte MaxDailyChallenges;

// DO NOT EDIT
var public globalconfig array<string> TodayChallenges;
var private globalconfig int ChallengesGeneratedTime;

/** Necessary to load up the challenges collection. */
final static function BTChallenges Load()
{
    return new(none) default.Class;
}

final function GenerateTodayChallenges( LevelInfo Level, BTServer_RecordsData RDat )
{
    local int i;

    if( Level.Day == ChallengesGeneratedTime )
    {
        return;
    }

    TodayChallenges.Length = 0;
    for( i = 0; i < MaxDailyChallenges; ++ i )
    {
        TodayChallenges.Insert( 0, 1 );
        TodayChallenges[0] = RDat.Rec[Rand( RDat.Rec.Length - 1 )].TMN;
    }
    ChallengesGeneratedTime = Level.Day;
    SaveConfig();
}

final function bool IsTodaysChallenge( string mapName )
{
    local int i;

    for( i = 0; i < TodayChallenges.Length; ++ i )
    {
        if( TodayChallenges[i] == mapName )
            return true;
    }
    return false;
}

final function sChallenge GetChallenge( string trophyID )
{
    local int i;

    for( i = 0; i < Challenges.Length; ++ i )
    {
        if( Challenges[i].ID ~= trophyID )
            return Challenges[i];
    }
    return DailyChallenge;
}

defaultproperties
{
    ChallengesGeneratedTime=-1

    DailyChallenge=(Title="%MAPNAME% Master",Description="Complete the map %MAPNAME%",ID="MAP_%MAPNAME%",Points=3)
    MaxDailyChallenges=10
}
