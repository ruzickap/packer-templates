# [Windows ${WINDOWS_TYPE_UC} $WINDOWS_VERSION ${WINDOWS_EDITION_UC} Evaluation](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-${WINDOWS_TYPE}-${WINDOWS_VERSION})

Clean and minimal Windows ${WINDOWS_TYPE_UC} $WINDOWS_VERSION
${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation base box for [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)
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

## Requirements for Linux distributions running Vagrant

Unfortunately you can not use the Vagrant package provided by your Linux
distribution (at least for CentOS / Fedora / Debian).
These distributions doesn't support naively [Ruby library for WinRM](https://github.com/WinRb/WinRM)
needed by Vagrant for talking to Windows.
Luckily [WinRM communicator](https://github.com/mitchellh/vagrant/tree/master/plugins/communicators/winrm)
including the Ruby WinRM library is part of official Vagrant package.
You will also need the latest version of [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)
supporting [libvirt channels](https://libvirt.org/formatdomain.html#elementCharChannel).

Here are the steps for latest Fedora how to install Vagrant from the official
web pages:

```bash
dnf remove vagrant

VAGRANT_LATEST_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant | jq -r -M '.current_version')
dnf install https://releases.hashicorp.com/vagrant/${VAGRANT_LATEST_VERSION}/vagrant_${VAGRANT_LATEST_VERSION}_x86_64.rpm

# virtualbox
# Details here: https://rpmfusion.org/Howto/VirtualBox

# libvirt
dnf install -y gcc libvirt-daemon-kvm qemu-kvm libvirt-devel make rdesktop
vagrant plugin install vagrant-libvirt
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
```

## RDP access

Install [freerdp](https://www.freerdp.com/) to connect to Windows using [RDP](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol)
protocol:

```bash
# Fedora
dnf install freerdp
# Ubuntu
apt-get install freerdp2-x11

vagrant rdp -- /cert-ignore
```

## Login Credentials

* Username: Administrator, vagrant
* Password: vagrant

## VM Specifications

Drivers / Devices added for the VMs for specific providers.

### Libvirt

* Libvirt Provider
* VirtIO dynamic Hard Disk (up to 50 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)
* Channel Device (com.redhat.spice.0)

### VirtualBox

* SATA Disk

## Configuration

### Minimal installation

See the [Autounattend file](https://github.com/ruzickap/packer-templates/blob/main/http/windows-${WINDOWS_VERSION}/Autounattend.xml)

* UTC timezone
* IEHarden disabled
* Home Page set to `about:blank`
* First Run Wizard disabled
* Firewall allows Remote Desktop connections
* AutoActivation skipped
* DoNotOpenInitialConfigurationTasksAtLogon set to true
* WinRM (SSL) enabled
* New Network Window turned off
* Administrator account enabled
* EnableLUA
* Windows image was finalized using `sysprep`: [unattended.xml](https://github.com/ruzickap/packer-templates/blob/main/scripts/win-common/unattend.xml)

### Additional Drivers installed for libvirt boxes - [VirtIO](https://docs.fedoraproject.org/en-US/quick-docs/creating-windows-virtual-machines-using-virtio-drivers/)

Installed during installation:

* NetKVM: VirtIO Network driver
* qxldod: QXL graphics driver
* viostor: VirtIO Block driver (VirtIO SCSI controller driver)

Installed components via Ansible playbook [win-simple.yml](https://github.com/ruzickap/packer-templates/blob/main/ansible/win-simple.yml):

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

## Thanks to

* [https://github.com/boxcutter/windows](https://github.com/boxcutter/windows)
* [https://github.com/StefanScherer/packer-windows](https://github.com/StefanScherer/packer-windows)
* [https://github.com/hashicorp/best-practices](https://github.com/hashicorp/best-practices)
* [https://github.com/chef/bento/](https://github.com/chef/bento/)
