@echo off
call build_common.bat
dmd %GB_D_LIB% %GB_D_INCLUDES% %GB_D_MODULES% -run %GB_D_MAIN%
