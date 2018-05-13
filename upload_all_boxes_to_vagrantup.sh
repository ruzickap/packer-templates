#!/bin/bash -eu

VAGRANT_CLOUD_USER=${VAGRANT_CLOUD_USER:-peru}
LOGFILE="vagrant_init_destroy_boxes.log"
export VERSION=${VERSION:-`date +%Y%m%d`.01}

(
  for BOX in *.box; do
    echo "*** $BOX"
    ./upload_box_to_vagrantup.sh ${VAGRANT_CLOUD_USER}@${BOX}
  done
) 2>&1 | tee $LOGFILE
