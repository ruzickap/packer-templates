#!/bin/bash -eu

USER="peru"
LOGFILE="vagrant_init_destroy_boxes.log"


(
  for BOX in *.box; do
    echo "*** $BOX"
    ./upload_box_to_vagrantup.sh ${USER}@${BOX}
  done
) 2>&1 | tee $LOGFILE
