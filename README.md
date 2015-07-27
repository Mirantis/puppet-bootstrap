# puppet-bootstrap
These scripts are for bootstrapping/standing up a Foreman server and Puppetmaster.  They are intended to be used with the following projects and assume that you have your own fork/copy of those repositories with your data in them:

* https://github.com/mirantis/puppet-control-template.git
* https://github.com/mirantis/profiles.git
* https://github.com/mirantis/roles.git

## Installation:
* Install hiera-eyaml
```
gem install hiera-eyaml
```
* Create pkcs7 keys
```
eyaml createkeys
```
* Clone this repo
```
git clone https://github.com/mirantis/puppet-bootstrap.git
```
* Modify bootstrap-foreman.sh and fill in the values for the pkcs7 keys, control repo location, etc
* Modify bootstrap-master.sh and fill in the values for the pkcs7 keys, control repo location, csr_attributes info, etc.
* Modify bootstrap-node.sh and fill in the values for the csr_attributes info, etc

## Bootstrapping
Once your values are properly filled in in the bootstrap scripts, create a foreman server by running:
```
./bootstrap-foreman.sh
```
Once that is created, create a PuppetBD server by running:
```
./bootstrap-node.sh
```
When the initial run is done, login to foreman and edit the host.  Add the following info:
```
parameters -> global parameter -> application_tier = puppetdb
puppet classes = roles::puppet::db
```
Run puppet again on the node to stand up the puppetdb server.
```
puppet agent -t --server [your foreman server fqdn] --ca_server [your foreman server fqdn]
```

Once your puppetdb server is running, bootstrap a puppet master:
```
./bootstrap-master.sh
```
Once the initial run is done, login to foreman and edit the host. Add the following info:
```
parameters -> global parameter -> application_tier = puppet
puppet classes = roles::puppet::master
```
Run puppet agein on the node to stand up the master:
```
puppet agent -t --server [your foreman server fqdn] --ca_server [your foreman server fqdn]
```
