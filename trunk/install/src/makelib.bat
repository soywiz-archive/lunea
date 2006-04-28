@ECHO OFF
SET PATH2=%PATH%
SET PATH_BACK=%CD%
SET PATH=%CD%\..\..\dm\bin\;%CD%\..\..\dmd\bin\;%PATH2%

CD phobos
REM MAKE.EXE -fwin32.mak phobos.lib > NUL 2> NUL
MAKE.EXE -fwin32.mak phobos.lib
CD %PATH_BACK%
COPY /Y phobos\phobos.lib ..\lib\phobos.lib > NUL 2> NUL

SET PATH=%PATH2%
SET PATH2=