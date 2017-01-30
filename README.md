# Packer Templates mainly for the [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider

## Customized+Clean/Minimal boxes for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider.

---

#### Github repository for bug reports or  feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)


#### Atlas/Vagrant repository

[https://atlas.hashicorp.com/peru](https://atlas.hashicorp.com/peru)


## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)


## Login Credentials

(root password is "vagrant" or is not set )

* Username: vagrant
* Password: vagrant


## VM Specifications

* Libvirt Provider
* VirtIO dynamic Hard Disk (up to 50 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)


## Configuration

#### Customized installation

* there are usually many customization depends on distribution - all are described in Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible).
* added packages: see the [Common list](https://github.com/ruzickap/packer-templates/blob/master/ansible/roles/common_defaults/vars/main.yml) and [Debian list](https://github.com/ruzickap/packer-templates/blob/master/ansible/roles/common_defaults/vars/Debian.yml) or [CentOS list](https://github.com/ruzickap/packer-templates/blob/master/ansible/roles/common_defaults/vars/RedHat.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes


#### Minimal installation

* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using btrfs filesystem (all files in one partition)
* no swap
