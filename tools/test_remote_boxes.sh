#!/usr/bin/env bash

set -o pipefail

LOGFILE="/tmp/test_remote_boxes.log"
PACKER_IMAGES_OUTPUT_DIR="/var/tmp/packer-templates-images-web"
VAGRANT_CLOUD_USER="peru"

(
  if [[ ! -d ${PACKER_IMAGES_OUTPUT_DIR} ]]; then
    mkdir ${PACKER_IMAGES_OUTPUT_DIR}
  fi

  for PACKER_VAGRANT_PROVIDER in libvirt virtualbox; do
    for BOX in {my_,}windows-10-enterprise-x64-eval windows-server-{2019,2016,2012_r2}-standard-x64-eval; do
      BOX_CURRENT_VERSION=$(curl -s https://vagrantcloud.com/api/v1/box/${VAGRANT_CLOUD_USER}/${BOX} | jq -r '.current_version.number')
      echo "*** ${VAGRANT_CLOUD_USER}/${BOX} | ${BOX_CURRENT_VERSION}"
      wget -c "https://vagrantcloud.com/${VAGRANT_CLOUD_USER}/boxes/${BOX}/versions/${BOX_CURRENT_VERSION}/providers/${PACKER_VAGRANT_PROVIDER}.box" -O "${PACKER_IMAGES_OUTPUT_DIR}/${BOX}-${PACKER_VAGRANT_PROVIDER}.box"
    done
  done

  ../vagrant_init_destroy_boxes.sh ${PACKER_IMAGES_OUTPUT_DIR}/*.box
) 2>&1 | tee $LOGFILE
