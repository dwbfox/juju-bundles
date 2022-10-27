#!/usr/bin/bash

# Read out some stuff 
source openrcv3_project
openstack catalog list
openstack service list
openstack network agent list
openstack volume service list

# Add a new image to glance
curl http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img | \
   openstack image create --public --container-format=bare --disk-format=qcow2 \
   focal-amd64


# Create external network
openstack network create ext_net --external --share --default \
   --provider-network-type flat --provider-physical-network physnet1

# and the external subnet
openstack subnet create ext_subnet --allocation-pool start=10.0.8.201,end=10.0.8.254 \
   --subnet-range 10.0.8.0/24 --no-dhcp --gateway 10.0.8.1 --network ext_net

# Create internal subnet and network
openstack network create int_net --internal
openstack subnet create int_subnet \
   --allocation-pool start=192.168.20.10,end=192.168.20.99 \
   --subnet-range 192.168.20.0/24 \
   --gateway 192.168.20.1 --dns-nameserver 10.0.8.1 \
   --network int_net

# Create a router to stictch internal subnet with external subnet
openstack router create router1
openstack router add subnet router1 int_subnet
openstack router set router1 --external-gateway ext_net

# Add a  new flavor
openstack flavor create --public --ram 512 --disk 5 --ephemeral 0 --vcpus 1 m1.tiny

# Generate an SSH key and add it to openstack
ssh-keygen -q -N '' -f ~/.ssh/osc_key
openstack keypair create --public-key ~/.ssh/osc_key.pub osc_key

# Add ping and SSH access to the default security group list
for i in $(openstack security group list | awk '/default/{ print $2 }'); do
    openstack security group rule create $i --protocol icmp --remote-ip 0.0.0.0/0;
    openstack security group rule create $i --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 22;
done

echo "Done!"
