#!/usr/bin/env bash

cd /home/user/workdir

if [[ $* ]] && [[ $1 != "start" ]]; then
  echo "INFO: extra params specified, passing them directly to the final step.. "
  cd openwrt
  make $*

  if [[ $? -eq 0 ]]; then
    echo "INFO: build successful! please find image in: \$BUILD_WORKDIR/openwrt/bin/targets/mvebu/cortexa9"
    cd bin/targets/mvebu/cortexa9
    echo
    ls -l *linksys_wrt32x*sysupgrade*
    echo
    exit 0
  else
    exit 1
  fi
fi

if ! [[ -d openwrt ]]; then
  echo "INFO: openwrt git repo not yet cloned, first run? cloning now, please wait.."
  git clone https://git.openwrt.org/openwrt/openwrt.git
  git config pull.rebase true
  echo
fi

cd /home/user/workdir/openwrt
echo "INFO: rewinding openwrt git repo and updating master branch.."
git am --abort 2>/dev/null
git reset --hard origin/master
git pull
echo

if ! [[ -n $BUILD_LATEST ]]; then
  cd /home/user/upstream
  BUILD_LATEST=$(ls -1d 2???????-?? | tail -1)
  cd $OLDPWD
fi
echo "INFO: planning to build release: $BUILD_LATEST"
echo

echo "INFO: setting up a default config.."
make defconfig
echo

echo "INFO: cleaning up existing git repo.."
make clean
echo

VERSION_COMMIT=$(awk -F- '{print $NF}' ../../upstream/$BUILD_LATEST/version.buildinfo)
echo
echo "INFO: rewinding git repo to release's commit: $VERSION_COMMIT"
git am --abort 2>/dev/null
git reset --hard $VERSION_COMMIT
echo

echo "INFO: loading feeds commits configuration"
cp ../../upstream/$BUILD_LATEST/feeds.buildinfo feeds.conf
echo

echo "INFO: updating feeds.."
./scripts/feeds update -a -f 2>&1 >/dev/null
echo

echo -n "INFO: rewinding feeds to "
awk '{printf "%s @ %s   ", $2, substr($3,index($3,"^")+1)} END {printf "\n"}' ../../upstream/$BUILD_LATEST/feeds.buildinfo
for D in $(awk '{print $2}' ../../upstream/$BUILD_LATEST/feeds.buildinfo); do
  cd ./feeds/"$D"
  git reset --hard
  cd "$OLDPWD"
done
echo

echo "INFO: installing feeds.."
./scripts/feeds install -a -f
echo

ls ../../upstream/$BUILD_LATEST/*.patch 2>/dev/null 1>/dev/null
if [[ $? -eq 0 ]]; then
  echo "INFO: applying release specific patches.."
  for P in ../../upstream/$BUILD_LATEST/*.patch; do 
    git am --whitespace=nowarn $P
    if [[ $? -ne 0 ]]; then
      echo "WARN: the patch $P did not apply cleanly.. soldiering on.."
      git am --skip
    fi
  done
  echo
fi

ls ../../upstream/patches/*.patch 2>/dev/null 1>/dev/null
if [[ $? -eq 0 ]]; then
  echo "INFO: applying non-release specific patches.."
  for P in ../../upstream/patches/*.patch; do
    git am --whitespace=nowarn $P
    if [[ $? -ne 0 ]]; then
      echo "WARN: the patch $P did not apply cleanly.. soldiering on.."
      git am --skip
    fi
  done
  echo
fi

ls ../../custom/*.diff-patch 2>/dev/null 1>/dev/null
if [[ $? -eq 0 ]]; then
  echo "INFO: applying diff-specific patches.."
  for P in ../../custom/*.diff-patch; do
    echo "INFO: applying $P.. "
    patch -f -p0 < $P
    if [[ $? -ne 0 ]]; then
      echo "WARN: the patch $P did not apply cleanly.. soldiering on.."
    fi
    echo
  done
fi

echo "INFO: loading release base config.."
cp ../../upstream/$BUILD_LATEST/config.buildinfo .config
echo

echo "INFO: patching base config.."
git add -f .config
git commit -m'stage config file'
git am --whitespace=nowarn ../../custom/*.patch
if [[ $? -ne 0 ]]; then
  echo "ERROR: custom patches did not apply cleaning.. aborting!"
  exit 1
fi
echo

echo "INFO: expanding config to full-set of options.."
make defconfig
echo

echo "INFO: downloading necessary files.."
make download -j4
echo

echo "INFO: copying any custom files to the build tree.."
rsync -av --delete ../../livefs/ files/
echo

echo "INFO: building release $BUILD_LATEST.."
if [[ $1 != "start" ]]; then
  make $*
else
  make -j8
fi

if [[ $? -eq 0 ]]; then
  echo
  echo "INFO: build successful! please find image in: \$BUILD_WORKDIR/openwrt/bin/targets/mvebu/cortexa9"
  cd bin/targets/mvebu/cortexa9
  echo
  ls -l *linksys_wrt32x*sysupgrade*
  echo
else
  exit 1
fi
