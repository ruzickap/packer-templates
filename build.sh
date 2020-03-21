#!/bin/bash -eu

# Temporary directory where to store the iso images and other packer files
export TMPDIR=${TMPDIR:-$PWD/packer_cache}
# VirtIO win iso URL (https://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers)
export VIRTIO_WIN_ISO_URL=${VIRTIO_WIN_ISO_URL:-https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso}
export VIRTIO_WIN_ISO=${VIRTIO_WIN_ISO:-$TMPDIR/$(basename "$VIRTIO_WIN_ISO_URL")}
# Do not use any GUI X11 windows
export HEADLESS=${HEADLESS:-true}
# Use packer, virtualboc, ansible in docker image
export USE_DOCKERIZED_PACKER=${USE_DOCKERIZED_PACKER:-false}
# Packer binary (doesn't apply of you are using Dockerized packer)
export PACKER_BINARY=${PACKER_BINARY:-packerio}
# Directory where all the images will be stored
export PACKER_IMAGES_OUTPUT_DIR=${PACKER_IMAGES_OUTPUT_DIR:-/var/tmp/packer-templates-images}
# Directory where to store the logs
export LOGDIR=${LOGDIR:-$PACKER_IMAGES_OUTPUT_DIR}
# Enable packer debug log if set to 1 (default 0)
export PACKER_LOG=${PACKER_LOG:-0}
# Max amount of time which packer can run (default 5 hours) - this prevent packer form running forever when something goes bad during provisioning/build process
export PACKER_RUN_TIMEOUT=${PACKER_RUN_TIMEOUT:-18000}
# User docker / podman executable
if command -v podman &> /dev/null; then
  DOCKER_COMMAND=${DOCKER_COMMAND:-podman}
else
  DOCKER_COMMAND=${DOCKER_COMMAND:-docker}
fi


readonly PROGNAME=$(basename "$0")
readonly ARGS=$*

set -o pipefail

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
 * ubuntu-19.10-desktop-amd64-{libvirt,virtualbox}
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

Build Ubuntu Desktop 19.10, 18.04; Ubuntu Server 18.04, 16.04, 14.04; My Ubuntu Server 18.04, 16.04, 14.04; My CentOS 7 for libvirt and Virtualbox:
  $PROGNAME \\
    ubuntu-{19.10,18.04}-desktop-amd64-{libvirt,virtualbox} \\
    ubuntu-{18.04,16.04,14.04}-server-amd64-{libvirt,virtualbox} \\
    my_ubuntu-{18.04,16.04,14.04}-server-amd64-{libvirt,virtualbox} \\
    my_centos-7-x86_64-{libvirt,virtualbox}
EOF
}

cmdline() {
  BUILDS=$*

  if [ -z "$BUILDS" ]; then
    usage
    exit 0;
  fi

  for BUILD in $BUILDS; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*-}"
    export NAME="${BUILD%-*}"
    MY_NAME=$(echo "$NAME" | awk -F '-' '{ print $1 }')
    export MY_NAME

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

    test -d "$TMPDIR"                   || mkdir -v "$TMPDIR"
    test -d "$PACKER_IMAGES_OUTPUT_DIR" || mkdir -v "$PACKER_IMAGES_OUTPUT_DIR"
    test -d "$LOGDIR"                   || mkdir -v "$LOGDIR"

    echo -e "\n\n*** $MY_NAME | $NAME | $BUILD - $PACKER_VAGRANT_PROVIDER/$PACKER_BUILDER_TYPE"

    case $NAME in
      *centos*)
        CENTOS_VERSION=$(echo "$NAME" | awk -F '-' '{ print $2 }')
        export CENTOS_VERSION
        CENTOS_TAG=$(curl -s "ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha256sum.txt" | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1)
        export CENTOS_TAG
        export CENTOS_TYPE="NetInstall"
        ISO_CHECKSUM=$(curl -s "ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha256sum.txt" | awk "/CentOS-${CENTOS_VERSION}-x86_64-${CENTOS_TYPE}-${CENTOS_TAG}.iso/ { print \$1 }")
        export ISO_CHECKSUM
        export PACKER_FILE="${MY_NAME}-${CENTOS_VERSION}.json"
        export DOCKER_ENV_PARAMETERS="-e CENTOS_VERSION -e CENTOS_TAG -e CENTOS_TYPE -e NAME"
        echo "* NAME: $NAME, CENTOS_VERSION: $CENTOS_VERSION, CENTOS_TAG: $CENTOS_TAG, CENTOS_TYPE: $CENTOS_TYPE, PACKER_FILE: $PACKER_FILE "
      ;;
      *ubuntu*)
        UBUNTU_TYPE=$(echo "$NAME" | awk -F '-' '{ print $3 }')
        export UBUNTU_TYPE
        UBUNTU_VERSION=$(echo "$NAME" | awk -F '-' '{ print $2 }')
        export UBUNTU_VERSION
        UBUNTU_CODENAME=$(curl -s http://releases.ubuntu.com/ | sed -n "s@.*<a href=\"\([a-z]*\)/\">.*Ubuntu ${UBUNTU_VERSION}.*@\1@p" | head -1)
        export UBUNTU_CODENAME
        ISO_CHECKSUM=$(curl -s "http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_CODENAME}/main/installer-amd64/current/images/SHA256SUMS" | awk '/.\/netboot\/mini.iso/ { print $1 }')
        export ISO_CHECKSUM
        export PACKER_FILE="${MY_NAME}-${UBUNTU_TYPE}.json"
        export DOCKER_ENV_PARAMETERS="-e UBUNTU_TYPE -e UBUNTU_VERSION -e UBUNTU_CODENAME -e NAME"
        echo "* NAME: $NAME, UBUNTU_TYPE: $UBUNTU_TYPE, UBUNTU_CODENAME: $UBUNTU_CODENAME, PACKER_FILE: $PACKER_FILE"
      ;;
      *windows*)
        export WINDOWS_ARCH="x64"
        WINDOWS_VERSION=$(echo "$NAME" | sed -n -e 's/.*-\([0-9][0-9][0-9][0-9]\)[_-].*/\1/p' -e 's/.*-\([0-9][0-9]\)-.*/\1/p')
        export WINDOWS_VERSION
        export PACKER_FILE="${MY_NAME}.json"
        WINDOWS_EDITION=$(echo "$NAME" | awk -F - '{ print $(NF-2) }')
        export WINDOWS_EDITION

        case $NAME in
          *windows-10-enterprise*)
            export ISO_URL="https://software-download.microsoft.com/download/pr/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
            export ISO_CHECKSUM="9ef81b6a101afd57b2dbfa44d5c8f7bc94ff45b51b82c5a1f9267ce2e63e9f53"
          ;;
          *windows-server-2019-*)
            export WINDOWS_TYPE="server"
            export ISO_URL="https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
            export ISO_CHECKSUM="549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
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
        test -f "$VIRTIO_WIN_ISO" || wget --continue "$VIRTIO_WIN_ISO_URL" -O "$VIRTIO_WIN_ISO"
        DOCKER_ENV_PARAMETERS="-e WINDOWS_VERSION -e NAME -e ISO_URL -e ISO_CHECKSUM -e VIRTIO_WIN_ISO=packer_cache/$(basename "$VIRTIO_WIN_ISO")"
        export DOCKER_ENV_PARAMETERS
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
    set -x
    if [ "$USE_DOCKERIZED_PACKER" = "true" ]; then
      $DOCKER_COMMAND pull peru/packer_qemu_virtualbox_ansible
      $DOCKER_COMMAND run --rm -t -u "$(id -u):$(id -g)" --privileged --tmpfs /dev/shm:size=67108864 --network host --name "packer_${BUILD}" "$DOCKER_ENV_PARAMETERS" \
        -v "$PACKER_IMAGES_OUTPUT_DIR:/home/docker/packer_images_output_dir" \
        -v "$PWD:/home/docker/packer" \
        -v "$TMPDIR:/home/docker/packer/packer_cache" \
        -e PACKER_RUN_TIMEOUT \
        -e PACKER_LOG \
        -e PACKER_IMAGES_OUTPUT_DIR=/home/docker/packer_images_output_dir \
        peru/packer_qemu_virtualbox_ansible build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" "$PACKER_FILE" 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    else
      $PACKER_BINARY build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS" "$PACKER_FILE" 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    fi
    test -L "${TMPDIR}/${NAME}.iso" || ln -rvs "${TMPDIR}/$(echo -n $ISO_CHECKSUM | sha1sum | awk '{ print $1 }').iso" "${TMPDIR}/${NAME}.iso"
  else
    echo -e "\n* File ${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box already exists. Skipping....\n";
  fi
}



#######
# Main
#######

main() {
  cmdline "$ARGS"
}

main
