#!/bin/bash

# this file can be pulled git clone https://github.com/nlouwere1/labsa.git
# first section is to force a speciffic mirror in yum had issues that it takes a repo that was down

yum install -y nfs-utils libnfsidmap
mkdir /nfs
mount -o rw -t nfs nas:/export/openstack /nfs
/bin/cp /nfs/repo/CentOS-Base.repo /etc/yum.repos.d/.
yum update -y
yum install -y epel-release
yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
yum install nfs-utils libnfsidmap
systemctl enable nfs-server
mkdir /cinder
chmod 777 /cinder
chown root.wheel/cinder
echo "/cinder    10.0.0.0/8(rw,sync,no_root_squash,no_all_squash,insecure)" >> /etc/exports
echo "10.0.1.1:/export/openstack    /nfs   nfs defaults 0 0" >> /etc/fstab
/bin/cp /nfs/repo2/* /etc/yum.repos.d/.
yum install -y openstack-packstack
yum install -y openstack-tools
tee /etc/environment<<-'EOF'
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
EOF
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
echo ''
echo 'you are now ready to run packstack'
echo ''
echo 'disbled selinx,firewall,networkmanager enabled network and lanugae support'
echo ''
echo 'please configure second interfave to manual and NM_CONTROLLED=no'
echo ''
echo 'packstack --gen-answer-file=answer.txt --default-password=cisco --allinone --provision-demo=n --os-neutron-ovs-bridge-mappings=extnet:br-ex --os-neutron-ovs-bridge-interfaces=br-ex:ens256 --os-neutron-ml2-type-drivers=vxlan,flat,vlan --cinder-volumes-create=n --nagios-install=n --os-swift-install=n --os-cinder-install=y --cinder-nfs-mounts=10.0.1.21:/cinder --cinder-backend=nfs --os-neutron-lbaas-install=y --os-heat-install=y'
