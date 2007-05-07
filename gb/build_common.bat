@echo off
SET GB_D_LIB=lib\SDL.lib lib\pdcurses.lib gdi32.lib
SET GB_D_INCLUDES=src\sdl\sdl.d src\curses\pdcurses.d
SET GB_D_MODULES=src\gb\z80.d src\gb\joypad.d src\gb\lcd.d src\gb\common.d src\gb\memory.d src\gb\tables.d

GOTO DFL

:SDL
SET GB_D_COMPILER=dmd
SET GB_D_MAIN=src\winsdlmain.d
GOTO END

:DFL
SET GB_D_COMPILER=dfl
SET GB_D_MAIN=src\windflmain.d
GOTO END

:END

