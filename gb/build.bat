@echo off
dmd lib\SDL.lib src\sdl\sdl.d src\gb\z80.d src\gb\common.d src\gb\memory.d src\gb\tables.d gdi32.lib src\winsdlmain.d -ofgameboy.exe
del *.obj
del gameboy.map
upx gameboy.exe
