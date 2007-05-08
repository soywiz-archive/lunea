@echo off

SET GB_D_LIB=lib\pdcurses.lib gdi32.lib
SET GB_D_INCLUDES=src\curses\pdcurses.d
SET GB_D_MODULES=src\gb\z80.d src\gb\joypad.d src\gb\lcd.d src\gb\common.d src\gb\memory.d src\gb\tables.d

SET GB_D_COMPILER=dfl
SET GB_D_MAIN=src\windflmain.d src\gameboy.res

del /q gameboy.exe
rcc src\gameboy.rc -osrc\gameboy.res
%GB_D_COMPILER% -release %GB_D_MAIN% %GB_D_LIB% %GB_D_INCLUDES% %GB_D_MODULES% -ofgameboy.exe
del *.obj
del gameboy.map
if NOT EXIST "gameboy.exe" GOTO end
cls
gameboy.exe
:end
