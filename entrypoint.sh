#!/usr/bin/env bash

cd /home/user/workdir

if ! [[ -d openwrt ]]; then
  echo "INFO: openwrt git repo not yet cloned, first run? cloning now, please wait.."
  git clone https://git.openwrt.org/openwrt/openwrt.git
  git config pull.rebase true
else
  echo "INFO: cleaning up existing git repo.."
  make clean
fi

cd openwrt
echo "INFO: resetting openwrt git repo and updating master branch.."
git reset --hard origin/master
git pull

if ! [[ -n $BUILD_LATEST ]]; then
  cd /home/user/upstream
  BUILD_LATEST=$(ls -1d 2???????-?? | tail -1)
fi
echo "INFO: Will build the following release: $BUILD_LATEST"

cd /home/user/workdir/openwrt

VERSION_COMMIT=$(awk -F- '{print $NF}' ../../upstream/$BUILD_LATEST/version.buildinfo)

echo "INFO: Resetting git repo to release's commit: $VERSION_COMMIT"
git reset --hard $VERSION_COMMIT

echo -n "INFO: Resetting feeds to "
awk '{printf "%s @ %s   ", $2, substr($3,index($3,"^")+1)} END {printf "\n"}' ../../upstream/$BUILD_LATEST/feeds.buildinfo
cp ../../upstream/$BUILD_LATEST/feeds.buildinfo feeds.conf

#echo "INFO: updating feeds.."
./scripts/feeds update -a -f 2>&1 >/dev/null
echo "INFO: installing feeds.."
./scripts/feeds install -a -f

ls ../../upstream/patches/*.patch 2>/dev/null 1>/dev/null
if [[ $? -eq 0 ]]; then
  echo "INFO: applying non-release specific patches.."
  git am --whitespace=nowarn ../../upstream/patches/*.patch
fi

ls ../../upstream/$BUILD_LATEST/*.patch 2>/dev/null 1>/dev/null
if [[ $? -eq 0 ]]; then
  echo "INFO: applying release specific patches.."
  git am --whitespace=nowarn ../../upstream/$BUILD_LATEST/*.patch
fi

echo "INFO: loading release base config.."
cp ../../upstream/$BUILD_LATEST/config.buildinfo .config

echo "INFO: patching base config.."
git add -f .config
git commit -m'stage config file'
git am --whitespace=nowarn ../../custom/*.patch

echo "INFO: generating full config.."
make defconfig

echo "INFO: downloading necessary files.."
make download -j4 

echo "INFO: building release $BUILD_LATEST.."
make -j8

if [[ $? -eq 0 ]]; then
  echo "INFO: build successful! please find image in: $BUILD_WORKDIR/openwrt/bin/targets/mvebu/cortexa9"
  cd bin/targets/mvebu/cortexa9
  ls -l *linksys_wrt32x*sysupgrade*
else
  exit 1
fi
