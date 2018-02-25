#!/bin/bash -eu

export VERSION="$(date +%Y%m%d).01"

date

for PACKER_VAGRANT_PROVIDER in libvirt; do
  for BUILD in ubuntu-desktop-17.10 ubuntu-server-16.04 ubuntu-server-14.04 my_ubuntu-server-16.04 my_ubuntu-server-14.04 my_centos-7; do
    ./build.sh $BUILD:$PACKER_VAGRANT_PROVIDER
  done
done

for PACKER_VAGRANT_PROVIDER in libvirt virtualbox; do
  for BUILD in windows_10 windows_2016 windows_2012_r2; do
    ./build.sh $BUILD:$PACKER_VAGRANT_PROVIDER
  done
done

date
