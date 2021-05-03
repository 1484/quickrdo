#!/bin/sh
sudo dnf -y install virt-manager virt-viewer virt-install libguestfs-tools libvirt-daemon-config-network
sudo sh -c "echo 'options kvm-intel nested=1' > /etc/modprobe.d/kvm-intel.conf"
sudo sh -c "echo 'options kvm-amd nested=1' > /etc/modprobe.d/kvm-amd.conf"

