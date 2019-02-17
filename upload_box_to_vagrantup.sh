#!/bin/bash -eu

export VERSION=${VERSION:-`date +%Y%m%d`.01}
export LOGDIR=${LOGDIR:-/var/tmp}

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"


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
* peru@ubuntu-18.10-desktop-amd64-libvirt.box
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
  export VAGRANTUP_ACCESS_TOKEN="123456"

  $PROGNAME <vagrant_cloud_user>@<box_image>
  $PROGNAME peru@windows-server-2012_r2-standard-x64-eval-virtualbox.box
EOF
}

cmdline() {
  local VAGRANT_CLOUD_USER_BOXES=$@

  if [ -z "$VAGRANT_CLOUD_USER_BOXES" ] || [ -z "$VAGRANTUP_ACCESS_TOKEN" ]; then
    usage
    exit 0;
  fi

  for VAGRANT_CLOUD_USER_BOX in $VAGRANT_CLOUD_USER_BOXES; do
    export VAGRANT_CLOUD_USER="${VAGRANT_CLOUD_USER_BOX%@*}"
    VAGRANT_CLOUD_BOX_FILE="${VAGRANT_CLOUD_USER_BOX##*@}"
    VAGRANT_CLOUD_BOX_NAME=`basename $VAGRANT_CLOUD_BOX_FILE .box`
    MY_NAME=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $1 }'`
    export VAGRANT_PROVIDER=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $NF }'`

    if [ ! -f $VAGRANT_CLOUD_BOX_FILE ]; then
      echo -e "*** ERROR: \"$VAGRANT_CLOUD_BOX_FILE\" does not exist!\n"
      exit 1
    fi

    echo "*** My Name: $MY_NAME, User: $VAGRANT_CLOUD_USER, Box file: $VAGRANT_CLOUD_BOX_FILE, Box name: $VAGRANT_CLOUD_BOX_NAME"

    case $VAGRANT_CLOUD_BOX_NAME in
      *centos*)
        export CENTOS_VERSION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $2 }'`
        export CENTOS_TAG=`curl -s ftp://ftp.cvut.cz/centos/$CENTOS_VERSION/isos/x86_64/sha256sum.txt | sed -n 's/.*-\(..\)\(..\)\.iso/\1\2/p' | head -1`
        export CENTOS_ARCH=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $3 }'`
        export CENTOS_TYPE="NetInstall"
        export NAME="${MY_NAME}-${CENTOS_VERSION}-${CENTOS_ARCH}"
        export SHORT_DESCRIPTION="My CentOS ${CENTOS_VERSION} ${CENTOS_ARCH} for libvirt and virtualbox"
        export LONG_DESCRIPTION=$(envsubst < templates/my_centos.md)
      ;;
      *ubuntu*)
        export UBUNTU_TYPE=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $3 }'`
        export UBUNTU_TYPE_UC=${UBUNTU_TYPE^}
        export UBUNTU_MAJOR_VERSION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $2 }'`
        export UBUNTU_ARCH=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $4 }'`
        export UBUNTU_VERSION=`curl -s http://releases.ubuntu.com/${UBUNTU_MAJOR_VERSION}/SHA1SUMS | sed -n "s/.*ubuntu-\([^-]*\)-.*-${UBUNTU_ARCH}.iso/\1/p" | head -1`
        export NAME="${MY_NAME}-${UBUNTU_MAJOR_VERSION}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
        export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_MAJOR_VERSION} ${UBUNTU_TYPE} (${UBUNTU_ARCH}) for libvirt and virtualbox"
        export LONG_DESCRIPTION=$(envsubst < templates/${MY_NAME}.md)
      ;;
      *windows-10*)
        export WINDOWS_VERSION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $2 }'`
        export WINDOWS_ARCH=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $4 }'`
        export WINDOWS_EDITION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $3 }'`
        export WINDOWS_EDITION_UC=${WINDOWS_EDITION^}
        export NAME="${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
        export SHORT_DESCRIPTION="Windows $WINDOWS_VERSION ${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
        export LONG_DESCRIPTION=$(envsubst < templates/${MY_NAME}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-eval.md)
      ;;
      *windows-*-2012*)
        export WINDOWS_VERSION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '[-_]' '{ print $3 }'`
        export WINDOWS_RELEASE=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '[-_]' '{ print $4 }'`
        export WINDOWS_RELEASE_UC=${WINDOWS_RELEASE^}
        export WINDOWS_ARCH=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $5 }'`
        export WINDOWS_TYPE=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $2 }'`
        export WINDOWS_TYPE_UC=${WINDOWS_TYPE^}
        export WINDOWS_EDITION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $4 }'`
        export WINDOWS_EDITION_UC=${WINDOWS_EDITION^}
        export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}_${WINDOWS_RELEASE}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
        export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE_UC} $WINDOWS_VERSION ${WINDOWS_RELEASE_UC} ${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
        export LONG_DESCRIPTION=$(envsubst < templates/${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md)
      ;;
      *windows-*-201[69]*)
        export WINDOWS_VERSION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $3 }'`
        export WINDOWS_ARCH=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $5 }'`
        export WINDOWS_TYPE=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $2 }'`
        export WINDOWS_TYPE_UC=${WINDOWS_TYPE^}
        export WINDOWS_EDITION=`echo $VAGRANT_CLOUD_BOX_NAME | awk -F '-' '{ print $4 }'`
        export WINDOWS_EDITION_UC=${WINDOWS_EDITION^}
        export NAME="${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-${WINDOWS_EDITION}-${WINDOWS_ARCH}-eval"
        export SHORT_DESCRIPTION="Windows ${WINDOWS_TYPE_UC} $WINDOWS_VERSION ${WINDOWS_EDITION_UC} ($WINDOWS_ARCH) Evaluation for libvirt and virtualbox"
        export LONG_DESCRIPTION=$(envsubst < templates/${MY_NAME}-${WINDOWS_TYPE}-${WINDOWS_VERSION}-eval.md)
      ;;
    esac

    vagrantup_upload $VAGRANT_CLOUD_BOX_FILE | tee $LOGDIR/${VAGRANT_CLOUD_BOX_NAME}-upload.log
  done
}

create_vagrantup_box() {
  if wget -O /dev/null "https://vagrantcloud.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME" 2>&1 | grep -q 'ERROR 404'; then
    #Create box, because it doesn't exists
    echo "*** Creating box: ${NAME}, Short Description: $SHORT_DESCRIPTION"
    curl -s https://app.vagrantup.com/api/v1/boxes -X POST -d box[name]="$NAME" -d box[short_description]="${SHORT_DESCRIPTION}" -d box[is_private]=false -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  else
    echo "*** Box: ${NAME} - already exists..."
  fi
}

upload_boxfile_to_vagrantup() {
  #Get the current version before uploading anything
  echo "*** Getting current version of the box (if exists)"
  local CURRENT_VERSION=$(curl -s https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME | jq -r ".current_version.version")
  echo "*** Current version of the box: $CURRENT_VERSION"
  curl -sS https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/versions -X POST -d version[version]="$VERSION" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  curl -sS https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$VERSION -X PUT -d version[description]="$LONG_DESCRIPTION" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  curl -sS https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$VERSION/providers -X POST -d provider[name]="$VAGRANT_PROVIDER" -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  local UPLOAD_PATH=$(curl -sS https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$VERSION/provider/$VAGRANT_PROVIDER/upload?access_token=$VAGRANTUP_ACCESS_TOKEN | jq -r '.upload_path')
  echo "*** Uploading \"${VAGRANT_CLOUD_BOX_FILE}\" to \"https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME\" as version [$VERSION]"
  curl -s -X PUT --upload-file ${VAGRANT_CLOUD_BOX_FILE} $UPLOAD_PATH
  curl -s https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$VERSION/release -X PUT -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  # Check if uploaded file really exists
  if curl --output /dev/null --silent --head --fail "https://app.vagrantup.com/$VAGRANT_CLOUD_USER/boxes/$NAME/versions/$VERSION/providers/$VAGRANT_PROVIDER.box"; then
    echo "*** File \"https://vagrantcloud.com/$VAGRANT_CLOUD_USER/boxes/$NAME/versions/$VERSION/providers/$VAGRANT_PROVIDER.box\" is reachable and exists..."
  else
    echo "*** File \"https://vagrantcloud.com/$VAGRANT_CLOUD_USER/boxes/$NAME/versions/$VERSION/providers/$VAGRANT_PROVIDER.box\" does not exists !!!"
    exit 1
  fi
  # Check if previous version really exists and then remove it (always keep just one - latest version - recently uploaded)
  CURRENT_VERSION_EXISTS=$(curl -s https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$CURRENT_VERSION | jq -r '.success')
  if [ "$CURRENT_VERSION" != "null" ] && [ "$CURRENT_VERSION" != "$VERSION" ] && [ "$CURRENT_VERSION_EXISTS" != "false" ]; then
    echo "*** Removing previous version: https://vagrantcloud.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$CURRENT_VERSION"
    curl -s https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$NAME/version/$CURRENT_VERSION -X DELETE -d access_token="$VAGRANTUP_ACCESS_TOKEN" > /dev/null
  fi
  echo "*** Done"
}

vagrantup_upload() {
  local PACKER_FILE=$1; shift

  echo -e "*** $SHORT_DESCRIPTION ($NAME) [$PACKER_FILE]\n"
  create_vagrantup_box
  upload_boxfile_to_vagrantup
}


#######
# Main
#######

main() {
  cmdline $ARGS
}

main
