#!/bin/bash

# this file can be pulled git clone https://github.com/nlouwere1/labsa.git
# first section is to force a speciffic mirror in yum had issues that it takes a repo that was down
# forcing reslove to my fastest mirror change ip if needed
echo "mirror.centos.org 154.66.153.4" >> /etc/hosts
sed -i "s/mirrorlist=/#mirrorlist=/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i "s/#baseurl=/baseurl=/g" /etc/yum.repos.d/CentOS-Base.repo
sed -i "s/mirror.centos.org/mirror.wiru.co.za/g" /etc/yum.repos.d/CentOS-Base.repo
#disable the fastest mirror plugin
sed -i "s/enabled=1/enabled=0/g" /etc/yum/pluginconf.d/fastestmirror.conf


# setting up environoment
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

# adding git environoment permananet
git config --global user.name "nlouwere1"
git config --global user.email "nlouwere@me.com"
git config --global color.ui auto

#updating and installing needed packages including switch from chrony to NTP
yum update -y
yum install -y nfs-utils libnfsidmap epel-release ntp ntpdate open-vm-tools
yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
sed -i "s/mirror.centos.org/mirror.wiru.co.za/g" /etc/yum.repos.d/rdo-release.repo
sed -i "s/mirror.centos.org/mirror.wiru.co.za/g" /etc/yum.repos.d/rdo-qemu-ev.repo 
sed -i "s/mirrorlist=/#mirrorlist=/g" /etc/yum.repos.d/CentOS-fasttrack.repo
sed -i "s/#baseurl=/baseurl=/g" /etc/yum.repos.d/CentOS-fasttrack.repo
sed -i "s/mirror.centos.org/mirror.wiru.co.za/g" /etc/yum.repos.d/CentOS-fasttrack.repo
sed -i "s/mirror.centos.org/mirror.wiru.co.za/g" /etc/yum.repos.d/CentOS-CR.repo
yum erase chrony -y
sed -i "s/#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap/#restrict 10.0.0.0 mask 255.0.0.0 nomodify notrap/g" /etc/ntp.conf
sed -i "s/server 3.centos.pool.ntp.org iburst/#server 3.centos.pool.ntp.org iburst/g" /etc/ntp.conf
sed -i "s/server 1.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburst/g" /etc/ntp.conf
sed -i "s/server 2.centos.pool.ntp.org iburst/#server 2.centos.pool.ntp.org iburst/g" /etc/ntp.conf
sed -i "s/server 0.centos.pool.ntp.org iburst/server 10.0.1.254 iburst/g" /etc/ntp.conf
systemctl start ntpd && systemctl enable ntpd && systemctl status ntpd


# setting up NFS
mkdir /nfs
systemctl enable nfs-server
systemctl start rpcbind
systemctl start nfs-server
systemctl start rpc-statd
systemctl start nfs-idmapd
mkdir /cinder
chmod 777 /cinder
chown root.wheel /cinder
echo "/cinder    10.0.0.0/8(rw,sync,no_root_squash,no_all_squash,insecure)" >> /etc/exports
echo "10.0.1.1:/export/openstack    /nfs   nfs defaults 0 0" >> /etc/fstab
exportfs -r
systemctl enable nfs-server
systemctl restart nfs-server

#packstack install (latest if specific release openstack-packstac-<release>)
yum update -y
yum install -y openstack-packstack openstack-tools



# done just some things to print
echo ''
echo 'you are now ready to run packstack'
echo ''
echo 'disbled selinx,firewall,networkmanager enabled network and lanugae support'
echo ''
echo 'please configure second interfave to manual and NM_CONTROLLED=no'
echo 'packstack --gen-answer-file=answer.txt --default-password=cisco --allinone --provision-demo=n --os-neutron-ovs-bridge-mappings=extnet:br-ex --os-neutron-ovs-bridge-interfaces=br-ex:ens256 --os-neutron-ml2-type-drivers=vxlan,flat,vlan --cinder-volumes-create=n --nagios-install=n --os-neutron-lbaas-install=y --os-heat-install=y --cinder-nfs-mounts=10.0.1.21:/cinder --cinder-backend=nfs'
echo 'remember to change --os-neutron-ovs-bridge-interfaces=br-ex:ens256 and --cinder-nfs-mounts=10.0.1.21:/cinder'
echo 'after that run packstack --answer-file=answer.txt or edit it to suite your needs'
echo ''
echo 'REBOOT IMMER GOOD'
ntpq -p
# echo 'handy command sed -e 's/#.*$//' -e '/^$/d' answer.txt  > answer1.txt to get rid of all comments'
