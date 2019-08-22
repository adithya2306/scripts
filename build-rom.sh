#!/bin/bash
#
# Script to build any android ROM for any device and upload it to Google Drive or transfer.sh.
# Not recommended for retarded build butts.
#
# Usage (in root of source):
# 	./build-rom.sh [options]
#
# See below for options.
#

# Set defaults
MAKE_TARGET="bacon"
CCACHE_DIR="$HOME/.ccache"

# Spit out usage info when there are no arguments
if [[ $# -eq 0 ]]; then
	echo -e "\nUsage: ./build-rom.sh [options]\n"
	echo "Options:"
	echo "  -l, --lunch-command <value>    The lunch command e.g. lineage_A6020-userdebug"
	echo "  -m, --make-target <value>      Compilation target name e.g. bacon or bootimage"
	echo "                                 Default: bacon"
	echo "  -n, --custom-target            Set this if you are compiling something other"
	echo "                                 than the flashable ROM zip, e.g. bootimage"
	echo "  -c, --clean                    Perform a clean build"
	echo "  -s, --sync                     Sync the sources (repo sync) before building"
	echo "  -o, --out <path>               Full or relative path to the output directory"
	echo "                                 Default: <ROM source root>/out"
	echo "  -C, --ccache-dir <path>        Full or relative path to the ccache directory"
	echo "                                 Default: $HOME/.ccache"
	echo ""
	exit 0
fi

# Parse arguments
while [[ "$#" -gt 0 ]]; do case $1 in
	-l|--lunch) LUNCH="$2"; shift;;
	-m|--make-target) MAKE_TARGET="$2"; shift;;
	-n|--custom-target) CUSTOM=1;;
	-c|--clean) CLEAN=1;;
	-s|--sync) SYNC=1;;
	-o|--out) OUTDIR="$2"; shift;;
	-C|--ccache-dir) CCACHE_DIR="$2"; shift;;
	*) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Abort if lunch command isn't specified
if [[ -z $LUNCH ]]; then echo "ERROR: Lunch command not specified! Aborting ..."; exit 1; fi

# Get the device name from the lunch command
DEVICE=$(sed -e "s/^.*_//" -e "s/-.*//" <<< "$LUNCH")

# Limit java's RAM usage to half if system has <16GB RAM
memsize=$(($(grep MemTotal /proc/meminfo | awk '{print $2}')/(1024 * 1024)))
if [ $memsize -lt 16 ]; then
	export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx$((memsize/2))g"
	export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx$((memsize/2))g"
fi

# Enable CCACHE
export USE_CCACHE=1
export CCACHE_NOCOMPRESS=true
ccache -M 500G &>/dev/null

# Set the ccache and build output directories
export CCACHE_DIR
if [[ -n $OUTDIR ]]; then export OUTDIR_COMMON_BASE=$OUTDIR
else OUTDIR=$(pwd)/out; fi

# Spit out some build info
echo -e "\nDevice: $DEVICE \nROM Source directory: $(pwd) \nCCACHE directory: $CCACHE_DIR \nOutput directory: $OUTDIR \nMake target: $MAKE_TARGET \n"

# Do a quick repo sync if specified
if [[ -n $SYNC ]]; then
	echo -e "Syncing sources ...\n"
	if ! schedtool -B -n 1 -e ionice -n 1 "$(command -v repo)" sync -c -f --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j8; then
		echo -e "\nError occured while syncing! Continuing with the build ...\n"
	fi
fi

# Do cleanup if user has specified it
if [[ -n $CLEAN ]]; then echo -e "Clearing output directory ...\n"; rm -rf out; fi

# Aaaand... begin compilation!
source build/envsetup.sh
echo -e "\nStarting build ...\n"
SECONDS=0	# Reset bash timer
lunch "$LUNCH"
if mka "$MAKE_TARGET"; then
	if [[ -z $CUSTOM ]]; then
		echo -e "\nBuild completed succesfully in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) :-) \n"

		zipdir=$(get_build_var PRODUCT_OUT)
		zippath=$(ls "$zipdir"/*2019*.zip | tail -n -1)

		# Upload the ROM to google drive if it's available, else upload to transfer.sh
		if [ -x "$(command -v gdrive)" ]; then
			echo -e "Uploading ROM to Google Drive using gdrive CLI ..."
			# In some cases when the gdrive CLI is not set up properly, upload fails.
			# In that case upload it to transfer.sh itself
			if ! gdrive upload --share "$zippath"; then
				echo -e "\nAn error occured while uploading to Google Drive."
				echo "Uploading ROM zip to transfer.sh..."
				echo "ROM zip uploaded succesfully: $(curl -sT "$zippath" https://transfer.sh/"$(basename "$zippath")")"
			fi
		else
			echo "Uploading ROM zip to transfer.sh..."
			echo "ROM zip uploaded succesfully: $(curl -sT "$zippath" https://transfer.sh/"$(basename "$zippath")")"
		fi
		echo -e "\n Good bye!"
		exit 0
	else echo -e "\n $MAKE_TARGET compiled succesfully in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) :-) Good bye! \n"; fi
else echo -e "\nERROR OCCURED DURING COMPILATION :'( EXITING ... \n"; exit 1; fi
