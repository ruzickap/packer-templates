#!/bin/bash -eux

# Use with Ubuntu Server 20.04

REMOTE_IP="company-nb"
REMOTE_USER="pruzicka"
USER_PASSWORD="xxxxxxxxxx"
MY_PACKER_TEMPLATES_GITHUB_REPOSITORY="https://github.com/ruzickap/packer-templates"
GITHUB_SELF_HOSTED_RUNNER_TOKEN=${TOKEN:-Axxxxxxxxxxxxxxxxxxxxxxxxxxx4}

# Prepare remote machine for build
if [ -n "$GITHUB_SELF_HOSTED_RUNNER_TOKEN" ]; then
  ansible-playbook -i "$REMOTE_IP," -e "ansible_sudo_pass=$USER_PASSWORD" -e GITHUB_SELF_HOSTED_RUNNER_TOKEN="$GITHUB_SELF_HOSTED_RUNNER_TOKEN" -e MY_PACKER_TEMPLATES_GITHUB_REPOSITORY="$MY_PACKER_TEMPLATES_GITHUB_REPOSITORY" --user "$REMOTE_USER" build_remote_ssh_ubuntu.yml
else
  echo "Missing GITHUB_SELF_HOSTED_RUNNER_TOKEN"
  exit 1
fi
