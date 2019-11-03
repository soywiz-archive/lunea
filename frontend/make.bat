@echo off
@md ..\bin > NUL 2> NUL

@..\bin\dm\bin\rcc res\lunea.rc -32 -ores\lunea.res

if NOT ERRORLEVEL 0 GOTO delend

@..\bin\dmd\bin\dmd src\main src\config src\ini src\compile src\ltoken src\lparser src\util res\lunea.res -oflunea.exe -of..\bin\lunea.exe -O -release

if NOT ERRORLEVEL 0 GOTO delend

..\bin\upx.exe --force ..\bin\lunea.exe > NUL 2> NUL

:delend

@del /F /Q lunea.map > NUL 2> NUL
@del /F /Q *.obj > NUL 2> NUL
@del /F /Q res\lunea.res > NUL 2> NUL
