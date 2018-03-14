#!/bin/bash -eux

REMOTE_IP="192.168.121.70"
REMOTE_USER="root"

# Build ALL images (this takes several hours)
ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER ansible/build_remote_ssh.yml

# Build single image - windows_10:virtualbox
#ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER --extra-vars 'run_script="./build.sh windows_10:virtualbox"' ansible/build_remote_ssh.yml

# Build multiple images - windows_10 (virtualbox, libvirt) and ubuntu-server-16.04 (libvirt)
#ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER --extra-vars 'run_script="./build.sh windows_10:virtualbox windows_10:libvirt ubuntu-server-16.04:libvirt"' ansible/build_remote_ssh.yml

