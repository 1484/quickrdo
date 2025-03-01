#!/bin/sh

function pre_install {
    setenforce 0
    sed -i.bak 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
    yum install -y iptables-services patch
    systemctl stop firewalld.service
    systemctl mask firewalld.service
    systemctl start iptables.service
    systemctl enable iptables.service
    yum -y install network-scripts
    readlink $(readlink $(which ifup))
    touch /etc/sysconfig/disable-deprecation-warnings
    systemctl disable --now NetworkManager
    systemctl enable network
    systemctl start network


#    yum -y install http://repos.fedorapeople.org/repos/openstack/EOL/openstack-havana/rdo-release-havana-9.noarch.rpm
#    sed -i 's/openstack\/openstack-havana/openstack\/EOL\/openstack-havana/' /etc/yum.repos.d/rdo-release.repo
#    sed -i 's/$releasever/20/g' /etc/yum.repos.d/puppetlabs.repo

    yum -y install centos-release-openstack-victoria
    yum config-manager --set-enabled powertools

    yum -y install openstack-packstack
}

function pre_reboot {
    az_num=$1
    if cat /proc/cpuinfo | grep -E "^flags.+hypervisor" | grep -q -E "(vmx|svm)"; then
        openstack-config --set /etc/nova/nova.conf DEFAULT libvirt_type kvm
    fi

    # https://bugzilla.redhat.com/show_bug.cgi?id=1103800
    list=("/usr/lib/python2.7/site-packages/cinder/openstack/common/rpc/impl_qpid.py" \
          "/usr/lib/python2.7/site-packages/keystone/openstack/common/rpc/impl_qpid.py" \
          "/usr/lib/python2.7/site-packages/neutron/openstack/common/rpc/impl_qpid.py" \
          "/usr/lib/python2.7/site-packages/nova/openstack/common/rpc/impl_qpid.py")
    for module in ${list[@]}; do
        sed -i 's/\(^            node_name = \)msg_id$/\1"%s\/%s" % (msg_id, msg_id)/' $module
    done

    # https://bugzilla.redhat.com/show_bug.cgi?id=1139907
    patch -p0 -Nsb /usr/lib/python2.7/site-packages/cinder/backup/api.py < /root/cinder_backup_api.py.patch

    systemctl disable openstack-cinder-api.service
    systemctl disable openstack-cinder-scheduler.service  

    openstack-config --set /etc/cinder/cinder.conf DEFAULT host $HOSTNAME
    openstack-config --set /etc/cinder/cinder.conf DEFAULT volume_clear none
    openstack-config --set /etc/cinder/cinder.conf DEFAULT storage_availability_zone az$az_num
    openstack-config --set /etc/nova/nova.conf DEFAULT allow_resize_to_same_host true

    cat <<'EOF' >/etc/rc.d/rc.local
#!/bin/sh
for i in $(ip -o link | awk -F: '/ eth[0-9]+/{print $2}'); do
  ethtool -K $i tx off gro off gso off
done
EOF
    chmod u+x /etc/rc.d/rc.local
}

function post_install {
    privnic=$1

    if virsh net-info default >/dev/null ; then
        virsh net-destroy default
        virsh net-autostart default --disable
    fi

    if ! ovs-vsctl list-ports br-priv | grep -q ${privnic}; then
        ovs-vsctl add-port br-priv ${privnic}
    fi
}

## main

case $1 in
  pre)
    pre_install
    ;;
  post1)
    pre_reboot $2
    ;;
  post2)
    post_install $2
    ;;
esac

