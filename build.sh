#!/bin/bash -eu

# Temporary directory where to store the iso images and other packer files
export TMPDIR=${TMPDIR:-$PWD/packer_cache}
# VirtIO win iso URL (https://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers)
export VIRTIO_WIN_ISO_URL=${VIRTIO_WIN_ISO_URL:-https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso}
export VIRTIO_WIN_ISO=${VIRTIO_WIN_ISO:-$TMPDIR/$(basename $VIRTIO_WIN_ISO_URL)}
# Do not use any GUI X11 windows
export HEADLESS=${HEADLESS:-true}
# Use packer, virtualboc, ansible in docker image
export USE_DOCKERIZED_PACKER=${USE_DOCKERIZED_PACKER:-true}
# Packer binary (doesn't apply of you are using Dockerized packer)
export PACKER_BINARY=${PACKER_BINARY:-packerio}
# Directory where all the images will be stored
export PACKER_IMAGES_OUTPUT_DIR=${PACKER_IMAGES_OUTPUT_DIR:-/var/tmp/packer-templates-images}
# Directory where to store the logs
export LOGDIR=${LOGDIR:-$PACKER_IMAGES_OUTPUT_DIR}
# Enable packer debug log if set to 1 (default 0)
export PACKER_LOG=${PACKER_LOG:-0}
# User docker / podman executable
if `which podman &> /dev/null`; then
  DOCKER_COMMAND=${DOCKER_COMMAND:-podman}
else
  DOCKER_COMMAND=${DOCKER_COMMAND:-docker}
fi


readonly PROGNAME=$(basename $0)
readonly ARGS="$@"


usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:
 * my_windows-10-enterprise-x64-eval-{libvirt,virtualbox}
 * windows-10-enterprise-x64-eval-{libvirt,virtualbox}
 * windows-server-2019-standard-x64-eval-{libvirt,virtualbox}
 * windows-server-2016-standard-x64-eval-{libvirt,virtualbox}
 * windows-server-2012_r2-standard-x64-eval-{libvirt,virtualbox}
 * ubuntu-18.10-desktop-amd64-{libvirt,virtualbox}
 * ubuntu-18.04-desktop-amd64-{libvirt,virtualbox}
 * ubuntu-18.04-server-amd64-{libvirt,virtualbox}
 * ubuntu-16.04-server-amd64-{libvirt,virtualbox}
 * ubuntu-14.04-server-amd64-{libvirt,virtualbox}
 * my_ubuntu-18.04-server-amd64-{libvirt,virtualbox}
 * my_ubuntu-16.04-server-amd64-{libvirt,virtualbox}
 * my_ubuntu-14.04-server-amd64-{libvirt,virtualbox}
 * my_centos-7-x86_64-{libvirt,virtualbox}

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2019 Standard Evaluation, Windows Server 2016 Standard Evaluation and Windows Server 2012 Standard Evaluation for Virtualbox and libvirt:
  $PROGNAME \\
    my_windows-10-enterprise-x64-eval-{libvirt,virtualbox} \\
    windows-10-enterprise-x64-eval-{libvirt,virtualbox} \\
    windows-server-2019-standard-x64-eval-{libvirt,virtualbox} \\
    windows-server-2016-standard-x64-eval-{libvirt,virtualbox} \\
    windows-server-2012_r2-standard-x64-eval-{libvirt,virtualbox}

Build Ubuntu Desktop 18.10, 18.04; Ubuntu Server 18.04, 16.04, 14.04; My Ubuntu Server 18.04, 16.04, 14.04; My CentOS 7 for libvirt and Virtualbox:
  $PROGNAME \\
    ubuntu-{18.10,18.04}-desktop-amd64-{libvirt,virtualbox} \\
    ubuntu-{18.04,16.04,14.04}-server-amd64-{libvirt,virtualbox} \\
    my_ubuntu-{18.04,16.04,14.04}-server-amd64-{libvirt,virtualbox} \\
    my_centos-7-x86_64-{libvirt,virtualbox}
EOF
}

cmdline() {
  BUILDS=$@

  if [ -z "$BUILDS" ]; then
    usage
    exit 0;
  fi

  for BUILD in $BUILDS; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*-}"
    export NAME="${BUILD%-*}"
    export MY_NAME=`echo $NAME | awk -F '-' '{ print $1 }'`

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

    test -d $TMPDIR                   || mkdir -v $TMPDIR
    test -d $PACKER_IMAGES_OUTPUT_DIR || mkdir -v $PACKER_IMAGES_OUTPUT_DIR
    test -d $LOGDIR                   || mkdir -v $LOGDIR

    echo -e "\n\n*** $MY_NAME | $NAME | $BUILD - $PACKER_VAGRANT_PROVIDER/$PACKER_BUILDER_TYPE"

    case $NAME in
      *centos*)
        export CENTOS_VERSION=`echo $NAME | awk -F '-' '{ print $2 }'`
        export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
        export CENTOS_TYPE="NetInstall"
        export PACKER_FILE="${MY_NAME}-${CENTOS_VERSION}.json"
        export DOCKER_ENV_PARAMETERS="-e CENTOS_VERSION -e CENTOS_TAG -e CENTOS_TYPE -e NAME"
        echo "* NAME: $NAME, CENTOS_VERSION: $CENTOS_VERSION, CENTOS_TAG: $CENTOS_TAG, CENTOS_TYPE: $CENTOS_TYPE, PACKER_FILE: $PACKER_FILE "
      ;;
      *ubuntu*)
        export UBUNTU_TYPE=`echo $NAME | awk -F '-' '{ print $3 }'`
        export UBUNTU_VERSION=`echo $NAME | awk -F '-' '{ print $2 }'`
        export UBUNTU_CODENAME=`curl -s http://releases.ubuntu.com/ | sed -n "s@^<li><a href=\"\(.*\)/\">Ubuntu ${UBUNTU_VERSION}.*@\1@p" | head -1`
        export PACKER_FILE="${MY_NAME}-${UBUNTU_TYPE}.json"
        export DOCKER_ENV_PARAMETERS="-e UBUNTU_TYPE -e UBUNTU_VERSION -e UBUNTU_CODENAME -e NAME"
        echo "* NAME: $NAME, UBUNTU_TYPE: $UBUNTU_TYPE, UBUNTU_CODENAME: $UBUNTU_CODENAME, PACKER_FILE: $PACKER_FILE"
      ;;
      *windows*)
        export WINDOWS_ARCH="x64"
        export WINDOWS_VERSION=`echo $NAME | sed -n -e 's/.*-\([0-9][0-9][0-9][0-9]\)[_-].*/\1/p' -e 's/.*-\([0-9][0-9]\)-.*/\1/p'`
        export PACKER_FILE="${MY_NAME}.json"
        export WINDOWS_EDITION=`echo $NAME | sed -e 's/.*-\([^-]*\)-x64-eval$/\1/'`

        case $NAME in
          *windows-10-enterprise*)
            export ISO_URL="https://software-download.microsoft.com/download/sg/17763.107.101029-1455.rs5_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
            export ISO_CHECKSUM="0278fc4638741f4a1dc85c39ed7fa76bb15fd582165f6ef036e9a9fb2f029351"
          ;;
          *windows-server-2019-*)
            export WINDOWS_TYPE="server"
            export ISO_URL="https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_SERVER_EVAL_x64FRE_en-us.iso"
            export ISO_CHECKSUM="dbb0ffbab5d114ce7370784c4e24740191fefdb3349917c77a53ff953dd10f72"
          ;;
          *windows-server-2016-*)
            export WINDOWS_TYPE="server"
            export ISO_URL="https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
            export ISO_CHECKSUM="1ce702a578a3cb1ac3d14873980838590f06d5b7101c5daaccbac9d73f1fb50f"
          ;;
          *windows-server-2012_r2-*)
            export WINDOWS_RELEASE="r2"
            export WINDOWS_TYPE="server"
            export ISO_URL="http://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
            export ISO_CHECKSUM="6612b5b1f53e845aacdf96e974bb119a3d9b4dcb5b82e65804ab7e534dc7b4d5"
          ;;
          *)
            echo "*** Unsupported Windows build type: \"$NAME\" used from \"$BUILD\""
            exit 1
          ;;
        esac

        echo "* NAME: $NAME, WINDOWS_ARCH: $WINDOWS_ARCH, WINDOWS_VERSION: $WINDOWS_VERSION, WINDOWS_EDITION: $WINDOWS_EDITION, PACKER_FILE: $PACKER_FILE"
        test -f $VIRTIO_WIN_ISO || wget --continue $VIRTIO_WIN_ISO_URL -O $VIRTIO_WIN_ISO
        export DOCKER_ENV_PARAMETERS="-e WINDOWS_VERSION -e NAME -e ISO_URL -e ISO_CHECKSUM -e VIRTIO_WIN_ISO=packer_cache/$(basename $VIRTIO_WIN_ISO)"
      ;;
      *)
        echo "*** Unsupported build type: \"$NAME\" used from \"$BUILD\""
        exit 1
      ;;
    esac

    packer_build
  done
}


packer_build() {
  if [ ! -f "${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box" ]; then
    if [ $USE_DOCKERIZED_PACKER = "true" ]; then
      $DOCKER_COMMAND pull peru/packer_qemu_virtualbox_ansible
      $DOCKER_COMMAND run --rm -t -u $(id -u):$(id -g) --privileged --tmpfs /dev/shm:size=67108864 --network host --name "packer_${BUILD}" $DOCKER_ENV_PARAMETERS \
        -v /dev/kvm:/dev/kvm \
        -v /dev/vboxdrv:/dev/vboxdrv \
        -v $PACKER_IMAGES_OUTPUT_DIR:/home/docker/packer_images_output_dir \
        -v $PWD:/home/docker/packer \
        -v $TMPDIR:/home/docker/packer/packer_cache \
        -e PACKER_LOG \
        -e PACKER_IMAGES_OUTPUT_DIR=/home/docker/packer_images_output_dir \
        peru/packer_qemu_virtualbox_ansible build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" $PACKER_FILE 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    else
      $PACKER_BINARY build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" $PACKER_FILE 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    fi
  else
    echo -e "\n* File ${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box already exists. Skipping....\n";
  fi
}



#######
# Main
#######

main() {
  cmdline $ARGS
}

main
