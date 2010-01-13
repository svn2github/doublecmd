#!/bin/bash
# Build all plugins

# This script run from _make.sh
# If you run it direct, set up $lazpath first

# CD to plugins directory
pushd plugins

# WCX plugins
$lazpath/lazbuild wcx/cpio/src/cpio.lpi $DC_ARCH
$lazpath/lazbuild wcx/deb/src/deb.lpi $DC_ARCH
$lazpath/lazbuild wcx/lzma/src/lzma.lpi $DC_ARCH
$lazpath/lazbuild wcx/rpm/src/rpm.lpi $DC_ARCH
$lazpath/lazbuild wcx/unbz2/src/unbz2.lpi $DC_ARCH
$lazpath/lazbuild wcx/unrar/src/unrar.lpi $DC_ARCH
$lazpath/lazbuild wcx/zip/src/Zip.lpi $DC_ARCH

# WDX plugins
$lazpath/lazbuild wdx/rpm_wdx/src/rpm_wdx.lpi $DC_ARCH
$lazpath/lazbuild wdx/deb_wdx/src/deb_wdx.lpi $DC_ARCH

# WLX plugins
$lazpath/lazbuild wlx/WlxMplayer/src/wlxMplayer.lpi $DC_ARCH

# DSX plugins
$lazpath/lazbuild dsx/DSXLocate/src/DSXLocate.lpi $DC_ARCH

# Strip and rename WCX
pushd wcx/cpio/lib/
strip --strip-all cpio.so
mv cpio.so cpio.wcx
popd

pushd wcx/deb/lib/
strip --strip-all deb.so
mv deb.so deb.wcx
popd

pushd wcx/lzma/lib/
strip --strip-all lzma.so
mv lzma.so lzma.wcx
popd

pushd wcx/rpm/lib/
strip --strip-all rpm.so
mv rpm.so rpm.wcx
popd

pushd wcx/unbz2/lib/
strip --strip-all unbz2.so
mv unbz2.so unbz2.wcx
popd

pushd wcx/unrar/lib/
strip --strip-all unrar.so
mv unrar.so unrar.wcx
popd

pushd wcx/zip/lib/
strip --strip-all Zip.so
mv Zip.so zip.wcx
popd

# Strip and rename WDX
pushd wdx/rpm_wdx/lib/
strip --strip-all rpm_wdx.so
mv rpm_wdx.so rpm_wdx.wdx
popd

pushd wdx/deb_wdx/lib/
strip --strip-all deb_wdx.so
mv deb_wdx.so deb_wdx.wdx
popd

# Strip and rename WLX
pushd wlx/WlxMplayer/lib/
strip --strip-all wlxMplayer.so
mv wlxMplayer.so wlxMplayer.wlx
popd

# Strip and rename DSX
pushd dsx/DSXLocate/lib/
strip --strip-all DSXLocate.so
mv DSXLocate.so DSXLocate.dsx
popd

# Return from plugins directory
popd