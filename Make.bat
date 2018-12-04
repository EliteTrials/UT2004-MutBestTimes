@echo off
set project_version=V7b
for %%* in (.) do set "project_name=%%~n*"
set "project_build_name=%project_name%%project_version%"

title %project_build_name%
color 0F

cd..
cd system
del %project_build_name%.u
del %project_build_name%.ucl
del %project_build_name%.int

cd..
cd %project_name%

xcopy content "..\%project_build_name%\content" /i /y /q
copy /y "ClientBTimes.utx" "..\%project_build_name%\ClientBTimes.utx"
copy /y "CountryFlagsUT2K4.utx" "..\%project_build_name%\CountryFlagsUT2K4.utx"

cd src
for /r %%i in (*.uc) do (
	copy /y "%%~fi" "..\..\%project_build_name%\Classes\%%~nxi"
)

cd..
cd..
cd system
:: Add editpackage
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 ServerBTimes
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %project_build_name%
ucc.exe MakeCommandlet
:: Remove editpackage
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %project_build_name%
:: Work around the stripper, so that it cannot embed the current .ini settings.
ren ClientBTimes.ini ClientBTimes_bak.ini
ucc.exe Editor.StripSourceCommandlet %project_build_name%.u
ren ClientBTimes_bak.ini ClientBTimes.ini
pause
goto compile