@echo off
call build_common.bat
del /q gameboy.exe
%GB_D_COMPILER% -release %GB_D_MAIN% %GB_D_LIB% %GB_D_INCLUDES% %GB_D_MODULES% -ofgameboy.exe
del *.obj
del gameboy.map
if NOT EXIST "gameboy.exe" GOTO end
cls
gameboy.exe
cls
:end
