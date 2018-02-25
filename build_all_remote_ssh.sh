#!/bin/bash -eu

REMOTE_IP="192.168.121.164"
REMOTE_USER="vagrant"

ansible-playbook -i "$REMOTE_IP," --user $REMOTE_USER ansible/build_all.yml
