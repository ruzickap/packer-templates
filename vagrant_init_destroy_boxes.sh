#!/bin/bash -eu

set -o pipefail

BOXES_LIST=${*:-`find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f\n" | sort | tr "\n" " "`}
TMPDIR=${TMPDIR:-/var/tmp/vagrant_init_destroy_boxes}
LOGDIR=${LOGDIR:-/var/tmp/}
export VAGRANT_IGNORE_WINRM_PLUGIN=true

# Enable vagrant debug log if set to 'info' (default 'warn')
export VAGRANT_LOG=${VAGRANT_LOG:-warn}

export VAGRANT_BOX_PROVIDER=virtualbox

vagrant_box_add() {
  vagrant box add $VAGRANT_BOX_FILE --name=${VAGRANT_BOX_NAME} --force
}

vagrant_init_up() {
  vagrant init $VAGRANT_BOX_NAME

  # Disable VirtualBox GUI
  if [ "$VAGRANT_BOX_PROVIDER" = "virtualbox" ]; then
    sed -i '/config.vm.box =/a \ \ config.vm.provider "virtualbox" do |v|\n \ \ \ v.gui = false\n\ \ end' $VAGRANT_CWD/Vagrantfile
    #ps -elf | grep qemu
    #virsh list
  fi

  vagrant up --provider $VAGRANT_BOX_PROVIDER | grep -v 'Progress:'
}

check_vagrant_vm() {
  local SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ControlMaster=no -o PreferredAuthentications=password -o PubkeyAuthentication=no"
  VAGRANT_VM_IP=`vagrant ssh-config | awk '/HostName/ { print $2 }'`

  case $VAGRANT_BOX_FILE in
    *windows* )
      echo "*** Getting version: systeminfo | findstr /B /C:\"OS Name\" /C:\"OS Version\""
      vagrant winrm --shell cmd --command 'systeminfo | findstr /B /C:"OS Name" /C:"OS Version"'
      echo "*** Running: vagrant winrm --shell powershell --command 'Get-Service ...'"
      vagrant winrm --shell powershell --command 'Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher; Get-Service | where {$_.Name -match ".*QEMU.*|.*Spice.*|.*vdservice.*|.*VBoxService.*"}; Get-WmiObject -Class Win32_Product; Get-WmiObject Win32_PnPSignedDriver | where {$_.devicename -match ".*Red Hat.*|.*VirtIO.*"} | select devicename, driverversion' | uniq
    ;;
    *centos* | *ubuntu* )
      echo "*** Checking if there are some packages to upgrade (there should be none)"
      vagrant ssh --command '\
        grep PRETTY_NAME /etc/os-release; \
        sudo sh -c "test -x /usr/bin/apt && apt-get update 2>&1 > /dev/null && echo \"apt list -qq --upgradable\" && apt list -qq --upgradable"; \
        sudo sh -c "test -x /usr/bin/yum && yum list -q updates"; \
        id; \
      '
      echo "*** vagrant ssh test completed..."
      if [ "$VAGRANT_BOX_PROVIDER" != "virtualbox" ]; then
        echo "*** Running: sshpass -pvagrant ssh vagrant@${VAGRANT_VM_IP} 'id; sudo id'"
        sshpass -pvagrant ssh $SSH_OPTIONS vagrant@${VAGRANT_VM_IP} '\
          id; \
          sudo id; \
        '
        echo "*** sshpass test completed..."
      fi
    ;;
  esac
}

vagrant_remove_boxes_images() {
  vagrant box remove -f $VAGRANT_BOX_NAME

  if echo $VAGRANT_BOX_NAME | grep -q -i "libvirt"; then
    virsh --connect=qemu:///system vol-delete --pool default --vol ${VAGRANT_BOX_NAME}_vagrant_box_image_0.img
  fi
}

vagrant_destroy() {
  vagrant destroy -f
}


#######
# Main
#######

main() {
  if [ -n "$BOXES_LIST" ]; then
    test -d $TMPDIR || mkdir -p $TMPDIR
    test -d $LOGDIR || mkdir -p $LOGDIR

    for VAGRANT_BOX_FILE in $BOXES_LIST; do
      export VAGRANT_BOX_NAME=`basename ${VAGRANT_BOX_FILE%.*}`
      export VAGRANT_BOX_NAME_SHORT=`basename $VAGRANT_BOX_FILE | cut -d - -f 1,2,3`
      export VAGRANT_BOX_PROVIDER=${VAGRANT_BOX_NAME##*-}
      export VAGRANT_CWD="$TMPDIR/$VAGRANT_BOX_NAME_SHORT"
      export LOG_FILE="$LOGDIR/${VAGRANT_BOX_NAME}-init.log"

      echo -e "*** ${VAGRANT_BOX_FILE} [$VAGRANT_BOX_NAME] ($VAGRANT_BOX_PROVIDER) ($TMPDIR/$VAGRANT_BOX_NAME_SHORT)" | tee $LOG_FILE
      test -d "$VAGRANT_CWD" && rm -rf "$VAGRANT_CWD"
      mkdir "$VAGRANT_CWD"

      vagrant_box_add
      vagrant_init_up 2>&1 | tee -a $LOG_FILE

      check_vagrant_vm 2>&1 | tee -a $LOG_FILE

      #vagrant_destroy
      #vagrant_remove_boxes_images

      #rm -rf $VAGRANT_CWD/{Vagrantfile,.vagrant}
      #rmdir $VAGRANT_CWD
      echo "*** Completed"
    done

  fi
}

main
