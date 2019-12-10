#!/bin/bash -eu

set -o pipefail

VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH=$PWD
TMPDIR=${TMPDIR:-/var/tmp/vagrant_init_destroy_boxes}
LOGDIR=${LOGDIR:-/var/tmp/}

BOXES_LIST=${*:-$(find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f\n" | sort | tr "\n" " ")}
# User docker / podman executable
if command -v podman &> /dev/null; then
  DOCKER_COMMAND=${DOCKER_COMMAND:-podman}
else
  DOCKER_COMMAND=${DOCKER_COMMAND:-docker}
fi


vagrant_box() {
  VAGRANT_BOX_FILE_FULL_PATH=$1
  VAGRANT_BOX_FILE_BASE_DIR=$(dirname "${VAGRANT_BOX_FILE_FULL_PATH}")
  VAGRANT_BOX_FILE_BASE_NAME=$(basename "${VAGRANT_BOX_FILE_FULL_PATH}")

  ${DOCKER_COMMAND} pull peru/vagrant_libvirt_virtualbox
  ${DOCKER_COMMAND} run --rm -t -u "$(id -u):$(id -g)" --privileged --network host --name "vagrant_libvirt_virtualbox_${VAGRANT_BOX_FILE_BASE_NAME}" \
  -e HOME=/home/docker \
  -e "TMPDIR=${TMPDIR}" \
  -e "LOGDIR=${LOGDIR}" \
  -v /dev/vboxdrv:/dev/vboxdrv \
  -v /var/run/libvirt/libvirt-sock:/var/run/libvirt/libvirt-sock \
  -v "${VAGRANT_INIT_DESTROY_BOXES_SCRIPT_PATH}:/home/docker/vagrant_script" \
  -v "${VAGRANT_BOX_FILE_BASE_DIR}:/home/docker/vagrant" \
  -v "${TMPDIR}:${TMPDIR}" \
  -v "${LOGDIR}:${LOGDIR}" \
  peru/vagrant_libvirt_virtualbox /home/docker/vagrant_script/vagrant_init_destroy_boxes.sh /home/docker/vagrant/"${VAGRANT_BOX_FILE_BASE_NAME}"
}


#######
# Main
#######

main() {
  test -d "${TMPDIR}" || mkdir "${TMPDIR}"

  for VAGRANT_BOX_FILE in ${BOXES_LIST}; do
    VAGRANT_BOX_FILE_FULL_PATH=$(readlink -f "${VAGRANT_BOX_FILE}")

    if [ ! -f "${VAGRANT_BOX_FILE_FULL_PATH}" ]; then
      echo -e "\n*** ERROR: Box file \"${VAGRANT_BOX_FILE_FULL_PATH}\" does not exist!\n"
      exit 1
    fi

    vagrant_box "${VAGRANT_BOX_FILE_FULL_PATH}"
  done

}

main
