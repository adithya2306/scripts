#!/bin/bash
#
# Script to build any android ROM for any device and upload it to Google Drive or transfer.sh.
# Not recommended for retarded build butts.
#
# Usage (in root of source):
# 	./build_rom.sh [options]
#
# See below for options.
#

# Set defaults
MAKE_TARGET="bacon"
CCACHE_DIR="$HOME/.ccache"
OUT_DIR="out"

# Spit out usage info when there are no arguments
if [[ $# -eq 0 ]]; then
	echo -e "\nUsage: ./build_rom.sh [options]\n"
	echo "Options:"
	echo "  -l, --lunch-command <value>    The lunch command e.g. lineage_A6020-userdebug"
	echo "  -m, --make-target <value>      Compilation target name e.g. bacon or bootimage"
	echo "                                 Default: bacon"
	echo "  -n, --custom-target            Set this if you are compiling something other"
	echo "                                 than the flashable ROM zip, e.g. bootimage"
	echo "  -c, --clean                    Perform a clean build"
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
	-o|--out) OUT_DIR="$2"; shift;;
	-C|--ccache-dir) CCACHE_DIR="$2"; shift;;
	*) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# Abort if lunch command isn't specified
if [[ -z $LUNCH ]]; then echo "ERROR: Lunch command not specified! Aborting ..."; exit 1; fi

# Set the ccache and build output directories
export CCACHE_DIR=$CCACHE_DIR
export OUT_DIR_COMMON_BASE=$OUT_DIR

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
ccache -M 500G

# Spit out some build info
echo -e "\nDevice: $DEVICE \nROM Source directory: $(pwd) \nCCACHE directory: $CCACHE_DIR \nOutput directory: $OUT_DIR \nMake target: $MAKE_TARGET \n"

# Do cleanup if user has specified it
if [[ -n $CLEAN ]]; then echo -e "Clearing output directory ...\n"; rm -rf out; fi

# Aaaand... begin compilation!
source build/envsetup.sh
lunch "$LUNCH"

# Equivalent of "mka" command, modified to use 2 x (no. of cores) threads for compilation
if schedtool -B -n 1 -e ionice -n 1 make -j$(($(nproc --all) * 2)) "$MAKE_TARGET"; then
	if [[ -z $CUSTOM ]]; then
		echo -e "\nROM compiled succesfully :-) \n"

		# Get the path of the output zip. Few ROMs generate an intermediate otapackage zip
		# along with the actual flashable zip, so in order to pick that one out, I'll be
		# using a simple logic. Most of the ROMs that generate the intermediate zip also
		# generate an md5sum of the actual flashable zip. I'll simply get the filename 
		# of that md5sum and put .zip in front of it to get the actual zip's path! :)
		if [ "$(ls "$OUT_DIR/target/product/$DEVICE/*.zip" | wc -l)" -gt 1 ]; then
			zippath=$(sed "s/\.md5sum//" <<< "$(ls "$OUT_DIR"/target/product/"$DEVICE"/*.md5sum)")
		else
			zippath=$(ls "$OUT_DIR/target/product/$DEVICE/*.zip")
		fi

		# Upload the ROM to google drive if it's available, else upload to transfer.sh
		if [ -x "$(command -v gdrive)" ]; then
			echo -e "Uploading ROM to Google Drive using gdrive CLI ..."
			# In some cases when the gdrive CLI is not set up properly, upload fails.
			# In that case upload it to transfer.sh itself
			if ! gdrive upload --share "$zippath"; then
				echo -e "\nAn error occured while uploading to Google Drive."
				echo "Uploading ROM zip to transfer.sh..."
				echo "ROM zip uploaded succesfully to $(curl -sT "$zippath" https://transfer.sh/"$(basename "$zippath")")"
			fi
		else
			echo "Uploading ROM zip to transfer.sh..."
			echo "ROM zip uploaded succesfully to $(curl -sT "$zippath" https://transfer.sh/"$(basename "$zippath")")"
		fi

		# Move the zip to the root of the source to prevent conflicts in future builds
		cp "$zippath" .
		rm -rf "$OUT_DIR"/target/product/"$DEVICE"/*.zip*
		echo -e "\nROM zip copied here; deleted from outdir. Good bye! \n"
		exit 0
	else echo -e "\n $MAKE_TARGET compiled succesfully :-) Good bye! \n"; fi
else echo -e "\nERROR OCCURED DURING COMPILATION :'( EXITING ... \n"; exit 1; fi
