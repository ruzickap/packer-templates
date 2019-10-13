#!/bin/bash -eu

# Temporary directory where to store the iso images and other packer files
export TMPDIR=${TMPDIR:-$PWD/packer_cache}
# Do not use any GUI X11 windows
export HEADLESS=${HEADLESS:-true}
# Use packer, virtualboc, ansible in docker image
export USE_DOCKERIZED_PACKER=${USE_DOCKERIZED_PACKER:-false}
# Packer binary (doesn't apply of you are using Dockerized packer)
export PACKER_BINARY=${PACKER_BINARY:-packer}
# Directory where all the images will be stored
export PACKER_IMAGES_OUTPUT_DIR=${PACKER_IMAGES_OUTPUT_DIR:-/var/tmp/packer-templates-images}
# Directory where to store the logs
export LOGDIR=${LOGDIR:-$PACKER_IMAGES_OUTPUT_DIR}
# Enable packer debug log if set to 1 (default 0)
export PACKER_LOG=${PACKER_LOG:-0}
# Max amount of time which packer can run (default 5 hours) - this prevent packer form running forever when something goes bad during provisioning/build process
export PACKER_RUN_TIMEOUT=${PACKER_RUN_TIMEOUT:-18000}
# User docker / podman executable
if `which podman &> /dev/null`; then
  DOCKER_COMMAND=${DOCKER_COMMAND:-podman}
else
  DOCKER_COMMAND=${DOCKER_COMMAND:-docker}
fi

# This variable is a workaround for "guest_os_type" VirtualBox parameter (should be removed in the future when VirtualBox support "Windows2019_64")

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"

set -o pipefail

usage() {
  cat <<- EOF

Usage: $PROGNAME options

This script can build the various libvirt and virtualbox images.
You should have Packer, Ansible, libvirt and VirtualBox installed.

List of all supported builds:

 * ubuntu-18.04-desktop-amd64-{libvirt,virtualbox}
 * ubuntu-18.04-server-amd64-{libvirt,virtualbox}


Examples:


Build Ubuntu Desktop 18.04; Ubuntu Server 18.04 for libvirt and Virtualbox:
  $PROGNAME \\
    ubuntu-{18.04}-desktop-amd64-{libvirt,virtualbox} \\
    ubuntu-{18.04}-server-amd64-{libvirt,virtualbox} \\
EOF
}

cmdline() {
  BUILDS=$@

  if [ -z "$BUILDS" ]; then
    usage
    exit 0;
  fi

  for BUILD in $BUILDS; do
    export PACKER_VAGRANT_PROVIDER="${BUILD##*-}"
    export NAME="${BUILD%-*}"
    export MY_NAME=`echo $NAME | awk -F '-' '{ print $1 }'`

    case $PACKER_VAGRANT_PROVIDER in
      libvirt )
        export PACKER_BUILDER_TYPE="qemu"
      ;;
      virtualbox )
        export PACKER_BUILDER_TYPE="virtualbox-iso"
      ;;
      *)
        echo -e "\n\n*** Unsupported PACKER_VAGRANT_PROVIDER: \"$PACKER_VAGRANT_PROVIDER\" used from \"$BUILD\""
        exit 1
      ;;
    esac

    test -d $TMPDIR                   || mkdir -v $TMPDIR
    test -d $PACKER_IMAGES_OUTPUT_DIR || mkdir -v $PACKER_IMAGES_OUTPUT_DIR
    test -d $LOGDIR                   || mkdir -v $LOGDIR

    echo -e "\n\n*** $MY_NAME | $NAME | $BUILD - $PACKER_VAGRANT_PROVIDER/$PACKER_BUILDER_TYPE"

    case $NAME in
      *ubuntu*)
        export UBUNTU_TYPE=`echo $NAME | awk -F '-' '{ print $3 }'`
        export UBUNTU_VERSION=`echo $NAME | awk -F '-' '{ print $2 }'`
        export UBUNTU_CODENAME=`curl -s http://releases.ubuntu.com/ | sed -n "s@.*<a href=\"\([a-z]*\)/\">.*Ubuntu ${UBUNTU_VERSION}.*@\1@p" | head -1`
        export PACKER_FILE="${MY_NAME}-${UBUNTU_TYPE}.json"
        export DOCKER_ENV_PARAMETERS="-e UBUNTU_TYPE -e UBUNTU_VERSION -e UBUNTU_CODENAME -e NAME"
        echo "* NAME: $NAME, UBUNTU_TYPE: $UBUNTU_TYPE, UBUNTU_CODENAME: $UBUNTU_CODENAME, PACKER_FILE: $PACKER_FILE"
      ;;
      *)
        echo "*** Unsupported build type: \"$NAME\" used from \"$BUILD\""
        exit 1
      ;;
    esac

    packer_build
  done
}


packer_build() {
  if [ ! -f "${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box" ]; then
    if [ $USE_DOCKERIZED_PACKER = "true" ]; then
      $DOCKER_COMMAND pull peru/packer_qemu_virtualbox_ansible
      $DOCKER_COMMAND run --rm -t -u $(id -u):$(id -g) --privileged --tmpfs /dev/shm:size=67108864 --network host --name "packer_${BUILD}" $DOCKER_ENV_PARAMETERS \
        -v $PACKER_IMAGES_OUTPUT_DIR:/home/docker/packer_images_output_dir \
        -v $PWD:/home/docker/packer \
        -v $TMPDIR:/home/docker/packer/packer_cache \
        -e PACKER_RUN_TIMEOUT \
        -e PACKER_LOG \
        -e PACKER_IMAGES_OUTPUT_DIR=/home/docker/packer_images_output_dir \
        peru/packer_qemu_virtualbox_ansible build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS"  $PACKER_FILE 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    else
      $PACKER_BINARY build -only="$PACKER_BUILDER_TYPE" -color=false -var "headless=$HEADLESS"  $PACKER_FILE 2>&1 | tee "${LOGDIR}/${BUILD}-packer.log"
    fi
  else
    echo -e "\n* File ${PACKER_IMAGES_OUTPUT_DIR}/${BUILD}.box already exists. Skipping....\n";
  fi
}



#######
# Main
#######

main() {
  cmdline $ARGS
}

main
