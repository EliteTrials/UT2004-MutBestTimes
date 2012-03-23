@echo off
color 0F
title ServerBTimes
cd..
cd system
:remove
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ServerBTimes
pause
goto remove