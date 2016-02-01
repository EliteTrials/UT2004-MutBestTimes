@echo off

set projn=ServerBTimes
set inin=MutBestTimes

title %projn%
color 0F

echo.
echo Deleting compiled files %projn%
echo.
cd..
cd system
del %projn%.u
del %projn%.ucl
del %projn%.int

cd..
cd System
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %projn%
ucc.exe editor.MakeCommandlet -EXPORTCACHE -SHOWDEP -SILENTBUILD -AUTO
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %projn%
pause

echo.
echo Stripping source!
echo.
ren BTStore.ini BTStore_bak.ini
ren %inin%.ini %inin%_bak.ini
ren %inin%_Rewards.ini %inin%_Rewards_bak.ini
ucc.exe editor.stripsourcecommandlet %projn%.u
ren %inin%_bak.ini %inin%.ini
ren %inin%_Rewards_bak.ini %inin%_Rewards.ini
ren BTStore_bak.ini BTStore.ini
echo.
echo Successfuly stripped the source code
echo.

echo.
echo Generate files?
echo.
pause

echo.
echo Generating cache files
echo.
ucc.exe dumpintCommandlet %projn%.u
pause