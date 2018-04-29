#!/bin/bash -eux


if grep -q QEMU /proc/scsi/scsi; then
  echo "*** Installing spice-vdagent"

  export DEBIAN_FRONTEND="noninteractive"
  apt-get install -y -qq --no-install-recommends spice-vdagent

  # https://bugs.launchpad.net/ubuntu/+source/spice-vdagent/+bug/1633609
  echo 'SPICE_VDAGENTD_EXTRA_ARGS="-X"' > /etc/default/spice-vdagentd
fi
