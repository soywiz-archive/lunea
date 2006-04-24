@echo off

SET SUCCESS=1

SET RETERR=reterr1
@dir /D dm*c.zip > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO notex1

:reterr1

SET RETERR=reterr2
@dir /D bup.zip > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO notex2

:reterr2

SET RETERR=reterr3
@dir /D dmd*.zip > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO notex3

:reterr3

IF %SUCCESS%==0 GOTO insterroend

GOTO install

:notex1
echo NO EXISTE EL FICHERO "dm*c.zip" ( Digital Mars C/C++ Compiler Version 8.47 )
echo DEBE BAJARLO DE http://www.digitalmars.com/download/dmcpp.html
SET SUCCESS=0
GOTO %RETERR%

:notex2
echo NO EXISTE EL FICHERO "bup.zip" ( Basic Utilities )
echo DEBE BAJARLO DE http://www.digitalmars.com/download/dmcpp.html
SET SUCCESS=0
GOTO %RETERR%

:notex3
echo NO EXISTE EL FICHERO "dmd*.zip" ( Digital Mars D Compiler )
echo DEBE BAJARLO DE http://www.digitalmars.com/d/changelog.html
SET SUCCESS=0
GOTO %RETERR%

:install
echo Instalando...
echo Descomprimiendo dmc.zip...
unzip -u -o dm*c.zip  -d ..\bin > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO insterror
echo Descomprimiendo dmd.zip...
unzip -u -o dmd*.zip -d ..\bin > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO insterror
echo Descomprimiendo bup.zip...
unzip -u -o bup.zip  -d ..\bin > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO insterror
cd ..\bin\dmd\src

IF NOT EXIST "..\..\..\install\phobos_patch.7z" GOTO mod_src

echo Descomprimiendo phobos_patch.7z...
..\..\..\install\7z x -y -bd ..\..\..\install\phobos_patch.7z > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO insterror

:mod_src

IF NOT EXIST "..\..\..\install\src" GOTO finish_install

echo Copiando cambios del directorio SRC...
XCOPY /S /Q /Y /I ..\..\..\install\src . > NUL 2> NUL
echo Compilando librería PHOBOS.LIB...
@CALL makelib.bat > NUL
cd ..\..\..\install
IF NOT %ERRORLEVEL%==0 GOTO insterror

:finish_install

echo Instalacion completada satisfactoriamente
GOTO end

:insterror
echo HUBO UN ERROR AL INSTALAR

:insterroend
PAUSE

:end