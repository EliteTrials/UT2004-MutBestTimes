@echo off
set version=V7b
set packageName=ClientBTimes

title %packageName%
color 0F

cd ..\..\System
del %packageName%.u /q
del %packageName%.ucl /q
del %packageName%.int /q

cd ..
cd MutBestTimes\%packageName%

xcopy Resources "..\..\%packageName%%version%\Resources" /i /y /s /e /q /b
xcopy Textures "..\..\%packageName%%version%\Textures" /i /y /s /e /q /b

cd Classes
for /r %%i in (*.uc, *.uci) do (
	copy /y "%%~fi" "..\..\..\%packageName%%version%\Classes\%%~nxi"
)

cd ..\..\..\System
:: Add editpackage
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ServerBTimes
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %packageName%%version%
ucc.exe MakeCommandlet
:: Remove editpackage
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %packageName%%version%
pause