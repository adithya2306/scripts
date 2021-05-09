#!/bin/bash
#
# Script to set up an Ubuntu 20.04+ server
# (with minimum 16GB RAM, 4 cores CPU) for android ROM compiling
#
# Sudo access is mandatory to run this script
#
# IMPORTANT NOTICE: This script sets my personal git config, update
# it with your details before you run this script!
#
# Usage:
#	./ubuntu-setup.sh
#

# Go to home dir
orig_dir=$(pwd)
cd $HOME

echo -e "Installing and updating packages...\n"
sudo apt update -qq
sudo apt full-upgrade -y -qq
sudo apt install -y -qq git-core gnupg flex bc bison build-essential zip curl zlib1g-dev gcc-multilib \
                        g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev jq \
                        lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig imagemagick \
                        python2 python3 python3-pip python3-dev python-is-python3 schedtool ccache libtinfo5 \
                        libncurses5 lzop tmux libssl-dev neofetch patchelf apktool dos2unix git-lfs default-jdk
sudo apt autoremove -y -qq
sudo apt purge snapd -y -qq

wget -q https://storage.googleapis.com/git-repo-downloads/repo
chmod a+x repo
sudo install repo /usr/local/bin/repo
rm repo
echo -e "\nDone."

echo -e "\nInstalling Android SDK platform tools..."
wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip &> /dev/null
rm platform-tools-latest-linux.zip
echo -e "Done."

echo -e "\nInstalling Google Drive CLI..."
wget -q https://raw.githubusercontent.com/usmanmughalji/gdriveupload/master/gdrive
chmod a+x gdrive
sudo install gdrive /usr/local/bin/gdrive
rm gdrive
echo -e "Done."

echo -e "\nSetting up shell environment..."
if [[ $SHELL = *zsh* ]]; then
sh_rc=".zshrc"
else
sh_rc=".bashrc"
fi

cat <<'EOF' >> $sh_rc

# Upload a file to transfer.sh
transfer() { if [ $# -eq 0 ]; then echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; }

# Super-fast repo sync
repofastsync() { time schedtool -B -e ionice -n 0 `which repo` sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle -j$(nproc --all) "$@"; }

# List lib dependencies of any lib/bin
list_blob_deps() { readelf -d $1 | grep "\(NEEDED\)" | sed -r "s/.*\[(.*)\]/\1/"; }

export TZ='Asia/Kolkata'
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

# Unlimited history file
sed -i 's/HISTSIZE=.*/HISTSIZE=-1/g' $sh_rc
sed -i 's/HISTFILESIZE=.*/HISTFILESIZE=-1/g' $sh_rc

echo -e "Done."

# Increase tmux scrollback buffer size
echo "set-option -g history-limit 6000" >> .tmux.conf

###
### IMPORTANT !!! REPLACE WITH YOUR PERSONAL DETAILS IF NECESSARY
###
# Configure git
echo -e "\nSetting up Git..."

if [[ $USER == "adithya" ]]; then
git config --global user.email "gh0strider.2k18.reborn@gmail.com"
git config --global user.name "Adithya R"
git config --global review.gerrit.aospa.co.username "ghostrider-reborn"
git config --global review.review.lineageos.org.username "ghostrider-reborn"
git config --global review.review.arrowos.net.username "ghostrider_reborn"
fi

if [[ $USER == "panda" ]]; then
git config --global user.name "Jyotiraditya Panda"
git config --global user.email "jyotiraditya@aospa.co"
fi

git config --global alias.cp 'cherry-pick'
git config --global alias.c 'commit'
git config --global alias.f 'fetch'
git config --global alias.rb 'rebase'
git config --global alias.rs 'reset'
git config --global alias.ck 'checkout'
git config --global credential.helper 'cache --timeout=99999999'
echo "Done."

# Done!
echo -e "\nALL DONE. Now sync sauces & start baking!"
echo -e "Please relogin or run \`source ~/$sh_rc && source ~/.profile\` for environment changes to take effect."

# Go back to original dir
cd "$orig_dir"
