@echo off

for %%* in (.) do set project_name=%%~n*

title %project_name%
color 0F

cd..
cd system
del %project_name%.u
del %project_name%.ucl
del %project_name%.int

cd..
cd %project_name%
xcopy Preprocessed Classes /Y /Q  

cd Preprocessed
for %%F in (*.uc) do (
    ..\gema.exe -i -t -nobackup -w -f ..\Patterns.cfg -in %%F -out ..\Classes\%%F
)

cd..
cd..
cd system
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 1 %project_name%
ucc.exe MakeCommandlet
ucc.exe MakeCommandletUtils.EditPackagesCommandlet 0 %project_name%
pause
goto compile