@echo off
dmd gameboy SDL SDL.lib common memory tables gdi32.lib winmain
del *.obj
del gameboy.map
upx gameboy.exe
