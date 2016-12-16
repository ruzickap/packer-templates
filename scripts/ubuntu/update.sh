#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Update the box
apt-get update > /dev/null
apt-get -y upgrade > /dev/null
