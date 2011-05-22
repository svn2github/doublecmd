@echo off

rem Build all plugins

rem This script is run from build.bat.
rem If you run it directly set %lazpath% first
rem or have lazbuild in your PATH.

rem CD to plugins directory
pushd plugins

rem WCX plugins
lazbuild wcx\cpio\src\cpio.lpi %DC_ARCH%
lazbuild wcx\deb\src\deb.lpi %DC_ARCH%
lazbuild wcx\lzma\src\lzma.lpi %DC_ARCH%
lazbuild wcx\rpm\src\rpm.lpi %DC_ARCH%
lazbuild wcx\unbz2\src\unbz2.lpi %DC_ARCH%
lazbuild wcx\unrar\src\unrar.lpi %DC_ARCH%
lazbuild wcx\zip\src\zip.lpi %DC_ARCH%

rem WDX plugins
lazbuild wdx\rpm_wdx\src\rpm_wdx.lpi %DC_ARCH%
lazbuild wdx\deb_wdx\src\deb_wdx.lpi %DC_ARCH%

rem WFX plugins
lazbuild wfx\ftp\src\ftp.lpi %DC_ARCH%
lazbuild wfx\network\src\network.lpi %DC_ARCH%

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

rem Strip and rename WFX
pushd wfx\ftp\lib\
strip --strip-all ftp.dll
rename ftp.dll ftp.wfx
popd

pushd wfx\network\lib\
strip --strip-all network.dll
rename network.dll network.wfx
popd

rem Return from plugins directory
popd