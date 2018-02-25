#!/bin/bash -ue

export USER="peru"
export TMPDIR="/var/tmp/"
export VIRTIO_WIN_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
export VIRTIO_WIN_ISO=$(basename $VIRTIO_WIN_ISO_URL)
export VERSION=${VERSION:-`date +%Y%m%d`.01}

#export PACKER_LOG=1
export LOG_DIR="./build_logs/"

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"


usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:
 * windows_10             (libvirt, virtualbox)
 * windows_2016           (libvirt, virtualbox)
 * windows_2012_r2        (libvirt, virtualbox)
 * ubuntu-desktop-17.10   (libvirt)
 * ubuntu-server-16.04    (libvirt)
 * ubuntu-server-14.04    (libvirt)
 * my_ubuntu-server-16.04 (libvirt)
 * my_ubuntu-server-14.04 (libvirt)
 * my_centos-7            (libvirt)

Examples:

Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for Virtualbox:
  $PROGNAME windows_10:virtualbox windows_2016:virtualbox windows_2012_r2:virtualbox


Build Windows 10 Enterprise Evaluation, Windows Server 2016 Evaluation and Windows Server 2012 Evaluation for libvirt:
  $PROGNAME windows_10:libvirt windows_2016:libvirt windows_2012_r2:libvirt


Build Ubuntu Desktop 17.10, Ubuntu Server 16.04, 14.04, My Ubuntu Server 16.04, 14.04 and My Centos 7 for libvirt:
  $PROGNAME ubuntu-desktop-17.10:libvirt ubuntu-server-16.04:libvirt ubuntu-server-14.04:libvirt my_ubuntu-server-16.04:libvirt my_ubuntu-server-14.04:libvirt my_centos-7:libvirt
EOF
}

cmdline() {
  BUILDS=$@

  if [ -z $BUILDS ]; then
    usage
    exit 0;
  fi

  for BUILD in $BUILDS; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*:}"
    export MYBUILD="${BUILD%:*}"
    echo "*** $MYBUILD - $PACKER_VAGRANT_PROVIDER"

    case $MYBUILD in
      *centos*)
        export MY_NAME=`echo $MYBUILD | awk -F '-' '{ print $1 }'`
        export CENTOS_VERSION=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        eval centos
      ;;
      *ubuntu*)
        export MY_NAME=`echo $MYBUILD | awk -F '-' '{ print $1 }'`
        export UBUNTU_TYPE=`echo $MYBUILD | awk -F '-' '{ print $2 }'`
        export UBUNTU_MAJOR_VERSION=`echo $MYBUILD | awk -F '-' '{ print $3 }'`
        eval ubuntu
      ;;
      windows*)
        eval ${MYBUILD}
      ;;
    esac
  done
}

create_vagrantup_box() {
  if wget -O /dev/null "https://vagrantcloud.com/api/v1/box/$USER/$NAME" 2>&1 | grep -q 'ERROR 404'; then
    #Create box, because it doesn't exists
    echo "*** Creating box: ${NAME}, Short Description: $SHORT_DESCRIPTION"
    curl -s https://app.vagrantup.com/api/v1/boxes -X POST -d box[name]="$NAME" -d box[short_description]="${SHORT_DESCRIPTION}" -d box[is_private]=false -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  else
    echo "*** Box: ${NAME} - already exists..."
  fi
}

remove_vagrantup_box() {
  echo "*** Removing box: $USER/$NAME"
  curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME -X DELETE -d access_token="$VAGRANTUP_ACCESS_TOKEN"
}

upload_boxfile_to_vagrantup() {
  #Get the current version before uploading anything
  echo "*** Getting current version of the box (if exists)"
  CURRENT_VERSION=$(curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME -X GET -d access_token="$VAGRANTUP_ACCESS_TOKEN" | jq -r ".current_version.version")
  echo "*** Cureent version of the box: $CURRENT_VERSION"
  curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/versions -X POST -d version[version]="$VERSION" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION -X PUT -d version[description]="$LONG_DESCRIPTION" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION/providers -X POST -d provider[name]="$PACKER_VAGRANT_PROVIDER" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  UPLOAD_PATH=$(curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION/provider/$PACKER_VAGRANT_PROVIDER/upload?access_token=$VAGRANTUP_ACCESS_TOKEN | jq -r '.upload_path')
  echo "*** Uploading \"${NAME}-${PACKER_VAGRANT_PROVIDER}.box\" to $UPLOAD_PATH as version [$VERSION]"
  curl -s -X PUT --upload-file ${NAME}-${PACKER_VAGRANT_PROVIDER}.box $UPLOAD_PATH
  curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION/release -X PUT -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  # Check if uploaded file really exists
  if curl --output /dev/null --silent --head --fail "https://vagrantcloud.com/$USER/boxes/$NAME/versions/$VERSION/providers/$PACKER_VAGRANT_PROVIDER.box"; then
    echo "*** File \"https://vagrantcloud.com/$USER/boxes/$NAME/versions/$VERSION/providers/$PACKER_VAGRANT_PROVIDER.box\" is reachable and exists..."
  else
    echo "*** File \"https://vagrantcloud.com/$USER/boxes/$NAME/versions/$VERSION/providers/$PACKER_VAGRANT_PROVIDER.box\" does not exists !!!"
    exit 1
  fi
  #Remove previous version (always keep just one - latest version - recently uploaded)
  if [ "$CURRENT_VERSION" != "null" ]; then
    echo "*** Removing previous version: https://vagrantcloud.com/api/v1/box/$USER/$NAME/version/$CURRENT_VERSION"
    curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$CURRENT_VERSION -X DELETE -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  fi
}

render_template() {
  eval "echo \"$(cat $1)\""
}

packer_build() {
  PACKER_FILE=$1; shift

  case $PACKER_VAGRANT_PROVIDER in
    libvirt )
      export PACKER_BUILDER_TYPE="qemu"
      if echo $NAME | grep -q -i "windows"; then
        test -f $TMPDIR/virtio-win.iso || wget $VIRTIO_WIN_ISO_URL -P $TMPDIR
        export VIRTIO_WIN_ISO="$TMPDIR/virtio-win.iso"
      fi
    ;;
    virtualbox )
      export PACKER_BUILDER_TYPE="virtualbox-iso"
    ;;
  esac

  echo -e "\n\n*** $SHORT_DESCRIPTION ($NAME) [$PACKER_FILE] [$PACKER_BUILDER_TYPE]\n"
  echo "$LONG_DESCRIPTION" > /var/tmp/${NAME}-${PACKER_BUILDER_TYPE}-packer.md
  packerio build -only="$PACKER_BUILDER_TYPE" -on-error=ask -color=false -var 'headless=true' $PACKER_FILE | tee "${LOG_DIR}/${NAME}-${PACKER_BUILDER_TYPE}-packer.log"
  create_vagrantup_box
  upload_boxfile_to_vagrantup
  rm -v ${NAME}-${PACKER_VAGRANT_PROVIDER}.box
}

# Expected enviroments: UBUNTU_TYPE="desktop" UBUNTU_MAJOR_VERSION="17.10" MY_NAME="ubuntu"
ubuntu() {
  export UBUNTU_ARCH="amd64"
  export UBUNTU_VERSION=`curl -s http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS | sed -n "s/.*ubuntu-\([^-]*\)-${UBUNTU_TYPE}-${UBUNTU_ARCH}.iso/\1/p" | head -1`
  export NAME="${MY_NAME}-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
  export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_VERSION::5} ${UBUNTU_TYPE} (${UBUNTU_ARCH}) for libvirt"
  export LONG_DESCRIPTION=$(render_template templates/${MY_NAME}.md)

  sudo dnf upgrade -y ansible

  packer_build ${MY_NAME}-${UBUNTU_TYPE}.json
}

# Expected enviroments: CENTOS_VERSION="7" MY_NAME="ubuntu"
centos() {
  export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
  export CENTOS_ARCH="x86_64"
  export CENTOS_TYPE="NetInstall"
  export NAME="${MY_NAME}-${CENTOS_VERSION}-${CENTOS_ARCH}"
  export SHORT_DESCRIPTION="My CentOS ${CENTOS_VERSION} ${CENTOS_ARCH} for libvirt"
  export LONG_DESCRIPTION=$(render_template templates/my_centos.md)

  sudo dnf upgrade -y ansible

  packer_build my_centos-${CENTOS_VERSION}.json
}

windows_2012_r2() {
  export WINDOWS_VERSION="2012"
  export WINDOWS_RELEASE="r2"
  export WINDOWS_ARCH="x64"
  export WINDOWS_TYPE="server"
  export WINDOWS_EDITION="standard"
  export NAME="windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
  export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE^} $WINDOWS_VERSION ${WINDOWS_RELEASE^^} ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
  export LONG_DESCRIPTION=$(render_template templates/windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md)

  # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
  sudo dnf install -y ansible-2.4.0.0-1.fc27

  packer_build windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
}

windows_2016() {
  export WINDOWS_VERSION="2016"
  export WINDOWS_ARCH="x64"
  export WINDOWS_TYPE="server"
  export WINDOWS_EDITION="standard"
  export NAME="windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
  export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE^} $WINDOWS_VERSION ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
  export LONG_DESCRIPTION=$(render_template templates/windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md)

  # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
  sudo dnf install -y ansible-2.4.0.0-1.fc27

  packer_build windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
}

windows_10() {
  export WINDOWS_VERSION="10"
  export WINDOWS_ARCH="x64"
  export WINDOWS_EDITION="enterprise"
  export NAME="windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
  export SHORT_DESCRIPTION="Windows $WINDOWS_VERSION ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
  export LONG_DESCRIPTION=$(render_template templates/windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.md)

  # Do no use latest ansible 2.4.2 for now (Gathering Facts is not working properly on Windows + WinRM)
  sudo dnf install -y ansible-2.4.0.0-1.fc27

  packer_build windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.json
}



#######
# Main
#######

main() {
  cmdline $ARGS
}

main
