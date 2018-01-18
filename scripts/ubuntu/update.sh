#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Update the box
# Use apt instead of apt-get to upgrade kernel as well. apt-get doesn't upgrade kernel by default...
apt update > /dev/null
apt -y upgrade > /dev/null
