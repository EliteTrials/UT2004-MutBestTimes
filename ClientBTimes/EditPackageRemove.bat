@echo off

for %%* in (.) do set project_name=%%~n*

color 0F
title %project_name%
cd..
cd system
:remove
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %project_name%
pause
goto remove