#!/bin/bash

if [[ `facter osfamily` == 'Debian' ]]; then
  package=('git' 'ntp' 'puppet')
  debs=('http://apt.puppetlabs.com/puppetlabs-release-trusty.deb')
  echo "deb http://deb.theforeman.org/ trusty stable" >> /etc/apt/sources.list.d/foreman.list
  echo "deb http://deb.theforeman.org/ plugins stable" >> /etc/apt/sources.list.d/foreman.list
  wget -q http://deb.theforeman.org/pubkey.gpg -O- | apt-key add -

  apt-get update

  for i in ${debs[@]}; do
    wget $i
    deb_package=`echo $i | awk -F / '{print $NF}'`
    dpkg -i $deb_package
  done

  apt-get update

  for i in ${package[@]}; do
    apt-get -y install $i
  done

else
  package=('git' 'http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm' 'ntp' 'puppet' 'http://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm' 'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm')
  for i in ${package[@]}; do
    yum -y install $i
  done
fi


service ntpd stop
ntpdate time.apple.com
service ntpd start

# The following sets up autosigning of the puppet cert
# The OID and key listed here need to be in /etc/puppet/csr_attributes.yaml
# prior to the cert being generated and need to be checked in your autosign
# executable at /etc/puppet/autosign-policy.rb
echo '### This file is managed by Puppet ###

# This is a yaml file for specifying custom CSR extensions for policy-based auto signing
---
extension_requests:
  [Your OID here]: "[Your key here]"' > /etc/puppet/csr_attributes.yaml

rm -rf /var/lib/puppet/ssl
puppet agent -t --server [your puppet master] --ca_server [your CA server]
