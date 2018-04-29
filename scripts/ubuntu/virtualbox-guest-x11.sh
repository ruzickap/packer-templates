#!/bin/bash -eux

#The script is used for graphic environment

if grep -q VBOX /proc/scsi/scsi; then
  echo "*** Installing virtualbox-guest-x11"

  export DEBIAN_FRONTEND="noninteractive"
  apt-get install -y -qq --no-install-recommends virtualbox-guest-x11
fi
