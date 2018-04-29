#!/bin/bash -eux

# This script should fix problems with hanged ssh session when the Ubuntu server is rebooted
# The same problem appear when using "vagrant halt"
# I saw this issue in minimal installation for Xenial
# Description: https://serverfault.com/questions/706475/ssh-sessions-hang-on-shutdown-reboot

export DEBIAN_FRONTEND="noninteractive"
apt-get install -qq -y --no-install-recommends libpam-systemd
