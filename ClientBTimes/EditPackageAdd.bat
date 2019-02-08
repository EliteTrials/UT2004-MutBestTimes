@echo off

for %%* in (.) do set project_name=%%~n*

color 0F
title %project_name%
cd..
cd system
:add
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %project_name%
pause
goto add