#!/bin/bash -eux

if grep -q QEMU /proc/scsi/scsi; then
  echo "*** Installing spice-vdagent"

  export DEBIAN_FRONTEND="noninteractive"
  apt-get install -y -qq --no-install-recommends spice-vdagent
fi
