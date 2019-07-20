#!/bin/bash
#
# Script to merge specified AOSP tag in repos tracked by Google's repo tool (git-repo)
#
# Usage (in root of ROM source):
#       repo forall -c $(pwd)/merge_aosp_tag.sh <tag_name> <aosp_remote_name> [<additional_remote_name>]
#

TAG=$1
AOSP_REMOTE=$2
if [ -n "$3" ]; then ADDNL_REMOTE=$3, else ADDNL_REMOTE="k"; fi

###
### TODO: Whitelisted repos support
###

if [[ $REPO_REMOTE != "$AOSP_REMOTE" && $REPO_REMOTE != "$ADDNL_REMOTE" ]]; then

        # Workaround for build/make as it lies in "platform/build" repo in AOSP
        if [[ $REPO_PATH = "build/make" ]]; then REPO_PATH="build"; fi

        # Check if it is a repo which is forked from AOSP
        if wget -q --spider https://android.googlesource.com/platform/$REPO_PATH; then
                # Find branch name from manifest & checkout
                branch=$(sed 's|refs\/heads\/||' <<< "$REPO_RREV")
                git checkout -q "$branch"

                # Fetch the tag from AOSP
                git fetch -q https://android.googlesource.com/platform/$REPO_PATH "$TAG"

                # Store the current hash value of HEAD
                hash=$(git rev-parse HEAD)

                # Merge and inform user on succesful merge, by comparing hash
                if git merge -q --no-ff -m "Merge tag '$TAG' into $branch" FETCH_HEAD; then
                        if [[ $(git rev-parse HEAD) != "$hash" ]] && [[ $(git diff HEAD "$REPO_REMOTE"/"$branch") ]]; then
                                echo -e "\n\e[34m$REPO_PATH merged succesfully\e[0m\n"
                        else git reset --hard "$REPO_REMOTE"/"$branch"; fi
                else
                        echo -e "\n\e[31m$REPO_PATH has merge errors\e[0m\n"
                fi
        fi
fi
