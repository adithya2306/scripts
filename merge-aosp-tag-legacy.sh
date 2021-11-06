#!/usr/bin/env bash
# Script to merge latest AOSP tag in AOSP-LEGACY source
# Can be adapted to other AOSP-based ROMs as well
#
# After completion, you'll get the following files in the ROM source dir:
# 	success - repos where merge succeeded
# 	failed - repos where merge failed
#
# Also supports auto-pushing of repos where merge succeeded
#
# Usage: Just run the script in root of ROM source
#

# Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
blu=$'\e[1;34m'
end=$'\e[0m'

# Assumes user is running the script in root of source
ROM_PATH=$(pwd)

# ROM-specific constants
BRANCH=ten
REMOTE_NAME=legacy
REPO_XML_PATH="snippets/legacy.xml"

# Blacklisted repos - don't try to merge
blacklist="manifest \
hardware/qcom/display \
hardware/qcom/media \
hardware/qcom/audio \
hardware/qcom/bt \
hardware/qcom/wlan \
hardware/ril \
prebuilts/r8"

# Get merge tag from user
read -p "Enter the AOSP tag you want to merge: " TAG

# Set the base URL for all repositories to be pulled from
AOSP="https://android.googlesource.com"

reset_branch () {
  git checkout $BRANCH &> /dev/null
  git fetch $REMOTE_NAME $BRANCH &> /dev/null
  git reset --hard $REMOTE_NAME/$BRANCH &> /dev/null
}

# Logic kanged from some similar script
repos="$(grep "remote=\"$REMOTE_NAME\"" $ROM_PATH/.repo/manifests/$REPO_XML_PATH  | awk '{print $2}' | awk -F '"' '{print $2}')"

for files in success failed; do
    rm $files 2> /dev/null
    touch $files
done

for REPO in $repos; do
    if [[ $blacklist =~ $REPO ]]; then
        echo -e "\n$REPO is in blacklist, skipping"
    else
        case $REPO in
            build/make) repo_url="$AOSP/platform/build" ;;
            *) repo_url="$AOSP/platform/$REPO" ;; esac

        if wget -q --spider $repo_url; then
            echo -e "$blu \nMerging $REPO $end"
            cd $REPO
            reset_branch
            git fetch -q $repo_url $TAG &> /dev/null
            if git merge FETCH_HEAD -q -m "Merge tag '$TAG' into $BRANCH" &> /dev/null; then
                if [[ $(git rev-parse HEAD) != $(git rev-parse $REMOTE_NAME/$BRANCH) ]] && [[ $(git diff HEAD $REMOTE_NAME/$BRANCH) ]]; then
                    echo "$REPO" >> $ROM_PATH/success
                    echo "${grn}Merging $REPO succeeded :) $end"
                else
                    echo "$REPO - unchanged"
                    git reset --hard $REMOTE_NAME/$BRANCH &> /dev/null
                fi
            else
                echo "$REPO" >> $ROM_PATH/failed
                echo "${red}$REPO merging failed :( $end"
            fi
            cd $ROM_PATH
        fi
    fi
done

echo -e "$red \nThese repos failed merging: \n $end"
cat failed
echo -e "$grn \nThese repos succeeded merging: \n $end"
cat success

echo $red
read -p "Do you want to push the succesfully merged repos? (Y/N): " PUSH
echo $end

if [[ $PUSH == "Y" ]] || [[ $PUSH == "y" ]]; then
    # Push succesfully merged repos
    for REPO in $(cat success); do
        cd $REPO
        echo -e "Pushing $REPO ..."
        git push -q $REMOTE_NAME HEAD:$BRANCH &> /dev/null
        cd $ROM_PATH
    done
fi

echo -e "\n${blu}All done :) $end"
