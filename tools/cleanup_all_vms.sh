#!/bin/bash -eu

TMPDIR=${TMPDIR:-/tmp}
PACKER_CACHE_DIR=${PACKER_CACHE_DIR:-/var/tmp/packer_cache}
LOGDIR=${LOGDIR:-/var/tmp/packer-templates-logs}

set -o pipefail

echo "*** Delete forgotten vagrant instances from ${TMPDIR}"
if [[ -d "${TMPDIR}" ]]; then
  while IFS= read -r -d '' DIR; do
    VAGRANT_BOX_NAME=$(awk -F\" '/config.vm.box =/ { print $2 }' "${DIR}/Vagrantfile")

    echo "*** ${DIR} | ${VAGRANT_BOX_NAME} | ${VAGRANT_BOX_PROVIDER}"
    cd "${DIR}"
    vagrant destroy -f
    if [[ "${VAGRANT_BOX_NAME}" = "-libvirt" ]]; then
      virsh --connect=qemu:///system vol-delete --pool default --vol "${VAGRANT_BOX_NAME}_vagrant_box_image_0.img"
    fi
    cd
    rm -rf "${DIR}"
  done <   <(find "${TMPDIR}" -maxdepth 2 ! -readable -prune -o -type f -name Vagrantfile -printf "%h\0")
fi


echo "*** Remove all PACKER_CACHE_DIR mess (not the iso files)"
find "${PACKER_CACHE_DIR}" -mindepth 1 ! \( -type f -name "*.iso" \) -user "${USER}" -delete -print

echo "*** Remove all Vagrant boxes"
while IFS= read -r BOX; do
  [[ "${BOX}" = "There" ]] && continue
  echo "*** ${BOX}"
  vagrant box remove --force --all "${BOX}"
done <   <(vagrant box list | awk '{ print $1 }')


echo "*** Remove all VirtualBox instances"
while IFS= read -r VM; do
  VM_ID=$(echo "${VM}" | awk -F '[{}]' '{ print $2 }')
  echo "*** ${VM} | ${VM_ID}"
  VBoxManage unregistervm "${VM_ID}" --delete
done <   <(VBoxManage list vms)
test -d "${HOME}/VirtualBox VMs" && rm -r -v "${HOME}/VirtualBox VMs"


echo "*** Remove all libvirt instances"
for VM in $(virsh --connect=qemu:///system list --all --name); do
  echo "*** ${VM}"
  if virsh --connect=qemu:///system dominfo "${VM}" | grep -q running; then
    virsh --connect=qemu:///system destroy "${VM}"
  fi
  virsh --connect=qemu:///system undefine --remove-all-storage "${VM}"
done


if [[ -d "${LOGDIR}" ]]; then
  echo "*** Remove drectory: ${LOGDIR}"
  rm -rf "${LOGDIR}"
fi
