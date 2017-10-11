# rpc-octavia

This integrated Pike Octavia with Newton RPC-O.

In the future this repo might include script to update/remove things
once RPC-O Pike is ready.

Below you will find three prerequisits for installing Octavia:

## Octavia SSL Certificates
The system will automatically create the necessary certificates in `/var/tmp/certs` -
to disable this behavior set ansible variable `generate_client_cert` to `False`

Please note that the default values in 'vars/certs.yml' are suboptimal and should
be reviewed.

In any case make sure to backup the generated certs in a safe place for further use.

For more information refer to [Creating the Cryptographic Certificates](https://docs.openstack.org/openstack-ansible-os_octavia/latest/configure-octavia.html#creating-the-cryptographic-certificates)

## Octavia Networking Setup
The AIO configuration aims to setup the necessary bridge and network automatically
by overwriting some default files. This is not scalable to production and hence
the guide in [Setup a Neutron Network for Octavia](https://docs.openstack.org/openstack-ansible-os_octavia/latest/configure-octavia.html#setup-a-neutron-network-for-use-by-octavia)
should be followed.

## Octavia Diskimage Creation
As part of the gate tests (pre and run) the system will automatically create an image in <PWD>/amp-image You can use that image to install in the system as described in [Building Octavia Iamges](https://docs.openstack.org/openstack-ansible-os_octavia/latest/configure-octavia.html#building-octavia-images). It is recommneded to use images from an official source if possible.

## Additional Information
* [Octavia's docs](https://docs.openstack.org/octavia/latest/)
* [OSA Octavia doc](https://docs.openstack.org/openstack-ansible-os_octavia/latest/index.html)

## Apendix
### Setup an AIO

1. Update the host to the latest packages

    apt-get update && apt-get -y dist-upgrade && reboot

2. Install RPC-O as an AIO

    add-apt-repository ppa:canonical-kernel-team/ppa
    add-apt-repository ppa:ubuntu-toolchain-r/ppa
    cd /opt
    git clone --recursive -b  newton https://github.com/rcbops/rpc-openstack.git
    cd rpc-openstack/
    export DEPLOY_AIO="yes"
    ./scripts/deploy.sh

3. Install Octavia

    cd /opt
    git clone https://github.com/rcbops/rpc-octavia.git
    cd rpc-octavia
    ./scripts/deploy.sh

4. Build, upload and tag an amphora image *before* you can use Octavia

### Run tests (post gate)
1. Update the host to the latest packages

    apt-get update && apt-get -y dist-upgrade && reboot

2. Prepare tests (this might go away eventually)

    add-apt-repository ppa:canonical-kernel-team/ppa
    add-apt-repository ppa:ubuntu-toolchain-r/ppa
    cd /opt
    git clone https://github.com/rcbops/rpc-octavia.git
    cd rpc-octavia

3. Run tests
    ./gating/[pre_merge_test|post_merge_test]/[pre|run|post]


