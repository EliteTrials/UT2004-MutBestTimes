//=============================================================================
// Copyright 2005-2014 Eliot Van Uytfanghe. All Rights Reserved.
//=============================================================================
class BTAchievements extends Object
    config(BTAchievements);

/** List of categories for achievements such as "Records", "Trophies". */
var() globalconfig array<BTClient_ClientReplication.sAchievementCategory> Categories;

/** A structure that defines an earnable achievement. */
struct sAchievement
{
    /** Title of the achievement e.g. "Recwhore" */
    var string Title;

    /** Identity for the achievement, used to identifiy which achievement an user has achieved.
        Changing this will make the players that have earned this achievement obsolete. */
    var name ID;

    /** The kind of achievement it is e.g. Record related? Deaths related?
        Used to automatic increment the earned Count of all @Type when that kind of @Type is progressed. */
    var name Type;

    /** Amount of @Type's progress necessary to earn the achievement. */
    var int Count;

    /** Description explaining what to do to earn the achievement. */
    var string Description;

    /** Icon portraying the achievement. */
    var string Icon;

    /** Value of the achievement. */
    var int Points;

    /** The @Id of a sCategory to bind to. */
    var string CatID;

    /** The GUI color for the special effects. */
    var Color EffectColor;

    /** Reward to be given on completion of this achievement. Add multiple rewards by splitting with a semicolon. */
    var string ItemRewardId;
};

/** Collection of achievements that players are able to achieve. */
var() globalconfig array<sAchievement> Achievements;

var private int LastAchievementsCount;

struct sMapTest
{
    var string MapTitle;
    var float Time;
    var name Event;
    var name Target;
    var bool bCount;
};
var() globalconfig array<sMapTest> MapTests;

final function Free();

/** Necessary to load up the achievements collection. */
final static function BTAchievements Load()
{
    // StaticSaveConfig();
    return new(none) default.Class;
}

final function InitForMap( MutBestTimes BT, string mapName, string mapTitle )
{
    local int i;

    for( i = 0; i < MapTests.Length; ++ i )
    {
        if( MapTests[i].Event != '' && MapTests[i].MapTitle == mapTitle )
        {
            BT.Spawn( class'BTServer_AchievementListener', BT, MapTests[i].Event );
        }
    }
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
        if( MapTests[i].Event != '' )
        {
            return false;
        }

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
    // Achievements related to Trials.
    Categories(0)=(Name="Trials",ID="cat_trials")
    Categories(1)=(Name="Server",ID="cat_server")
    // Achievements that are related with records.
    Categories(2)=(Name="Records",ID="cat_records",ParentId="cat_trials")
    Categories(3)=(Name="Admin Challenges",ID="cat_challenges",ParentId="cat_trials")
    Categories(4)=(Name="Map Challenges",ID="cat_map",ParentId="cat_trials")
    Categories(5)=(Name="Map Collections",ID="cat_col",ParentId="cat_trials")
    Categories(6)=(Name="Geometric Absolution",ID="cat_col_gemab",ParentId="cat_col")
    // Achievements that are generated on a daily basis.
    Categories(7)=(Name="Daily Trophies",ID="cat_trophies",ParentId="cat_trials")
    Categories(8)=(Name="Game",ID="cat_game",ParentId="cat_trials")
    Categories(9)=(Name="Other",ID="cat_other",ParentId="cat_trials")

    // Record Count kinds
    Achievements(0)=(Title="Newbie Recwhore",ID=recwhore_0,CatID="cat_records",Type=RecordsCount,Count=1,Description="Achieve one record",Points=1,EffectColor=(B=255,A=255))
    Achievements(1)=(Title="Noob Recwhore",ID=recwhore_1,CatID="cat_records",Type=RecordsCount,Count=5,Description="Achieve five records",Points=2,EffectColor=(B=255,A=255))
    Achievements(2)=(Title="Experienced Recwhore",ID=recwhore_2,CatID="cat_records",Type=RecordsCount,Count=20,Description="Achieve twenty records",Points=2,EffectColor=(B=255,A=255))
    Achievements(3)=(Title="Hardcore Recwhore",ID=recwhore_3,CatID="cat_records",Type=RecordsCount,Count=50,Description="Achieve fifty records",Points=5,EffectColor=(B=255,A=255))
    Achievements(4)=(Title="Recwhore",ID=recwhore_4,CatID="cat_records",Type=RecordsCount,Count=100,Description="Achieve a hundred records",Points=10,EffectColor=(B=255,A=255))

    Achievements(5)=(Title="TechChallenge whore",ID=map_1,Count=50,CatID="cat_map",Type=FinishTech,Description="Complete any TechChallenge map 50 times",Points=2,EffectColor=(R=255,G=165,A=255))
    Achievements(6)=(Title="Another fan",ID=map_2,CatID="cat_map",Description="Set a record on Eliot'sTrial of 4 minutes or less",Points=10,EffectColor=(R=255,G=165,A=255))
    Achievements(7)=(Title="What's a Checkpoint?",ID=checkpoint_1,CatID="cat_other",Type=CheckpointUses,Count=10,Description="Reach 10 Checkpoints",Points=1,EffectColor=(G=128,B=128,A=255))
    Achievements(8)=(Title="Epic failer",ID=clientspawn_1,CatID="cat_other",Description="Set a 'Client Spawn' by using 'SetClientSpawn'",Points=1,EffectColor=(G=128,B=128,A=255))
    Achievements(9)=(Title="Jani maps hater",ID=jani_1,CatID="cat_other",Description="Insult a jani's map while playing one",Points=1,EffectColor=(G=128,B=128,A=255))    // Done
    Achievements(10)=(Title="Group lover",ID=mode_1,CatID="cat_other",Description="Complete a Group map",Points=5,EffectColor=(G=128,B=128,A=255))    // Done
    Achievements(11)=(Title="I like it Regular",ID=mode_2,CatID="cat_other",Description="Complete a Regular map",Points=2,EffectColor=(G=128,B=128,A=255)) // Done
    Achievements(12)=(Title="ForeverAlone.jpg",ID=mode_3,CatID="cat_other",Type=FinishSolo,Count=20,Description="Complete a Solo map 20 times",Points=5,EffectColor=(G=128,B=128,A=255)) // Done
    Achievements(13)=(Title="Newbie",ID=level_0,CatID="cat_game",Type=LevelUp,Count=2,Description="Level up 2 times",Points=1)
    Achievements(14)=(Title="Noob",ID=level_2,CatID="cat_game",Type=LevelUp,Count=8,Description="Level up 8 times",Points=2)
    Achievements(15)=(Title="Experienced",ID=level_3,CatID="cat_game",Type=LevelUp,Count=20,Description="Level up 20 times",Points=2)
    Achievements(16)=(Title="Experience lover",ID=experience_0,CatID="cat_game",Description="Earn 64 experience from one action",Points=2)
    Achievements(17)=(Title="I bought an Item!",ID=store_0,CatID="cat_other",Description="Buy your first item from the Store",Points=1,EffectColor=(G=128,B=128,A=255))
    // Achievements(18)=(Title="BTimes explorer",ID=store_1,Description="Find the Store",Points=1)
    Achievements(19)=(Title="Dedicated noob",ID=level_4,CatID="cat_game",Description="Reach level 50",Points=5)
    Achievements(20)=(Title="Dedicated gamer",ID=level_5,CatID="cat_game",Description="Reach level 100",Points=5)
    Achievements(22)=(Title="Map loveist",ID=finish_0,CatID="cat_other",Type=Finish,Count=200,Description="Finish 200 times any trial map",Points=5,EffectColor=(G=128,B=128,A=255))
    Achievements(23)=(Title="Lucky lucker",ID=tie_0,CatID="cat_records",Type=Tied,Count=5,Description="Tie a record on a Solo map 5 times",Points=5,EffectColor=(B=255,A=255))
    Achievements(24)=(Title="Ghoster",ID=ghost_0,CatID="cat_other",Description="Get your first ghost",Points=5,EffectColor=(G=128,B=128,A=255))
    Achievements(25)=(Title="I'm no muffin",ID=points_0,CatID="cat_records",Description="Earn 20 points from one record",Points=2,EffectColor=(B=255,A=255))
    Achievements(26)=(Title="Loner",ID=holiday_0,CatID="cat_other",Description="Spawn on a 'Client Spawn' on a BTimes holiday",Points=1,EffectColor=(G=128,B=128,A=255))
    Achievements(27)=(Title="Robin Hood",ID=records_0,CatID="cat_records",Type=StealRecord,Count=50,Description="Steal 50 first place records not owned by you",Points=20,EffectColor=(B=255,A=255))
    Achievements(28)=(Title="Who's bad?",ID=map_3,CatID="cat_map",Description="Set a record on Blood On The Floor",Points=10,EffectColor=(R=255,G=165,A=255))
    Achievements(29)=(Title="A prelude rusher",ID=map_4,CatID="cat_map",Description="Set a record on EgyptianRush-Prelude of 5 minutes or less",Points=10,EffectColor=(R=255,G=165,A=255))
    Achievements(30)=(Title="Classic lovelist",ID=map_5,CatID="cat_map",Description="Set a record on a RoomTrials map of 4 minutes or less",Points=5,EffectColor=(R=255,G=165,A=255))
    Achievements(31)=(Title="(no homo)",ID=sirdicky,CatID="cat_other",Description="Find dicky and touch him(no homo)",Points=1,EffectColor=(G=128,B=128,A=255))
    Achievements(32)=(Title="Night whore",ID=mode_3_night,CatID="cat_other",Description="Complete a Solo map at night",Points=1,EffectColor=(G=128,B=128,A=255))
    Achievements(21)=(Title="Server loveist",ID=playtime_0,CatID="cat_server",Description="Play for over 10 hours on this server",Points=2,EffectColor=(R=255,B=255,A=255))
    Achievements(33)=(Title="Home sweet home",ID=playtime_1,CatID="cat_server",Description="Play for over 1000 hours on this server",Points=10,EffectColor=(R=255,B=255,A=255))
    Achievements(34)=(Title="Fan of Haydon",ID=quality_0,CatID="cat_other",Type=FinishQuality,Count=10,Description="Finish 10 times a map that's designed by Eliot or Haydon",Points=5,EffectColor=(G=128,B=128,A=255))
    Achievements(35)=(Title="Challenges master",ID=challenge_0,CatID="cat_challenges",Type=FinishDailyChallenge,Count=25,Description="Earn 25 trophies from daily challenges",Points=10)
    Achievements(36)=(Title="Perfectionist",ID=prelude_1,CatID="cat_map",Description="Finish EgyptianRush-Prelude with maximum health",Points=10,EffectColor=(R=255,G=165,A=255))
    Achievements(37)=(Title="High achiever",ID=ach_0,CatID="cat_game",Description="Achieve 30 achievements",Points=5)
    Achievements(38)=(Title="Ragequitter",ID=records_1,CatID="cat_records",Description="Lose 5 records since your last visit",Points=1,EffectColor=(B=255,A=255))
    Achievements(39)=(Title="Hatist",ID=store_2,CatID="cat_other",Description="Buy 10 items",Points=2,EffectColor=(G=128,B=128,A=255))
    Achievements(40)=(Title="EgyptRuin whore",ID=map_6,CatID="cat_map",Type=FinishRuin,Count=15,Description="Complete any EgyptRuin map 15 times",Points=5,EffectColor=(R=255,G=165,A=255))
    Achievements(41)=(Title="Immune to failure",ID=records_2,CatID="cat_records",Description="Hijack a Solo record that players had failed 50 times to achieve",Points=1,EffectColor=(B=255,A=255))
    Achievements(42)=(Title="Birthday wisher",ID=eliot_0,CatID="cat_other",Description="Say Happy Birthday Eliot! on August 26th",Points=1,EffectColor=(G=128,B=128,A=255))
    Achievements(43)=(Title="Objectives farmer",ID=obj_0,CatID="cat_game",Description="Complete 10000 objectives",Points=5)
    Achievements(44)=(Title="Solo gamer",ID=records_3,CatID="cat_records",Description="Own 50 Solo records",Points=5,EffectColor=(B=255,A=255))
    Achievements(45)=(Title="Regular gamer",ID=records_4,CatID="cat_records",Description="Own 10 Regular records",Points=5,EffectColor=(B=255,A=255))
    Achievements(46)=(Title="Group gamer",ID=records_5,CatID="cat_records",Description="Own 4 Group records",Points=5,EffectColor=(B=255,A=255))
    Achievements(47)=(Title="Trials master",ID=ach_1,CatID="cat_records",Description="Earn all four gamer achievements",Points=10,EffectColor=(B=255,A=255))
    Achievements(48)=(Title="Freeman",ID=map_7,CatID="cat_map",Description="Eliminate the Mothership Kran queen and escape",Points=10,EffectColor=(R=255,G=165,A=255),ItemRewardId="md_mok")
    Achievements(49)=(Title="Fast and heavy lander",ID=map_8,CatID="cat_map",Description="Set a record on Geometry Basics of 3 minutes or less",Points=5,EffectColor=(R=255,G=165,A=255),ItemRewardId="md_gemb")
    Achievements(50)=(Title="Naliman",ID=map_9,CatID="cat_map",Description="Survive through the Eldora passages",Points=10,EffectColor=(R=255,G=165,A=255),ItemRewardId="md_eldor")

    // Geometric Absolution Achievements
    Achievements(51)=(Title="Collection Absolute",ID=map_10_col,CatID="cat_col",Type=ColGem,Count=6,Description="Complete all the achievements for Geometric Absolution",Points=5,EffectColor=(R=255,G=255,B=255,A=255),Icon="AS_FX_TX.Icons.ScoreBoard_Objective_Final")
    Achievements(52)=(Title="Karma Cube",ID=map_10_kcube,CatID="cat_col_gemab",Description="Karma cubes?",Points=1,EffectColor=(R=255,G=255,B=255,A=255))
    Achievements(53)=(Title="Companion Cube",ID=map_10_ccube,CatID="cat_col_gemab",Description="Find the Companion Cube",Points=1,EffectColor=(R=255,G=255,B=255,A=255))
    Achievements(54)=(Title="Absoluted",ID=map_10,CatID="cat_col_gemab",Description="Set a record on Geometric Absolution",Points=5,EffectColor=(R=255,G=255,B=255,A=255))
    Achievements(55)=(Title="Hardmode",ID=map_10_hm,CatID="cat_col_gemab",Description="Easy paths ain't my thing!",Points=1,EffectColor=(R=255,G=255,B=255,A=255))

    MapTests(0)=(MapTitle="Eliot's Trial",Time=240,Target=map_2)
    MapTests(1)=(MapTitle="Blood On The Floor",Time=-1,Target=map_3)
    MapTests(2)=(MapTitle="EgyptianRush-Prelude",Time=300,Target=map_4)
    MapTests(3)=(MapTitle="RoomTrials*",Time=240,Target=map_5)
    //MapTests(4)=(MapTitle="EgyptRuin-*",Time=-1,Target=map_6,bCount=true)     // Hardcoded
    MapTests(4)=(MapTitle="Mothership Kran",Time=-1,Target=map_7)
    MapTests(5)=(MapTitle="Geometry Basics",Time=180,Target=map_8)
    MapTests(6)=(MapTitle="The Eldora Passages",Time=-1,Target=map_9)
    MapTests(7)=(MapTitle="Geometric Absolution",Event=ACHIEVEMENT_KarmaCube,Target=map_10_kcube)
    MapTests(8)=(MapTitle="Geometric Absolution",Event=ACHIEVEMENT_CompanionCube,Target=map_10_ccube)
    MapTests(9)=(MapTitle="Geometric Absolution",Time=-1,Target=map_10)
    MapTests(10)=(MapTitle="Geometric Absolution",Event=ACHIEVEMENT_HardMode,Target=map_10_hm)
}
