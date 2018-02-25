#!/bin/bash -eu

BOXES_LIST=`find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f\n" | sort | tr "\n" " "`
TMPDIR="/tmp/"
LOGFILE="vagrant_init_destroy_boxes.log"


vagrant_box_add() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  vagrant box add $VAGRANT_BOX_FILE --name=${VAGRANT_BOX_NAME} --force 2>/dev/null
}

vagrant_init_up() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}
  VAGRANT_BOX_PROVIDER=${VAGRANT_BOX_NAME##*-}

  test -d "$TMPDIR/$VAGRANT_BOX_NAME" && rm -rf "$TMPDIR/$VAGRANT_BOX_NAME"
  mkdir "$TMPDIR/$VAGRANT_BOX_NAME"
  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  sudo virsh pool-list | awk '/active/ { print $1 }' | xargs -n1 sudo virsh pool-refresh > /dev/null
  vagrant init $VAGRANT_BOX_NAME > /dev/null
  vagrant up --provider $VAGRANT_BOX_PROVIDER 2>/dev/null
}

check_vagrant_vm_linux() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  export SSH_OPTIONS="-q -o StrictHostKeyChecking=no -o ControlMaster=no -o PreferredAuthentications=password -o PubkeyAuthentication=no"
  echo "*** Running: vagrant ssh --command uptime"
  vagrant ssh --command '\
    sudo sh -c "test -x /usr/bin/apt && apt-get update 2>&1 > /dev/null && echo \"apt list -qq --upgradable\" && apt list -qq --upgradable"; \
    sudo sh -c "test -x /usr/bin/yum && yum update -q && yum list -q updates"; \
    uptime; \
    id; \
  '
  echo "*** Running: sshpass -pvagrant ssh vagrant@${VAGRANT_BOX_NAME}_default 'uptime; id; sudo id'"
  sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_BOX_NAME}_default '\
    grep PRETTY_NAME /etc/os-release; \
    uptime; \
    id; \
    sudo id; \
  '
}

check_vagrant_vm_win() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}

  export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME"
  echo "*** Running: vagrant winrm --shell powershell --command 'Get-Service ...'"
  vagrant winrm --shell powershell --command 'Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher; Get-Service | where {$_.Name -match ".*QEMU.*|.*Spice.*|.*vdservice.*|.*VBoxService.*"}; Get-WmiObject -Class Win32_Product; Get-WmiObject Win32_PnPSignedDriver | where {$_.devicename -match ".*Red Hat.*|.*VirtIO.*"} | select devicename, driverversion' 2>/dev/null
}


vagrant_remove_boxes_images() {
  VAGRANT_BOX_FILE=$1; shift
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE%.*}
  export VAGRANT_CWD="$TMPDIR"

  vagrant box remove -f $VAGRANT_BOX_NAME >/dev/null

  if echo $VAGRANT_BOX_NAME | grep -q -i "libvirt"; then
    sudo virsh vol-delete --pool default --vol ${VAGRANT_BOX_NAME}_vagrant_box_image_0.img
  fi
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
    test -f $LOGFILE && rm $LOGFILE
    for BOX in $BOXES_LIST; do
      echo -e "\n******************************************************\n*** ${BOX}\n******************************************************\n" | tee -a $LOGFILE
      vagrant_box_add $BOX
      vagrant_init_up $BOX

      (
        case $BOX in
          *windows* )
            check_vagrant_vm_win $BOX
          ;;
          *centos* | *ubuntu* )
            check_vagrant_vm_linux $BOX
          ;;
        esac
      ) 2>&1 | tee -a $LOGFILE

      vagrant_destroy $BOX
      vagrant_remove_boxes_images $BOX
    done
  fi
}

main
