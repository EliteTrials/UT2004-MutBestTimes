@echo off

cd System
xcopy "MakeCommandletUtils.u" "..\..\..\System\MakeCommandletUtils.u" /i /y
cd ..\Textures
xcopy "TextureBTimes.utx" "..\..\..\Textures\TextureBTimes.utx" /i /y
pause