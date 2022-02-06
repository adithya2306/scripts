#!/bin/bash
#
# Script to set up an Ubuntu 20.04+ server
# (with minimum 16GB RAM, 8 threads CPU) for android ROM compiling
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

echo -e "Installing and updating APT packages...\n"
sudo apt update -qq
sudo apt full-upgrade -y -qq
sudo apt install -y -qq git-core gnupg flex bc bison build-essential zip curl zlib1g-dev gcc-multilib \
                        g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev jq \
                        lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig imagemagick \
                        python2 python3 python3-pip python3-dev python-is-python3 schedtool ccache libtinfo5 \
                        libncurses5 lzop tmux libssl-dev neofetch patchelf apktool dos2unix git-lfs default-jdk \
                        libxml-simple-perl
sudo apt autoremove -y -qq
sudo apt purge snapd -y -qq
echo -e "\nDone."

echo -e "\nInstalling git-repo..."
wget -q https://storage.googleapis.com/git-repo-downloads/repo
chmod a+x repo
sudo install repo /usr/local/bin/repo
rm repo
echo -e "Done."

echo -e "\nInstalling Android SDK platform tools..."
wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -qq platform-tools-latest-linux.zip
rm platform-tools-latest-linux.zip
echo -e "Done."

echo -e "\nInstalling Google Drive CLI..."
wget -q https://raw.githubusercontent.com/usmanmughalji/gdriveupload/master/gdrive
chmod a+x gdrive
sudo install gdrive /usr/local/bin/gdrive
rm gdrive
echo -e "Done."

echo -e "\nInstalling apktool and JADX..."
mkdir -p bin
wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.6.0.jar -O bin/apktool.jar
echo 'alias apktool="java -jar $HOME/bin/apktool.jar"' >> .bashrc

wget -q https://github.com/skylot/jadx/releases/download/v1.3.2/jadx-1.3.2.zip
unzip -qq jadx-1.2.0.zip -d jadx
rm jadx-1.2.0.zip
echo 'export PATH="$HOME/jadx/bin:$PATH"' >> .bashrc
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
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; echo; }

# Super-fast repo sync
repofastsync() { time schedtool -B -e ionice -n 0 `which repo` sync -c --force-sync --optimized-fetch --no-tags --no-clone-bundle -j$(nproc --all) "$@"; }

# List lib dependencies of any lib/bin
list_blob_deps() { readelf -d $1 | grep "\(NEEDED\)" | sed -r "s/.*\[(.*)\]/\1/"; }

export TZ='Asia/Kolkata'
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

function msg() {
  echo -e "\e[1;32m$1\e[0m"
}

function helptree() {
  if [[ -z $1 && -z $2 ]]; then
    msg "Usage: helptree <tag> <add/pull>"
    return
  fi
  kernel_version="$( cat Makefile | grep VERSION | head -n 1 | sed "s|.*=||1" | sed "s| ||g" )"
  kernel_patchlevel="$( cat Makefile | grep PATCHLEVEL | head -n 1 | sed "s|.*=||1" | sed "s| ||g" )"
  version=$kernel_version.$kernel_patchlevel
  if [[ $version != "4.14" && $version != "5.4" ]]; then
    msg "Kernel $version not supported! Only msm-5.4 and msm-4.14 are supported as of now."
    return
  fi
  if [[ -z $3 ]]; then
    spec=all
  else
    spec=$3
  fi
  if [[ $2 = "add" ]]; then
    tree_status="Adding"
    commit_status="Import from"
  else
    tree_status="Updating"
    commit_status="Merge"
    if [[ $spec = "all" ]]; then
      msg "Merging kernel as of $1.."
      git fetch https://source.codeaurora.org/quic/la/kernel/msm-$version $1
      git merge FETCH_HEAD -m "Merge tag '$1' of msm-$version"
    fi
  fi
  if [[ $spec = "wifi" || $spec = "all" ]]; then
    for i in qcacld-3.0 qca-wifi-host-cmn fw-api; do
      msg "$tree_status $i subtree as of $1..."
      git subtree $2 -P drivers/staging/$i -m "$i: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/wlan/$i $1
    done
  fi
  if [[ $spec = "techpack" || $spec = "all" ]]; then
    msg "$tree_status audio-kernel subtree as of $1..."
    git subtree $2 -P techpack/audio -m "techpack: audio: $commit_status tag '$1'" \
      https://source.codeaurora.org/quic/la/platform/vendor/opensource/audio-kernel $1
    if [[ $version = "5.4" ]]; then
      msg "$tree_status camera-kernel subtree as of $1..."
      git subtree $2 -P techpack/camera -m "techpack: camera: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/opensource/camera-kernel $1
      msg "$tree_status dataipa subtree as of $1..."
      git subtree $2 -P techpack/dataipa -m "techpack: dataipa: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/opensource/dataipa $1
      msg "$tree_status datarmnet subtree as of $1..."
      git subtree $2 -P techpack/datarmnet -m "techpack: datarmnet: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/qcom/opensource/datarmnet $1
      msg "$tree_status datarmnet-ext subtree as of $1..."
      git subtree $2 -P techpack/datarmnet-ext -m "techpack: datarmnet-ext: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/qcom/opensource/datarmnet-ext $1
      msg "$tree_status display-drivers subtree as of $1..."
      git subtree $2 -P techpack/display -m "techpack: display: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/opensource/display-drivers $1
      msg "$tree_status video-driver subtree as of $1..."
      git subtree $2 -P techpack/video -m "techpack: video: $commit_status tag '$1'" \
        https://source.codeaurora.org/quic/la/platform/vendor/opensource/video-driver $1
    elif [[ $version = "4.14" ]]; then
      if [[ $2 = "add" ]] || [ -d "techpack/data" ]; then
        msg "$tree_status data-kernel as of $1..."
        git subtree $2 -P techpack/data -m "techpack: data: $commit_status tag '$1'"  \
          https://source.codeaurora.org/quic/la/platform/vendor/qcom-opensource/data-kernel $1
      fi
    fi
  fi
}

function addtree() {
  if [[ -z $1 ]]; then
    msg "Usage: addtree <tag> [optional: spec]"
    return
  fi
  helptree $1 add $2
}

function updatetree() {
  if [[ -z $1 ]]; then
    msg "Usage: updatetree <tag> [optional: spec]"
    return
  fi
  helptree $1 pull $2
}
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

# Increase maximum ccache size
ccache -M 100G

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
