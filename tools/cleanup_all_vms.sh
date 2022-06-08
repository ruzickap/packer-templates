#!/usr/bin/env bash

PACKER_CACHE_DIR=${PACKER_CACHE_DIR:-/var/tmp/packer_cache}
PACKER_IMAGES_OUTPUT_DIR=${PACKER_IMAGES_OUTPUT_DIR:-/var/tmp/packer-templates-images}
TMPDIR=${TMPDIR:-/tmp}
LOGDIR=${LOGDIR:-/var/tmp/packer-templates-logs}

set -euo pipefail

echo "*** Delete forgotten vagrant instances from ${TMPDIR}"
if [[ -d "${TMPDIR}" ]]; then
  while IFS= read -r -d '' DIR; do
    [ ! -f "${DIR}/Vagrantfile" ] && continue
    VAGRANT_BOX_NAME=$(awk -F\" '/config.vm.box =/ { print $2 }' "${DIR}/Vagrantfile")

    echo "*** ${DIR} | ${VAGRANT_BOX_NAME}"
    cd "${DIR}"
    vagrant destroy -f
    if [[ "${VAGRANT_BOX_NAME}" = "-libvirt" ]]; then
      virsh --connect=qemu:///system vol-delete --pool default --vol "${VAGRANT_BOX_NAME}_vagrant_box_image_0.img"
    fi
    cd
    rm -rf "${DIR}"
  done < <(find "${TMPDIR}" -maxdepth 2 ! -readable -prune -o -type f -name Vagrantfile -printf "%h\0")
fi

echo "*** Remove all PACKER_CACHE_DIR mess (not the iso files)"
test -d "${PACKER_CACHE_DIR}" && find "${PACKER_CACHE_DIR}" -mindepth 1 ! \( -type f -name "*.iso" \) -user "${USER}" -delete -print

echo "*** Remove all Vagrant boxes"
while IFS= read -r BOX; do
  [[ "${BOX}" = "There" ]] && continue
  echo "*** ${BOX}"
  vagrant box remove --force --all "${BOX}"
done < <(vagrant box list | awk '{ print $1 }')

echo "*** Remove all VirtualBox instances"
while IFS= read -r VM; do
  VM_ID=$(echo "${VM}" | awk -F '[{}]' '{ print $2 }')
  echo "*** ${VM} | ${VM_ID}"
  VBoxManage unregistervm "${VM_ID}" --delete
done < <(VBoxManage list vms)

echo "*** Remove all VirtualBox HDDs"
while IFS= read -r HDD; do
  HDD_ID=$(echo "${HDD}" | awk -F ':' '{ print $2 }')
  echo "*** ${HDD_ID}"
  VBoxManage closemedium disk "${HDD_ID}" --delete
done < <(VBoxManage list hdds | grep '^UUID:')

test -d "${HOME}/VirtualBox VMs" && rm -rvf "${HOME}/VirtualBox VMs"

if command -v virsh &> /dev/null; then
  echo "*** Remove all libvirt instances"
  for VM in $(virsh --connect=qemu:///system list --all --name); do
    echo "*** ${VM}"
    if virsh --connect=qemu:///system dominfo "${VM}" | grep -q running; then
      virsh --connect=qemu:///system destroy "${VM}"
    fi
    virsh --connect=qemu:///system undefine --remove-all-storage "${VM}"
  done

  echo "*** Remove all libvirt disks"
  for VOL in $(virsh --connect=qemu:///system vol-list default | awk '/.img/ { print $1 }'); do
    echo "*** ${VOL}"
    virsh --connect=qemu:///system vol-delete "${VOL}" --pool default
  done
fi

if [[ -d "${LOGDIR}" ]]; then
  echo "*** Remove logs created by vagrant_init_destroy_boxes.sh or build.sh form \"${LOGDIR}\""
  find "${LOGDIR}" -maxdepth 1 -mindepth 1 -regextype egrep -regex ".*-(init|packer)\.log" -delete -print
  if [[ ! "$(ls -A "${LOGDIR}")" ]]; then
    echo "*** Remove directory: ${LOGDIR}"
    rmdir -v "${LOGDIR}"
  fi
fi

if [[ -d "${PACKER_IMAGES_OUTPUT_DIR}" ]]; then
  echo "*** Remove boxes created by build.sh form \"${PACKER_IMAGES_OUTPUT_DIR}\""
  find "${PACKER_IMAGES_OUTPUT_DIR}" -maxdepth 1 -mindepth 1 -regextype egrep -regex ".*-(libvirt|virtualbox)\.box" -delete -print
  if [[ ! "$(ls -A "${PACKER_IMAGES_OUTPUT_DIR}")" ]]; then
    echo "*** Remove directory: ${PACKER_IMAGES_OUTPUT_DIR}"
    rmdir -v "${PACKER_IMAGES_OUTPUT_DIR}"
  fi
fi
