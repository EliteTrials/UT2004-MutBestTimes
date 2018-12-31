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