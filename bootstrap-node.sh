#!/bin/bash

package=('git' 'http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm' 'ntp' 'puppet' 'http://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm' 'http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm')

for i in ${package[@]}; do
    yum -y install $i
done

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

puppet agent -t --server [your puppet master] --ca_server [your CA server]
