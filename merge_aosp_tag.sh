#!/bin/bash
#
# Script to merge specified AOSP tag in repos tracked by Google's repo tool (git-repo)
#
# Usage (in root of ROM source):
#       repo forall -c $(pwd)/merge_aosp_tag.sh <tag_name> <aosp_remote_name> <caf_remote_name>
#
# NOTE: if CAF remote doesnt exist then leave it as "caf"

TAG=$1
AOSP_REMOTE=$2
CAF_REMOTE=$3

if [[ $REPO_REMOTE != $AOSP_REMOTE && $REPO_REMOTE != $CAF_REMOTE ]]; then
        # Check if it is a repo which is forked from AOSP
        if [[ $(wget -q --spider https://android.googlesource.com/platform/$REPO_PATH) -eq 0 ]]; then
                # Find branch name from manifest & checkout
                branch=$(sed 's|refs\/heads\/||' <<< $REPO_RREV)
                git checkout -q $branch

                # Fetch the tag from AOSP
                git fetch -q https://android.googlesource.com/platform/$REPO_PATH $TAG

                # Store the current hash value of HEAD
                hash=$(git rev-parse HEAD)

                # Merge and inform user on succesful merge, by comparing hash
                git merge -q --no-ff -m "Merge tag '$TAG' into $branch" FETCH_HEAD
                if [ $? -eq 0 ]; then
                        if [[ $(git rev-parse HEAD) != $hash ]]; then
                                echo -e "\n\e[34m$REPO_PATH merged succesfully\e[0m\n"
                        fi
                else
                        echo -e "\n\e[31m$REPO_PATH has merge errors\e[0m\n"
                fi
        fi
fi
