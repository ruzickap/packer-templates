#!/bin/bash -eux

#The script is used for non-graphic environment (server)

if grep -q VBOX /proc/scsi/scsi; then
  echo "*** Installing virtualbox-guest-utils"

  export DEBIAN_FRONTEND="noninteractive"
  apt-get install -y -qq --no-install-recommends virtualbox-guest-utils
fi
