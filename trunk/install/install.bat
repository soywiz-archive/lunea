@echo off

@dir /D dm*c.zip > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO notex1

@dir /D bup.zip > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO notex2

@dir /D dmd*.zip > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO notex3

GOTO install

:notex1
echo NO EXISTE EL FICHERO "dm*c.zip"
echo DEBE BAJARLO DE http://www.digitalmars.com/download/dmcpp.html
GOTO insterroend

:notex2
echo NO EXISTE EL FICHERO "bup.zip"
echo DEBE BAJARLO DE http://www.digitalmars.com/download/dmcpp.html
GOTO insterroend

:notex3
echo NO EXISTE EL FICHERO "dmd*.zip"
echo DEBE BAJARLO DE http://www.digitalmars.com/d/changelog.html
GOTO insterroend

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
echo Descomprimiendo phobos_patch.7z...
cd ..\bin\dmd\src
..\..\..\install\7z x -y -bd ..\..\..\install\phobos_patch.7z > NUL 2> NUL
IF NOT %ERRORLEVEL%==0 GOTO insterror
echo Modificando el directorio SRC...
XCOPY /S /Q /Y /I ..\..\..\install\src . > NUL 2> NUL
echo Compilando librería PHOBOS.LIB...
@CALL makelib.bat > NUL
cd ..\..\..\install
IF NOT %ERRORLEVEL%==0 GOTO insterror

echo Instalacion completada satisfactoriamente
GOTO end

:insterror
echo HUBO UN ERROR AL INSTALAR

:insterroend
PAUSE

:end