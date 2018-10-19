# Packer Templates mainly for the Vagrant [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) provider

## Customized+Clean/Minimal boxes for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) and [virtualbox](https://www.vagrantup.com/docs/virtualbox/) provider

[![Build Status](https://travis-ci.com/ruzickap/packer-templates.svg?branch=master)](https://travis-ci.com/ruzickap/packer-templates)

---

### Github repository for bug reports or feature requests

* [https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)

### Vagrant Cloud repository for the images build by these templates

* [https://app.vagrantup.com/peru](https://app.vagrantup.com/peru)

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

### Minimal Linux installation

* en_US.UTF-8
* keymap for standard US keyboard
* UTC timezone
* NTP enabled (default configuration)
* full-upgrade
* unattended-upgrades
* /dev/vda1 mounted on / using ext4/xfs filesystem (all files in one partition)
* no swap

### Customized Linux installation

Some of the Linux [images](https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=&q=peru/my)/templates begins with "my_" - they are preconfigured with the following:

* there are usually many customization depends on distribution - all are described in Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible).
* added packages: see the [Common list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/main.yml) and [Debian list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/Debian.yml) or [CentOS list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/RedHat.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes

### Minimal Windows installation

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

### Customized Windows 10 installation

* added packages: see the [common_windows_packages](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/Windows.yml)
* Additional configuration done via ansible playbook [Win32NT-common.yml](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/tasks/Win32NT-common.yml)

### Additional Drivers installed for libvirt boxes - [VirtIO](https://fedoraproject.org/wiki/Windows_Virtio_Drivers)

Installed during installation:

* NetKVM: VirtIO Network driver
* qxldod: QXL graphics driver
* viostor: VirtIO Block driver (VirtIO SCSI controller driver)

Installed components via Ansible playbook [win-simple.yml](https://github.com/ruzickap/packer-templates/blob/master/ansible/win-simple.yml) for Windows:

* vioscsi: Support for VirtIO SCSI pass-through controller
* Balloon: VirtIO Memory Balloon driver
* viorng: VirtIO RNG Device driver
* vioser: VirtIO Serial Driver
* vioinput: VirtIO Input Driver - support for new QEMU input devices virtio-keyboard-pci, virtio-mouse-pci, virtio-tablet-pci, virtio-input-host-pci
* pvpanic: QEMU pvpanic device driver
* qemu-ga: [Qemu Guest Agent](http://wiki.libvirt.org/page/Qemu_guest_agent)

### Additional Drivers installed for virtualbox boxes

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
You can build the images using the build script [build.sh](build.sh) or directly with Packer.

### Build process with the [build.sh](build.sh) script

* Ubuntu:

```bash
# Ubuntu Server
./build.sh ubuntu-{18.04,16.04,14.04}-server-amd64-{libvirt,virtualbox}

# Ubuntu Desktop
./build.sh ubuntu-18.10-desktop-amd64-{libvirt,virtualbox}

# Ubuntu Server - customized
./build.sh my_ubuntu-{18.04,16.04,14.04}-server-amd64-{libvirt,virtualbox}
```

* Windows:

```bash
# Windows Server
./build.sh windows-server-2012_r2-standard-x64-eval-{libvirt,virtualbox}
./build.sh windows-server-2016-standard-x64-eval-{libvirt,virtualbox}
./build.sh windows-server-2019-standard-x64-eval-{libvirt,virtualbox}

# Windows 10
./build.sh windows-10-enterprise-x64-eval-{libvirt,virtualbox}

# Windows 10 - customized
./build.sh my_windows-10-enterprise-x64-eval-{libvirt,virtualbox}
```

### Build process with the Docker image

If you do not want to install Packer, Vagrant, Vagrant plugins or Ansible, then you can use Docker image.
You can find the Docker image and it's source on these URLs:

* Docker image: [https://hub.docker.com/r/peru/packer_qemu_virtualbox_ansible/](https://hub.docker.com/r/peru/packer_qemu_virtualbox_ansible/)
* Dockerfile: [https://github.com/ruzickap/docker-packer_qemu_virtualbox_ansible](https://github.com/ruzickap/docker-packer_qemu_virtualbox_ansible)

#### Ubuntu example with Docker image

```bash
sudo apt update
sudo apt install -y --no-install-recommends curl git jq docker.io virtualbox
sudo gpasswd -a ${USER} docker

sudo reboot
```

#### Fedora example with Docker image

```bash
sudo sed -i 's@^SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
sudo dnf upgrade -y
# Reboot if necessary (especialy if you upgrade the kernel or related packages)

sudo dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y akmod-VirtualBox curl docker git jq kernel-devel-$(uname -r) libvirt-daemon-kvm
sudo akmods

sudo bash -c 'echo "vboxdrv" > /etc/modules-load.d/vboxdrv.conf'
sudo usermod -a -G libvirt ${USER}
sudo groupadd docker && sudo gpasswd -a ${USER} docker
sudo systemctl enable docker

sudo reboot
```

### Build process with the Packer

Use the `USE_DOCKERIZED_PACKER=true` to use Dockerized Packer to build images.

* Ubuntu:

```bash
# Ubuntu Server
NAME="ubuntu-18.04-server-amd64" UBUNTU_CODENAME="bionic" UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" ubuntu-server.json
NAME="ubuntu-16.04-server-amd64" UBUNTU_CODENAME="xenial" UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" ubuntu-server.json
NAME="ubuntu-14.04-server-amd64" UBUNTU_CODENAME="trusty" UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" ubuntu-server.json

# Ubuntu Desktop
NAME="ubuntu-18.10-desktop-amd64" UBUNTU_CODENAME="cosmic" UBUNTU_TYPE="desktop" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" ubuntu-desktop.json
NAME="ubuntu-18.04-desktop-amd64" UBUNTU_CODENAME="bionic" UBUNTU_TYPE="desktop" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" ubuntu-desktop.json

# Ubuntu Server - customized
NAME="my_ubuntu-18.04-server-amd64" UBUNTU_CODENAME="bionic" UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" my_ubuntu-server.json
NAME="my_ubuntu-16.04-server-amd64" UBUNTU_CODENAME="xenial" UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" my_ubuntu-server.json
NAME="my_ubuntu-14.04-server-amd64" UBUNTU_CODENAME="trusty" UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" packer build -only="qemu" my_ubuntu-server.json
```

* Windows:

```bash
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso -P /var/tmp/
export TMPDIR=/var/tmp

# Windows Server
## Windows Server 2012
export NAME="windows-server-2012_r2-standard-x64-eval"
export WINDOWS_VERSION="2012"
export VIRTIO_WIN_ISO="/var/tmp/virtio-win.iso"
export ISO_CHECKSUM="6612b5b1f53e845aacdf96e974bb119a3d9b4dcb5b82e65804ab7e534dc7b4d5"
export ISO_URL="http://care.dlservice.microsoft.com/dl/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
packer build -only="qemu" windows.json

## Windows Server 2019
export NAME="windows-server-2019-standard-x64-eval"
export WINDOWS_VERSION="2019"
export VIRTIO_WIN_ISO="/var/tmp/virtio-win.iso"
export ISO_CHECKSUM="dbb0ffbab5d114ce7370784c4e24740191fefdb3349917c77a53ff953dd10f72"
export ISO_URL="https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_SERVER_EVAL_x64FRE_en-us.iso"
export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
packer build -only="qemu" windows.json

## Windows Server 2016
export NAME="windows-server-2016-standard-x64-eval"
export WINDOWS_VERSION="2016"
export VIRTIO_WIN_ISO="/var/tmp/virtio-win.iso"
export ISO_CHECKSUM="1ce702a578a3cb1ac3d14873980838590f06d5b7101c5daaccbac9d73f1fb50f"
export ISO_URL="https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
packer build -only="qemu" windows.json

# Windows 10
export NAME="windows-10-enterprise-x64-eval"
export WINDOWS_VERSION="10"
export VIRTIO_WIN_ISO="/var/tmp/virtio-win.iso"
export ISO_CHECKSUM="a37718a13ecff4e8497e8feef50e4c91348e97c6bfe93474e364c9d03ad381a2"
export USO_URL="https://software-download.microsoft.com/download/pr/17763.1.180914-1434.rs5_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
packer build -only="qemu" windows.json

# Windows 10 - customized
export NAME="my_windows-10-enterprise-x64-eval"
export WINDOWS_VERSION="10"
export VIRTIO_WIN_ISO="/var/tmp/virtio-win.iso"
export ISO_CHECKSUM="27e4feb9102f7f2b21ebdb364587902a70842fb550204019d1a14b120918e455"
export ISO_URL="https://software-download.microsoft.com/download/pr/17134.1.180410-1804.rs4_release_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
packer build -only="qemu" my_windows.json
```

## Helper scripts

* `build.sh` - build single image specified on command line
* `build_all.sh` - builds all images
* `build_all_remote_ssh.sh` - connects to remote Ubuntu server, install the necessary packages for building images and execute `build_all.sh`
* `vagrant_init_destroy_boxes.sh` - tests all `*.box` images in the current directory using `vagrant add/up/ssh/winrm/destroy`
