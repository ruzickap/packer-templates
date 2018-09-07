#!/bin/bash -eu

VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH=$PWD
LOGDIR=${LOGDIR:-/var/tmp}
VAGRANT_BOX_FILE=$1

vagrant_box() {
  docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
  -e HOME=/home/docker \
  -e LOGDIR=/home/docker/vagrant_logdir \
  -v /dev/vboxdrv:/dev/vboxdrv \
  -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
  -v $VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH:/home/docker/vagrant_script \
  -v $VAGRANT_BOX_FILE_BASE_DIR:/home/docker/vagrant \
  -v $LOGDIR:/home/docker/vagrant_logdir \
  peru/vagrant_libvirt_virtualbox /home/docker/vagrant_script/vagrant_init_destroy_boxes.sh $VAGRANT_BOX_FILE_BASENAME
}


#######
# Main
#######

main() {
  VAGRANT_BOX_FILE_FULL_PATH=$(readlink -f $VAGRANT_BOX_FILE)
  VAGRANT_BOX_FILE_BASE_DIR=$(dirname $VAGRANT_BOX_FILE_FULL_PATH)
  VAGRANT_BOX_FILE_BASENAME=$(basename $VAGRANT_BOX_FILE)
  VAGRANT_BOX_NAME=${VAGRANT_BOX_FILE_BASENAME%.*}
  LOG_FILE="$LOGDIR/${VAGRANT_BOX_NAME}_vagrant_init_destroy_boxes.log"

  if [ ! -f $VAGRANT_BOX_FILE ]; then
    echo -e "\n*** ERROR: Box file \"$VAGRANT_BOX_FILE\" does not exist!\n"
    exit 1
  fi

  if [ -f $LOG_FILE ]; then
    echo -e "\n*** ERROR: Logfile \"$LOG_FILE\" exist! Skipping...\n"
  else
    vagrant_box
  fi
}

main
