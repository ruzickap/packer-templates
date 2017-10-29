#!/bin/bash -eu

LINUX_BOXES_LIST="*ubuntu*.box *centos*.box"
WINDOWS_BOXES_LIST="*windows*.box"
TMPDIR="/tmp/"
export VAGRANT_DEFAULT_PROVIDER=libvirt
unset http_proxy
unset https_proxy

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
}

check_vagrant_vm() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  export SSH_OPTIONS=" -q -o StrictHostKeyChecking=no -o ControlMaster=no -o PreferredAuthentications=password -o PubkeyAuthentication=no "
  echo "*** Running: vagrant ssh --command uptime"
  vagrant ssh --command uptime && echo "*** OK"
  echo "*** Running: sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_BOX_NAME}_default uptime"
  sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_BOX_NAME}_default uptime && echo "*** OK"
  echo "*** Running: sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_BOX_NAME}_default sudo id"
  sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_BOX_NAME}_default sudo id && echo "*** OK"
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
  if `ls $LINUX_BOXES_LIST &> /dev/null`; then
    for LINUX_BOX in $LINUX_BOXES_LIST; do
      echo -e "\n******************************************************\n*** ${LINUX_BOX}\n******************************************************\n"
      vagrant_box_add $LINUX_BOX
      vagrant_init_up $LINUX_BOX
      check_vagrant_vm $LINUX_BOX
      vagrant_destroy $LINUX_BOX
      vagrant_remove_boxes_images $LINUX_BOX
    done
  fi

  if `ls $WINDOWS_BOXES_LIST &> /dev/null`; then
    for WIN_BOX in $WINDOWS_BOXES_LIST; do
      echo -e "\n******************************************************\n*** ${WIN_BOX}\n******************************************************\n"
      vagrant_box_add $WIN_BOX
      vagrant_init_up $WIN_BOX
    done

    echo -e "\n\n*** Check your Windows boxes. Hit ENTER to remove all Windows VMs + boxes + libvirt/snapshots"
    read A

    for WIN_BOX in $WINDOWS_BOXES_LIST; do
      echo "*** $WIN_BOX"
      vagrant_destroy $WIN_BOX
      vagrant_remove_boxes_images $WIN_BOX
    done
  fi
}

main
