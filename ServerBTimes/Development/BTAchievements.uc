//=============================================================================
// Copyright 2005-2011 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTAchievements extends Object
    config(BTAchievements);

/** A structure that defines an earnable achievement. */
struct sAchievement
{
    /** Title of the achievement e.g. "Recwhore" */
    var string Title;

    /** Identifiy of the achievement, used to identifiy which achievement an user has achieved.
        Changing this will make the players that have earned this achievement obsolete. */
    var name ID;

    /** The kind of achievement it is e.g. Record related? Deaths related?
        Used to automatic increment the earned Count of all <type> when that kind of <type> is progressed. */
    var name Type;

    /** Amount of <type> necessary to earn the achievement. */
    var int Count;

    /** Description explaining what to do to earn the achievement. */
    var string Description;

    /** Icon portraying the achievement. */
    var string Icon;

    /** Value of the achievement. */
    var int Points;
};

/** Collection of achievements that players are able to achieve. */
var() globalconfig array<sAchievement> Achievements;

var private int LastAchievementsCount;

struct sMapTest
{
    var string MapTitle;
    var float Time;
    var name Target;
    var bool bCount;
};
var() globalconfig array<sMapTest> MapTests;

/** Necessary to load up the achievements collection. */
final static function BTAchievements Load()
{
    // StaticSaveConfig();
    return new(none) default.Class;
}

final function int FindAchievementByTitle( string title )
{
    local int i;

    for( i = 0; i < Achievements.Length; ++ i )
    {
        if( Achievements[i].Title ~= title )
        {
            return i;
        }
    }
    return -1;
}

final function int FindAchievementByID( name id )
{
    local int i;

    for( i = 0; i < Achievements.Length; ++ i )
    {
        if( Achievements[i].ID == id )
        {
            return i;
        }
    }
    return -1;
}

// Note:Do not modify the struct because it is copied not passed!
final function sAchievement GetAchievementByID( name id )
{
    return Achievements[FindAchievementByID( id )];
}

final function int FindAchievementsByType( name type, out array<int> collection )
{
    local int i;

    for( i = 0; i < Achievements.Length; ++ i )
    {
        if( Achievements[i].Type == type )
        {
            collection.Insert( 0, 1 );
            collection[0] = i;
        }
    }
    return collection.Length;
}

final function bool TestMap( string title, float recordTime, out name target )
{
    local int i, asterik;

    for( i = 0; i < MapTests.Length; ++ i )
    {
        asterik = InStr( MapTests[i].MapTitle, "*" );
        if( MapTests[i].MapTitle ~= title || (asterik != -1 && Left( MapTests[i].MapTitle, asterik ) ~= Left( title, asterik )) )
        {
            target = MapTests[i].Target;
            return recordTime <= MapTests[i].Time || MapTests[i].Time == -1;
        }
    }
    return false;
}

defaultproperties
{
    // Record Count kinds
    Achievements(0)=(Title="Newbie Recwhorerer",ID=recwhore_0,Type=RecordsCount,Count=1,Description="Achieve one record",Points=1)
    Achievements(1)=(Title="Noob Recwhorerer",ID=recwhore_1,Type=RecordsCount,Count=5,Description="Achieve five records",Points=1)
    Achievements(2)=(Title="Experienced Recwhorerer",ID=recwhore_2,Type=RecordsCount,Count=20,Description="Achieve twenty records",Points=2)
    Achievements(3)=(Title="Hardcore Recwhorerer",ID=recwhore_3,Type=RecordsCount,Count=50,Description="Achieve fifty records",Points=2)
    Achievements(4)=(Title="Recwhorerer",ID=recwhore_4,Type=RecordsCount,Count=100,Description="Achieve a hundred records",Points=5)

    Achievements(5)=(Title="TechChallenge whorerer",ID=map_1,Count=50,Type=FinishTech,Description="Complete any TechChallenge map 50 times",Points=3)   // Done
    Achievements(6)=(Title="Fan of Eliot",ID=map_2,Description="Set a record on Eliot's of 4 minutes or less",Points=4)     // Done
    Achievements(7)=(Title="What's a Checkpoint?",ID=checkpoint_1,Type=CheckpointUses,Count=10,Description="Reach 10 Checkpoints",Points=1)     // Done
    Achievements(8)=(Title="Epic failer",ID=clientspawn_1,Description="Use a 'Client Spawn' by using 'SetClientSpawn'",Points=1)    // Done
    Achievements(9)=(Title="Jani maps hater",ID=jani_1,Description="Insult a jani's map while playing one",Points=1)    // Done
    Achievements(10)=(Title="Group lover",ID=mode_1,Description="Complete a Group map",Points=5)    // Done
    Achievements(11)=(Title="I like it Regular",ID=mode_2,Description="Complete a Regular map",Points=2) // Done
    Achievements(12)=(Title="ForeverAlone.jpg",ID=mode_3,Type=FinishSolo,Count=20,Description="Complete a Solo map 20 times",Points=1) // Done
    Achievements(13)=(Title="Newbie",ID=level_0,Type=LevelUp,Count=2,Description="Level up 2 times",Points=1)
    Achievements(14)=(Title="Noob",ID=level_2,Type=LevelUp,Count=8,Description="Level up 8 times",Points=2)
    Achievements(15)=(Title="Experienced",ID=level_3,Type=LevelUp,Count=20,Description="Level up 20 times",Points=5)
    Achievements(16)=(Title="Experience lover",ID=experience_0,Description="Earn 64 experience from one action",Points=2)
    Achievements(17)=(Title="I bought an Item!",ID=store_0,Description="Buy your first item from the Store",Points=1)
    // Achievements(18)=(Title="BTimes explorer",ID=store_1,Description="Find the Store",Points=1)
    Achievements(19)=(Title="Dedicated noob",ID=level_4,Description="Reach level 50",Points=10)
    Achievements(20)=(Title="Dedicated gamer",ID=level_5,Description="Reach level 100",Points=20)
    Achievements(21)=(Title="Server loveist",ID=playtime_0,Description="Play for over 10 hours on this server",Points=2)
    Achievements(22)=(Title="Map loveist",ID=finish_0,Type=Finish,Count=200,Description="Finish 200 times any trial map",Points=4)
    Achievements(23)=(Title="Lucky lucker",ID=tie_0,Type=Tied,Count=5,Description="Tie a record on a Solo map 5 times",Points=4)
    Achievements(24)=(Title="Ghoster",ID=ghost_0,Description="Get your first ghost",Points=2)
    Achievements(25)=(Title="I'm no muffin",ID=points_0,Description="Earn 20 points from one record",Points=2)
    Achievements(26)=(Title="Loner",ID=holiday_0,Description="Spawn on a 'Client Spawn' on a BTimes holiday",Points=1)
    Achievements(27)=(Title="Robin Hood",ID=records_0,Type=StealRecord,Count=50,Description="Steal 50 first place records not owned by you",Points=5)
    Achievements(28)=(Title="Who's bad?",ID=map_3,Description="Set a record on Blood On The Floor",Points=5)
    Achievements(29)=(Title="A prelude rusher",ID=map_4,Description="Set a record on EgyptianRush-Prelude of 5 minutes or less",Points=5)
    Achievements(30)=(Title="Classic lovelist",ID=map_5,Description="Set a record on a RoomTrials map of 4 minutes or less",Points=2)
    Achievements(31)=(Title="Dicky toucher(no homo)",ID=sirdicky,Description="Find dicky and touch him(no homo)",Points=1)
    Achievements(32)=(Title="Night whorerer",ID=mode_3_night,Description="Complete a Solo map at night",Points=1)
    Achievements(33)=(Title="Home sweet home",ID=playtime_1,Description="Play for over 1000 hours on this server",Points=2)
    Achievements(34)=(Title="Fan of Haydon",ID=quality_0,Type=FinishQuality,Count=10,Description="Finish 10 times a map that's designed by Eliot or Haydon",Points=1)
    Achievements(35)=(Title="Challenges master",ID=challenge_0,Type=FinishDailyChallenge,Count=25,Description="Earn 25 trophies from daily challenges",Points=3)
    Achievements(36)=(Title="Perfectionist",ID=prelude_1,Description="Finish EgyptianRush-Prelude with maximum health",Points=5)
    Achievements(37)=(Title="High achiever",ID=ach_0,Description="Achieve 30 achievements",Points=5)
    Achievements(38)=(Title="Ragequitter",ID=records_1,Description="Lose 5 records since your last visit",Points=3)
    Achievements(39)=(Title="Hatist",ID=store_2,Description="Buy 10 items",Points=2)
    Achievements(40)=(Title="EgyptRuin whorerer",ID=map_6,Type=FinishRuin,Count=15,Description="Complete any EgyptRuin map 15 times",Points=1)
    Achievements(41)=(Title="Immune to failure",ID=records_2,Description="Hijack a Solo record that people has failed 50 times to achieve",Points=3)
    Achievements(42)=(Title="Birthday wisher",ID=eliot_0,Description="Say Happy Birthday Eliot! on August 26th",Points=1)
    Achievements(43)=(Title="Objectives farmer",ID=obj_0,Description="Complete 10000 objectives",Points=2)
    Achievements(44)=(Title="Solo gamer",ID=records_3,Description="Own 50 Solo records",Points=2)
    Achievements(45)=(Title="Regular gamer",ID=records_4,Description="Own 10 Regular records",Points=2)
    Achievements(46)=(Title="Group gamer",ID=records_5,Description="Own 4 Group records",Points=3)
    Achievements(47)=(Title="Trials master",ID=ach_1,Description="Earn all four gamer achievements",Points=5)

    MapTests(0)=(MapTitle="Eliot's Trial",Time=240,Target=map_2)
    MapTests(1)=(MapTitle="Blood On The Floor",Time=-1,Target=map_3)
    MapTests(2)=(MapTitle="EgyptianRush-Prelude",Time=300,Target=map_4)
    MapTests(3)=(MapTitle="RoomTrials*",Time=240,Target=map_5)
    //MapTests(4)=(MapTitle="EgyptRuin-*",Time=-1,Target=map_6,bCount=true)     // Hardcoded
}
