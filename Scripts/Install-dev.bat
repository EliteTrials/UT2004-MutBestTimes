@echo off

cd System
:: No system files anymore.

cd ..\Textures
xcopy "TextureBTimes.utx" "..\..\..\Textures\TextureBTimes.utx" /i /y
pause