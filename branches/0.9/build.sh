#!/bin/sh 

set -e

# if you compile first time you must change variable "lazpath" and "lcl"
# after it execute this script with parameter "all" at doublecmd dir 
# "./build.sh all" it build doublecmd
#                                                 by Attid


# You can execute this script with different parameters:
# components - compiling components needed for DC
# plugins - compiling all DC plugins
# all - compiling components, plugins and DC
# default - compiling DC only (using by default)

# path to lazbuild
export lazbuild=$(which lazbuild)

# Set up widgetset: gtk or gtk2 or qt
# Set up processor architecture: i386 or x86_64
if [ $2 ]
  then export lcl=$2
fi
if [ $lcl ] && [ $CPU_TARGET ]
  then export DC_ARCH=$(echo "--widgetset=$lcl")" "$(echo "--cpu=$CPU_TARGET")
elif [ $lcl ]
  then export DC_ARCH=$(echo "--widgetset=$lcl")
elif [ $CPU_TARGET ]
  then export DC_ARCH=$(echo "--cpu=$CPU_TARGET")
fi

build_default()
{
  $lazbuild src/doublecmd.lpi $DC_ARCH
  
  strip doublecmd
}

build_beta()
{
  components/build.sh
  plugins/build.sh
  
  # Build Double Commander
  $lazbuild src/doublecmd.lpi --bm=beta $DC_ARCH
  
  # Build Dwarf LineInfo Extractor
  $lazbuild tools/extractdwrflnfo.lpi
  
  # Extract debug line info
  chmod a+x tools/extractdwrflnfo
  if [ -f doublecmd.dSYM/Contents/Resources/DWARF/doublecmd ]; then
    mv -f doublecmd.dSYM/Contents/Resources/DWARF/doublecmd $(pwd)/doublecmd.dbg
  fi
  tools/extractdwrflnfo doublecmd.dbg
  
  # Strip debug info
  strip doublecmd
}

build_all()
{
  components/build.sh
  plugins/build.sh
  build_default
}


case $1 in
  components)  components/build.sh;;
     plugins)  plugins/build.sh;;
        beta)  build_beta;;
         all)  build_all;;
           *)  build_default;;
esac
