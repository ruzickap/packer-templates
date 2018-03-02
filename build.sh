#!/bin/bash -ue

export TMPDIR="/var/tmp/packer"
export PACKER_CACHE_DIR="$TMPDIR"
#export PACKER_LOG=1
export VIRTIO_WIN_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
export VIRTIO_WIN_ISO=$(basename $VIRTIO_WIN_ISO_URL)
export LOG_DIR="$TMPDIR"

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"


usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:
 * windows_10             (libvirt, virtualbox)
 * windows_2016           (libvirt, virtualbox)
 * windows_2012_r2        (libvirt, virtualbox)
 * ubuntu-desktop-17.10   (libvirt)
 * ubuntu-server-16.04    (libvirt)
 * ubuntu-server-14.04    (libvirt)
 * my_ubuntu-server-16.04 (libvirt)
 * my_ubuntu-server-14.04 (libvirt)
 * my_centos-7            (libvirt)

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for Virtualbox:
  $PROGNAME windows_10:virtualbox windows_2016:virtualbox windows_2012_r2:virtualbox


Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for libvirt:
  $PROGNAME windows_10:libvirt windows_2016:libvirt windows_2012_r2:libvirt


Build Ubuntu Desktop 17.10, Ubuntu Server 16.04, 14.04, My Ubuntu Server 16.04, 14.04 and My Centos 7 for libvirt:
  $PROGNAME ubuntu-desktop-17.10:libvirt ubuntu-server-16.04:libvirt ubuntu-server-14.04:libvirt my_ubuntu-server-16.04:libvirt my_ubuntu-server-14.04:libvirt my_centos-7:libvirt
EOF
}

cmdline() {
  BUILDS=$@

  if [ -z $BUILDS ]; then
    usage
    exit 0;
  fi

  for BUILD in $BUILDS; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*:}"
    export MYBUILD="${BUILD%:*}"
    echo "*** $MYBUILD - $PACKER_VAGRANT_PROVIDER"

    case $MYBUILD in
      *centos*)
        export MY_NAME=`echo $MYBUILD | awk -F '-' '{ print $1 }'`
        export CENTOS_VERSION=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        eval centos
      ;;
      *ubuntu*)
        export MY_NAME=`echo $MYBUILD | awk -F '-' '{ print $1 }'`
        export UBUNTU_TYPE=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export UBUNTU_MAJOR_VERSION=`echo $MYBUILD | awk -F '-' '{ print $3 }'`
        eval ubuntu
      ;;
      windows*)
        eval ${MYBUILD}
      ;;
    esac
  done
}


packer_build() {
  PACKER_FILE=$1; shift

  test -d $TMPDIR || mkdir -v $TMPDIR
  test -d $LOG_DIR || mkdir -v $LOG_DIR
  case $PACKER_VAGRANT_PROVIDER in
    libvirt )
      export PACKER_BUILDER_TYPE="qemu"
      if echo $PACKER_FILE | grep -q -i "windows"; then
        test -f $TMPDIR/virtio-win.iso || wget $VIRTIO_WIN_ISO_URL -P $TMPDIR
        export VIRTIO_WIN_ISO="$TMPDIR/virtio-win.iso"
      fi
    ;;
    virtualbox )
      export PACKER_BUILDER_TYPE="virtualbox-iso"
    ;;
  esac

  echo -e "\n\n*** $NAME [$PACKER_FILE] [$PACKER_BUILDER_TYPE]\n"
  packerio build -only="$PACKER_BUILDER_TYPE" -color=false -var 'headless=true' $PACKER_FILE | tee "${LOG_DIR}/${NAME}-${PACKER_BUILDER_TYPE}-packer.log"
}

# Expected enviroments: UBUNTU_TYPE="desktop" UBUNTU_MAJOR_VERSION="17.10" MY_NAME="ubuntu"
ubuntu() {
  export UBUNTU_ARCH="amd64"
  export UBUNTU_VERSION=`curl -s http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS | sed -n "s/.*ubuntu-\([^-]*\)-${UBUNTU_TYPE}-${UBUNTU_ARCH}.iso/\1/p" | head -1`
  export NAME="${MY_NAME}-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"

  sudo dnf upgrade -y ansible

  packer_build ${MY_NAME}-${UBUNTU_TYPE}.json
}

# Expected enviroments: CENTOS_VERSION="7" MY_NAME="ubuntu"
centos() {
  export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
  export CENTOS_ARCH="x86_64"
  export CENTOS_TYPE="NetInstall"
  export NAME="${MY_NAME}-${CENTOS_VERSION}-${CENTOS_ARCH}"

  sudo dnf upgrade -y ansible

  packer_build my_centos-${CENTOS_VERSION}.json
}

windows_2012_r2() {
  export WINDOWS_VERSION="2012"
  export WINDOWS_RELEASE="r2"
  export WINDOWS_ARCH="x64"
  export WINDOWS_TYPE="server"
  export WINDOWS_EDITION="standard"
  export NAME="windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"

  # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
  sudo dnf install -y ansible-2.4.0.0-1.fc27

  packer_build windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
}

windows_2016() {
  export WINDOWS_VERSION="2016"
  export WINDOWS_ARCH="x64"
  export WINDOWS_TYPE="server"
  export WINDOWS_EDITION="standard"
  export NAME="windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"

  # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
  sudo dnf install -y ansible-2.4.0.0-1.fc27

  packer_build windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
}

windows_10() {
  export WINDOWS_VERSION="10"
  export WINDOWS_ARCH="x64"
  export WINDOWS_EDITION="enterprise"
  export NAME="windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"

  # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
  sudo dnf install -y ansible-2.4.0.0-1.fc27

  packer_build windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.json
}



#######
# Main
#######

main() {
  cmdline $ARGS
}

main
