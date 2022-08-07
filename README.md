# Packer Templates mainly for the Vagrant [libvirt][libvirt] and [VirtualBox][virtualbox]

## Customized+Clean/Minimal boxes for [libvirt][libvirt] and [VirtualBox][virtualbox]

[libvirt]: https://github.com/vagrant-libvirt/vagrant-libvirt
[virtualbox]: https://www.vagrantup.com/docs/providers/virtualbox

[![Build Status](https://github.com/ruzickap/packer-templates/workflows/build/badge.svg)](https://github.com/ruzickap/packer-templates)

---

### GitHub repository for bug reports or feature requests

* [https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/issues)

### Vagrant Cloud repository for the images build by these templates

* [https://app.vagrantup.com/peru](https://app.vagrantup.com/peru)

## Requirements

* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)
* [VirtualBox](https://www.virtualbox.org/) (Version 6.1 or later)
* [Packer](https://www.packer.io/) (Version 1.8.0 or later)

## Login Credentials

`root` / `Administrator` password is `vagrant` or is not set.

Default login credentials:

* Username: `vagrant`
* Password: `vagrant`

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

Some of the [images](https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=&q=peru/my)/templates
begins with "my_" - they are preconfigured with [Ansible role](https://github.com/ruzickap/ansible-role-my_common_defaults/):

* there are usually many customization depends on distribution - all are
  described in [Ansible playbook](https://github.com/ruzickap/packer-templates/blob/main/ansible/site.yml).
* added packages: see the [Common list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/vars/main.yml)
  and [Debian list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/vars/Debian.yml)
  or [CentOS list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/vars/RedHat.yml)
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
* WinRM (SSL) enabled
* OpenSSH installed and enabled
* New Network Window turned off
* Administrator account enabled
* EnableLUA
* Windows image was finalized using `sysprep`: [unattended.xml](https://github.com/ruzickap/packer-templates/blob/main/scripts/win-common/unattend.xml)

### Customized Windows 10 installation

* added packages: see the [common_windows_packages](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/vars/Windows.yml)
* Additional configuration done via Ansible playbook [Win32NT-common.yml](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/main/tasks/Win32NT-common.yml)

### Additional Drivers installed for libvirt boxes - [VirtIO](https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers)

Installed during installation:

* NetKVM: VirtIO Network driver
* qxldod: QXL graphics driver
* viostor: VirtIO Block driver (VirtIO SCSI controller driver)

Installed components via Ansible playbook [win-simple.yml](https://github.com/ruzickap/packer-templates/blob/main/ansible/win-simple.yml)
for Windows:

* vioscsi: Support for VirtIO SCSI pass-through controller
* Balloon: VirtIO Memory Balloon driver
* viorng: VirtIO RNG Device driver
* vioser: VirtIO Serial Driver
* vioinput: VirtIO Input Driver - support for new QEMU input devices
  virtio-keyboard-pci, virtio-mouse-pci, virtio-tablet-pci,
  virtio-input-host-pci
* pvpanic: QEMU pvpanic device driver
* qemu-ga: [Qemu Guest Agent](http://wiki.libvirt.org/page/Qemu_guest_agent)

### Additional Drivers installed for VirtualBox boxes

* VirtualBox Guest Additions

## How to build images

If you have necessary software installed+configured on your local machine you
can use the following commands to build the images.
You can build the images using the build script [build.sh](build.sh) or directly
with Packer.

* Ubuntu requirements:

  ```bash
  sudo apt update
  sudo apt install -y ansible curl dnsmasq freerdp2-x11 git jq libc6-dev libvirt-daemon-system libvirt-dev python3-winrm qemu-kvm qemu-utils sshpass xorriso unzip virtualbox

  PACKER_LATEST_VERSION="$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer | jq -r -M '.current_version')"
  curl "https://releases.hashicorp.com/packer/${PACKER_LATEST_VERSION}/packer_${PACKER_LATEST_VERSION}_linux_amd64.zip" --output /tmp/packer_linux_amd64.zip
  sudo unzip /tmp/packer_linux_amd64.zip -d /usr/local/bin/
  rm /tmp/packer_linux_amd64.zip

  VAGRANT_LATEST_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant | jq -r -M '.current_version')
  curl "https://releases.hashicorp.com/vagrant/${VAGRANT_LATEST_VERSION}/vagrant_${VAGRANT_LATEST_VERSION}_x86_64.deb" --output /tmp/vagrant_x86_64.deb
  sudo apt install --no-install-recommends -y /tmp/vagrant_x86_64.deb
  rm /tmp/vagrant_x86_64.deb

  sudo gpasswd -a ${USER} kvm ; sudo gpasswd -a ${USER} libvirt ; sudo gpasswd -a ${USER} vboxusers

  vagrant plugin install vagrant-libvirt
  ```

* Debian 10+ requirements:

  VirtualBox is not in Debian 10 or later. If you need it, you will need to
  figure out a way to install it.

  ```bash
  echo 'deb http://deb.debian.org/debian bullseye main contrib non-free' | sudo tee /etc/apt/sources.list.d/bullseye.list
  sudo sed --regexp-extended 's/^([^#].+\s+main)$/\1 contrib non-free/;' --in-place /etc/apt/sources.list  ## Ensure required apt components are enabled.
  cat <<EOF | sudo tee /etc/apt/preferences.d/bullseye.pref
  Explanation: Just install packages from bullseye if they are not in buster or buster-backports. Do not upgrade. Delete this file when you want to upgrade to bullseye.
  Package: *
  Pin: release o=Debian,n=bullseye
  Pin-Priority: 50
  EOF
  sudo apt update
  sudo apt install -y ansible curl dnsmasq freerdp2-x11 git jq libc6-dev libvirt-daemon-system libvirt-dev python3-winrm qemu-kvm qemu-utils sshpass xorriso unzip packer/bullseye vagrant vagrant-libvirt

  sudo gpasswd -a ${USER} kvm ; sudo gpasswd -a ${USER} libvirt
  sudo gpasswd -a ${USER} vboxusers  ## If you have VirtualBox installed.
  ```

* Fedora requirements:

  ```bash
  sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install -y ansible curl freerdp git jq libvirt libvirt-devel qemu-kvm ruby-devel xorriso unzip VirtualBox

  PACKER_LATEST_VERSION="$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer | jq -r -M '.current_version')"
  curl "https://releases.hashicorp.com/packer/${PACKER_LATEST_VERSION}/packer_${PACKER_LATEST_VERSION}_linux_amd64.zip" --output /tmp/packer_linux_amd64.zip
  sudo unzip /tmp/packer_linux_amd64.zip -d /usr/local/bin/
  rm /tmp/packer_linux_amd64.zip

  VAGRANT_LATEST_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant | jq -r -M '.current_version')
  sudo dnf install -y https://releases.hashicorp.com/vagrant/${VAGRANT_LATEST_VERSION}/vagrant_${VAGRANT_LATEST_VERSION}_x86_64.rpm
  CONFIGURE_ARGS="with-ldflags=-L/opt/vagrant/embedded/lib with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib64/libvirt" vagrant plugin install vagrant-libvirt

  sudo gpasswd -a ${USER} kvm ; sudo gpasswd -a ${USER} libvirt ; sudo gpasswd -a ${USER} vboxusers
  systemctl start libvirtd
  ```

### Build process with the [build.sh](build.sh) script

```bash
git clone --recurse-submodules https://github.com/ruzickap/packer-templates.git
cd packer-templates
```

* Ubuntu:

  ```bash
  # Ubuntu Server
  ./build.sh ubuntu-{20.04,18.04,16.04}-server-amd64-{libvirt,virtualbox}

  # Ubuntu Desktop
  ./build.sh ubuntu-{20.04,18.04}-desktop-amd64-{libvirt,virtualbox}

  # Ubuntu Server - customized
  ./build.sh my_ubuntu-{20.04,18.04,16.04}-server-amd64-{libvirt,virtualbox}
  ```

* Windows:

  ```bash
  # Windows Server
  ./build.sh windows-server-2016-standard-x64-eval-{libvirt,virtualbox}
  ./build.sh windows-server-2019-standard-x64-eval-{libvirt,virtualbox}
  ./build.sh windows-server-2022-standard-x64-eval-{libvirt,virtualbox}

  # Windows 10
  ./build.sh windows-10-enterprise-x64-eval-{libvirt,virtualbox}

  # Windows 10 - customized
  ./build.sh my_windows-10-enterprise-x64-eval-{libvirt,virtualbox}
  ```

### Build process with the Packer

* Ubuntu:

  ```bash
  export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
  export LOGDIR="/tmp/"

  # Ubuntu Server
  NAME="ubuntu-20.04-server-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/" \
  UBUNTU_TYPE="server" \
  packer build -only="qemu" ubuntu-server.json

  NAME="ubuntu-18.04-server-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/" \
  UBUNTU_TYPE="server" \
  packer build -only="qemu" ubuntu-server.json

  NAME="ubuntu-16.04-server-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/xenial-updates/main/installer-amd64/current/images/" \
  UBUNTU_TYPE="server" \
  packer build -only="qemu" ubuntu-server.json

  # Ubuntu Desktop
  NAME="ubuntu-20.04-desktop-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/" \
  UBUNTU_TYPE="desktop" \
  packer build -only="qemu" ubuntu-desktop.json

  # Ubuntu Server - customized
  NAME="my_ubuntu-20.04-server-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/" \
  UBUNTU_TYPE="server" \
  packer build -only="qemu" my_ubuntu-server.json

  NAME="my_ubuntu-18.04-server-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/" \
  UBUNTU_TYPE="server" \
  packer build -only="qemu" my_ubuntu-server.json

  NAME="my_ubuntu-16.04-server-amd64" \
  UBUNTU_IMAGES_URL="http://archive.ubuntu.com/ubuntu/dists/xenial-updates/main/installer-amd64/current/images/" \
  UBUNTU_TYPE="server" \
  packer build -only="qemu" my_ubuntu-server.json
  ```

* Windows:

  ```bash
  export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
  export TMPDIR="/var/tmp"
  export LOGDIR="/tmp/"
  export VIRTIO_WIN_ISO_DIR="/var/tmp/virtio-win"

  curl -L -o "${TMPDIR}/virtio-win.iso" https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
  xorriso -report_about WARNING -osirrox on -indev "${TMPDIR}/virtio-win.iso" -extract / "${VIRTIO_WIN_ISO_DIR}"
  find "${VIRTIO_WIN_ISO_DIR}" -type d -exec chmod u+rwx {} \;

  # Windows Server
  ## Windows Server 2022
  export NAME="windows-server-2022-standard-x64-eval"
  export WINDOWS_VERSION="2022"
  export ISO_URL="https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
  packer build -only="qemu" windows.json

  ## Windows Server 2019
  export NAME="windows-server-2019-standard-x64-eval"
  export WINDOWS_VERSION="2019"
  export ISO_URL="https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
  packer build -only="qemu" windows.json

  ## Windows Server 2016
  export NAME="windows-server-2016-standard-x64-eval"
  export WINDOWS_VERSION="2016"
  export ISO_URL="https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
  packer build -only="qemu" windows.json

  # Windows 10
  export NAME="windows-10-enterprise-x64-eval"
  export WINDOWS_VERSION="10"
  export VIRTIO_WIN_ISO_DIR="/var/tmp/virtio-win"
  export ISO_URL="https://software-download.microsoft.com/download/sg/444969d5-f34g-4e03-ac9d-1f9786c69161/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
  export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
  packer build -only="qemu" windows.json

  # Windows 10 - customized
  export NAME="my_windows-10-enterprise-x64-eval"
  export WINDOWS_VERSION="10"
  export VIRTIO_WIN_ISO_DIR="/var/tmp/virtio-win"
  export ISO_URL="https://software-download.microsoft.com/download/sg/444969d5-f34g-4e03-ac9d-1f9786c69161/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
  export PACKER_IMAGES_OUTPUT_DIR="/var/tmp/"
  packer build -only="qemu" my_windows.json
  ```

## Helper scripts

* `build.sh` - build single image specified on command-line
* `build_all.sh` - builds all images
* `build_all_remote_ssh.sh` - connects to remote Ubuntu server, install
  the necessary packages for building images and execute `build_all.sh`
* `vagrant_init_destroy_boxes.sh` - tests all `*.box` images in the current
  directory using `vagrant add/up/ssh/winrm/destroy`

GitLab CI configuration (obsolete) can be found here: [GitLab_CI_configuration.md](docs/GitLab_CI_configuration.md)
