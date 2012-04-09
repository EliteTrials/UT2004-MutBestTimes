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

echo.
echo Copying Development to Classes
echo.
cd..
cd %projn%
xcopy Development Classes /Y /Q  

echo.
echo Obfuscating classes
echo.
cd Development
for %%F in (*.uc) do (
    if NOT %%F == BTServer_RecordsData.uc if NOT %%F == BTServer_CheckPoint.uc if NOT %%F == BTServer_PlayersData.uc if NOT %%F == BTPerks.uc  ( 
        echo Obfusctating class %%F
        ..\..\System\Gema\gema.exe -i -t -nobackup -w -f ..\Patterns.cfg -in %%F -out ..\Classes\%%F
    )
)
cd..

echo.
echo Obfuscating done. Preprocessing and compiling!
echo.
cd..
cd System
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %projn%
ucpp.exe -wait -debug -include ..\%projn%\Defines.puc -P SYSTEM=. %projn%
ucc.exe editor.MakeCommandlet -EXPORTCACHE -DEBUG -SHOWDEP
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %projn%
pause

echo.
echo StripSource?
echo.
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

cd..
cd %projn%
del Classes
pause