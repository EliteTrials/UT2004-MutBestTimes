@echo off
setlocal
for %%I in ("%~dp0..\..") do set "ut2004_dir=%%~fI"
if not exist "%ut2004_dir%\Textures" mkdir "%ut2004_dir%\Textures"
copy /y "%~dp0Textures\TextureBTimes.utx" "%ut2004_dir%\Textures\TextureBTimes.utx"
exit /b %errorlevel%
