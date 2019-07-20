#!/bin/bash
# Script to clone my Android Pie device sources for bacon

read -pr "Enter branch name of device tree (default lineage-16.0): " DEVICE_BRANCH
read -pr "Enter branch name of remaining trees (default lineage-16.0): " BRANCH
read -pr "Building LineageOS/based ROM ? (Y/N) (default Y): " IS_LINEAGE

GITHUB='https://github.com/ghostrider-reborn'

if [ -z "$BRANCH" ]; then BRANCH="lineage-16.0"; fi
if [ -z "$DEVICE_BRANCH" ]; then DEVICE_BRANCH="lineage-16.0"; fi
if [ -z "$IS_LINEAGE" ]; then IS_LINEAGE="Y"; fi

echo -e "\n============== CLONING DEVICE TREE ==============\n"
git clone -b $DEVICE_BRANCH $GITHUB/android_device_oneplus_bacon device/oneplus/bacon

echo -e "\n============== CLONING VENDOR TREE ==============\n"
git clone -b $BRANCH $GITHUB/android_vendor_oneplus_bacon vendor/oneplus/bacon

echo -e "\n============== CLONING KERNEL ==============\n"
git clone -b $BRANCH $GITHUB/android_kernel_oneplus_msm8974 kernel/oneplus/msm8974

echo -e "\n============== CLONING OPPO/COMMON ==============\n"

case $IS_LINEAGE in
    Y|y) git clone -b lineage-16.0 https://github.com/LineageOS/android_device_oppo_common device/oppo/common ;;
    *) git clone -b baked-release https://github.com/PotatoDevices/device_oppo_common device/oppo/common ;; esac

git clone -b lineage-16.0 https://github.com/LineageOS/android_packages_resources_devicesettings packages/resources/devicesettings

echo -e "\n============== DONE ==============\n"

