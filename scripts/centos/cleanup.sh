#!/bin/bash -eux

SSH_USER=${SSH_USERNAME:-vagrant}

#Stop logging services
service rsyslog stop
service auditd stop

# Make sure udev does not block our network - http://6.ptmc.org/?p=164
echo "==> Cleaning up udev rules"
rm -rf /dev/.udev/ /lib/udev/rules.d/70-*

#Remove the traces of the template MAC address and UUIDs
sed -i '/^(HWADDR|UUID)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0

echo "==> Cleaning up tmp"
rm -rf /tmp/* /var/tmp/*

#Remove the SSH host keys
rm -f /etc/ssh/*key*

#Clean out yum
yum clean all

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/${SSH_USER}/.bash_history

#Force the logs to rotate & remove old logs we don't need
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz
/bin/rm -f /var/log/dmesg.old
/bin/rm -rf /var/log/anaconda

echo "==> Clearing last login information"
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

# Make sure we wait until all the data is written to disk.
sync
