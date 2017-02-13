# [My CentOS ${CENTOS_VERSION}](https://www.centos.org/)

## Modified CentOS ${CENTOS_VERSION} ${UBUNTU_ARCH} box with [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider.

---

#### Github repository for bug reports or feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)


## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)


## Getting started

Install and connect to the box:

\`\`\`
mkdir ${NAME}
cd ${NAME}
vagrant init ${USER}/${NAME}
VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up
vagrant ssh
\`\`\`


## Login Credentials

Root password is: vagrant

* Username: vagrant
* Password: vagrant


## VM Specifications

* Libvirt Provider
* VirtIO dynamic Hard Disk (up to 50 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)


## Configuration

Based on: CentOS-${CENTOS_VERSION}-${CENTOS_ARCH}-${CENTOS_TYPE}-${CENTOS_TAG}.iso

#### Preconfigured installation - see the [kickstart file](https://github.com/ruzickap/packer-templates/blob/master/http/centos${CENTOS_VERSION}/my-ks.cfg) and Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible) applied.

* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using btrfs filesystem (all files in one partition)
* no swap

---

* added packages: see the [Common list](https://github.com/ruzickap/packer-templates/blob/master/ansible/vars/common_variables.yml) and [CentOS list](https://github.com/ruzickap/packer-templates/blob/master/ansible/vars/RedHat.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes
