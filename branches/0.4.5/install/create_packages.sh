#!/bin/sh

# Set Double Commander version
DC_VER=0.4.5.2

# The new package will be saved here
PACK_DIR=$(pwd)/linux/release

# Temp dir for creating *.tar.bz2 package
BUILD_PACK_DIR=/var/tmp/doublecmd-$(date +%y.%m.%d)

# Create temp dir for building
BUILD_DC_TMP_DIR=/var/tmp/doublecmd-$DC_VER
rm -rf $BUILD_DC_TMP_DIR
svn export ../ $BUILD_DC_TMP_DIR

# Save revision number
mkdir $BUILD_DC_TMP_DIR/.svn
cp -a ../.svn/entries $BUILD_DC_TMP_DIR/.svn/

# Copy package description file
cp linux/description-pak $BUILD_DC_TMP_DIR/

# Set widgetset
if [ -z $1 ]
  then export lcl=gtk2
  else export lcl=$1
fi

# Set processor architecture
if [ -z $CPU_TARGET ] 
  then export CPU_TARGET=$(fpc -iTP)
fi

# Debian package architecture
if [ "$CPU_TARGET" = "x86_64" ]
  then
    export DEB_ARCH="amd64"
  else
    export DEB_ARCH=$CPU_TARGET
fi

# Copy libraries
cp -a linux/lib/$CPU_TARGET/*.so         $BUILD_DC_TMP_DIR/
cp -a linux/lib/$CPU_TARGET/$lcl/*.so    $BUILD_DC_TMP_DIR/

cd $BUILD_DC_TMP_DIR

# Build all components of Double Commander
./_make.sh all

# Export variables for checkinstall
export MAINTAINER="Alexander Koblov <Alexx2000@mail.ru>"

# Create *.rpm package

checkinstall -R --default --pkgname=doublecmd --pkgversion=$DC_VER --pkgarch=$CPU_TARGET --pkgrelease=1.$lcl --pkglicense=GPL --pkggroup=Applications/File --nodoc --pakdir=$PACK_DIR $BUILD_DC_TMP_DIR/install/linux/install.sh

# Create *.deb package

checkinstall -D --default --pkgname=doublecmd --pkgversion=$DC_VER --pkgarch=$DEB_ARCH --pkgrelease=1.$lcl --pkglicense=GPL --pkggroup=contrib/misc --requires=libx11-6 --nodoc --pakdir=$PACK_DIR $BUILD_DC_TMP_DIR/install/linux/install.sh

# Create *.tgz package

checkinstall -S --default --pkgname=doublecmd --pkgversion=$DC_VER --pkgarch=$CPU_TARGET --pkgrelease=1.$lcl --pkglicense=GPL --pkggroup=Applications/File --nodoc --pakdir=$PACK_DIR $BUILD_DC_TMP_DIR/install/linux/install.sh

# Create *.tar.bz2 package

mkdir -p $BUILD_PACK_DIR
install/linux/install.sh $BUILD_PACK_DIR
cd $BUILD_PACK_DIR
sed -i -e 's/UseIniInProgramDir=0/UseIniInProgramDir=1/' doublecmd/doublecmd.ini
tar -cvjf $PACK_DIR/doublecmd-$DC_VER-1.$lcl.$CPU_TARGET.tar.bz2 doublecmd

# Create help packages ------------------------------------------------------------
cd $BUILD_DC_TMP_DIR
# Copy help files
install/linux/install-help.sh $BUILD_PACK_DIR
# Create help package for each language
cd $BUILD_PACK_DIR/doublecmd/doc
for HELP_LANG in `ls`
  do
    cd $BUILD_PACK_DIR/doublecmd
    tar -cvjf $PACK_DIR/doublecmd-help.$HELP_LANG-$DC_VER.noarch.tar.bz2 doc/$HELP_LANG
  done
# ---------------------------------------------------------------------------------

# Clean DC build dir
rm -rf $BUILD_DC_TMP_DIR
rm -rf $BUILD_PACK_DIR
