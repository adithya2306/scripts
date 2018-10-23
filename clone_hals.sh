#!/bin/bash

# Shell script to clone stable pie HALS for lettuce
# NOTE: Only for ROMs with project pathmap support.

HALS_REPO="https://github.com/lettuce-pie/LOS-16-hals"

for i in "audio" "media" "display"
do
    echo -e "\n====== CLONING MSM8916 $i HAL ======\n"
    rm -rf hardware/qcom/$i-caf/msm8916
    git clone -b $i-caf/msm8916 $HALS_REPO hardware/qcom/$i-caf/msm8916
done

for j in "keymaster" "ril-caf" "wlan-caf" "bt-caf"
do
    echo -e "\n====== CLONING MSM8916 $j HAL ======\n"
    rm -rf hardware/qcom/$j
    git clone -b $j $HALS_REPO hardware/qcom/$j
done

echo -e "\n====== CLONING CAF RIL ======\n"
rm -rf hardware/ril-caf
git clone -b ril-caf $HALS_REPO hardware/ril-caf
