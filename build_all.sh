#!/bin/bash -eu

export VERSION="$(date +%Y%m%d).01"
LOGFILE="/tmp/build_all.log"

(

  date

  for PACKER_VAGRANT_PROVIDER in libvirt virtualbox; do
    for BUILD in ubuntu-18.04-desktop ubuntu-{18.04,16.04,14.04}-server my_ubuntu-{18.04,16.04}-server my_centos-7 my_windows-10 windows-10 windows-2016 windows-2012_r2; do
      ./build.sh $BUILD:$PACKER_VAGRANT_PROVIDER
    done
  done

  date

  ./vagrant_init_destroy_boxes.sh

  date

) 2>&1 | tee $LOGFILE
