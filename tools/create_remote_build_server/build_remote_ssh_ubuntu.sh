#!/bin/bash -eux

# Use with Ubuntu Server 20.04

REMOTE_IP="${REMOTE_IP:-company-nb}"
REMOTE_USER="${REMOTE_USER:-pruzicka}"
USER_PASSWORD="${USER_PASSWORD:-xxxxxxxxxx}"
MY_PACKER_TEMPLATES_GITHUB_REPOSITORY="https://github.com/ruzickap/packer-templates"
GITHUB_SELF_HOSTED_RUNNER_TOKEN=${GITHUB_SELF_HOSTED_RUNNER_TOKEN:-Axxxxxxxxxxxxxxxxxxxxxxxxxxx4}

# Prepare remote machine for build
ansible-playbook -i "$REMOTE_IP," -e "ansible_sudo_pass=$USER_PASSWORD" -e GITHUB_SELF_HOSTED_RUNNER_TOKEN="$GITHUB_SELF_HOSTED_RUNNER_TOKEN" -e MY_PACKER_TEMPLATES_GITHUB_REPOSITORY="$MY_PACKER_TEMPLATES_GITHUB_REPOSITORY" --user "$REMOTE_USER" build_remote_ssh_ubuntu.yml
