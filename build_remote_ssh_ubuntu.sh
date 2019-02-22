#!/bin/bash -eux

REMOTE_IP="172.16.246.243,172.16.242.252,172.16.241.47"
REMOTE_USER="ubuntu"

# Prepare remote machine for build
ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER ansible/build_remote_ssh_ubuntu.yml
