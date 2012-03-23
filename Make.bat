@echo off
color 0F
title ClientBTimes
cd..
cd system
echo (X)
echo Deleting Compiled ClientBTimesV4C
echo ----------------------------------------------------
del ClientBTimesV4C.u
del ClientBTimesV4C.ucl
echo ----------------------------------------------------
echo (X)
echo Copying WorkClasses to Classes
echo ----------------------------------------------------
cd..
cd ClientBTimesV4C
xcopy WorkClasses Classes /Y /Q  
echo ----------------------------------------------------
echo (X)
echo Obfuscating Classes...
echo ----------------------------------------------------
echo Obfuscating BTClient_MutatorReplicationInfo.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_MutatorReplicationInfo.uc -out Classes\BTClient_MutatorReplicationInfo.uc
echo Obfuscating BTClient_ClientReplication.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_ClientReplication.uc -out Classes\BTClient_ClientReplication.uc
echo Obfuscating BTClient_Interaction.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_Interaction.uc -out Classes\BTClient_Interaction.uc
echo Obfuscating BTClient_TrialScoreBoard.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_TrialScoreBoard.uc -out Classes\BTClient_TrialScoreBoard.uc
echo Obfuscating BTClient_SoloFinish.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_SoloFinish.uc -out Classes\BTClient_SoloFinish.uc
echo Obfuscating BTClient_Ghost.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_Ghost.uc -out Classes\BTClient_Ghost.uc
echo Obfuscating BTClient_Menu.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_Menu.uc -out Classes\BTClient_Menu.uc
echo Obfuscating BTClient_TrailerInfo.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_TrailerInfo.uc -out Classes\BTClient_TrailerInfo.uc
echo Obfuscating BTClient_TrailerMenu.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_TrailerMenu.uc -out Classes\BTClient_TrailerMenu.uc
echo Obfuscating BTClient_Config.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTClient_Config.uc -out Classes\BTClient_Config.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTGUI_Settings.uc -out Classes\BTGUI_Settings.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTGUI_Achievements.uc -out Classes\BTGUI_Achievements.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTGUI_Trophies.uc -out Classes\BTGUI_Trophies.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTGUI_Challenges.uc -out Classes\BTGUI_Challenges.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTGUI_StatsTab.uc -out Classes\BTGUI_StatsTab.uc
..\System\Gema\gema.exe -i -t -nobackup -w -f Patterns.cfg -in WorkClasses\BTGUI_Store.uc -out Classes\BTGUI_Store.uc
echo ----------------------------------------------------
echo (X)
echo Compiling...
echo ----------------------------------------------------
cd..
cd system
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 ClientBTimesV4C
ucc.exe MakeCommandlet -exportcache -DEBUG -SHOWDEP
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ClientBTimesV4C
echo Compiled!
echo ----------------------------------------------------
echo (X)
echo StripSource?
echo ----------------------------------------------------
pause
echo Stripping Source!
ren ClientBTimes.ini ClientBTimes_bak.ini
UCC.exe editor.stripsourcecommandlet ClientBTimesV4C.u
ren ClientBTimes_bak.ini ClientBTimes.ini
echo ----------------------------------------------------
pause
goto compile