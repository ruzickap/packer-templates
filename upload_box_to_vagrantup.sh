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

You need to define the "VAGRANTUP_ACCESS_TOKEN" variable with proper access token.

Box names with user:

* peru@my_centos-7-x86_64-libvirt.box
* peru@my_ubuntu-14.04-server-amd64-libvirt.box
* peru@my_ubuntu-16.04-server-amd64-libvirt.box
* peru@my_ubuntu-18.04-server-amd64-libvirt.box
* peru@ubuntu-14.04-server-amd64-libvirt.box
* peru@ubuntu-16.04-server-amd64-libvirt.box
* peru@ubuntu-18.04-server-amd64-libvirt.box
* peru@ubuntu-19.04-desktop-amd64-libvirt.box
* peru@ubuntu-18.10-desktop-amd64-libvirt.box
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
  export VAGRANTUP_ACCESS_TOKEN="123456"

  $PROGNAME <vagrant_cloud_user>@<box_image>
  $PROGNAME peru@windows-server-2012_r2-standard-x64-eval-virtualbox.box
EOF
}

cmdline() {
  local VAGRANT_CLOUD_USER_BOXES=$*

  if [ -z "$VAGRANT_CLOUD_USER_BOXES" ] || [ -z "$VAGRANTUP_ACCESS_TOKEN" ]; then
    usage
    exit 1;
  fi

  for VAGRANT_CLOUD_USER_BOX in $VAGRANT_CLOUD_USER_BOXES; do
    export VAGRANT_CLOUD_USER="${VAGRANT_CLOUD_USER_BOX%@*}"
    VAGRANT_CLOUD_BOX_FILE="${VAGRANT_CLOUD_USER_BOX##*@}"
    VAGRANT_CLOUD_BOX_NAME=$(basename "$VAGRANT_CLOUD_BOX_FILE" .box)
    MY_NAME=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $1 }')
    VAGRANT_PROVIDER=$(echo "$VAGRANT_CLOUD_BOX_NAME" | awk -F '-' '{ print $NF }')
    export VAGRANT_PROVIDER

    if [ ! -f "$VAGRANT_CLOUD_BOX_FILE" ]; then
      echo -e "*** ERROR: \"$VAGRANT_CLOUD_BOX_FILE\" does not exist!\n"
      exit 1
    fi

    echo "*** My Name: $MY_NAME, User: $VAGRANT_CLOUD_USER, Box file: $VAGRANT_CLOUD_BOX_FILE, Box name: $VAGRANT_CLOUD_BOX_NAME"

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

    vagrantup_upload "$VAGRANT_CLOUD_BOX_FILE" | tee "$LOGDIR/${VAGRANT_CLOUD_BOX_NAME}-upload.log"
  done
}

create_vagrantup_box() {
  if curl --silent --fail "https://vagrantcloud.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME" -o /dev/null; then
    echo "*** Box: ${NAME} - already exists..."
  else
    #Create box, because it doesn't exists
    echo "*** Creating box: ${NAME}, Short Description: $SHORT_DESCRIPTION"
    curl -s https://app.vagrantup.com/api/v1/boxes -X POST -d "box[name]=$NAME" -d "box[short_description]=${SHORT_DESCRIPTION}" -d "box[is_private]=false" -d "access_token=$VAGRANTUP_ACCESS_TOKEN" -o /dev/null
  fi
}

upload_boxfile_to_vagrantup() {
  #Get the current version before uploading anything
  echo "*** Getting current version of the box (if exists) from Vagrant Cloud"
  CURRENT_VERSION=$(curl -s "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME" | jq -r ".current_version.version")
  echo "*** Current version of the box in Vagrant Cloud: $CURRENT_VERSION"
  if [ "$CURRENT_VERSION" != "$BOX_VERSION" ]; then
    curl -sS "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/versions" -X POST -d "version[version]=$BOX_VERSION" -d "access_token=$VAGRANTUP_ACCESS_TOKEN" -o /dev/null
    curl -sS "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$BOX_VERSION" -X PUT -d "version[description]=$LONG_DESCRIPTION" -d "access_token=$VAGRANTUP_ACCESS_TOKEN" -o /dev/null
    curl -sS "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$BOX_VERSION/providers" -X POST -d "provider[name]=$VAGRANT_PROVIDER" -d "access_token=$VAGRANTUP_ACCESS_TOKEN" -o /dev/null
    UPLOAD_PATH=$(curl -sS "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$BOX_VERSION/provider/$VAGRANT_PROVIDER/upload?access_token=$VAGRANTUP_ACCESS_TOKEN" | jq -r '.upload_path')
    echo "*** Uploading \"${VAGRANT_CLOUD_BOX_FILE}\" to \"https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME\" as version [$BOX_VERSION]"
    curl -s -X PUT --upload-file "${VAGRANT_CLOUD_BOX_FILE}" "$UPLOAD_PATH"

    if ! curl -s --output /dev/null "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$BOX_VERSION/release" -X PUT -d "access_token=$VAGRANTUP_ACCESS_TOKEN"; then
      echo -e "\nUpload to Vagrant Cloud failed !\nOne more try..."
      curl -s --output /dev/null "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$BOX_VERSION/release" -X PUT -d "access_token=$VAGRANTUP_ACCESS_TOKEN"
    fi

    # Check if uploaded file really exists
    if curl --output /dev/null --silent --head --fail "https://app.vagrantup.com/$VAGRANT_CLOUD_USER/boxes/$NAME/versions/$BOX_VERSION/providers/$VAGRANT_PROVIDER.box"; then
      echo "*** File \"https://vagrantcloud.com/$VAGRANT_CLOUD_USER/boxes/$NAME/versions/$BOX_VERSION/providers/$VAGRANT_PROVIDER.box\" is reachable and exists..."
    else
      echo "*** File \"https://vagrantcloud.com/$VAGRANT_CLOUD_USER/boxes/$NAME/versions/$BOX_VERSION/providers/$VAGRANT_PROVIDER.box\" does not exists !!!"
      exit 1
    fi
    # Check if previous version really exists and then remove it (always keep just one - latest version - recently uploaded)
    CURRENT_VERSION_STATUS=$(curl -s "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$CURRENT_VERSION" | jq -r '.status')
    if [ "$CURRENT_VERSION" != "null" ] && [ "$CURRENT_VERSION" != "$BOX_VERSION" ] && [ "$CURRENT_VERSION_STATUS" = "active" ]; then
      echo "*** Removing previous version: https://vagrantcloud.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$CURRENT_VERSION"
      curl -s "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$CURRENT_VERSION" -X DELETE -d "access_token=$VAGRANTUP_ACCESS_TOKEN" -o /dev/null
    fi
    echo "*** Done"
  else
    echo  "*** The box with version \"$BOX_VERSION\" already exists in Vagrant Cloud. Skipping upload..."
  fi
}

vagrantup_upload() {
  local PACKER_FILE=$1; shift

  echo -e "*** $SHORT_DESCRIPTION ($NAME) [$PACKER_FILE]"
  create_vagrantup_box
  upload_boxfile_to_vagrantup
}


#######
# Main
#######

main() {
  cmdline "$ARGS"
}

main
