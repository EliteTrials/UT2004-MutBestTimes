@echo off
setlocal
set "bt_project_dir=%~dp0"
for %%I in ("%bt_project_dir%..") do set "bt_ut2004_dir=%%~fI"

if not exist "%bt_ut2004_dir%\System\ucc.exe" (
    echo UT2004 Windows compiler missing: "%bt_ut2004_dir%\System\ucc.exe" >&2
    exit /b 1
)
for %%P in (Core Engine TrialGroup) do (
    if not exist "%bt_ut2004_dir%\System\%%P.u" (
        echo Required package missing: "%bt_ut2004_dir%\System\%%P.u" >&2
        exit /b 1
    )
)

fc /b "%bt_project_dir%Scripts\Textures\TextureBTimes.utx" "%bt_ut2004_dir%\Textures\TextureBTimes.utx" >nul 2>&1
if errorlevel 1 (
    echo Development texture is missing or outdated. Run: >&2
    echo "%bt_project_dir%Scripts\Install-dev.bat" >&2
    exit /b 1
)

echo Installation validated. Building ClientBTimes...
pushd "%bt_project_dir%ClientBTimes" || exit /b 1
call Make.bat
if errorlevel 1 goto build_failed
popd

echo Building ServerBTimes...
pushd "%bt_project_dir%ServerBTimes" || exit /b 1
call Make.bat
if errorlevel 1 goto build_failed
popd

if not exist "%bt_ut2004_dir%\System\ServerBTimes.u" (
    echo Server build did not produce "%bt_ut2004_dir%\System\ServerBTimes.u" >&2
    exit /b 1
)
echo Client and server builds completed.
exit /b 0

:build_failed
set "bt_build_status=%errorlevel%"
popd
exit /b %bt_build_status%
