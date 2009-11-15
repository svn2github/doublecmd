
rem Set Double Commander version
set DC_VER=0.4.5

rem Path to subversion
set SVN_EXE="c:\Program Files\svn-win32-1.6.5\bin\svn.exe"

rem Path to Inno Setup compiler
set ISCC_EXE="c:\Program Files\Inno Setup 5\ISCC.exe"

rem The new package will be created from here
set BUILD_PACK_DIR=%TEMP%\doublecmd-%DATE%

rem The new package will be saved here
set PACK_DIR=%CD%\windows\release

rem Create temp dir for building
set BUILD_DC_TMP_DIR=%TEMP%\doublecmd-%DC_VER%
rm -rf %BUILD_DC_TMP_DIR%
%SVN_EXE% export ..\ %BUILD_DC_TMP_DIR%

rem Save revision number
mkdir %BUILD_DC_TMP_DIR%\.svn
copy ..\.svn\entries %BUILD_DC_TMP_DIR%\.svn\

rem Prepare package build dir
rm -rf %BUILD_PACK_DIR%
mkdir %BUILD_PACK_DIR%
mkdir %BUILD_PACK_DIR%\release

rem Copy needed files
copy windows\doublecmd.iss %BUILD_PACK_DIR%\
copy windows\portable.diff %BUILD_PACK_DIR%\

rem Copy libraries
copy windows\lib\*.dll %BUILD_DC_TMP_DIR%\

cd /D %BUILD_DC_TMP_DIR%

rem Get processor architecture
if "%DC_ARCH%" == "" (
  if "%PROCESSOR_ARCHITECTURE%" == "x86" (
    set DC_ARCH=i386
  ) else if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
    set DC_ARCH=x86_64
  )
)

rem Build all components of Double Commander
call _make.bat all

rem Prepare install files
call %BUILD_DC_TMP_DIR%\install\windows\install.bat

cd /D %BUILD_PACK_DIR%
rem Create *.exe package
%ISCC_EXE% doublecmd.iss

rem Move created package
move release\*.exe %PACK_DIR%

rem Create *.zip package
patch doublecmd/doublecmd.ini portable.diff
zip -9 -Dr %PACK_DIR%\doublecmd-%DC_VER%.%DC_ARCH%-win32.zip doublecmd 

rem Clean temp directories
cd \
rm -rf %BUILD_DC_TMP_DIR%
rm -rf %BUILD_PACK_DIR%