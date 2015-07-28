#!/bin/bash

SIZE=$2
VOLGROUP=$1
CPU=$3
RAM=$4

if [[ -z $SIZE || -z $VOLGROUP || -z $CPU || -z $RAM ]]; then
  echo "Usage: create-vms.sh <Volume Group> <Size in GB> <cpu count> <RAM in MB>"
  exit 1
fi

lvcreate --name gitlab --size ${SIZE}G ${VOLGROUP}
lvcreate --name foreman --size ${SIZE}G ${VOLGROUP}
lvcreate --name puppetdb --size ${SIZE}G ${VOLGROUP}
lvcreate --name puppet --size ${SIZE}G ${VOLGROUP}

# Create foreman server
for i in gitlab foreman puppetdb puppet
do
  virt-install -n $i -r $RAM --vcpus $CPU --description='$i server' --initrd-inject=bootstrap/$i.ks -l http://mirrors.bluehost.com/centos/7/os/x86_64/ --os-type=linux --os-variant=rhel7 --disk path=/dev/${VOLGROUP}/$i,bus=virtio,size=${SIZE} --network bridge=br0,model=virtio --autostart --graphics none  --console pty,target_type=serial --noautoconsole --extra-args "console=ttyS0,115200n8 serial net.ifnames=0 inst.repo=http://mirrors.bluehost.com/centos/7/os/x86_64/ ks.device=eth0 ks=file:/bootstrap/$i.ks"
done
