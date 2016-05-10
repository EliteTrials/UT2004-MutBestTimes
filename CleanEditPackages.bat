@echo off
color 0F
title ServerBTimes
cd..
cd system
:remove
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ClientBTimesV7
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ServerBTimes
pause
goto remove