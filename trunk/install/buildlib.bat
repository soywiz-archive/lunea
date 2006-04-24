@ECHO off

ECHO Construyendo PHOBOS.LIB...

CD ..\bin\dmd\src

IF NOT EXIST "..\..\..\install\phobos_patch.7z" GOTO mod_src

..\..\..\install\7z x -y -bd ..\..\..\install\phobos_patch.7z > NUL 2>NUL

IF NOT EXIST "..\..\..\install\src" GOTO finish_install

XCOPY /S /Q /Y /I ..\..\..\install\src . > NUL 2> NUL

CALL makelib.bat

CD ..\..\..\install

:finish_install
