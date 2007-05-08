@echo off

SET GB_D_COMPILER=dfl
SET GB_D_LIB=lib\pdcurses.lib gdi32.lib
SET GB_D_INCLUDES=src\curses\pdcurses.d
SET GB_D_MODULES=src\gb\z80.d src\gb\joypad.d src\gb\lcd.d src\gb\common.d src\gb\memory.d src\gb\tables.d
SET GB_D_MAIN_DFL=src\gui\main.d src\gui\about.d
SET GB_D_RESOURCES=src\gui\gameboy.res

del /q gameboy.exe 2> NUL
rcc src\gui\gameboy.rc -osrc\gui\gameboy.res
%GB_D_COMPILER% -release %GB_D_MAIN_DFL% %GB_D_RESOURCES% %GB_D_LIB% %GB_D_MODULES% %GB_D_INCLUDES% -ofgameboy.exe
del /q *.obj 2> NUL
del /q gameboy.map 2> NUL
del /q %GB_D_RESOURCES% 2> NUL
if NOT EXIST "gameboy.exe" GOTO end
cls
gameboy.exe
:end
