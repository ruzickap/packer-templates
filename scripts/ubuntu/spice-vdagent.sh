#!/bin/bash -eux

apt-get install -y -q spice-vdagent

# https://bugs.launchpad.net/ubuntu/+source/spice-vdagent/+bug/1633609
echo 'SPICE_VDAGENTD_EXTRA_ARGS="-X"' > /etc/default/spice-vdagentd
