#!/bin/bash -eux

REMOTE_IP="172.16.246.17,172.16.241.102"
REMOTE_USER="ubuntu"
GITLAB_REGISTRATION_TOKEN=${GITLAB_REGISTRATION_TOKEN:-}

# Prepare remote machine for build
if [ -n "$GITLAB_REGISTRATION_TOKEN" ]; then
  ansible-playbook -i "$REMOTE_IP," -e GITLAB_REGISTRATION_TOKEN="$GITLAB_REGISTRATION_TOKEN" --user $REMOTE_USER ansible/build_remote_ssh_ubuntu.yml
else
  ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER ansible/build_remote_ssh_ubuntu.yml
fi
