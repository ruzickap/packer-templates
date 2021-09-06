#!/bin/bash -eu

set -o pipefail

LOGFILE="/tmp/build_all.log"
PACKER_IMAGES_OUTPUT_DIR="/var/tmp/packer-templates-images"

(
  cd ..
  for PACKER_VAGRANT_PROVIDER in libvirt virtualbox; do
    for BUILD in ubuntu-{20,18,16}.04-desktop-amd64 ubuntu-{20,18,16}.04-server-amd64 my_ubuntu-{20,18,16}.04-server-amd64 my_centos-7-x86_64 {my_,}windows-10-enterprise-x64-eval windows-server-{2022,2019,2016,2012_r2}-standard-x64-eval; do
      echo "**** $(date)"
      ./build.sh ${BUILD}-${PACKER_VAGRANT_PROVIDER}
    done
  done

  ./vagrant_init_destroy_boxes.sh ${PACKER_IMAGES_OUTPUT_DIR}/*.box
) 2>&1 | tee $LOGFILE
