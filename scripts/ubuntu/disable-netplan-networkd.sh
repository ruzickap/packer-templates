#!/bin/bash -eux

# This needs to be executed on the Ubuntu server installation (mini.iso) when installing Desktop environment using
# `tasksel tasksel/first multiselect ubuntu-desktop`

# By default Ubuntu server installation (mini.iso) creates the `/etc/netplan/01-netcfg.yaml` and `/etc/netplan/01-network-manager-all.yaml` which causes problems to Vagrant.
# Some details can be found here: https://github.com/hashicorp/vagrant/issues/11378
# In short the /etc/netplan/01-netcfg.yaml should not be on the Ubuntu Desktop installation when using Vagrant otherwise `vagrant up` is hanging.

test -s /etc/netplan/01-netcfg.yaml && rm -v /etc/netplan/01-netcfg.yaml
