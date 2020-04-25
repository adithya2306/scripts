#!/bin/bash
#
# Script to set up an Ubuntu 16.04+ server or PC
# (with minimum 8GB RAM, 4 cores CPU) for android ROM compiling
#
# IMPORTANT NOTICE: This script sets my personal git config, update 
# it with your details before you run this script!
#
# Usage:
#	./ubuntu_setup.sh
#

# Go to home dir
orig_dir=$(pwd)
cd ~ || return

# Installing packages
echo -e "\n================== INSTALLING & CONFIGURING PACKAGES ==================\n"
sudo apt -qq update
sudo apt full-upgrade -y -qq
sudo apt install -y -qq bc bison build-essential curl flex g++-multilib gcc-multilib git gnupg gperf \
                        imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool \
                        libncurses5-dev libsdl1.2-dev libxml2 libxml2-utils lzop pngcrush \
                        schedtool squashfs-tools xsltproc zip zlib1g-dev unzip openjdk-8-jdk python ccache \
                        libtinfo5 libncurses5 android-tools-adb tmux libssl-dev neofetch

if [[ $(lsb_release -rs) == "20"* ]]; then
sudo apt install -y -qq libwxgtk3.0-gtk3-dev
else
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt install -y -qq libwxgtk3.0-dev git-lfs
fi

sudo apt autoremove -y -qq

# Install git-repo
mkdir bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# CCache hax (unlimited ccache)
ccache -M 500G

# Install Android SDK
echo -e "\n================== INSTALLING ANDROID SDK ==================\n"
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip

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
repofastsync() { schedtool -B -n 0 -e ionice -n 0 `which repo` sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all) "$@"; }

# List lib dependencies of any lib/bin
list_blob_deps() { readelf -d $1 | grep "\(NEEDED\)" | sed -r "s/.*\[(.*)\]/\1/"; }

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
EOF

# Add android sdk to path
cat <<'EOF' >> .profile
 
# Add Android SDK platform tools to path
if [ -d "$HOME/platform-tools" ] ; then
    PATH="$HOME/platform-tools:$PATH"
fi
EOF

# Set time zone to IST
sudo ln -sf /usr/share/zoneinfo/Asia/Calcutta /etc/localtime

# Set env from .bashrc and .profile
source .profile
source .bashrc
echo "Done"

###
### IMPORTANT !!! REPLACE WITH YOUR PERSONAL DETAILS
###
# Configure git
echo -e "\n================== CONFIGURING GIT ==================\n"
git config --global user.email "radithya2002@gmail.com"
git config --global user.name "Adithya R"
git config --global alias.cp 'cherry-pick'
git config --global alias.c 'commit'
git config --global alias.f 'fetch'
git config --global alias.rb 'rebase'
git config --global alias.rs 'reset'
git config --global alias.ck 'checkout'
git config --global credential.helper 'cache --timeout=9999999'
echo "Done"

# Done!
echo -e "\nALL DONE. Now sync sauces & start baking! \n"

# Go back to original dir
cd "$orig_dir" || return
