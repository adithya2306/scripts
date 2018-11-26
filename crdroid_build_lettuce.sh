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

BUILDDATE=$(date +%Y%m%d)
lunch lineage_lettuce-userdebug

mka bacon

if [ $? -eq 0 ]; then
    echo -e "\nROM compiled succesfully :-) Now uploading ROM zip to gdrive ...\n"
    gdrive upload $CR_DIR/out/target/product/lettuce/crDroidAndroid-9.0-$BUILDDATE-*
    if [ $? -eq 0 ]; then
        echo -e "\nERROR occured while uploading ROM zip to gdrive :< EXITING ..."
        exit 1
    fi
else
    echo -e "\nERROR OCCURED DURING COMPILATION :'( EXITING ..."
    exit 1
fi
