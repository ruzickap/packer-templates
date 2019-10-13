# Packer Templates mainly for the Vagrant [libvirt][libvirt] and [virtualbox][virtualbox]

## Customized+Clean/Minimal boxes for [libvirt][libvirt] and [virtualbox][virtualbox]

[libvirt]: https://github.com/vagrant-libvirt/vagrant-libvirt
[virtualbox]: https://www.vagrantup.com/docs/virtualbox/

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

Some of the Linux [images](https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=&q=peru/my)/templates
begins with "my_" - they are preconfigured with the following:

* there are usually many customization depends on distribution - all are
  described in Ansible [playbook](https://github.com/ruzickap/packer-templates/tree/master/ansible).
* added packages: see the [Common list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/main.yml)
  and [Debian list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/Debian.yml)
  or [CentOS list](https://github.com/ruzickap/ansible-role-my_common_defaults/blob/master/vars/RedHat.yml)
* mouse disabled in Midnight Commander + other MC customizations
* preconfigured snmpd, vim, screen
* logrotate using xz instead of gzip
* logwatch is running once per week instead of once per day
* sshd is using only the strong algorithms
* sysstat (sar) is running every minute instead of every 5 minutes

### Additional Drivers installed for virtualbox boxes

* VirtualBox Guest Additions

## How to build images remotely

If you want to build the images yourself you will need passwordless ssh access
to the latest Fedora server and locally installed Ansible. The server should
not have IPs from this range `192.168.121.0/24` - this is
used by Vagrant + libvirt by default.

Then you just need to modify the `REMOTE_IP` and `REMOTE_USER`
in `build_remote_ssh.sh` file.

The `build_remote_ssh.sh` script will connect to your Fedora server, downloads
necessary packages (initiate reboot if necessary for kernel update) and start
building the images using Packer.
It will also test the newly created images by Vagrant.
The whole procedure will take several hours.
You can check the progress by sshing to the server and checking the log files
in `/tmp/` directory.

## How to build images locally

If you have necessary software installed+configured on your local machine you
can use the following commands to build the images.
You can build the images using the build script [build.sh](build.sh) or directly
with Packer.

### Build process with the [build.sh](build.sh) script

Real examples can be found here: [https://gitlab.com/ruzickap/packer-templates/pipelines](https://gitlab.com/ruzickap/packer-templates/pipelines)

* Ubuntu:

```bash
# Ubuntu Server
./build.sh ubuntu-{18.04}-server-amd64-{libvirt,virtualbox}

# Ubuntu Desktop
./build.sh ubuntu-18.04-desktop-amd64-{libvirt,virtualbox}

# Ubuntu Server - customized
./build.sh my_ubuntu-{18.04}-server-amd64-{libvirt,virtualbox}
```

### Build process with the Docker image

If you do not want to install Packer, Vagrant, Vagrant plugins or Ansible,
then you can use Docker image.
You can find the Docker image and it's source on these URLs:

* Docker image: [https://hub.docker.com/r/peru/packer_qemu_virtualbox_ansible/](https://hub.docker.com/r/peru/packer_qemu_virtualbox_ansible/)
* Dockerfile: [https://github.com/ruzickap/docker-packer_qemu_virtualbox_ansible](https://github.com/ruzickap/docker-packer_qemu_virtualbox_ansible)

#### Ubuntu example with Docker image

```bash
sudo apt update
sudo apt install -y --no-install-recommends curl git jq docker.io virtualbox
sudo gpasswd -a ${USER} docker
# This is mandatory for Ubuntu otherwise docker container will not have
# access to /dev/kvm - this is default in Fedora (https://bugzilla.redhat.com/show_bug.cgi?id=993491)
sudo bash -c "echo 'KERNEL==\"kvm\", GROUP=\"kvm\", MODE=\"0666\"' > /etc/udev/rules.d/60-qemu-system-common.rules"
sudo sed -i 's/^unix_sock_/#&/' /etc/libvirt/libvirtd.conf
sudo reboot
```

### Build process with the Packer

Use the `USE_DOCKERIZED_PACKER=true` to use Dockerized Packer to build images.

* Ubuntu:

```bash
# Ubuntu Server
NAME="ubuntu-18.04-server-amd64" UBUNTU_CODENAME="bionic" \
UBUNTU_TYPE="server" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" \
packer build -only="qemu" ubuntu-server.json

# Ubuntu Desktop
NAME="ubuntu-18.04-desktop-amd64" UBUNTU_CODENAME="bionic" \
UBUNTU_TYPE="desktop" PACKER_IMAGES_OUTPUT_DIR="/var/tmp/" \
packer build -only="qemu" ubuntu-desktop.json
```

## Helper scripts

* `build.sh` - build single image specified on command line
* `build_all.sh` - builds all images
* `build_all_remote_ssh.sh` - connects to remote Ubuntu server, install
  the necessary packages for building images and execute `build_all.sh`
* `vagrant_init_destroy_boxes.sh` - tests all `*.box` images in the current
  directory using `vagrant add/up/ssh/winrm/destroy`

GitLab CI configuration can be found here: [GitLab_CI_configuration.md](GitLab_CI_configuration.md)
