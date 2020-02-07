#!/bin/bash -eu

set -o pipefail

export BOX_VERSION=${BOX_VERSION:-$(date +%Y%m%d).01}
export LOGDIR=${LOGDIR:-/var/tmp}

readonly PROGNAME=$(basename "$0")
readonly ARGS=$*


usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can upload Packer box images to Vagrant Cloud.

You need to define the "VAGRANT_CLOUD_TOKEN" variable with proper access token.

Box names with user:

* peru@my_centos-7-x86_64-libvirt.box
* peru@my_ubuntu-14.04-server-amd64-libvirt.box
* peru@my_ubuntu-16.04-server-amd64-libvirt.box
* peru@my_ubuntu-18.04-server-amd64-libvirt.box
* peru@ubuntu-14.04-server-amd64-libvirt.box
* peru@ubuntu-16.04-server-amd64-libvirt.box
* peru@ubuntu-18.04-server-amd64-libvirt.box
* peru@ubuntu-19.10-desktop-amd64-libvirt.box
* peru@ubuntu-18.04-desktop-amd64-libvirt.box
* peru@windows-10-enterprise-x64-eval-libvirt.box
* peru@windows-10-enterprise-x64-eval-virtualbox.box
* peru@my_windows-10-enterprise-x64-eval-libvirt.box
* peru@my_windows-10-enterprise-x64-eval-virtualbox.box
* peru@windows-server-2012_r2-standard-x64-eval-libvirt.box
* peru@windows-server-2012_r2-standard-x64-eval-virtualbox.box
* peru@windows-server-2016-standard-x64-eval-libvirt.box
* peru@windows-server-2016-standard-x64-eval-virtualbox.box
* peru@windows-server-2019-standard-x64-eval-libvirt.box
* peru@windows-server-2019-standard-x64-eval-virtualbox.box

Examples:

Upload the "windows-server-2012_r2-standard-x64-eval-virtualbox.box" to peru/windows-server-2012_r2-standard-x64-eval:
  export VAGRANT_CLOUD_TOKEN="123456"

  $PROGNAME <vagrant_cloud_user>@<box_image>
  $PROGNAME peru@windows-server-2012_r2-standard-x64-eval-virtualbox.box
EOF
}

cmdline() {
  local USER_BOX=$*

  if [ -z "$USER_BOX" ] || [ -z "$VAGRANT_CLOUD_TOKEN" ]; then
    usage
    exit 1;
  fi

  export VAGRANT_CLOUD_USER="${USER_BOX%@*}"
  VAGRANT_CLOUD_BOX_FILE="${USER_BOX##*@}"
  VAGRANT_CLOUD_BOX_NAME=$(basename "$VAGRANT_CLOUD_BOX_FILE" .box)
  MY_NAME=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $1 }')
  VAGRANT_PROVIDER=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $NF }')
  export VAGRANT_PROVIDER

  if [ ! -f "$VAGRANT_CLOUD_BOX_FILE" ]; then
    echo -e "*** ERROR: \"$VAGRANT_CLOUD_BOX_FILE\" does not exist!\n"
    exit 1
  fi

  echo "*** My Name: $MY_NAME | User: $VAGRANT_CLOUD_USER  | Provider: $VAGRANT_PROVIDER | Box file: $VAGRANT_CLOUD_BOX_FILE | Box name: $VAGRANT_CLOUD_BOX_NAME"

  case $VAGRANT_CLOUD_BOX_NAME in
    *centos*)
      CENTOS_VERSION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $2 }')
      export CENTOS_VERSION
      CENTOS_TAG=$(curl -s "ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha256sum.txt" | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1)
      export CENTOS_TAG
      CENTOS_ARCH=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $3 }')
      export CENTOS_ARCH
      export CENTOS_TYPE="NetInstall"
      export NAME="${MY_NAME}-${CENTOS_VERSION}-${CENTOS_ARCH}"
      export SHORT_DESCRIPTION="My CentOS ${CENTOS_VERSION} ${CENTOS_ARCH} for libvirt and virtualbox"
      LONG_DESCRIPTION=$(envsubst < templates/my_centos.md)
      export LONG_DESCRIPTION
    ;;
    *ubuntu*)
      UBUNTU_TYPE=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $3 }')
      export UBUNTU_TYPE
      export UBUNTU_TYPE_UC=${UBUNTU_TYPE^}
      UBUNTU_MAJOR_VERSION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $2 }')
      export UBUNTU_MAJOR_VERSION
      UBUNTU_ARCH=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $4 }')
      export UBUNTU_ARCH
      UBUNTU_VERSION=$(curl -s "http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS" | sed -n "s/.*ubuntu-\([^-]*\)-.*-${UBUNTU_ARCH}.iso/\1/p" | head -1)
      export UBUNTU_VERSION
      export NAME="${MY_NAME}-${UBUNTU_MAJOR_VERSION}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
      export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_MAJOR_VERSION} ${UBUNTU_TYPE} (${UBUNTU_ARCH}) for libvirt and virtualbox"
      LONG_DESCRIPTION=$(envsubst < "templates/${MY_NAME}.md")
      export LONG_DESCRIPTION
    ;;
    *windows-10*)
      WINDOWS_VERSION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $2 }')
      export WINDOWS_VERSION
      WINDOWS_ARCH=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $4 }')
      export WINDOWS_ARCH
      WINDOWS_EDITION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $3 }')
      export WINDOWS_EDITION
      export WINDOWS_EDITION_UC=${WINDOWS_EDITION^}
      export NAME="${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
      export SHORT_DESCRIPTION="Windows $WINDOWS_VERSION ${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
      LONG_DESCRIPTION=$(envsubst < "templates/${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.md")
      export LONG_DESCRIPTION
    ;;
    *windows-*-2012*)
      WINDOWS_VERSION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '[-_]' '{ print $3 }')
      export WINDOWS_VERSION
      WINDOWS_RELEASE=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '[-_]' '{ print $4 }')
      export WINDOWS_RELEASE
      export WINDOWS_RELEASE_UC=${WINDOWS_RELEASE^}
      WINDOWS_ARCH=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $5 }')
      export WINDOWS_ARCH
      WINDOWS_TYPE=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $2 }')
      export WINDOWS_TYPE
      export WINDOWS_TYPE_UC=${WINDOWS_TYPE^}
      WINDOWS_EDITION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $4 }')
      export WINDOWS_EDITION
      export WINDOWS_EDITION_UC=${WINDOWS_EDITION^}
      export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}_${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
      export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE_UC} $WINDOWS_VERSION ${WINDOWS_RELEASE_UC} ${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
      LONG_DESCRIPTION=$(envsubst < "templates/${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md")
      export LONG_DESCRIPTION
    ;;
    *windows-*-201[69]*)
      WINDOWS_VERSION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $3 }')
      export WINDOWS_VERSION
      WINDOWS_ARCH=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $5 }')
      export WINDOWS_ARCH
      WINDOWS_TYPE=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $2 }')
      export WINDOWS_TYPE
      export WINDOWS_TYPE_UC=${WINDOWS_TYPE^}
      WINDOWS_EDITION=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $4 }')
      export WINDOWS_EDITION
      export WINDOWS_EDITION_UC=${WINDOWS_EDITION^}
      export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
      export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE_UC} $WINDOWS_VERSION ${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
      LONG_DESCRIPTION=$(envsubst < "templates/${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md")
      export LONG_DESCRIPTION
    ;;
  esac

  echo -e "*** ${NAME} | ${SHORT_DESCRIPTION}"
  vagrant cloud publish --force --description "$LONG_DESCRIPTION" --version-description "$LONG_DESCRIPTION" --release  --short-description "${SHORT_DESCRIPTION}" "${VAGRANT_CLOUD_USER}/${NAME}" "${BOX_VERSION}" "${VAGRANT_PROVIDER}" "${VAGRANT_CLOUD_BOX_FILE}"
}


#######
# Main
#######

main() {
  cmdline "$ARGS"
}

main
