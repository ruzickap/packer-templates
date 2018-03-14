# Packer Templates mainly for the Vagrant [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) provider

## Customized+Clean/Minimal boxes for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) provider

[![Build Status](https://travis-ci.org/ruzickap/packer-templates.svg)](https://travis-ci.org/ruzickap/packer-templates)

---

#### Github repository for bug reports or feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)


#### Vagrant Cloud repository

[https://app.vagrantup.com/peru](https://app.vagrantup.com/peru)


## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)
* [VirtualBox](https://www.virtualbox.org/)


## Login Credentials

(root/Administrator password is "vagrant" or is not set )

* Username: vagrant
* Password: vagrant


## VM Specifications

Drivers / Devices added for the VMs for specific providers.

### Libvirt
* VirtIO dynamic Hard Disk (up to 50 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)
* Channel Device (com.redhat.spice.0)

### VirtualBox
* SATA Disk


## Configuration

#### Customized Linux installation
* there are usually many customization depends on distribution - all are described in Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible).
* added packages: see the [Common list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/main.yml) and [Debian list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/Debian.yml) or [CentOS list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/RedHat.yml)
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
* Windows image was finalized using `sysprep`: [unattended.xml](https://github.com/ruzickap/packer-templates/blob/master/scripts/win-common/unattend.xml)


#### Additional Drivers installed for libvirt boxes - [VirtIO](https://fedoraproject.org/wiki/Windows_Virtio_Drivers)
Installed during installation:
* NetKVM: VirtIO Network driver
* qxldod: QXL graphics driver
* viostor: VirtIO Block driver (VirtIO SCSI controller driver)

Installed components via Ansible playbook [win.yml](https://github.com/ruzickap/packer-templates/blob/master/ansible/win.yml) for Windows:
* vioscsi: Support for VirtIO SCSI pass-through controller
* Balloon: VirtIO Memory Balloon driver
* viorng: VirtIO RNG Device driver
* vioser: VirtIO Serial Driver
* vioinput: VirtIO Input Driver - support for new QEMU input devices virtio-keyboard-pci, virtio-mouse-pci, virtio-tablet-pci, virtio-input-host-pci
* pvpanic: QEMU pvpanic device driver
* qemu-ga: [Qemu Guest Agent](http://wiki.libvirt.org/page/Qemu_guest_agent)


#### Additional Drivers installed for virtualbox boxes
* VirtualBox Guest Additions


## How to build images
If you want to build the images yourself you will need passwordless ssh access to the latest Fedora server and locally installed Ansible. The server should not have IPs from this range `192.168.121.0/24` - this is used by Vagrant + libvirt by default.

Then you just need to modify the `REMOTE_IP` and `REMOTE_USER` in `build_remote_ssh.sh` file.

The `build_remote_ssh.sh` script will connect to your Fedora server, downloads necessary packages (initiate reboot if necessary for kernel update) and start building the images using Packer.
It will also test the newly created images by Vagrant.
The whole procedure will take several hours.
You can check the progress by sshing to the server and checking the log files in `/tmp/` or `/var/tmp/packer` directories.


## Helper scripts
 * `build.sh` - build single image specified on command line
 * `build_all.sh` - builds all images
 * `build_all_remote_ssh.sh` - connects to remote Ubuntu server, install the necessary packages for building images and execute `build_all.sh`
 * `vagrant_init_destroy_boxes.sh` - tests all *.box images in the current directory using `vagrant add/up/ssh/winrm/destroy`
