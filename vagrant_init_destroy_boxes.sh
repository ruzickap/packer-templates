#!/usr/bin/env bash

set -eu -o pipefail

BOXES_LIST=${*:-$(find . -maxdepth 1 \( -name "*ubuntu*.box" -o -name "*centos*.box" -o -name "*windows*.box" \) -printf "%f\n" | sort | tr "\n" " ")}
TMPDIR=${TMPDIR:-/tmp}
LOGDIR=${LOGDIR:-/var/tmp/packer-templates-logs}
STDOUT="/dev/null"
export VAGRANT_IGNORE_WINRM_PLUGIN=true

vagrant_box_add() {
  vagrant box add "${VAGRANT_BOX_FILE}" --name="${VAGRANT_BOX_NAME}" --force > ${STDOUT}
}

vagrant_init_up() {
  vagrant init "${VAGRANT_BOX_NAME}" > ${STDOUT}

  # Disable VirtualBox GUI
  if [[ "${VAGRANT_BOX_PROVIDER}" = "virtualbox" ]]; then
    sed -i '/config.vm.box =/a \ \ config.vm.provider "virtualbox" do |v|\n \ \ \ v.gui = false\n\ \ end' "${VAGRANT_CWD}/Vagrantfile"
  fi

  vagrant up --provider "${VAGRANT_BOX_PROVIDER}" > ${STDOUT}
}

check_vagrant_vm() {
  vagrant ssh-config | head -5 > "${VAGRANT_CWD}/ssh-config"

  case ${VAGRANT_BOX_FILE} in
  *windows*)
    sleep 100

    echo '*** Running: Certificate "Red Hat" or "Oracle" driver check'
    TRUSTED_CERTIFICATES=$(vagrant winrm --shell powershell --command "Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher" | uniq)
    if [[ ! ${TRUSTED_CERTIFICATES} =~ (Red Hat|Oracle) ]]; then
      echo "${TRUSTED_CERTIFICATES}"
      echo "*** There are no certificates from 'Red Hat' or 'Oracle' installed !"
      vagrant_cleanup
      exit 1
    fi

    echo '*** Running: "QEMU" or "Virtualbox" driver check'
    VIRT_SERVICES=$(vagrant winrm --shell powershell --command "Get-Service | where {\$_.Name -match \".*QEMU.*|.*Spice.*|.*vdservice.*|.*VBoxService.*\"}" | uniq)
    if [[ ! ${VIRT_SERVICES} =~ (QEMU|Spice|vdservice|VBoxService) ]]; then
      echo "${VIRT_SERVICES}"
      echo "*** There are no 'Virtualization services/addons' running !"
      vagrant_cleanup
      exit 2
    fi

    echo '*** Running: "Red Hat" and "VirtIO" driver check'
    if [[ ${VAGRANT_BOX_FILE} =~ "libvirt" ]]; then
      VIRT_DEVICES=$(vagrant winrm --shell powershell --command "Get-WmiObject Win32_PnPSignedDriver | where {\$_.devicename -match \".*Red Hat.*|.*VirtIO.*\"} | select devicename, driverversion" | uniq)
      if [[ ! ${VIRT_DEVICES} =~ (Red Hat|VirtIO) ]]; then
        echo "${VIRT_DEVICES}"
        echo "*** There are no 'Virtualization services/addons' running !"
        vagrant_cleanup
        exit 3
      fi
    fi

    echo '*** Running: Windows version check'
    WIN_VERSION=$(vagrant winrm --shell cmd --command 'systeminfo | findstr /B /C:"OS Name" /C:"OS Version"')
    if [[ ! ${VAGRANT_BOX_FILE} =~ $(echo "${WIN_VERSION}" | awk '/^OS Name/ { print tolower($4 "-" $5 "-" $6) }') ]]; then
      echo "${WIN_VERSION}"
      echo "*** Windows version mismatch \"$(echo "${WIN_VERSION}" | awk '{ print tolower($4 "-" $5 "-" $6) }')\" vs \"${VAGRANT_BOX_FILE}\" !"
      vagrant_cleanup
      exit 4
    fi

    echo '*** Running: Windows license check'
    LICENSE_STATUS=$(vagrant winrm --shell cmd --command "cscript C:\Windows\System32\slmgr.vbs /dli" | uniq)
    if [[ ! ${LICENSE_STATUS} =~ (10|90|180)\ day ]]; then
      echo "${LICENSE_STATUS}"
      echo "*** Licensing issue - expiration should be 10, 90 or 180 days !"
      vagrant_cleanup
      exit 5
    fi
    ;;
  *centos* | *ubuntu*)
    echo '*** Checking if there are some packages to upgrade (there should be none)'
    vagrant ssh --command '
        grep PRETTY_NAME /etc/os-release;
        sudo sh -c "test -x /usr/bin/apt && apt-get update 2>&1 > /dev/null && echo \"apt list -qq --upgradable\" && apt list -qq --upgradable";
        sudo sh -c "test -x /usr/bin/yum && yum list -q updates";
        id; sudo id
      '
    ;;
  esac

  echo '*** Running: sshpass'
  sshpass -pvagrant ssh -q -F "${VAGRANT_CWD}/ssh-config" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ControlMaster=no -o PreferredAuthentications=password -o PubkeyAuthentication=no default 'cd'
}

vagrant_cleanup() {
  vagrant destroy -f > ${STDOUT}
  vagrant box remove -f "${VAGRANT_BOX_NAME}" > ${STDOUT}

  if [[ "${VAGRANT_BOX_NAME}" =~ "libvirt" ]]; then
    virsh --quiet --connect=qemu:///system vol-delete --pool default --vol "${VAGRANT_BOX_NAME}_vagrant_box_image_0.img"
  fi

  rm -rf "${VAGRANT_CWD}"/{Vagrantfile,.vagrant,ssh-config}
  rmdir "${VAGRANT_CWD}"
}

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

ctrl_c() {
  echo "** Trapped CTRL-C"
  vagrant_cleanup
}

#######
# Main
#######

main() {
  if [[ -n "${BOXES_LIST}" ]]; then
    if [[ ! -d "${TMPDIR}" ]]; then
      echo "*** Directory \"${TMPDIR}\" doesn't exist !"
      exit 1
    fi
    test -d "${LOGDIR}" || mkdir -p "${LOGDIR}"

    for VAGRANT_BOX_FILE in ${BOXES_LIST}; do
      VAGRANT_BOX_NAME=$(basename "${VAGRANT_BOX_FILE%.*}")
      export VAGRANT_BOX_NAME
      export VAGRANT_BOX_PROVIDER=${VAGRANT_BOX_NAME##*-}
      export VAGRANT_CWD="${TMPDIR}/${VAGRANT_BOX_NAME}"
      export LOG_FILE="${LOGDIR}/${VAGRANT_BOX_NAME}-init.log"

      if [[ -s "${LOG_FILE}" ]]; then
        echo "*** The logfile \"${LOG_FILE}\" already exists - skipping..."
        continue
      fi

      echo -e "*** ${VAGRANT_BOX_FILE} [${VAGRANT_BOX_NAME}] (${VAGRANT_BOX_PROVIDER}) (${VAGRANT_CWD})" | tee "${LOG_FILE}"

      if [[ -d "${VAGRANT_CWD}" ]]; then
        echo "*** Directory \"${VAGRANT_CWD}\" already exist !"
        exit 1
      fi

      mkdir "${VAGRANT_CWD}"

      vagrant_box_add
      vagrant_init_up 2>&1 | tee -a "${LOG_FILE}"

      check_vagrant_vm 2>&1 | tee -a "${LOG_FILE}"

      vagrant_cleanup

      echo "*** Completed"
    done
  fi
}

main
