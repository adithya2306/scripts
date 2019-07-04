#!/bin/bash
# Script to clone my Android Pie device sources for A6020 (Lenovo K5)

read -p "Enter branch name of device tree (default 'pie'): " DEVICE_BRANCH
read -p "Enter branch name of remaining trees (default 'pie'): " BRANCH

GITHUB='https://github.com/ghostrider-reborn'

if [ -z "$BRANCH" ]; then BRANCH="pie"; fi
if [ -z "$DEVICE_BRANCH" ]; then DEVICE_BRANCH="pie"; fi

echo -e "\n============== CLONING DEVICE TREE ==============\n"
git clone -b $DEVICE_BRANCH $GITHUB/android_device_lenovo_A6020 device/lenovo/A6020

echo -e "\n============== CLONING VENDOR TREE ==============\n"
git clone -b $BRANCH $GITHUB/android_vendor_lenovo_A6020 vendor/lenovo/A6020

echo -e "\n============== CLONING KERNEL ==============\n"
git clone -b $BRANCH $GITHUB/android_kernel_lenovo_msm8916 kernel/lenovo/msm8916

echo -e "\n============== DONE ==============\n"
