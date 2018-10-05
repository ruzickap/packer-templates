#!/bin/bash -eu

LOGFILE="/tmp/build_all.log"

(

  for PACKER_VAGRANT_PROVIDER in libvirt virtualbox; do
    for BUILD in ubuntu-18.04-desktop-amd64 ubuntu-{18.04,16.04,14.04}-server-amd64 my_ubuntu-{18.04,16.04}-server-amd64 my_centos-7-x86_64 my_windows-10-enterprise-x64-eval windows-{server-{2019,2016,2012_r2}-standard,10-enterprise}-x64-eval; do
      echo "**** `date`"
      ./build.sh ${BUILD}-${PACKER_VAGRANT_PROVIDER}
    done
  done

  ./vagrant_init_destroy_boxes_docker.sh

) 2>&1 | tee $LOGFILE
