#!/bin/bash -eu

export TMPDIR="$PWD/packer_cache"
export VIRTIO_WIN_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
export VIRTIO_WIN_ISO="$TMPDIR/$(basename $VIRTIO_WIN_ISO_URL)"
export LOG_DIR="/tmp"
export HEADLESS=${HEADLESS:-true}
export USE_DOCKERIZED_PACKER=${USE_DOCKERIZED_PACKER:-false}
export PACKER_BINARY="packerio"
# You can use VNC client to connect to machine which is building ot see the details (vncviewer 127.0.0.1:5999)
export VNC_PORT=5999
# You can use ssh/winrm to connect to machine when the OS is installed
export WINRM_SSH_PORT=2299

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"


usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:
 * my_windows-10:{libvirt,virtualbox}
 * windows-10:{libvirt,virtualbox}
 * windows-2016:{libvirt,virtualbox}
 * windows-2012_r2:{libvirt,virtualbox}
 * ubuntu-18.04-desktop:{libvirt,virtualbox}
 * ubuntu-17.10-desktop:{libvirt,virtualbox}
 * ubuntu-18.04-server:{libvirt,virtualbox}
 * ubuntu-16.04-server:{libvirt,virtualbox}
 * ubuntu-14.04-server:{libvirt,virtualbox}
 * my_ubuntu-18.04-server:{libvirt,virtualbox}
 * my_ubuntu-16.04-server:{libvirt,virtualbox}
 * my_ubuntu-14.04-server:{libvirt,virtualbox}
 * my_centos-7:{libvirt,virtualbox}

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for Virtualbox and libvirt:
  $PROGNAME my_windows-10:{virtualbox,libvirt} windows-10:{virtualbox,libvirt} windows-2016:{virtualbox,libvirt} windows-2012_r2:{virtualbox,libvirt}


Build Ubuntu Desktop 18.04, 17.10; Ubuntu Server 18.04, 16.04, 14.04; My Ubuntu Server 18.04, 16.04, 14.04; My CentOS 7 for libvirt:
  $PROGNAME \\
  ubuntu-{18.04,17.10}-desktop:{libvirt,virtualbox} \\
  ubuntu-{18.04,16.04,14.04}-server:{libvirt,virtualbox} \\
  my_ubuntu-{18.04,16.04,14.04}-server:{libvirt,virtualbox} \\
  my_centos-7:{libvirt,virtualbox}
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
        echo -e "\n\n*** Unsupported PACKER_VAGRANT_PROVIDER: \"$PACKER_VAGRANT_PROVIDER\" used from \"$BUILD\""
        exit 1
      ;;
    esac

    test -d $TMPDIR  || mkdir -v $TMPDIR
    test -d $LOG_DIR || mkdir -v $LOG_DIR

    echo -e "\n\n*** $MY_NAME | $MYBUILD - $PACKER_VAGRANT_PROVIDER/$PACKER_BUILDER_TYPE"

    case $MYBUILD in
      *centos*)
        export CENTOS_VERSION=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
        export CENTOS_TYPE="NetInstall"
        export NAME="${MY_NAME}-${CENTOS_VERSION}-x86_64"
        export PACKER_FILE="${MY_NAME}-${CENTOS_VERSION}.json"
        export DOCKER_ENV_PARAMETERS="-e CENTOS_VERSION=$CENTOS_VERSION -e CENTOS_TAG=$CENTOS_TAG -e CENTOS_TYPE=$CENTOS_TYPE -e NAME=$NAME"
        echo "* NAME: $NAME, CENTOS_VERSION: $CENTOS_VERSION, CENTOS_TAG: $CENTOS_TAG, CENTOS_TYPE: $CENTOS_TYPE, PACKER_FILE: $PACKER_FILE "
      ;;
      *ubuntu*)
        export UBUNTU_TYPE=`echo $MYBUILD | awk -F '-' '{ print $3 }'`
        export UBUNTU_VERSION=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export UBUNTU_CODENAME=`curl -s http://releases.ubuntu.com/ | sed -n "s@^<li><a href=\"\(.*\)/\">Ubuntu ${UBUNTU_VERSION}.*@\1@p" | head -1`
        export NAME="${MY_NAME}-${UBUNTU_VERSION}-${UBUNTU_TYPE}-amd64"
        export PACKER_FILE="${MY_NAME}-${UBUNTU_TYPE}.json"
        export DOCKER_ENV_PARAMETERS="-e UBUNTU_TYPE=$UBUNTU_TYPE -e UBUNTU_VERSION=$UBUNTU_VERSION -e UBUNTU_CODENAME=$UBUNTU_CODENAME -e NAME=$NAME"
        echo "* NAME: $NAME, UBUNTU_TYPE: $UBUNTU_TYPE, UBUNTU_CODENAME: $UBUNTU_CODENAME, PACKER_FILE: $PACKER_FILE"
      ;;
      *windows*)
        export WINDOWS_ARCH="x64"
        export WINDOWS_VERSION=`echo $MYBUILD | sed 's/.*windows-\([^-_]*\).*/\1/'`
        export PACKER_FILE="${MY_NAME}.json"

        case $MYBUILD in
          *windows-10*)
            export WINDOWS_EDITION="enterprise"
            export NAME="${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
            export ISO_URL="https://software-download.microsoft.com/download/pr/17134.1.180410-1804.rs4_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
            export ISO_CHECKSUM="27e4feb9102f7f2b21ebdb364587902a70842fb550204019d1a14b120918e455"

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
          *)
            echo "*** Unsupported Windows build type: \"$MYBUILD\" used from \"$BUILD\""
            exit 1
          ;;
        esac

        echo "* NAME: $NAME, WINDOWS_ARCH: $WINDOWS_ARCH, WINDOWS_VERSION: $WINDOWS_VERSION, WINDOWS_EDITION: $WINDOWS_EDITION, PACKER_FILE: $PACKER_FILE"
        test -f $VIRTIO_WIN_ISO || wget --continue $VIRTIO_WIN_ISO_URL -O $VIRTIO_WIN_ISO
        export DOCKER_ENV_PARAMETERS="-e WINDOWS_VERSION=$WINDOWS_VERSION -e NAME=$NAME -e ISO_URL=$ISO_URL -e ISO_CHECKSUM=$ISO_CHECKSUM -e VIRTIO_WIN_ISO=packer_cache/$(basename $VIRTIO_WIN_ISO)"
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
    if [ $USE_DOCKERIZED_PACKER = "true" ]; then
      docker run --rm -it -p $WINRM_SSH_PORT:2299 -p $VNC_PORT:5999 $DOCKER_ENV_PARAMETERS --privileged -v $PWD:/var/tmp/packer-templates/ -v $TMPDIR:/var/tmp/packer-templates/packer_cache/ peru/packer_qemu_virtualbox_ansible \
        build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" $PACKER_FILE 2>&1 | tee "${LOG_DIR}/${NAME}-${PACKER_BUILDER_TYPE}-packer.log"
    else
      $PACKER_BINARY build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" $PACKER_FILE 2>&1 | tee "${LOG_DIR}/${NAME}-${PACKER_BUILDER_TYPE}-packer.log"
    fi
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
