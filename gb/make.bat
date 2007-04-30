@echo off
cls
dmd gameboy SDL SDL.lib common memory tables gdi32.lib -run winmain
