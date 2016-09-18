#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Update the box
apt-get update
apt-get -y upgrade
