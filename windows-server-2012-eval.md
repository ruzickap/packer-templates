# [Windows ${WINDOWS_TYPE^} $WINDOWS_VERSION ${WINDOWS_RELEASE^} ${WINDOWS_EDITION^} Evaluation](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_RELEASE})
## Clean and minimal Windows ${WINDOWS_TYPE^} $WINDOWS_VERSION ${WINDOWS_RELEASE^} ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation base box with [libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt) provider.

---

#### Github repository for bug reports or feature requests:

[https://github.com/ruzickap/packer-templates/](https://github.com/ruzickap/packer-templates/)


## Requirements
* [QEMU-KVM](https://en.wikibooks.org/wiki/QEMU/Installing_QEMU)
* [Vagrant](https://www.vagrantup.com/downloads.html)
* [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation)


## Requirements for Linux distributions
Unfortunately you can not use the vagrant package provided by your Linux distribution (at least for Fedora / Debian).
Both distributions doesn't support naively [Ruby library for WinRM](https://github.com/WinRb/WinRM). Luckily [WinRM communicator](https://github.com/mitchellh/vagrant/tree/master/plugins/communicators/winrm) including the Ruby WinRM library is part of official Vagrant package.
You will also need the latest version of [Vagrant Libvirt Plugin](https://github.com/pradels/vagrant-libvirt#installation) supporting [libvirt channels](https://libvirt.org/formatdomain.html#elementCharChannel) option and which is usually not part of the distributions.

Here are the steps for Fedora 23 and 24 how to install Vagrant from the official web pages:
\`\`\`
dnf remove vagrant
dnf install -y libvirt-daemon-kvm qemu-kvm libvirt-devel
dnf install -y https://releases.hashicorp.com/vagrant/1.8.6/vagrant_1.8.6_x86_64.rpm
vagrant plugin install vagrant-libvirt
\`\`\`


## Getting started

Install and connect to the box:

\`\`\`
mkdir ${NAME}
cd ${NAME}
vagrant init ${USER}/${NAME}
VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up
\`\`\`


## Login Credentials

* Username: Administrator, vagrant
* Password: vagrant


## VM Specifications

* Libvirt Provider
* VirtIO dynamic Hard Disk (up to 100 GiB)
* VirtIO Network Interface
* QXL Video Card (SPICE display)
* Channel Device (com.redhat.spice.0)


## Configuration

#### Minimal installation - see the [Autounattend file](https://github.com/ruzickap/packer-templates/blob/master/http/windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}/Autounattend.xml)

* UTC timezone
* IEHarden disabled
* Home Page set to "about:blank"
* First Run Wizard disabled
* Firewall allows Remote Desktop connections
* AutoActivation skipped
* DoNotOpenInitialConfigurationTasksAtLogon set to true
* WinRM enabled
* New Network Window turned off

#### Additional Drivers installed (needed by libvirt) - [VirtIO](https://fedoraproject.org/wiki/Windows_Virtio_Drivers)

Installed during installation:
* NetKVM: Virtio Network driver
* qxldod: QXL graphics driver
* viostor: Virtio Block driver

Installed when the OS is installed via script [install_virtio_drivers.ps1](https://github.com/ruzickap/packer-templates/blob/master/scripts/win-common/install_virtio_drivers.ps1):
* Balloon: Virtio Memory Balloon driver
* viorng: Virtio RNG driver
* vioser: Virtio serial driver
* pvpanic: QEMU pvpanic device driver
* qemu-ga: [Qemu Guest Agent](http://wiki.libvirt.org/page/Qemu_guest_agent)


## Thanks to...

* https://github.com/boxcutter/windows
* https://github.com/joefitzgerald/packer-windows - [fixnetwork.ps1](https://github.com/joefitzgerald/packer-windows/blob/master/scripts/fixnetwork.ps1)
* https://github.com/hashicorp/best-practices - [install_windows_updates.ps1](https://github.com/hashicorp/best-practices/blob/master/packer/scripts/windows/install_windows_updates.ps1)
