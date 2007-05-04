@echo off
cls
dmd lib\SDL.lib src\sdl\sdl.d src\gb\z80.d src\gb\keypad.d src\gb\lcd.d src\gb\common.d src\gb\memory.d src\gb\tables.d gdi32.lib -run src\winsdlmain.d
