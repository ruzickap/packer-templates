#!/bin/bash -eux

REMOTE_IP="company-nb"
REMOTE_USER="pruzicka"
TOKEN=${TOKEN:-AxxxxxxxxxxxxxxxxxxxxxxxxxxxO}

# Prepare remote machine for build
if [ -n "$TOKEN" ]; then
  ansible-playbook -i "$REMOTE_IP," -e TOKEN="$TOKEN" --user $REMOTE_USER ../ansible/build_remote_ssh_ubuntu.yml
else
  echo "Missing TOKEN"
  exit 1
fi
