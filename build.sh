#!/usr/bin/env bash

set -eu -o pipefail

# Packer cache directory (where to store the iso images)
export PACKER_CACHE_DIR=${PACKER_CACHE_DIR:-${PWD}/packer_cache}
# VirtIO win iso URL (https://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers)
export VIRTIO_WIN_ISO_URL=${VIRTIO_WIN_ISO_URL:-https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso}
export VIRTIO_WIN_ISO=${VIRTIO_WIN_ISO:-${PACKER_CACHE_DIR}/$(basename "${VIRTIO_WIN_ISO_URL}")}
# Do not use any GUI X11 windows
export HEADLESS=${HEADLESS:-true}
# Qemu Accelerator - use kvm for Linux and hvf for MacOS
export ACCELERATOR=${ACCELERATOR:-kvm}
# Packer binary
export PACKER_BINARY=${PACKER_BINARY:-packer}
# Directory where all the images will be stored
export PACKER_IMAGES_OUTPUT_DIR=${PACKER_IMAGES_OUTPUT_DIR:-/var/tmp/packer-templates-images}
# Directory where to store the logs
export LOGDIR=${LOGDIR:-/var/tmp/packer-templates-logs}
# Enable packer debug log if set to 1 (default 0)
export PACKER_LOG=${PACKER_LOG:-0}
# Max amount of time which packer can run (default 5 hours) - this prevent packer form running forever when something goes bad during provisioning/build process
export PACKER_RUN_TIMEOUT=${PACKER_RUN_TIMEOUT:-18000}
# Use /var/tmp as temporary directory for Packer, because export of VM images can consume lot of disk space
export TMPDIR=${TMPDIR:-/var/tmp}

readonly PROGNAME=$(basename "$0")
readonly ARGS=$*

usage() {
  cat <<- EOF
Usage: ${PROGNAME} options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:
 * my_windows-10-enterprise-x64-eval-{libvirt,virtualbox}
 * windows-10-enterprise-x64-eval-{libvirt,virtualbox}
 * windows-server-2019-standard-x64-eval-{libvirt,virtualbox}
 * windows-server-2016-standard-x64-eval-{libvirt,virtualbox}
 * windows-server-2012_r2-standard-x64-eval-{libvirt,virtualbox}
 * ubuntu-20.04-desktop-amd64-{libvirt,virtualbox}
 * ubuntu-18.04-desktop-amd64-{libvirt,virtualbox}
 * ubuntu-20.04-server-amd64-{libvirt,virtualbox}
 * ubuntu-18.04-server-amd64-{libvirt,virtualbox}
 * ubuntu-16.04-server-amd64-{libvirt,virtualbox}
 * my_ubuntu-20.04-server-amd64-{libvirt,virtualbox}
 * my_ubuntu-18.04-server-amd64-{libvirt,virtualbox}
 * my_ubuntu-16.04-server-amd64-{libvirt,virtualbox}
 * my_centos-7-x86_64-{libvirt,virtualbox}

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2019 Standard Evaluation, Windows Server 2016 Standard Evaluation and Windows Server 2012 Standard Evaluation for Virtualbox and libvirt:
  ${PROGNAME} \\
    my_windows-10-enterprise-x64-eval-{libvirt,virtualbox} \\
    windows-10-enterprise-x64-eval-{libvirt,virtualbox} \\
    windows-server-2019-standard-x64-eval-{libvirt,virtualbox} \\
    windows-server-2016-standard-x64-eval-{libvirt,virtualbox} \\
    windows-server-2012_r2-standard-x64-eval-{libvirt,virtualbox}

Build Ubuntu Desktop 20.04, 18.04; Ubuntu Server 20.04, 18.04, 16.04; My Ubuntu Server 20.04, 18.04, 16.04; My CentOS 7 for libvirt and Virtualbox:
  ${PROGNAME} \\
    ubuntu-{20.04,18.04}-desktop-amd64-{libvirt,virtualbox} \\
    ubuntu-{20.04,18.04,16.04}-server-amd64-{libvirt,virtualbox} \\
    my_ubuntu-{20.04,18.04,16.04}-server-amd64-{libvirt,virtualbox} \\
    my_centos-7-x86_64-{libvirt,virtualbox}
EOF
}

cmdline() {
  BUILDS=$*

  if [[ -z "${BUILDS}" ]]; then
    usage
    exit 0;
  fi

  for BUILD in ${BUILDS}; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*-}"
    export NAME="${BUILD%-*}"
    MY_NAME=$(echo "${NAME}" | awk -F '-' '{ print $1 }')
    export MY_NAME

    case ${PACKER_VAGRANT_PROVIDER} in
      libvirt )
        export PACKER_BUILDER_TYPE="qemu"
      ;;
      virtualbox )
        export PACKER_BUILDER_TYPE="virtualbox-iso"
      ;;
      *)
        echo -e "\n\n*** Unsupported PACKER_VAGRANT_PROVIDER: \"${PACKER_VAGRANT_PROVIDER}\" used from \"${BUILD}\""
        exit 1
      ;;
    esac

    test -d "${PACKER_CACHE_DIR}"         || mkdir -v "${PACKER_CACHE_DIR}"
    test -d "${PACKER_IMAGES_OUTPUT_DIR}" || mkdir -v "${PACKER_IMAGES_OUTPUT_DIR}"
    test -d "${LOGDIR}"                   || mkdir -v "${LOGDIR}"

    echo -e "\n\n*** ${MY_NAME} | ${NAME} | ${BUILD} - ${PACKER_VAGRANT_PROVIDER}/${PACKER_BUILDER_TYPE}"

    case ${NAME} in
      *centos*)
        CENTOS_VERSION=$(echo "${NAME}" | awk -F '-' '{ print $2 }')
        export CENTOS_VERSION
        CENTOS_TAG=$(curl -s "ftp://ftp.cvut.cz/centos/${CENTOS_VERSION}/isos/x86_64/sha256sum.txt" | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1)
        export CENTOS_TAG
        export CENTOS_TYPE="NetInstall"
        ISO_CHECKSUM=$(curl -s "ftp://ftp.cvut.cz/centos/${CENTOS_VERSION}/isos/x86_64/sha256sum.txt" | awk "/CentOS-${CENTOS_VERSION}-x86_64-${CENTOS_TYPE}-${CENTOS_TAG}.iso/ { print \$1 }")
        export PACKER_FILE="${MY_NAME}-${CENTOS_VERSION}.json"
        echo "* NAME: ${NAME}, CENTOS_VERSION: ${CENTOS_VERSION}, CENTOS_TAG: ${CENTOS_TAG}, CENTOS_TYPE: ${CENTOS_TYPE}, PACKER_FILE: ${PACKER_FILE}"
      ;;
      *ubuntu*)
        UBUNTU_TYPE=$(echo "${NAME}" | awk -F '-' '{ print $3 }')
        export UBUNTU_TYPE
        UBUNTU_VERSION=$(echo "${NAME}" | awk -F '-' '{ print $2 }')
        export UBUNTU_VERSION
        UBUNTU_CODENAME=$(curl -s http://releases.ubuntu.com/ | sed -n "s@.*<a href=\"\([a-z]*\)/\">.*Ubuntu ${UBUNTU_VERSION}.*@\1@p" | head -1)
        if curl --fail --silent --head --output /dev/null "http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_CODENAME}-updates/main/installer-amd64/current/images/SHA256SUMS" ; then
          export UBUNTU_IMAGES_URL=http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_CODENAME}-updates/main/installer-amd64/current/images
        elif curl --fail --silent --head --output /dev/null "http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_CODENAME}/main/installer-amd64/current/legacy-images/SHA256SUMS" ; then
          export UBUNTU_IMAGES_URL=http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_CODENAME}/main/installer-amd64/current/legacy-images
        else
          export UBUNTU_IMAGES_URL=http://archive.ubuntu.com/ubuntu/dists/${UBUNTU_CODENAME}/main/installer-amd64/current/images
        fi
        ISO_CHECKSUM=$(curl -s "${UBUNTU_IMAGES_URL}/SHA256SUMS" | awk '/.\/netboot\/mini.iso/ { print $1 }')
        export PACKER_FILE="${MY_NAME}-${UBUNTU_TYPE}.json"
        echo "* NAME: ${NAME}, UBUNTU_TYPE: ${UBUNTU_TYPE}, PACKER_FILE: ${PACKER_FILE}, UBUNTU_IMAGES_URL: ${UBUNTU_IMAGES_URL}"
      ;;
      *windows*)
        export WINDOWS_ARCH="x64"
        WINDOWS_VERSION=$(echo "${NAME}" | sed -n -e 's/.*-\([0-9][0-9][0-9][0-9]\)[_-].*/\1/p' -e 's/.*-\([0-9][0-9]\)-.*/\1/p')
        export WINDOWS_VERSION
        export PACKER_FILE="${MY_NAME}.json"
        WINDOWS_EDITION=$(echo "${NAME}" | awk -F - '{ print $(NF-2) }')
        export WINDOWS_EDITION

        case ${NAME} in
          *windows-10-enterprise*)
            export ISO_URL="https://software-download.microsoft.com/download/pr/19041.264.200511-0456.vb_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
          ;;
          *windows-server-2019-*)
            export WINDOWS_TYPE="server"
            export ISO_URL="https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
          ;;
          *windows-server-2016-*)
            export WINDOWS_TYPE="server"
            export ISO_URL="https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
          ;;
          *windows-server-2012_r2-*)
            export WINDOWS_RELEASE="r2"
            export WINDOWS_TYPE="server"
            export ISO_URL="http://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
          ;;
          *)
            echo "*** Unsupported Windows build type: \"${NAME}\" used from \"${BUILD}\""
            exit 1
          ;;
        esac

        echo "* NAME: ${NAME}, WINDOWS_ARCH: ${WINDOWS_ARCH}, WINDOWS_VERSION: ${WINDOWS_VERSION}, WINDOWS_EDITION: ${WINDOWS_EDITION}, PACKER_FILE: ${PACKER_FILE}"
        ISO_CHECKSUM=$(awk "/$(basename ${ISO_URL})/ { print \$1 }" win_iso.sha256)
        test -f "${VIRTIO_WIN_ISO}" || curl -L "${VIRTIO_WIN_ISO_URL}" --output "${VIRTIO_WIN_ISO}"
      ;;
      *)
        echo "*** Unsupported build type: \"${NAME}\" used from \"${BUILD}\""
        exit 1
      ;;
    esac

    export ISO_CHECKSUM
    packer_build
  done
}


packer_build() {
  if [[ ! -f "${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box" ]]; then
    ${PACKER_BINARY} build -only="${PACKER_BUILDER_TYPE}" -color=false -var "headless=${HEADLESS}" -var "accelerator=${ACCELERATOR}" "${PACKER_FILE}" 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    ln -rfs "${PACKER_CACHE_DIR}/$(echo -n "${ISO_CHECKSUM}" | sha1sum | awk '{ print $1 }').iso" "${PACKER_CACHE_DIR}/${NAME}.iso"
  else
    echo -e "\n* File ${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box already exists. Skipping....\n";
  fi
}



#######
# Main
#######

main() {
  cmdline "${ARGS}"
}

main
