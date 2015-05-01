#!/bin/sh

yum -y install http://repos.fedorapeople.org/repos/openstack/EOL/openstack-havana/rdo-release-havana-9.noarch.rpm
sed -i 's/openstack\/openstack-havana/openstack\/EOL\/openstack-havana/' /etc/yum.repos.d/rdo-release.repo
sed -i 's/$releasever/20/g' /etc/yum.repos.d/puppetlabs.repo
yum -y install python-novaclient \
    python-neutronclient \
    python-glanceclient \
    python-cinderclient \
    python-swiftclient \
    python-keystoneclient
