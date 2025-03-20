@echo off

for %%* in (.) do set packageName=%%~n*
set project_dir=%~dp0
set version=V7b
:: DO NOT CHANGE VX
set compiledPackageName=%packageName%VX

title %packageName%
color 0F

cd ..\..\System

if exist %compiledPackageName%.u (
    del %compiledPackageName%.u /q
    del %compiledPackageName%.ucl /q
    del %compiledPackageName%.int /q
)

cd ..
cd MutBestTimes\%packageName%

if not exist "..\..\%compiledPackageName%\Resources" (
    xcopy Resources "..\..\%compiledPackageName%\Resources" /i /y /s /e /q /b >NUL
    xcopy Textures "..\..\%compiledPackageName%\Textures" /i /y /s /e /q /b >NUL
)

if not exist "..\..\%compiledPackageName%\Classes" (
    mkdir "..\..\%compiledPackageName%\Classes"
) else (
    del "..\..\%compiledPackageName%\Classes\*.uc"
    del "..\..\%compiledPackageName%\Classes\*.uci"
)

cd Classes
for /r %%i in (*.uc, *.uci) do (
    copy /Y "%%~fi" "..\..\..\%compiledPackageName%\Classes\%%~nxi" >NUL
)

cd ..\..\..\System

ucc.exe MakeCommandlet -ini="%project_dir%\make.ini"
del %packageName%%version%.u
ren %compiledPackageName%.u %packageName%%version%.u
del %compiledPackageName%.ucl