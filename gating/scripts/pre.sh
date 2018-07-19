#!/usr/bin/env bash
# Copyright 2014-2017 , Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## Shell Opts ----------------------------------------------------------------
set -xeuo pipefail

## Vars ----------------------------------------------------------------------
source ${PWD}/gating/scripts/vars.sh

## Main ----------------------------------------------------------------------
echo "Pre gate job started"
echo "+-------------------- START ENV VARS --------------------+"
env
echo "+-------------------- START ENV VARS --------------------+"

# Deploy RPC-Openstack
# Assume we have the packages. In my tests I had to add:
# * sudo add-apt-repository ppa:canonical-kernel-team/ppa
# * sudo add-apt-repository ppa:ubuntu-toolchain-r/ppa
if [ ! -d /opt/rpc-openstack ]; then
  git clone --recursive -b ${RPC_RELEASE} https://github.com/rcbops/rpc-openstack /opt/rpc-openstack
fi
cd /opt/rpc-openstack/
export DEPLOY_AIO="yes"
if [[ ! ${RE_JOB_IMAGE} =~ _snapshot$ ]]; then
  bash /opt/rpc-openstack/scripts/deploy.sh
fi

export SETUP_NETWORK=True
export CONFIGURE_NETWORK=True
# Install Octavia
bash /opt/rpc-octavia/scripts/deploy.sh

# install tempest
cd /opt/rpc-openstack/openstack-ansible/playbooks/
openstack-ansible  /opt/rpc-openstack/openstack-ansible/playbooks/os-tempest-install.yml

# Build an amphora image to be uplaoded
# work-around for bug https://github.com/ansible/ansible/issues/14468 deployed
openstack-ansible ${MY_BASE_DIR}/gating/scripts/rpc-build-image.yml \
                  -e rpc_release=${RPC_RELEASE} \
                  -e octavia_tmp_dir=${OCTAVIA_TEMP_DIR} \
                  -e working_dir=${MY_BASE_DIR} \
                  -e ansible_python_interpreter=/usr/bin/python \
                  ${ANSIBLE_PARAMETERS}

echo "Pre gate job ended"