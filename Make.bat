@echo off
set project_version=V6
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

xcopy Images "..\%project_build_name%\Images" /i /y /q
copy /y "ClientBTimes.utx" "..\%project_build_name%\ClientBTimes.utx"

cd src
for /r %%i in (*.uc) do (
	copy /y "%%~fi" "..\..\%project_build_name%\Classes\%%~nxi"
)

cd..
cd..
cd system
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %project_build_name%
ucc.exe MakeCommandlet
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %project_build_name%
pause
goto compile