# Packer Templates mainly for the Vagrant [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) provider

## Customized+Clean/Minimal boxes for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) provider

[![Build Status](https://travis-ci.org/ruzickap/packer-templates.svg)](https://travis-ci.org/ruzickap/packer-templates)

---

#### Github repository for bug reports or feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)

#### Vagrant Cloud repository for the images build by these templates

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

#### Minimal Linux installation
* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using ext4/xfs filesystem (all files in one partition)
* no swap

#### Customized Linux installation
Some of the Linux [images](https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=&q=peru/my)/templates begins with "my_" - they are preconfigured with the following:
* there are usually many customization depends on distribution - all are described in Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible).
* added packages: see the [Common list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/main.yml) and [Debian list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/Debian.yml) or [CentOS list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/RedHat.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes

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

#### Customized Windows 10 installation
* added packages: see the [common_windows_packages](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/Windows.yml)
* Additional configuration done via ansible playbook [Win32NT-common.yml](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/tasks/Win32NT-common.yml)

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


## How to build images remotely
If you want to build the images yourself you will need passwordless ssh access to the latest Fedora server and locally installed Ansible. The server should not have IPs from this range `192.168.121.0/24` - this is used by Vagrant + libvirt by default.

Then you just need to modify the `REMOTE_IP` and `REMOTE_USER` in `build_remote_ssh.sh` file.

The `build_remote_ssh.sh` script will connect to your Fedora server, downloads necessary packages (initiate reboot if necessary for kernel update) and start building the images using Packer.
It will also test the newly created images by Vagrant.
The whole procedure will take several hours.
You can check the progress by sshing to the server and checking the log files in `/tmp/` directory.


## How to build images locally
If you have necessary software installed+configured on your local machine you can use the following commands to build the images.
You can build the images using the build script [build.sh](build.sh) or directly with pakcer.

### Build process with the [build.sh](build.sh) script

* Ubuntu:
```
# Ubuntu Server
./build.sh ubuntu-server-{18.04,16.04,14.04}:{libvirt,virtualbox}

# Ubuntu Desktop
./build.sh ubuntu-desktop-18.04:{libvirt,virtualbox}

# Ubuntu Server - customized
./build.sh my_ubuntu-server-{18.04,16.04}:{libvirt,virtualbox}
```

* Windows:
```
# Windows Server
./build.sh windows-2012_r2:{libvirt,virtualbox}
./build.sh windows-2016:{libvirt,virtualbox}

# Windows 10
./build.sh windows-10:{libvirt,virtualbox}

# Windows 10 - customized
./build.sh my_windows-10:{libvirt,virtualbox}
```

### Build process with the Docker image
If you do not want to install Packer, Vagrant, Vagrant plugins or Ansible, then you can use Docker image.
You can find the Docker image and it's source on these URLs:

* https://hub.docker.com/r/peru/packer_qemu_virtualbox_ansible/
* https://github.com/ruzickap/docker-packer_qemu_virtualbox_ansible

#### Ubuntu example with Docker image
```
sudo apt update
sudo apt install -y --no-install-recommends curl git docker.io virtualbox
sudo gpasswd -a ${USER} docker

sudo reboot
```

#### Fedora example with Docker image
```
sudo sed -i 's@^SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
sudo dnf upgrade -y
sudo dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y curl git docker kmod-VirtualBox
sudo groupadd docker && sudo gpasswd -a ${USER} docker
sudo systemctl enable docker

sudo reboot
```

### Build process with the Packer

Use the `USE_DOCKERIZED_PACKER=true` to use Dockerized Packer to build images.

* Ubuntu:
```
# Ubuntu Server
NAME=ubuntu-18.04-server-amd64 UBUNTU_VERSION=18.04   UBUNTU_TYPE=server packer build ubuntu-server.json
NAME=ubuntu-16.04-server-amd64 UBUNTU_VERSION=16.04.4 UBUNTU_TYPE=server packer build ubuntu-server.json
NAME=ubuntu-14.04-server-amd64 UBUNTU_VERSION=14.04.5 UBUNTU_TYPE=server packer build ubuntu-server.json

# Ubuntu Desktop
NAME=ubuntu-18.10-desktop-amd64 UBUNTU_VERSION=18.10   UBUNTU_TYPE=desktop packer build ubuntu-desktop.json
NAME=ubuntu-17.10-desktop-amd64 UBUNTU_VERSION=17.10.1 UBUNTU_TYPE=desktop packer build ubuntu-desktop.json

# Ubuntu Server - customized
NAME=my_ubuntu-18.04-server-amd64 UBUNTU_VERSION=18.04   UBUNTU_TYPE=server packer build my_ubuntu-server.json
NAME=my_ubuntu-16.04-server-amd64 UBUNTU_VERSION=16.04.4 UBUNTU_TYPE=server packer build my_ubuntu-server.json
NAME=my_ubuntu-14.04-server-amd64 UBUNTU_VERSION=14.04.5 UBUNTU_TYPE=server packer build my_ubuntu-server.json
```

* Windows:
```
# Windows Server
NAME=windows-server-2012-r2-standard-x64-eval WINDOWS_VERSION=2012 VIRTIO_WIN_ISO=/var/tmp/packer/virtio-win.iso ISO_CHECKSUM=6612b5b1f53e845aacdf96e974bb119a3d9b4dcb5b82e65804ab7e534dc7b4d5 ISO_URL=http://care.dlservice.microsoft.com/dl/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO packer build windows.json
NAME=windows-server-2016-standard-x64-eval WINDOWS_VERSION=2016 VIRTIO_WIN_ISO=/var/tmp/packer/virtio-win.iso ISO_CHECKSUM=1ce702a578a3cb1ac3d14873980838590f06d5b7101c5daaccbac9d73f1fb50f ISO_URL=http://care.dlservice.microsoft.com/dl/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO packer build windows.json

# Windows 10
NAME=windows-10-enterprise-x64-eval WINDOWS_VERSION=10 VIRTIO_WIN_ISO=/var/tmp/packer/virtio-win.iso ISO_CHECKSUM=3d39dd9bd37db5b3c80801ae44003802a9c770a7400a1b33027ca474a1a7c691 ISO_URL=http://care.dlservice.microsoft.com/dl/download/6/5/D/65D18931-F626-4A35-AD5B-F5DA41FE6B76/16299.15.170928-1534.rs3_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso packer build windows.json

# Windows 10 - customized
NAME=my_windows-10-enterprise-x64-eval WINDOWS_VERSION=10 VIRTIO_WIN_ISO=/var/tmp/packer/virtio-win.iso ISO_CHECKSUM=3d39dd9bd37db5b3c80801ae44003802a9c770a7400a1b33027ca474a1a7c691 ISO_URL=http://care.dlservice.microsoft.com/dl/download/6/5/D/65D18931-F626-4A35-AD5B-F5DA41FE6B76/16299.15.170928-1534.rs3_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso packer build my_windows.json
```


## Helper scripts
 * `build.sh` - build single image specified on command line
 * `build_all.sh` - builds all images
 * `build_all_remote_ssh.sh` - connects to remote Ubuntu server, install the necessary packages for building images and execute `build_all.sh`
 * `vagrant_init_destroy_boxes.sh` - tests all `*.box` images in the current directory using `vagrant add/up/ssh/winrm/destroy`
