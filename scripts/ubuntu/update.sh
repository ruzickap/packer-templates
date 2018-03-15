#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Update the box
# Use apt instead of apt-get to upgrade kernel as well. apt-get doesn't upgrade kernel by default...
apt-get update -qq > /dev/null
apt-get upgrade -qq -y > /dev/null
