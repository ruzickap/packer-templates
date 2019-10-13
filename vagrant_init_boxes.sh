#!/bin/bash -eu

set -o pipefail

BOXES_LIST=${*:-`find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f\n" | sort | tr "\n" " "`}
TMPDIR=${TMPDIR:-/var/tmp/vagrant_init_destroy_boxes}
LOGDIR=${LOGDIR:-/var/tmp/}

# Enable vagrant debug log if set to 'info' (default 'warn')
export VAGRANT_LOG=${VAGRANT_LOG:-warn}

export VAGRANT_BOX_PROVIDER=virtualbox

vagrant_box_add() {
  vagrant box add $VAGRANT_BOX_FILE --name=${VAGRANT_BOX_NAME} --force
}

vagrant_init_up() {
  vagrant init $VAGRANT_BOX_NAME

  # Disable VirtualBox GUI
  #if [ "$VAGRANT_BOX_PROVIDER" = "virtualbox" ]; then
  #  sed -i '/config.vm.box =/a \ \ config.vm.provider "virtualbox" do |v|\n \ \ \ v.gui = false\n\ \ end' $VAGRANT_CWD/Vagrantfile
  #fi

  vagrant up --provider $VAGRANT_BOX_PROVIDER | grep -v 'Progress:'
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

      echo "*** Completed"
    done

  fi
}

main
