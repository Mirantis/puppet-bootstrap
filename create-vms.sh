#!/bin/bash

SIZE=$1

lvcreate --name foreman --size ${SIZE}G VMstorage
lvcreate --name puppetdb --size ${SIZE}G VMstorage
lvcreate --name puppet --size ${SIZE}G VMstorage

# Create foreman server
for i in foreman puppetdb puppet
do
  virt-install -n $i -r 2048 --vcpus 1 --description='$i server' --initrd-inject=bootstrap/$i.ks -l http://mirrors.bluehost.com/centos/7/os/x86_64/ --os-type=linux --os-variant=rhel7 --disk path=/dev/vms/$i,bus=virtio,size=10 --network bridge=br0,model=virtio --autostart --graphics none  --console pty,target_type=serial --noautoconsole --extra-args "console=ttyS0,115200n8 serial net.ifnames=0 inst.repo=http://mirrors.bluehost.com/centos/7/os/x86_64/ ks.device=eth0 ks=file:/bootstrap/$i.ks"
done
