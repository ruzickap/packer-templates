# [My Ubuntu ${UBUNTU_VERSION} ${UBUNTU_TYPE^}](http://www.ubuntu.com/${UBUNTU_TYPE})

## Modified Ubuntu ${UBUNTU_TYPE^} ${UBUNTU_ARCH} box with [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider.

---

#### Github repository for bug reports or feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)


## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)

Here are the steps for latest Fedora how to install Vagrant from the official web pages:
\`\`\`
dnf remove vagrant
dnf install -y libvirt-daemon-kvm qemu-kvm libvirt-devel
dnf install -y https://releases.hashicorp.com/vagrant/2.0.2/vagrant_2.0.2_x86_64.rpm
vagrant plugin install vagrant-libvirt
\`\`\`


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

#### Preconfigured installation - see the [preseed file](https://github.com/ruzickap/packer-templates/blob/master/http/ubuntu-${UBUNTU_TYPE}/my-preseed.cfg) and Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible/) applied.

* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using ext4 filesystem (all files in one partition)
* no swap

---

* added packages: see the [Common list](https://github.com/ruzickap/packer-templates/blob/master/ansible/vars/common_variables.yml) and [Debian list](https://github.com/ruzickap/packer-templates/blob/master/ansible/vars/Debian.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes
