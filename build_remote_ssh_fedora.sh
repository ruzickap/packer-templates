#!/bin/bash -eux

REMOTE_IP="192.168.121.70"
REMOTE_USER="vagrant"

# Build ALL images (this takes several hours)
ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER ansible/build_remote_ssh.yml

# Build single image - windows-10-enterprise-x64-eval-virtualbox
#ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER --extra-vars 'run_script="./build.sh windows-10-enterprise-x64-eval-virtualbox"' ansible/build_remote_ssh.yml

# Build multiple images - windows_10 (virtualbox, libvirt) and ubuntu-server-18.04 (libvirt)
#ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER --extra-vars 'run_script="./build.sh windows-10-enterprise-x64-eval-virtualbox windows-10-enterprise-x64-eval-libvirt ubuntu-18.04-server-amd64-libvirt"' ansible/build_remote_ssh.yml
