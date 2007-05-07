@echo off
call build_common.bat
%GB_D_COMPILER% %GB_D_LIB% %GB_D_INCLUDES% %GB_D_MODULES% %GB_D_MAIN% -ofgameboy.exe
del *.obj
del gameboy.map
upx gameboy.exe
