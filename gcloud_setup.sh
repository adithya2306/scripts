#!/bin/bash
#
# Script to set up Google Cloud Server
# for android ROM building
#
# Made by Adithya R (ghostrider-reborn)
#

# Go to home dir
cd ~

# Install the dependencies
echo   
echo =========Installing dependencies========
echo    
sudo apt-get update
sudo apt-get install --yes --force-yes bc bison build-essential curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline6-dev lib32z1-dev libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev unzip openjdk-8-jdk python
echo
echo ================Done====================
echo
echo ==========Updating system==============
echo   
sudo apt-get upgrade
echo
echo ================Done====================

# Install libtinfo6 (required for GCC 7.x and above)
echo    
echo ==========Installing libtinfo6============
echo      
wget http://ftp.debian.org/debian/pool/main///n/ncurses/lib32tinfo6_6.1+20180210-2_amd64.deb
sudo dpkg -i lib32tinfo6_6.1+20180210-2_amd64.deb
wget http://ftp.debian.org/debian/pool/main///n/ncurses/libtinfo6_6.1+20180210-2_amd64.deb
sudo dpkg -i libtinfo6_6.1+20180210-2_amd64.deb
echo
echo ================Done====================

# Install Android SDK
echo   
echo ===========Installing Android SDK===========
echo   
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip
echo
echo ================Done====================

# Install repo
echo   
echo ===========Installing repo tool==============
echo    
mkdir bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
sudo install repo /usr/local/bin/repo
echo
echo ================Done====================

# Add env variables to bashrc
echo    
echo ========Updating bashrc and .profile===========
echo     
cat <<EOT >> ~/.bashrc

export USE_CCACHE=1
export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation"
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
EOT

# Add ~/bin and sdk to path
cat <<EOT >> ~/.profile

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# add Android SDK platform tools to path
if [ -d "$HOME/platform-tools" ] ; then
    PATH="$HOME/platform-tools:$PATH"
fi
EOT

# Set env from .bashrc and .profile
source ~/.profile
source ~/.bashrc
echo
echo ================Done====================

# Install GDrive CLI
echo
echo =========Installing GDrive============
echo
wget -O gdrive "https://docs.google.com/uc?id=0B3X9GlR6EmbnWksyTEtCM0VfaFE&export=download"
chmod a+x gdrive
sudo install gdrive /usr/local/bin/gdrive
echo
echo ================Done====================

# Configure git
echo    
echo ===========Configuring git=============
echo    
git config --global user.email "adithya.r02@outlook.com"
git config --global user.name "Ad!thya R"
git config --global alias.cp 'cherry-pick -s'
git config --global alias.c 'commit -s'
echo
echo ================Done====================

# Done!
echo
echo ========== Everything done. =============
echo
