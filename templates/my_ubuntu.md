# [My Ubuntu ${UBUNTU_VERSION} ${UBUNTU_TYPE_UC}](http://www.ubuntu.com/${UBUNTU_TYPE})

Modified Ubuntu ${UBUNTU_TYPE_UC} ${UBUNTU_ARCH} box for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)
and [VirtualBox](https://www.vagrantup.com/docs/providers/virtualbox) Vagrant providers.

---

## GitHub repository for bug reports or feature requests

* [https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)
* Git commit hash: [${GITHUB_SHA}](https://github.com/ruzickap/packer-templates/tree/${GITHUB_SHA})

## Requirements

* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)
* [VirtualBox](https://www.virtualbox.org/)

Here are the steps for latest Fedora/Ubuntu to install Vagrant
and vagrant-libvirt + KVM:

```bash
# Fedora
dnf install -y vagrant-libvirt

# Ubuntu
apt install -y libvirt-bin vagrant-libvirt
```

## Getting started

Install and connect to the box:

```bash
mkdir ${NAME}
cd ${NAME}
vagrant init ${VAGRANT_CLOUD_USER}/${NAME}
VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up
# or
VAGRANT_DEFAULT_PROVIDER=virtualbox vagrant up
vagrant ssh
```

## Login Credentials

Root password is: vagrant

* Username: vagrant
* Password: vagrant

## VM Specifications

Drivers / Devices added for the VMs for specific providers.

### Libvirt

* Libvirt Provider
* VirtIO dynamic Hard Disk (up to 50 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)

### VirtualBox

* SATA Disk

## Configuration

### Preconfigured installation

See the [preseed file](https://github.com/ruzickap/packer-templates/blob/main/http/ubuntu-${UBUNTU_TYPE}/my-preseed.cfg)
and Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/main/ansible/)

* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using ext4 filesystem (all files in one partition)
* no swap

---

* added packages: see the [Common list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/vars/main.yml)
  and [Debian list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/vars/Debian.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes

### Additional Drivers installed for VirtualBox boxes

* VirtualBox Guest Additions
