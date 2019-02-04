#!/bin/bash
#
# Script to set up an Ubuntu 18.04+ server or PC
# (with minimum 8GB RAM, 4 cores CPU) for android ROM compiling
#
# Usage:
#	./ubuntu_setup.sh
#

# Go to home dir
cd ~

# Installing packages
echo -e "\n================== INSTALLING & CONFIGURING PACKAGES ==================\n"
sudo apt-get update
sudo apt-get install -y bc bison build-essential curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev unzip openjdk-8-jdk python ccache
sudo apt-get upgrade -y

# CCache hax (unlimited ccache)
ccache -M 500G

# Install Android SDK
echo -e "\n================== INSTALLING ANDROID SDK ==================\n"
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

# Install repo
echo -e "\n================== INSTALLING GIT-REPO ==================\n"
wget https://storage.googleapis.com/git-repo-downloads/repo
chmod a+x repo
sudo install repo /usr/local/bin/repo

# Install google drive command line tool
echo -e "\n================== INSTALLING GDRIVE CLI ==================\n"
wget -O gdrive "https://docs.google.com/uc?id=0B3X9GlR6EmbnWksyTEtCM0VfaFE&export=download"
chmod a+x gdrive
sudo install gdrive /usr/local/bin/gdrive

# Set up environment
echo -e "\n================== SETTING UP ENV ==================\n"
cat <<'EOF' >> ~/.bashrc

# Upload a file to transfer.sh
transfer() { if [ $# -eq 0 ]; then echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi 
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; } 

# Super-fast repo sync
repofastsync() { schedtool -B -n 1 -e ionice -n 1 `which repo` sync -c -f --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j8 "$@"; }

export USE_CCACHE=1
EOF

# Add android sdk to path
cat <<'EOF' >> ~/.profile

# Add Android SDK platform tools to path
if [ -d "$HOME/platform-tools" ] ; then
    PATH="$HOME/platform-tools:$PATH"
fi
EOF

# Set time zone to IST
sudo ln -sf /usr/share/zoneinfo/Asia/Calcutta /etc/localtime

# Set env from .bashrc and .profile
source ~/.profile
source ~/.bashrc
echo "Done"

###
### IMPORTANT: REPLACE WITH YOUR PERSONAL DETAILS
###
# Configure git
echo -e "\n================== CONFIGURING GIT ==================\n"
git config --global user.email "gh0strider.2k18.reborn@gmail.com"
git config --global user.name "Adithya R"
git config --global alias.cp 'cherry-pick'
git config --global alias.c 'commit'
git config --global credential.helper cache
git config --global credential.helper 'cache --timeout=9999999'
echo "Done"

# Done!
echo -e "\nALL DONE. Now sync sauces & start baking! \n"
