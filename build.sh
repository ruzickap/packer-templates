#!/bin/bash -ue

export TMPDIR="/var/tmp/packer"
export PACKER_CACHE_DIR="$TMPDIR"
#export PACKER_LOG=1
export VIRTIO_WIN_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
export VIRTIO_WIN_ISO=$(basename $VIRTIO_WIN_ISO_URL)
export LOG_DIR="/tmp"
export HEADLESS=${HEADLESS:-true}
export PACKER_BINARY="packerio"

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"


usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:
 * my_windows-10          (libvirt, virtualbox)
 * windows-10             (libvirt, virtualbox)
 * windows-2016           (libvirt, virtualbox)
 * windows-2012_r2        (libvirt, virtualbox)
 * ubuntu-desktop-17.10   (libvirt)
 * ubuntu-server-16.04    (libvirt)
 * ubuntu-server-14.04    (libvirt)
 * my_ubuntu-server-16.04 (libvirt)
 * my_ubuntu-server-14.04 (libvirt)
 * my_centos-7            (libvirt)

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for Virtualbox:
  $PROGNAME my_windows-10:virtualbox windows-10:virtualbox windows-2016:virtualbox windows-2012_r2:virtualbox


Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for libvirt:
  $PROGNAME my_windows-10:libvirt windows-10:libvirt windows-2016:libvirt windows-2012_r2:libvirt


Build Ubuntu Desktop 17.10, Ubuntu Server 16.04, 14.04, My Ubuntu Server 16.04, 14.04 and My CentOS 7 for libvirt:
  $PROGNAME ubuntu-desktop-17.10:libvirt ubuntu-server-16.04:libvirt ubuntu-server-14.04:libvirt my_ubuntu-server-16.04:libvirt my_ubuntu-server-14.04:libvirt my_centos-7:libvirt
EOF
}

cmdline() {
  BUILDS=$@

  if [ -z "$BUILDS" ]; then
    usage
    exit 0;
  fi

  for BUILD in $BUILDS; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*:}"
    export MYBUILD="${BUILD%:*}"
    export MY_NAME=`echo $MYBUILD | awk -F '-' '{ print $1 }'`

    echo "*** $MYBUILD - $PACKER_VAGRANT_PROVIDER"

    case $MYBUILD in
      *centos*)
        export CENTOS_VERSION=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
        export CENTOS_ARCH="x86_64"
        export CENTOS_TYPE="NetInstall"
        export NAME="${MY_NAME}-${CENTOS_VERSION}-${CENTOS_ARCH}"

        sudo dnf upgrade -y ansible

        packer_build ${MY_NAME}-${CENTOS_VERSION}.json
      ;;
      *ubuntu*)
        export UBUNTU_TYPE=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export UBUNTU_MAJOR_VERSION=`echo $MYBUILD | awk -F '-' '{ print $3 }'`
        export UBUNTU_ARCH="amd64"
        export UBUNTU_VERSION=`curl -s http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS | sed -n "s/.*ubuntu-\([^-]*\)-${UBUNTU_TYPE}-${UBUNTU_ARCH}.iso/\1/p" | head -1`
        export NAME="${MY_NAME}-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"

        sudo dnf upgrade -y ansible

        packer_build ${MY_NAME}-${UBUNTU_TYPE}.json
      ;;
      *windows-10*)
        export WINDOWS_VERSION="10"
        export WINDOWS_ARCH="x64"
        export WINDOWS_EDITION="enterprise"
        export NAME="${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"

        # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
        sudo dnf install -y ansible-2.4.0.0-1.fc27

        packer_build ${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.json
      ;;
      *windows-2016*)
        export WINDOWS_VERSION="2016"
        export WINDOWS_ARCH="x64"
        export WINDOWS_TYPE="server"
        export WINDOWS_EDITION="standard"
        export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"

        # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
        sudo dnf install -y ansible-2.4.0.0-1.fc27

        packer_build ${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
      ;;
      *windows-2012_r2*)
        export WINDOWS_VERSION="2012"
        export WINDOWS_RELEASE="r2"
        export WINDOWS_ARCH="x64"
        export WINDOWS_TYPE="server"
        export WINDOWS_EDITION="standard"
        export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"

        # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
        sudo dnf install -y ansible-2.4.0.0-1.fc27

        packer_build ${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
      ;;

    esac
  done
}


packer_build() {
  PACKER_FILE=$1; shift

  if [ ! -f "${NAME}-${PACKER_VAGRANT_PROVIDER}.box" ]; then 
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
      *)
        echo "*** Unsupported PACKER_VAGRANT_PROVIDER: $PACKER_VAGRANT_PROVIDER"
      ;;
    esac

    echo -e "\n\n*** $NAME [$PACKER_FILE] [$PACKER_BUILDER_TYPE]\n"
    $PACKER_BINARY build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" $PACKER_FILE 2>&1 | tee "${LOG_DIR}/${NAME}-${PACKER_BUILDER_TYPE}-packer.log"
  else
    echo -e "\n*** File ${NAME}-${PACKER_VAGRANT_PROVIDER}.box already exists. Skipping....\n";
  fi
}



#######
# Main
#######

main() {
  cmdline $ARGS
}

main
