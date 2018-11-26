CR_DIR=/home/adithya/cr

export USE_CCACHE=1
export CCACHE_DIR=$CR_DIR
export CCACHE_NOCOMPRESS=true

cd $CR_DIR

echo -e "\nCCACHE directory: $CCACHE_DIR\n"

if [[ $CR_BUILD_TYPE = "clean" ]]; then
    echo -e "\nClean build selected. Deleting outdir\n"
    rm -rf out
elif [[ $CR_BUILD_TYPE = "superclean" ]]; then
    echo -e "\nSuperclean build selected. Deleting outdir & ccache\n"
    ccache -C
    rm -rf out
fi

. build/envsetup.sh
lunch lineage_lettuce-userdebug
mka bacon
