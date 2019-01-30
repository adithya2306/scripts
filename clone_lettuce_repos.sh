#!/bin/bash
# Script to clone device sources for lettuce

read -p "Enter branch name of device tree (default lineage-16.0): " DEVICE_BRANCH
read -p "Enter branch name of remaining trees (default lineage-16.0): " BRANCH

ORGANIZATION='https://github.com/lettuce-pie'
if [ -z "$BRANCH"]; then BRANCH="lineage-16.0"; fi
if [ -z "$DEVICE_BRANCH"]; then DEVICE_BRANCH="lineage-16.0"; fi

echo -e "\n============== CLONING DEVICE TREE ==============\n"
git clone -b $DEVICE_BRANCH "$ORGANIZATION"'/android_device_yu_lettuce' device/yu/lettuce

echo -e "\n============== CLONING VENDOR TREE ==============\n"
git clone -b $BRANCH "$ORGANIZATION"'/proprietary_vendor_yu' vendor/yu

echo -e "\n============== CLONING KERNEL ==============\n"
git clone -b $BRANCH "$ORGANIZATION"'/android_kernel_cyanogen_msm8916' kernel/cyanogen/msm8916

echo -e "\n============== DONE ==============\n"
