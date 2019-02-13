# [Ubuntu ${UBUNTU_VERSION} ${UBUNTU_TYPE^}](http://www.ubuntu.com/${UBUNTU_TYPE})

## Clean + Minimal + Latest Ubuntu ${UBUNTU_TYPE^} ${UBUNTU_ARCH} base box for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) Vagrant providers

---

### Github repository for bug reports or feature requests

* [https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)

## Requirements

* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)
* [VirtualBox](https://www.virtualbox.org/)

Here are the steps for latest Fedora/Ubuntu to install Vagrant and vagrant-libvirt + KVM:
\`\`\`bash
# Fedora
dnf install -y vagrant-libvirt

# Ubuntu
apt install -y libvirt-bin vagrant-libvirt
\`\`\`

## Getting started

Install and connect to the box:

\`\`\`bash
mkdir ${NAME}
cd ${NAME}
vagrant init ${VAGRANT_CLOUD_USER}/${NAME}
VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up
# or
VAGRANT_DEFAULT_PROVIDER=virtualbox vagrant up
vagrant ssh
\`\`\`

## Login Credentials

(root password is not set)

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

### Minimal installation - see the [preseed file](https://github.com/ruzickap/packer-templates/blob/master/http/ubuntu-${UBUNTU_TYPE}/preseed.cfg)
(it's very close to official Ubuntu [preseed file](https://help.ubuntu.com/lts/installation-guide/example-preseed.txt))

* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using ext4 filesystem (all files in one partition)
* no swap

### Additional Drivers installed for VirtualBox boxes

* VirtualBox Guest Additions
