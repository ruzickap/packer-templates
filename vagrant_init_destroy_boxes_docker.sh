#!/bin/bash -eu

VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH=$PWD
LOGDIR=${LOGDIR:-/var/tmp}
BOXES_LIST=${*:-`find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f\n" | sort | tr "\n" " "`}

vagrant_box() {
  local VAGRANT_BOX_FILE=$1

  docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
  -e HOME=/home/docker \
  -e LOGDIR=/home/docker/vagrant_logdir \
  -v /dev/vboxdrv:/dev/vboxdrv \
  -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
  -v $VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH:/home/docker/vagrant_script \
  -v $VAGRANT_BOX_FILE_BASE_DIR:/home/docker/vagrant \
  -v $LOGDIR:/home/docker/vagrant_logdir \
  peru/vagrant_libvirt_virtualbox /home/docker/vagrant_script/vagrant_init_destroy_boxes.sh $VAGRANT_BOX_FILE
}


#######
# Main
#######

main() {
  for VAGRANT_BOX_FILE in $BOXES_LIST; do
    VAGRANT_BOX_FILE_FULL_PATH=$(readlink -f $VAGRANT_BOX_FILE)
    VAGRANT_BOX_FILE_BASE_DIR=$(dirname $VAGRANT_BOX_FILE_FULL_PATH)

    if [ ! -f $VAGRANT_BOX_FILE ]; then
      echo -e "\n*** ERROR: Box file \"$VAGRANT_BOX_FILE\" does not exist!\n"
      exit 1
    fi

    vagrant_box $VAGRANT_BOX_FILE
  done
}

main
