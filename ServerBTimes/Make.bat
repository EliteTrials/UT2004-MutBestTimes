@echo off

for %%* in (.) do set packageName=%%~n*
set project_dir=%~dp0
set inin=MutBestTimes

title %packageName%
color 0F

cd ..\..\System

if exist %packageName%.u (
    del %packageName%.u /q
    del %packageName%.ucl /q
)

cd ..
cd MutBestTimes\%packageName%

xcopy System "..\..\%packageName%\System" /i /y /s /e /q /b >NUL

if not exist "..\..\%packageName%\Classes" (
    mkdir "..\..\%packageName%\Classes"
) else (
    del "..\..\%packageName%\Classes\*.uc"
)

cd Classes
for /r %%i in (*.uc, *.uci) do (
    copy /y "%%~fi" "..\..\..\%packageName%\Classes\%%~nxi" >NUL
)

cd ..\..\..\System

ucc.exe editor.MakeCommandlet -SILENTBUILD -AUTO -ini="%project_dir%\make.ini"
del %packageName%.ucl /q