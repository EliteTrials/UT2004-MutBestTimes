/**
 * Originally coded by 'Marco' aka '.:..:' from 2005 to 2006(< 2.00), taken over by Eliot since 2007 to present.
 * ----------------------------------------------------------------------------
 * THOUGHTS:
 * A Race B - B Race C - C Race A = ??
 * ----------------------------------------------------------------------------
 * TODO:
 *	Fix Ghost view rotation on new record scene(unknown cause)
 *	ToggleGhost can cause a servercrash when the ghost spawns(unknown cause)
 *	ResetGhost option does not always reach its destination to the server(unknown cause)
 * ----------------------------------------------------------------------------
 * HISTORY:
 *
 * D/M/Y    Begin    -   Release          1-#-2
 * ...                                      #
 * 2.14 @ 30/08/2007 -            by Eliot  #
 * ...                                      #
 * 2.22 @ 04/02/2008 -            by Eliot  #
 * ...                                      #
 * 2.37 @ 11/06/2008              by Eliot  #
 * 2.38 @ 14/06/2008 - 18/06/2008 by Eliot	#
 * 2.39 @ 18/06/2008 - 18/06/2008 by Eliot	#
 * 2.40 @ 22/06/2008 - 22/06/2008 by Eliot	#
 * 2.41 @ 06/07/2008 - 06/07/2008 by Eliot	#
 * 2.42 @ 12/07/2008 - 12/07/2008 by Eliot	#
 * 2.43 @ 13/07/2008 - 13/07/2008 by Eliot	#
 * 2.44 @ 13/07/2008 - 13/07/2008 by Eliot	#
 * 2.45 @ 17/07/2008 - 19/07/2008 by Eliot	#
 * 2.46 @ 23/07/2008 - 31/07/2008 by Eliot	#
 * 2.47 @ 05/08/2008 - 12/08/2008 by Eliot	#
 * 2.48 @ 14/08/2008 - 16/08/2008 by Eliot	#
 * 2.49 @ 17/08/2008 - 17/08/2008 by Eliot	#
 * 2.50 @ 24/08/2008 - 21/10/2008 by Eliot	#
 * 2.51 @ 04/11/2008 - 04/11/2008 by Eliot	#
 * 2.52 @ 05/11/2008 - 05/11/2008 by Eliot	#
 * 2.53 @ 06/11/2008 - 06/11/2008 by Eliot	#
 * 2.54 @ 08/11/2008 - 26/11/2008 by Eliot	#
 * 2.55 @ 23/12/2008 - 28/12/2008 by Eliot	#
 * 2.56 @ 28/12/2008 - 28/12/2008 by Eliot	#
 * 2.57 @ 31/12/2008 - 31/12/2008 by Eliot	#
 * 2.58 @ 04/01/2009 - 04/01/2009 by Eliot	#
 * 2.59 @ 05/01/2009 - 05/01/2009 by Eliot	#
 * 2.60 @ 07/01/2009 - 07/01/2009 by Eliot	#
 * 2.61 @ 07/01/2009 - 07/01/2009 by Eliot	#
 * 2.62 @ 13/01/2009 - 13/01/2009 by Eliot	#
 * 2.63 @ 14/01/2009 - 14/01/2009 by Eliot	#
 * 2.64 @ 17/01/2009 - 17/01/2009 by Eliot	#
 * 2.65 @ 20/01/2009 - 01/02/2009 by Eliot	#
 * 2.66 @ 02/02/2009 - 02/02/2009 by Eliot	#
 * 2.67 @ 04/02/2009 - 04/02/2009 by Eliot	#
 * 2.68 @ 06/02/2009 - 19/02/2009 by Eliot	#
 * 2.69 @ 21/02/2009 - 01/03/2009 by Eliot	#
 * 2.70 @ 06/03/2009 - 06/03/2009 by Eliot	#
 * 2.71 @ 22/03/2009 - 22/03/2009 by Eliot	#
 * 2.72 @ 27/03/2009 - 27/03/2009 by Eliot	#
 * 2.73 @ 29/03/2009 - 29/03/2009 by Eliot	#
 * 2.74 @ 18/04/2009 - 20/04/2009 by Eliot	#
 * 2.75 @ 08/05/2009 - 14/05/2009 by Eliot	#
 * 2.76 @ 19/05/2009 - 20/05/2009 by Eliot	#
 * 2.77 @ 28/05/2009 - 28/05/2009 by Eliot	#
 * 2.78 @ 28/05/2009 - 05/06/2009 by Eliot	# 	// New Client Version, new SoloMode
 * 2.79 @ 05/06/2009 - 05/06/2009 by Eliot	# 	// SoloMode Fixes
 * 2.80 @ 05/06/2009 - 05/06/2009 by Eliot	# 	// SoloMode Fixes 2, New Client Version
 * 2.81 @ 07/06/2009 - 09/06/2009 by Eliot	# 	// .ini to .uvx
 * 2.82 @ 10/06/2009 - 11/06/2009 by Eliot	#
 * 2.83 @ 11/06/2009 - 11/06/2009 by Eliot	#
 * 2.84 @ 13/06/2009 - 13/06/2009 by Eliot	#
 * 2.85 @ 15/06/2009 - 15/06/2009 by Eliot	#
 * 2.86 @ 20/06/2009 - 21/06/2009 by Eliot	#
 * 2.87 @ 27/06/2009 - 28/06/2009 by Eliot	#	// New Client Version
 * 2.88 @ 01/07/2009 - 09/07/2009 by Eliot	#	// New Client Version
 * 2.89 @ 10/07/2009 - 10/07/2009 by Eliot	#	// New Client Version
 * 2.90 @ 12/07/2009 - 18/07/2009 by Eliot	#	// New Client Version
 * 2.91 @ 19/07/2009 - 26/07/2009 by Eliot	#	// New Client Version
 * 2.92 @ 06/08/2009 - 02/12/2009 by Eliot	#	// Fixes, neater document
 * 2.93 @ 08/12/2009 - 15/12/2009 by Eliot	#	// Minor Fixes
 * 2.94 @ 16/12/2009 - 16/12/2009 by Eliot  #	// XMas Update
 * 2.95 @ 25/12/2009 - 25/12/2009 by Eliot  #	// CheckPoints feature, support for lca!
 * 2.96 @ 26/12/2009 - 14/04/2010 by Eliot  #	// MutantGlow!, Gibs
 * 2.97 @ 17/04/2010 - 17/04/2010 by Eliot  #	// New Client Version, GhostFollow available for noobs and BTCommands added for noobs, new algorithm for points on solo maps
 * 2.98 @ 18/04/2010 - 18/04/2010 by Eliot  #	// New Mode Feature named Group!
 * 2.99 @ 05/05/2010 - 02/06/2010 by Eliot  #	// Group task points supported, cleaned up code..., merged quickstart into this file, rewrote commands, coloured messages, reversed RecentSetRecordsByPlayer, history length 50 to 25, new race command
 * 2.99.*.2 @ 13/09/2010 - 13/09/2010 by Eliot  #	// Http notificator
 * 2.99.8.2 @ 12/12/2010 - 12/12/2010 by Eliot  #
 *	Fixed:Mutate ShowPlayerInfo, ShowBadRecords, ShowMapInfo
 *	Fixed:MRI Replication, Initialization(the end msg stuff etc)
 *	Fixed:SetTrailerTexture, SetTrailerColor for players that ain't top 3(all people above top 3 were overwriting the settings of the top 3) and reversed selecting order
 *	Fixed:2 Clientside Accessed None's errors
 *	Fixed:ClientSpawn(and improved collision detection), CheckPoints???(test need)
 *	Fixed:ServerTraveling saving
 *	Added:More details to ShowMapInfo
 *	Added:Tracking for map finishing count
 *	Added:Tracking for player playedhours
 *	Added:Tracking for player playcounts
 * 2.99.9.0 @ 25/01/2011 - 29/03/2011 by Eliot  #
 *	Fixed:Ghost markers are now destroyed when the ghost is deleted
 *	New:Achievements!
 *	New:Tabs for F12 Scoreboards
 *	New:Quarterly Best and Daily Best
 *	New:Escape tab for Commands, Trophies, Achievements and Challenges
 *	New:April Fools Day!
 *	New:Rewards BTimes, receive rewards based upon your stats
  * 2.99.9.8 @ 25/06/2011 by Eliot  #
 *	New:Experience System!
 *	New:Currency System!
 *	New:Trailers are no longer given to the Top 3 but are bought instead
   * 2.99.9.9 @ 01/07/2011 by Eliot  #
 *	New:BT Store
 *	New:Items - Trailer and MNAFAccess
 *	New:Objective XP reward is spawn protected by 10 seconds
 *	Fixed:Middle mouse button bind to Mutate ResetCheckPoint
 *	Fixed:Mutate ResetCheckPoint now only replies if you had a CheckPoint
 *	Fixed:RandomVote-Solo
   * 2.99.10.0 @ 09/07/2011 by Eliot  #
 *	New:Added plenty of achievements
 *	New:Achievements are now ready
 *	New:Achievements give Currency points
 *	New:On Group all record players with the same time as the first player are now displayed in the Record Holder(s) place
 *	Changed:Levels no longer require too much experience
 *	Changed:Regular trials give more experience
 *	Fixes:Minor fixes
   * 2.99.10.1 @ 09/07/2011 by Eliot  #
 *	New:Added 15 new achievements
 *	New:Achievements total progress is now shown
 *	New:Achievement Currency reward is now shown
 *	New:Added the ability to add new Map completion tests for custom Achievements
 *	New:Added a advertise message on QuickStart and map completion
 *	Fixed:Jani achievement
 *	Fixed:Group achievement(did not reward the ghost owner)
 *	Removed:You no longer lose experience for dying(temporary)
   * 2.99.11.0 @ 13/07/2011 by Eliot  #
 *	New:Added 2 new achievements
 *	New:You can now configure modes for RandomMode and prefixes
 *	Fixed:Reprogrammed RandomVote
   * 2.99.11.1 @ 16/07/2011 by Eliot  #
 *	New:Ability to reset the achievements for everyone
 *	New:Changing the Trailer texture or color will now be updated in real-time.
 *	Changed:The TrailerMenu no longer looks at your current attached trailer for settings, but instead at your SAVED settings
 *	Changed:SetTrailerColor format is now: "R G B R G B" rather than "0 R= G= B="
 *	Fixed:SetTrailerTexture and Color
   * 2.99.11.2 @ 17/07/2011 by Eliot  #
 *	New:Touch Dicky achievement
 *	New:"Unlock GTR-GeometryBasics" store item
 *	Changed:TechChallenge Whore achievement is now Finish any TechChallenge map 50 times
   * 2.99.11.3 @ 19/07/2011 by Eliot  #
 *	New:Achievements("What a faggot", "Home sweet home", "Quality enjoyment")
 *	Changed:ForeverAlone.jpg, complete a Solo map 20 times instead of once
 *	Changed:Store now shows a name for the items instead of its ID
 *	Changed:Hijacks are shown again in the F12 table
 *	Improved:Optimized the amount of data send to clients upon connecting
 *	Fixed:Quarterly for RTR records
   * 2.99.12.0 @ 23/07/2011 by Eliot  #
 *	New:Achievement("Challenges master")
 *	New:Challenges and Trophies
   * 2.99.13.0 @ 02/08/2011 by Eliot  #
 *  New:Admins can now give Items
 *  New:Items can now made admin-exclusive
 *  New:Added an option for "Ghost timer markers" which determines whether to spawn them
 *  New:Store item "200% EXP Bonus" for 4 play hours
 *	New:Added donation button into store.
 *	New:Experience percentage gain is now shown next to the xp bar
 *  New:TotalCurrencySpent and TotalItemsBought are now tracked and shown at F12
 *	Fixed:Minor errors
   * 2.99.13.1 @ 06/08/2011 by Eliot  #
 *  New:Positive icon is now rendered before the ItemName if bought
 *	New:Toggling a item to true will disable all other items of the same "Type"
   * 2.99.13.2 @ 08/08/2011 by Eliot  #
 *  New:(Remove/Delete)Item <PlayerName> <ID> command
 *	New:GiveCurrency <PlayerName> <amount> command
 *	Fixed:Dicky achievement
   * 2.99.13.3 @ 09/08/2011 by Eliot  #
 *  New:Achievement("Perfection","High achiever","Timeout","Shopping like a girl","EgyptRuin whore","Failure immunity")
 *	New:Items can now be set to passive true which means you can't sell it
 *	Changed:Store item "200% EXP Bonus" now changed to "100% EXP Bonus" to avoid confusion
   * 2.99.14.0 @ 16/08/2011 by Eliot  #
 *  New:MultiGhosts for Group and Regular trials
 *	Fixed:Two ghost syncing bugs
 *	Fixed:"Shopping like a girl" - ID already in use
   * 2.99.14.1 @ 20/08/2011 by Eliot  #
 *  New:Store items GUI now supports item icons
 *	Changed:Store GUI
   * 2.99.14.2 @ 23-25/08/2011 by Eliot  #
 *	New:Categories("All","Other,"Admin","Trailers","Upgrades") added to the BTStore
 *	New:Achievement("Happy Birthliot")
 *	Changed:Admin items are only visible for Admins or Owner
 *	Improved:BTStore GUI now remembers last selected item
 *	Fixed:MNAFAccess
   * 2.99.14.3 @ 28/08/2011 by Eliot  #
 *	New:Achievement("Dedicated gamer","Objectives farmer","Solo gamer","Regular gamer","Group gamer","Trials master")
 *	New:Option for MaxLevel, ObjectivesEXPDelay
 *	New:Max level cap(100)
 *	New:Anti-farm delay per objective.
 *	Fixed:High achiever achievement(progressable achievements were counted)
   * 2.99.14.4 @ 0/09/2011 by Eliot  #
 *	New:Store now supports double clicking to Toggle selected item
 *	New:Store now supports right click with a context menu
 *	New:Store now remembers last used filter
   * 2.99.15.0 @ 09/09/2011 by Eliot  #
 *	New:Competitive Mode!
   * 2.99.15.1 @ 18-19/09/2011 by Eliot  #
 *	New:Added a 4 players limit to Competitive Mode
 *	New:ScoreBoard now shows Score(and obj icon) and Death(in Competitive Mode)
 *	New:ScoreBoard shows map screenshot if locally available
 *	New:Added ability to add LockedMap items
 *	Fixed:Net stats for Spectators in ScoreBoard
   * 2.99.16.0 @ 12/10/2011 by Eliot  #
 *	new:Trophies can now be exchanged for Currency points!
 */
