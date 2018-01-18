#!/bin/bash -u

export USER="peru"
export TMPDIR="/var/tmp/"
export VIRTIO_WIN_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
export VIRTIO_WIN_ISO=$(basename $VIRTIO_WIN_ISO_URL)
export VERSION="$(date +%Y%m%d).01"

#export PACKER_LOG=1
export LOG_DIR="./build_logs/"


create_vagrantup_box() {
  if wget -O /dev/null "https://vagrantcloud.com/api/v1/box/$USER/$NAME" 2>&1 | grep -q 'ERROR 404'; then
    #Create box, because it doesn't exists
    echo "*** Creating box: ${NAME}, Short Description: $SHORT_DESCRIPTION"
    curl -s https://app.vagrantup.com/api/v1/boxes -X POST -d box[name]="$NAME" -d box[short_description]="${SHORT_DESCRIPTION}" -d box[is_private]=false -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  fi
}

remove_vagrantup_box() {
  echo "*** Removing box: $USER/$NAME"
  curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME -X DELETE -d access_token="$VAGRANTUP_ACCESS_TOKEN"
}

upload_boxfile_to_vagrantup() {
  #Get the Current Vrsion before uploading anything
  echo "*** Getting current version of the box (if exists)"
  CURRENT_VERSION=$(curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME -X GET -d access_token="$VAGRANTUP_ACCESS_TOKEN" | jq -r ".current_version.version")
  echo "*** Cureent version of the box: $CURRENT_VERSION"
  curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/versions -X POST -d version[version]="$VERSION" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION -X PUT -d version[description]="$DESCRIPTION" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION/providers -X POST -d provider[name]='libvirt' -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  UPLOAD_PATH=$(curl -sS https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION/provider/libvirt/upload?access_token=$VAGRANTUP_ACCESS_TOKEN | jq -r '.upload_path')
  echo "*** Uploading \"${NAME}-libvirt.box\" to $UPLOAD_PATH as version [$VERSION]"
  curl -s -X PUT --upload-file ${NAME}-libvirt.box $UPLOAD_PATH
  curl -s https://app.vagrantup.com/api/v1/box/$USER/$NAME/version/$VERSION/release -X PUT -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  # Check if uploaded file really exists
  if curl --output /dev/null --silent --head --fail "https://vagrantcloud.com/$USER/boxes/$NAME/versions/$VERSION/providers/libvirt.box"; then
    echo "*** File \"https://vagrantcloud.com/$USER/boxes/$NAME/versions/$VERSION/providers/libvirt.box\" is reachable and exists..."
  else
    echo "*** File \"https://vagrantcloud.com/$USER/boxes/$NAME/versions/$VERSION/providers/libvirt.box\" does not exists !!!"
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

  packerio build -on-error=ask -color=false $PACKER_FILE | tee "${LOG_DIR}/${NAME}-packer.log"
  create_vagrantup_box
  upload_boxfile_to_vagrantup
  rm -v ${NAME}-libvirt.box
}


# Expected enviroments: UBUNTU_TYPE="desktop" UBUNTU_MAJOR_VERSION="17.10" MY_NAME="ubuntu"
build_ubuntu() {
  export UBUNTU_ARCH="amd64"
  export UBUNTU_VERSION=`curl -s http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS | sed -n "s/.*ubuntu-\([^-]*\)-${UBUNTU_TYPE}-${UBUNTU_ARCH}.iso/\1/p" | head -1`
  export NAME="${MY_NAME}-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
  export DESCRIPTION=$(render_template ${MY_NAME}.md)
  export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_VERSION::5} ${UBUNTU_TYPE} (${UBUNTU_ARCH}) for libvirt"

  echo -e "\n\n*** $SHORT_DESCRIPTION ($NAME) [${MY_NAME}-${UBUNTU_TYPE}.json]\n"
  echo "$DESCRIPTION" > $TMPDIR/${NAME}.md
  packer_build ${MY_NAME}-${UBUNTU_TYPE}.json
}

build_my_centos7() {
  export CENTOS_VERSION="7"
  export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha1sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
  export CENTOS_ARCH="x86_64"
  export CENTOS_TYPE="NetInstall"
  export NAME="my-centos-${CENTOS_VERSION}-${CENTOS_ARCH}"
  export DESCRIPTION=$(render_template my-centos${CENTOS_VERSION}.md)
  export SHORT_DESCRIPTION="My CentOS ${CENTOS_VERSION} ${CENTOS_ARCH} for libvirt"

  packer_build my-centos${CENTOS_VERSION}.json
}

build_windows_2012_r2() {
  export WINDOWS_VERSION="2012"
  export WINDOWS_RELEASE="r2"
  export WINDOWS_ARCH="x64"
  export WINDOWS_TYPE="server"
  export WINDOWS_EDITION="standard"
  export NAME="windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
  export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE^} $WINDOWS_VERSION ${WINDOWS_RELEASE^^} ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation for libvirt"
  export DESCRIPTION=$(render_template windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md)

  wget -c -q $VIRTIO_WIN_ISO_URL -P $TMPDIR
  export VIRTIO_WIN_ISO_DIR=$(mktemp -d --suffix=${NAME}-iso --tmpdir=$TMPDIR)
  sudo mount -o loop $TMPDIR/$VIRTIO_WIN_ISO $VIRTIO_WIN_ISO_DIR
  packer_build windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
  sudo umount $VIRTIO_WIN_ISO_DIR
  rmdir $VIRTIO_WIN_ISO_DIR
}

build_windows_2016() {
  export WINDOWS_VERSION="2016"
  export WINDOWS_ARCH="x64"
  export WINDOWS_TYPE="server"
  export WINDOWS_EDITION="standard"
  export NAME="windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
  export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE^} $WINDOWS_VERSION ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation for libvirt"
  export DESCRIPTION=$(render_template windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md)

  wget -c -q $VIRTIO_WIN_ISO_URL -P $TMPDIR
  export VIRTIO_WIN_ISO_DIR=$(mktemp -d --suffix=${NAME}-iso --tmpdir=$TMPDIR)
  sudo mount -o loop $TMPDIR/$VIRTIO_WIN_ISO $VIRTIO_WIN_ISO_DIR
  packer_build windows-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.json
  sudo umount $VIRTIO_WIN_ISO_DIR
  rmdir $VIRTIO_WIN_ISO_DIR
}

build_windows_10() {
  export WINDOWS_VERSION="10"
  export WINDOWS_ARCH="x64"
  export WINDOWS_EDITION="enterprise"
  export NAME="windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
  export SHORT_DESCRIPTION="Windows $WINDOWS_VERSION ${WINDOWS_EDITION^} ($WINDOWS_ARCH) Evaluation for libvirt"
  export DESCRIPTION=$(render_template windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.md)

  wget -c -q $VIRTIO_WIN_ISO_URL -P $TMPDIR
  export VIRTIO_WIN_ISO_DIR=$(mktemp -d --suffix=${NAME}-iso --tmpdir=$TMPDIR)
  sudo mount -o loop $TMPDIR/$VIRTIO_WIN_ISO $VIRTIO_WIN_ISO_DIR
  packer_build windows-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.json
  sudo umount $VIRTIO_WIN_ISO_DIR
  rmdir $VIRTIO_WIN_ISO_DIR
}


#######
# Main
#######

main() {
  date
  build_windows_10
  build_windows_2016
  build_windows_2012_r2
  UBUNTU_TYPE="desktop" UBUNTU_MAJOR_VERSION="17.10" MY_NAME="ubuntu"    build_ubuntu
  UBUNTU_TYPE="server"  UBUNTU_MAJOR_VERSION="16.04" MY_NAME="ubuntu"    build_ubuntu
  UBUNTU_TYPE="server"  UBUNTU_MAJOR_VERSION="14.04" MY_NAME="ubuntu"    build_ubuntu
  UBUNTU_TYPE="server"  UBUNTU_MAJOR_VERSION="16.04" MY_NAME="my-ubuntu" build_ubuntu
  UBUNTU_TYPE="server"  UBUNTU_MAJOR_VERSION="14.04" MY_NAME="my-ubuntu" build_ubuntu
  build_my_centos7
  date
}

main
