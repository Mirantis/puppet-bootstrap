install
lang 'en_US.UTF-8'
selinux --permissive
keyboard 'us'
skipx

network --bootproto dhcp --device=eth0 --hostname=foreman

rootpw --iscrypted $1$3bYWxLcb$muZnQbGo3I7PVZ.Lw2sGg0
authconfig --useshadow --passalgo=sha256 --kickstart
timezone --utc UTC

services --disabled gpm,sendmail,cups,pcmcia,isdn,rawdevices,hpoj,bluetooth,openibd,avahi-daemon,avahi-dnsconfd,hidd,hplip,pcscd

repo --name="EPEL" --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=x86_64
repo --name=puppetlabs-products --baseurl=http://yum.puppetlabs.com/el/7/products/x86_64
repo --name=puppetlabs-deps --baseurl=http://yum.puppetlabs.com/el/7/dependencies/x86_64

bootloader --location=mbr --append="nofb quiet splash=quiet net.ifnames=0 ks.device=eth0"

zerombr
clearpart --all --initlabel
part /boot --asprimary --fstype xfs --size=200
part swap --fstype="swap" --size=1024
part / --fstype xfs --size=1 --grow

text
reboot

%packages
@Core
yum
dhclient
ntp
git
telnet
bind-utils
net-tools
wget
redhat-lsb-core
epel-release
puppetlabs-release
%end

%post
logger "Starting anaconda postinstall"
exec < /dev/tty3 > /dev/tty3
#changing to VT 3 so that we can see whats going on....
/usr/bin/chvt 3
(

#update local time
echo "updating system time"
/usr/sbin/ntpdate -sub '0.us.pool.ntp.org'
/usr/sbin/hwclock --systohc

# update all the base packages from the updates repository
yum -t -y -e 0 update

# and add the puppet package
yum -t -y -e 0 install puppet

git clone https://github.com/mirantis/puppet-bootstrap.git /root/bootstrap

) 2>&1 | tee /root/install.post.log
exit 0
%end
