#!/bin/bash
#
# Script to build any android ROM for any device and upload it to transfer.sh.
# Not recommended for build butts.
#
# Usage (in root of source):
#   MAKE_TARGET=<make_target> OUT_DIR=<out_dir> CCACHE_DIR=<ccache_dir> ./build_rom.sh <lunch_command> <build_type>
#
# <build_type> can be any of the following [set to "default" by default]:
#   "default": Performs a normal build i.e. does not delete the output dir before building.
#   "clean": Performs a clean build by deleting outdir before compiling.
#   "superclean": Performs a 100% clean build by deleting outdir and ccache dir before compiling.
#
# ProTip™: To set build type in a jenkins project, make a choice parameter with these values and
#          pass the choice name variable as argument.
#
# MAKE_TARGET is an optional flag specifying the name of the target to compile, and defaults to "bacon" (i.e. the target 
# name of the final flashable ROM zip). In case of AOSP/CAF-based ROMs where usually the command is "otapackage" and 
# not "bacon", set this flag accordingly. It can also be set to "bootimage" to compile the boot.img only.
#
# OUT_DIR and CCACHE_DIR too are optional arguments which can be used to specify the ccache dir and the build 
# output dir respectively. Defaults to "./out" and "~/.ccache" respectively. They should not contain spaces in between.
#

if [[ -z "$1" ]]; then echo "ERROR: Lunch command not specified! Aborting ..."; exit 1; fi

LUNCH=$1
DEVICE=$(sed -e "s/^.*_//" -e "s/-.*//" <<< $LUNCH)

if [ -n "$2" ]; then
    if [[ $2 = "default" ]] || [[ $2 = "clean" ]] || [[ $2 = "superclean" ]]; then
        BUILD_TYPE=$2
    else
        echo "ERROR: Invalid build type: $2. Aborting ..."
        exit 1
    fi
else
    BUILD_TYPE="default"
fi

if [[ -z "$MAKE_TARGET" ]]; then MAKE_TARGET="bacon"; fi

if [ -n "$CCACHE_DIR" ]; then export CCACHE_DIR=$CCACHE_DIR; else CCACHE_DIR="$HOME/.ccache"; fi

if [ -n "$OUT_DIR" ]; then export OUT_DIR_COMMON_BASE=$OUT_DIR; else OUT_DIR=out; fi

# Set java compilation mem usage limit to half if system has RAM lesser than 16GB
memsize=$(($(grep MemTotal /proc/meminfo | awk '{print $2}')/(1024 * 1024)))
if [ $memsize -lt 16 ]; then
    export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx$(($memsize/2))g"
    export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx$(($memsize/2))g"
fi

# Enable CCACHE
export USE_CCACHE=1
export CCACHE_NOCOMPRESS=true

echo -e "\nDevice: $DEVICE \nROM Source directory: $(pwd) \nCCACHE directory: $CCACHE_DIR \nOutput directory: $OUT_DIR \n"

if [[ $BUILD_TYPE = "clean" ]]; then
    echo -e "Clean build selected. Clearing outdir\n"
    rm -rf out
elif [[ $BUILD_TYPE = "superclean" ]]; then
    echo -e "Superclean build selected. Clearing outdir & ccache dir\n"
    ccache -C
    rm -rf out
fi

. build/envsetup.sh
lunch $LUNCH

# Equivalent of "mka" command, modified to use 2 x (no. of cores) threads for compilation
schedtool -B -n 1 -e ionice -n 1 make -j$(($(nproc --all) * 2)) $MAKE_TARGET
result=$?

if [ $result -eq 0 ] && [[ $MAKE_TARGET != "bootimage" ]]; then
    echo -e "\nROM compiled succesfully :-) \n"

    if [ $(ls $OUT_DIR/target/product/$DEVICE/*.zip | wc -l) -gt 1 ]; then
        zippath=$(sed "s/\.md5sum//" <<< $(ls $OUT_DIR/target/product/$DEVICE/*.md5sum))
    else
        zippath=$(ls $OUT_DIR/target/product/$DEVICE/*.zip)
    fi

    if [ -x "$(command -v gdrive)" ]; then
        echo -e "Uploading ROM to Google Drive using gdrive CLI ..."
        gdrive upload --share $zippath
    else
        echo "Uploading ROM zip to transfer.sh..."
        echo -e "ROM zip uploaded succesfully to $(curl -sT $zippath https://transfer.sh/$(basename $zippath))"
    fi

    cp $zippath .
    rm -rf $OUT_DIR/target/product/$DEVICE/*.zip*
    echo -e "\nROM zip copied here; deleted from outdir. Good bye! \n"
    exit 0
elif [ $result -eq 0 ]; then
    echo -e "\n $MAKE_TARGET compiled succesfully :-) Good bye! \n"
else
    echo -e "\nERROR OCCURED DURING COMPILATION :'( EXITING ... \n"
    exit 1
fi
