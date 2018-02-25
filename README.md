# Packer Templates mainly for the [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider

## Customized+Clean/Minimal boxes for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider

---

#### Github repository for bug reports or feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)


#### Vagrant Cloud repository

[https://app.vagrantup.com/peru](https://app.vagrantup.com/peru)


## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)


## Login Credentials

(root/Administrator password is "vagrant" or is not set )

* Username: vagrant
* Password: vagrant


## VM Specifications

* Libvirt Provider
* VirtIO dynamic Hard Disk (up to 50 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)
* Channel Device (com.redhat.spice.0)


## Configuration

#### Customized Linux installation
* there are usually many customization depends on distribution - all are described in Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible).
* added packages: see the [Common list](https://github.com/ruzickap/packer-templates/blob/master/ansible/roles/common_defaults/vars/main.yml) and [Debian list](https://github.com/ruzickap/packer-templates/blob/master/ansible/roles/common_defaults/vars/Debian.yml) or [CentOS list](https://github.com/ruzickap/packer-templates/blob/master/ansible/roles/common_defaults/vars/RedHat.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes


#### Minimal Linux installation
* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using ext4/xfs filesystem (all files in one partition)
* no swap


#### Minimal Windows installation
* UTC timezone
* IEHarden disabled
* Home Page set to "about:blank"
* First Run Wizard disabled
* Firewall allows Remote Desktop connections
* AutoActivation skipped
* DoNotOpenInitialConfigurationTasksAtLogon set to true
* WinRM (ssl) enabled
* New Network Window turned off
* Administrator account enabled
* EnableLUA

Installed during installation:
* NetKVM: VirtIO Network driver
* qxldod: QXL graphics driver
* viostor: VirtIO Block driver (VirtIO SCSI controller driver)

Installed when the OS is installed via Ansible playbook [win.yml](https://github.com/ruzickap/packer-templates/blob/master/ansible/win.yml):
* vioscsi: Support for VirtIO SCSI pass-through controller
* Balloon: VirtIO Memory Balloon driver
* viorng: VirtIO RNG Device driver
* vioser: VirtIO Serial Driver
* vioinput: VirtIO Input Driver - support for new QEMU input devices virtio-keyboard-pci, virtio-mouse-pci, virtio-tablet-pci, virtio-input-host-pci
* pvpanic: QEMU pvpanic device driver
* qemu-ga: [Qemu Guest Agent](http://wiki.libvirt.org/page/Qemu_guest_agent)

Image was finalized using sysprep with [unattended.xml](https://github.com/ruzickap/packer-templates/blob/master/scripts/win-common/unattend.xml).

## Helper scripts

 * `build.sh` - build single image specified on command line
 * `build_all.sh` - builds all images
 * `build_all_remote_ssh.sh` - connects to remote Ubuntu server, install the necessary packages for building images and execute `build_all.sh`
 * `vagrant_init_destroy_boxes.sh` - tests all *.box images in the current directory using `vagrant add/up/ssh/winrm/destroy`
