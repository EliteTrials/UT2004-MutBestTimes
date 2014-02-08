@echo off

for %%* in (.) do set project_name=%%~n*

title %project_name%
color 0F

cd..
cd system
ren ClientBTimes.ini ClientBTimes_bak.ini
UCC.exe editor.stripsourcecommandlet %project_name%.u
ren ClientBTimes_bak.ini ClientBTimes.ini
pause