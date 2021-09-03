#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Update the box
apt-get update -qq > /dev/null
apt-get dist-upgrade -qq -y > /dev/null
