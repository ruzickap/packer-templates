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
 * ubuntu-desktop-18.04   (libvirt)
 * ubuntu-desktop-17.10   (libvirt)
 * ubuntu-server-18.04    (libvirt)
 * ubuntu-server-16.04    (libvirt)
 * ubuntu-server-14.04    (libvirt)
 * my_ubuntu-server-18.04 (libvirt)
 * my_ubuntu-server-16.04 (libvirt)
 * my_ubuntu-server-14.04 (libvirt)
 * my_centos-7            (libvirt)

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for Virtualbox:
  $PROGNAME my_windows-10:virtualbox windows-10:virtualbox windows-2016:virtualbox windows-2012_r2:virtualbox


Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for libvirt:
  $PROGNAME my_windows-10:libvirt windows-10:libvirt windows-2016:libvirt windows-2012_r2:libvirt


Build Ubuntu Desktop 18.04, 17.10; Ubuntu Server 18.04, 16.04, 14.04; My Ubuntu Server 18.04, 16.04, 14.04; My CentOS 7 for libvirt:
  $PROGNAME \\
  ubuntu-desktop-18.04:libvirt ubuntu-desktop-17.10:libvirt \\
  ubuntu-server-18.04:libvirt ubuntu-server-16.04:libvirt ubuntu-server-14.04:libvirt \\
  my_ubuntu-server-18.04:libvirt my_ubuntu-server-16.04:libvirt my_ubuntu-server-14.04:libvirt \\
  my_centos-7:libvirt
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

    case $PACKER_VAGRANT_PROVIDER in
      libvirt )
        export PACKER_BUILDER_TYPE="qemu"
      ;;
      virtualbox )
        export PACKER_BUILDER_TYPE="virtualbox-iso"
      ;;
      *)
        echo "*** Unsupported PACKER_VAGRANT_PROVIDER: \"$PACKER_VAGRANT_PROVIDER\" used from \"$BUILD\""
        exit 1
      ;;
    esac

    echo "*** $MY_NAME | $MYBUILD - $PACKER_VAGRANT_PROVIDER/$PACKER_VAGRANT_PROVIDER"

    case $MYBUILD in
      *centos*)
        export CENTOS_VERSION=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
        export CENTOS_ARCH="x86_64"
        export CENTOS_TYPE="NetInstall"
        export NAME="${MY_NAME}-${CENTOS_VERSION}-${CENTOS_ARCH}"
        export PACKER_FILE="${MY_NAME}-${CENTOS_VERSION}.json"

        sudo dnf upgrade -y ansible
      ;;
      *ubuntu*)
        export UBUNTU_TYPE=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export UBUNTU_MAJOR_VERSION=`echo $MYBUILD | awk -F '-' '{ print $3 }'`
        export UBUNTU_ARCH="amd64"
        export UBUNTU_VERSION=`curl -s http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS | sed -n "s/.*ubuntu-\([^-]*\)-${UBUNTU_TYPE}-${UBUNTU_ARCH}.iso/\1/p" | head -1`
        export NAME="${MY_NAME}-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
        export PACKER_FILE="${MY_NAME}-${UBUNTU_TYPE}.json"

        sudo dnf upgrade -y ansible
      ;;
      *windows*)
        export WINDOWS_ARCH="x64"
        export WINDOWS_VERSION=`echo $MYBUILD | sed 's/.*windows-\([^-_]*\).*/\1/'`
        export VIRTIO_WIN_ISO="$TMPDIR/virtio-win.iso"
        export PACKER_FILE="${MY_NAME}.json"

        case $MYBUILD in
          *windows-10*)
            export WINDOWS_EDITION="enterprise"
            export NAME="${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
            export ISO_URL="http://care.dlservice.microsoft.com/dl/download/6/5/D/65D18931-F626-4A35-AD5B-F5DA41FE6B76/16299.15.170928-1534.rs3_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
            export ISO_CHECKSUM="3d39dd9bd37db5b3c80801ae44003802a9c770a7400a1b33027ca474a1a7c691"
          ;;
          *windows-2016*)
            export WINDOWS_TYPE="server"
            export WINDOWS_EDITION="standard"
            export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
            export ISO_URL="http://care.dlservice.microsoft.com/dl/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO"
            export ISO_CHECKSUM="1ce702a578a3cb1ac3d14873980838590f06d5b7101c5daaccbac9d73f1fb50f"
          ;;
          *windows-2012_r2*)
            export WINDOWS_RELEASE="r2"
            export WINDOWS_TYPE="server"
            export WINDOWS_EDITION="standard"
            export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
            export ISO_URL="http://care.dlservice.microsoft.com/dl/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
            export ISO_CHECKSUM="6612b5b1f53e845aacdf96e974bb119a3d9b4dcb5b82e65804ab7e534dc7b4d5"
          ;;
        esac

        test -f $VIRTIO_WIN_ISO || wget --continue $VIRTIO_WIN_ISO_URL -O $VIRTIO_WIN_ISO
        sudo dnf install -y ansible-2.4.0.0-1.fc27
      ;;
      *)
        echo "*** Unsupported build type: \"$MYBUILD\" used from \"$BUILD\""
        exit 1
      ;;
    esac

    packer_build
  done
}


packer_build() {
  if [ ! -f "${NAME}-${PACKER_VAGRANT_PROVIDER}.box" ]; then
    test -d $TMPDIR  || mkdir -v $TMPDIR
    test -d $LOG_DIR || mkdir -v $LOG_DIR

    echo -e "\n\n* ${NAME} [${PACKER_FILE}] [${PACKER_VAGRANT_PROVIDER}/${PACKER_BUILDER_TYPE}]\n"
    $PACKER_BINARY build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" $PACKER_FILE 2>&1 | tee "${LOG_DIR}/${NAME}-${PACKER_BUILDER_TYPE}-packer.log"
  else
    echo -e "\n* File ${NAME}-${PACKER_VAGRANT_PROVIDER}.box already exists. Skipping....\n";
  fi
}



#######
# Main
#######

main() {
  cmdline $ARGS
}

main
