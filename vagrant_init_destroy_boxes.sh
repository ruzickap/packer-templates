#!/bin/bash -u

BOXES_LIST=`find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f "`
TMPDIR="/tmp/"
export VAGRANT_DEFAULT_PROVIDER=libvirt


vagrant_box_add() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  vagrant box add $VAGRANT_BOX_FILE --name=${VAGRANT_BOX_NAME} --force 2>/dev/null
}

vagrant_init_up() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  test -d "$TMPDIR/$VAGRANT_BOX_NAME" && rm -rf "$TMPDIR/$VAGRANT_BOX_NAME"
  mkdir "$TMPDIR/$VAGRANT_BOX_NAME"
  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  sudo virsh pool-list | awk '/active/ { print $1 }' | xargs -n1 sudo virsh pool-refresh > /dev/null
  vagrant init $VAGRANT_BOX_NAME > /dev/null
  vagrant up 2>/dev/null
}

check_vagrant_vm_linux() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  export SSH_OPTIONS="-q -o StrictHostKeyChecking=no -o ControlMaster=no -o PreferredAuthentications=password -o PubkeyAuthentication=no"
  echo "*** Running: vagrant ssh --command uptime"
  vagrant ssh --command '\
    sudo sh -c "test -x /usr/bin/apt && apt list -qq --upgradable"; \
    sudo sh -c "test -x /usr/bin/yum && yum list -q updates"; \
    uptime; \
    id; \
  ' 2>/dev/null && echo "*** OK"
  echo "*** Running: sshpass -pvagrant ssh vagrant@${VAGRANT_BOX_NAME}_default 'uptime; id; sudo id'"
  sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_BOX_NAME}_default '\
    grep PRETTY_NAME /etc/os-release; \
    uptime; \
    id; \
    sudo id; \
  ' && echo "*** OK"
}

check_vagrant_vm_win() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  echo "*** Running: vagrant winrm --shell powershell --command 'Get-Service ...'"
  vagrant winrm --shell powershell --command 'Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher; Get-Service | where {$_.Name -match ".*QEMU.*|.*Spice.*|.*vdservice.*"}; Get-WmiObject -Class Win32_Product; Get-WmiObject Win32_PnPSignedDriver | where {$_.devicename -match ".*Red Hat.*|.*VirtIO.*"} | select devicename, driverversion' 2>/dev/null
}


vagrant_remove_boxes_images() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}
  export VAGRANT_CWD="$TMPDIR"

  vagrant box remove -f $VAGRANT_BOX_NAME >/dev/null
  sudo virsh vol-delete --pool default --vol ${VAGRANT_BOX_NAME}_vagrant_box_image_0.img
}

vagrant_destroy() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  vagrant destroy -f > /dev/null 2>/dev/null
  rm -rf "$TMPDIR/$VAGRANT_BOX_NAME"
}


#######
# Main
#######

main() {
  if [ -n "$BOXES_LIST" ]; then
    for BOX in $BOXES_LIST; do
      echo -e "\n******************************************************\n*** ${BOX}\n******************************************************\n"
      vagrant_box_add $BOX
      vagrant_init_up $BOX

      if [ "${BOX::7}" = "windows" ]; then
        sleep 5
        check_vagrant_vm_win $BOX
      else
        check_vagrant_vm_linux $BOX
      fi

      vagrant_destroy $BOX
      vagrant_remove_boxes_images $BOX
    done
  fi
}

main
