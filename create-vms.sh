#!/bin/bash

SIZE=$2
VOLGROUP=$1
CPU=$3
RAM=$4

if [[ -z $SIZE || -z $VOLGROUP || -z $CPU || -z $RAM ]]; then
  echo "Usage: create-vms.sh <Volume Group> <Size in GB> <cpu count> <RAM in MB>"
  exit 1
fi

# Create foreman server
for i in gitlab foreman puppetdb puppet
do
  echo "Creating $i node..."
  lvcreate --name $i --size ${SIZE}G ${VOLGROUP}
  virt-install -n $i -r $RAM --vcpus $CPU --description='$i server' --initrd-inject=bootstrap/$i.ks -l http://mirrors.bluehost.com/centos/7/os/x86_64/ --os-type=linux --os-variant=rhel7 --disk path=/dev/${VOLGROUP}/$i,bus=virtio,size=${SIZE} --network bridge=br0,model=virtio --autostart --graphics none  --console pty,target_type=serial --noautoconsole --extra-args "console=ttyS0,115200n8 serial net.ifnames=0 inst.repo=http://mirrors.bluehost.com/centos/7/os/x86_64/ ks.device=eth0 ks=file:/$i.ks"
  echo "Done. Install will take a bit. You can virsh console one to see where it's at."
done

echo "Creating deploy node"
  lvcreate --name 'deploy' --size 10G ${VOLGROUP}
  virt-install -n 'deploy' -r 2048 --vcpus 1 --description='$i server' --initrd-inject=bootstrap/deploy.ks -l http://mirrors.bluehost.com/centos/7/os/x86_64/ --os-type=linux --os-variant=rhel7 --disk path=/dev/${VOLGROUP}/deploy,bus=virtio,size=10 --network bridge=br0,model=virtio --autostart --graphics none  --console pty,target_type=serial --noautoconsole --extra-args "console=ttyS0,115200n8 serial net.ifnames=0 inst.repo=http://mirrors.bluehost.com/centos/7/os/x86_64/ ks.device=eth0 ks=file:/deploy.ks"
echo "Done. Install will take a bit."
