rem Build all plugins

rem This script run from _make.bat
rem If you run it direct, set up %lazpath% first

rem CD to plugins directory
pushd plugins

rem WCX plugins
%lazpath%\lazbuild.exe wcx\cpio\src\cpio.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wcx\deb\src\deb.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wcx\lzma\src\lzma.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wcx\rpm\src\rpm.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wcx\unbz2\src\unbz2.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wcx\unrar\src\unrar.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wcx\zip\src\zip.lpi %DC_ARCH%

rem WDX plugins
%lazpath%\lazbuild.exe wdx\rpm_wdx\src\rpm_wdx.lpi %DC_ARCH%
%lazpath%\lazbuild.exe wdx\deb_wdx\src\deb_wdx.lpi %DC_ARCH%

rem Strip and rename WCX
pushd wcx\cpio\lib\
strip --strip-all cpio.dll
rename cpio.dll cpio.wcx
popd

pushd wcx\deb\lib\
strip --strip-all deb.dll
rename deb.dll deb.wcx
popd

pushd wcx\lzma\lib\
strip --strip-all lzma.dll
rename lzma.dll lzma.wcx
popd

pushd wcx\rpm\lib\
strip --strip-all rpm.dll
rename rpm.dll rpm.wcx
popd

pushd wcx\unbz2\lib\
strip --strip-all unbz2.dll
rename unbz2.dll unbz2.wcx
popd

pushd wcx\unrar\lib\
strip --strip-all unrar.dll
rename unrar.dll unrar.wcx
popd

pushd wcx\zip\lib\
strip --strip-all zip.dll
rename zip.dll zip.wcx
popd

rem Strip and rename WDX
pushd wdx\rpm_wdx\lib\
strip --strip-all rpm_wdx.dll
rename rpm_wdx.dll rpm_wdx.wdx
popd

pushd wdx\deb_wdx\lib\
strip --strip-all deb_wdx.dll
rename deb_wdx.dll deb_wdx.wdx
popd

rem Return from plugins directory
popd