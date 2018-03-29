# Install the dependencies
sudo apt-get update
sudo apt-get install -y bc bison build-essential curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline6-dev lib32z1-dev libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev unzip openjdk-8-jdk python
sudo apt-get upgrade

# Install libtinfo6 (required for GCC 7.x and above)
wget http://ftp.us.debian.org/debian/pool/main/n/ncurses/lib32tinfo6_6.1+20180210-1_amd64.deb
dpkg -i lib32tinfo6_6.1+20180210-1_amd64.deb
wget http://ftp.us.debian.org/debian/pool/main/n/ncurses/libtinfo6_6.1+20180210-1_amd64.deb
dpkg -i libtinfo6_6.1+20180210-1_amd64.deb

# Install Android SDK
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip platform-tools-latest-linux.zip

# Install repo
mkdir bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Add env variables to bashrc
cat <<EOT >> ~/.bashrc

export USE_CCACHE=1
export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx6144m"
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx6144m"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -Xmx6144m"
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

# Configure git
git config --global user.email "adithya.r02@outlook.com"
git config --global user.name "Adithya R"
git config --global alias.cp 'cherry-pick -s'
git config --global alias.c 'commit -s'

# Done!
echo
echo Everything done.
echo
