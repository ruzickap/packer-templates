#!/bin/bash -eux

#The script is used for non-graphic environment (server)

if grep -q VBOX /proc/scsi/scsi; then
  echo "*** Installing virtualbox-guest-utils"

  export DEBIAN_FRONTEND="noninteractive"

  # Method 1: from package manager
  # apt-get install -y -qq --no-install-recommends virtualbox-guest-utils

  # Method 2: from ISO
  # Install dependencies
  apt-get update
  apt-get install -y curl linux-headers-$(uname -r) build-essential dkms

  ## Fetch latest version
  BASE_URL="https://download.virtualbox.org/virtualbox"
  VERSION="$(curl -fsSL "${BASE_URL}/LATEST-STABLE.TXT")"

  ## Install
  ADDITIONS_ISO="VBoxGuestAdditions_${VERSION}.iso"
  ADDITIONS_PATH="/media/VBoxGuestAdditions"
  wget --quiet "${BASE_URL}/${VERSION}/${ADDITIONS_ISO}"
  mkdir "${ADDITIONS_PATH}"
  mount -o loop,ro "${ADDITIONS_ISO}" "${ADDITIONS_PATH}"
  # Return code when success is 2
  "${ADDITIONS_PATH}/VBoxLinuxAdditions.run" --nox11 || [ "$?" = 2 ] && true || false
  rm "${ADDITIONS_ISO}"
  umount "${ADDITIONS_PATH}"
  rmdir "${ADDITIONS_PATH}"
fi
