#!/bin/sh
sudo dnf -y install virt-manager virt-viewer virt-install libguestfs-tools libvirt-daemon-config-network
sudo sh -c "echo 'options kvm-intel nested=1' > /etc/modprobe.d/kvm-intel.conf"
sudo sh -c "echo 'options kvm-amd nested=1' > /etc/modprobe.d/kvm-amd.conf"
sudo virsh net-define net-materials/external01.xml 
sudo virsh net-start external01
sudo virsh net-autostart external01
sudo virsh net-define net-materials/internal01.xml
sudo virsh net-start internal01
sudo virsh net-autostart internal01

sudo mkdir -p /home/kvm/images/
sudo chown -R root:libvirt /home/kvm
sudo chmod -R 775 /home/kvm

sudo sh -c "echo 'group=\"libvirt\"' >> /etc/libvirt/qemu.conf"
sudo sh -c "echo 'dynamic_ownership=1' >> /etc/libvirt/qemu.conf"
sudo gpasswd -a $(whoami) kvm

cat << 'EOS' > /tmp/addlibvirtd.conf
unix_sock_group = "libvirt"
unix_sock_ro_perms = "0777"
unix_sock_rw_perms = "0770"
auth_unix_ro = "none"
auth_unix_rw = "none"
EOS
sudo sh -c "cat /tmp/addlibvirtd.conf >> /etc/libvirt/libvirtd.conf"
sudo usermod -a -G libvirt $(whoami)
sudo systemctl restart libvirtd.service


