#!/bin/bash -eux

set -o pipefail

TMPDIR=${TMPDIR:-/var/tmp/vagrant_init_destroy_boxes}

while IFS= read -r -d '' DIR; do
  VAGRANT_BOX_NAME=$(awk -F\" '/config.vm.box =/ { print $2 }' "$DIR/Vagrantfile")
  VAGRANT_BOX_PROVIDER=${VAGRANT_BOX_NAME##*-}

  echo "*** $DIR | $VAGRANT_BOX_NAME | $VAGRANT_BOX_PROVIDER"
  cd "$DIR"
  vagrant destroy -f
  if [ "$VAGRANT_BOX_PROVIDER" = "libvirt" ]; then
    virsh --connect=qemu:///system vol-delete --pool default --vol "${VAGRANT_BOX_NAME}_vagrant_box_image_0.img"
  fi
  cd
  rm -rf "$DIR"
done <   <(find "$TMPDIR" -maxdepth 1 -mindepth 1 -type d -print0)
