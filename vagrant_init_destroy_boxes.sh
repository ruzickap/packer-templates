#!/bin/bash -x

#BOXES_LIST="windows-10-enterprise-x64-eval-libvirt.box"
#BOXES_LIST="windows-server-2012-r2-standard-x64-eval-libvirt.box"
BOXES_LIST="*.box"
TMPDIR="/tmp/"
export VAGRANT_DEFAULT_PROVIDER=libvirt

vagrant_box_add() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  vagrant box add $VAGRANT_BOX_FILE --name=${VAGRANT_BOX_NAME} --force
}

vagrant_init_up() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  test -d "$TMPDIR/$VAGRANT_BOX_NAME" && rm -rf "$TMPDIR/$VAGRANT_BOX_NAME"
  mkdir "$TMPDIR/$VAGRANT_BOX_NAME"
  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  sudo virsh pool-list | awk '/active/ { print $1 }' | xargs -n1 sudo virsh pool-refresh
  vagrant init $VAGRANT_BOX_NAME
  vagrant up
  vagrant ssh-config
}

vagrant_remove_boxes_images() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}
  export VAGRANT_CWD="$TMPDIR"

  vagrant box remove -f $VAGRANT_BOX_NAME
  sudo virsh vol-delete --pool default --vol ${VAGRANT_BOX_NAME}_vagrant_box_image_0.img
}

vagrant_destroy() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  vagrant destroy -f
  rm -rf "$TMPDIR/$VAGRANT_BOX_NAME"
}


#######
# Main
#######

main() {
  for BOX in $BOXES_LIST; do
    echo "*** $BOX"
    vagrant_box_add $BOX
    vagrant_init_up $BOX
  done

  echo "*** Check your boxes. Hit ENTER to remove all VMs + boxes + libvirt/snapshots"
  read A

  for BOX in $BOXES_LIST; do
    echo "*** $BOX"
    vagrant_destroy $BOX
    vagrant_remove_boxes_images $BOX
  done
}

main
