#!/bin/bash -eux

set -o pipefail

TMPDIR=${TMPDIR:-/var/tmp/vagrant_init_destroy_boxes}

for DIR in `find /var/tmp -maxdepth 1 -mindepth 1 -type d`; do
  VAGRANT_BOX_NAME=$(basename $DIR)
  echo "*** $DIR"
  cd $DIR
  vagrant destroy -f
  virsh --connect=qemu:///system vol-delete --pool default --vol ${VAGRANT_BOX_NAME}_vagrant_box_image_0.img
  rm -rf $DIR
done
