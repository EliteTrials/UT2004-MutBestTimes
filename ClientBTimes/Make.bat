@echo off
set version=V7b
set packageName=ClientBTimes
set compiledPackageName=ClientBTimes%version%

title %packageName%
color 0F

cd ..\..\System
del %compiledPackageName%.u /q
del %compiledPackageName%.ucl /q
del %compiledPackageName%.int /q

cd ..
cd MutBestTimes\%packageName%

xcopy Resources "..\..\%compiledPackageName%\Resources" /i /y /s /e /q /b
xcopy Textures "..\..\%compiledPackageName%\Textures" /i /y /s /e /q /b

cd Classes
for /r %%i in (*.uc, *.uci) do (
	copy /y "%%~fi" "..\..\..\%compiledPackageName%\Classes\%%~nxi"
)

cd ..\..\..\System
:: Add editpackage
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ServerBTimes
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %compiledPackageName%
ucc.exe MakeCommandlet
:: Remove editpackage
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %compiledPackageName%
pause