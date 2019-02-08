@echo off

for %%* in (.) do set project_name=%%~n*

cd ..
cd System
del %project_name%.u
del %project_name%.ucl
del %project_name%.int