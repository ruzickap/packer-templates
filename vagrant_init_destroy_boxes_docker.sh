#!/bin/bash -eu

VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH=$PWD

VAGRANT_BOX_FILE=$1

vagrant_box() {
  docker run --rm -t -u $(id -u):$(id -g) --privileged --net=host \
  -e HOME=/home/docker \
  -e LOGFILE=/home/docker/vagrant/vagrant_init_destroy_boxes.log \
  -v /dev/vboxdrv:/dev/vboxdrv \
  -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
  -v $VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH:/home/docker/vagrant_script \
  -v $VAGRANT_BOX_FILE_BASE_DIR:/home/docker/vagrant \
  peru/vagrant_libvirt_virtualbox /home/docker/vagrant_script/vagrant_init_destroy_boxes.sh $VAGRANT_BOX_FILE_BASENAME
}



#######
# Main
#######

main() {
    VAGRANT_BOX_FILE_BASE_DIR=$(dirname $VAGRANT_BOX_FILE)
    VAGRANT_BOX_FILE_BASENAME=$(basename $VAGRANT_BOX_FILE)
    vagrant_box
}

main
