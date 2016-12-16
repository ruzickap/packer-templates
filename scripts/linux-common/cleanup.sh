#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}

# Make sure udev does not block our network - http://6.ptmc.org/?p=164
echo "==> Cleaning up udev rules"
rm -rf /dev/.udev/ /lib/udev/rules.d/75-persistent-net-generator.rules

#Stop logging services
service rsyslog stop


if [ -f /etc/os-release ] && grep -iq debian /etc/os-release; then
  # Debian based machines

  export DEBIAN_FRONTEND="noninteractive"

  # Add delay to prevent "vagrant reload" from failing
  echo "pre-up sleep 2" >> /etc/network/interfaces

  echo "==> Cleaning up leftover dhcp leases"
  # Ubuntu 10.04
  if [ -d "/var/lib/dhcp3" ]; then
      rm /var/lib/dhcp3/*
  fi
  # Ubuntu 12.04 & 14.04
  if [ -d "/var/lib/dhcp" ]; then
      rm /var/lib/dhcp/*
  fi

  # Cleanup apt cache
  apt-get -y autoremove --purge
  apt-get -y clean
  apt-get -y autoclean
else
  # RHEL based machines

  service auditd stop

  #Remove the traces of the template MAC address and UUIDs
  sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0

  #Clean out yum
  yum clean all
fi


echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/${SSH_USER}/.bash_history

# Clean up log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

echo "==> Clearing last login information"
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY_FILE bs=1M &> /dev/null  || echo "dd exit code $? is suppressed"
rm -f /EMPTY_FILE

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early before the large files are deleted
sync
