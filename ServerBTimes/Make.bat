@echo off
set packageName=ServerBTimes
set inin=MutBestTimes

title %packageName%
color 0F

cd ..\..\System
del %packageName%.u /q
del %packageName%.ucl /q
del %packageName%.int /q

cd ..
cd MutBestTimes\%packageName%

xcopy System "..\..\%packageName%\System" /i /y /s /e /q /b

cd Classes
for /r %%i in (*.uc, *.uci) do (
	copy /y "%%~fi" "..\..\..\%packageName%\Classes\%%~nxi"
)

cd ..\..\..\System
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %packageName%
ucc.exe editor.MakeCommandlet -SILENTBUILD -AUTO -DEBUG
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %packageName%
pause