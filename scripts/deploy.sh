#!/usr/bin/env bash
# Copyright 2014-2017, Rackspace US, Inc.
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

set -e -u -x
set -o pipefail

export BASE_DIR=${BASE_DIR:-"/opt/rpc-openstack"}
source ${BASE_DIR}/scripts/functions.sh

# setup Octavia
openstack-ansible /opt/rpc-octavia/playbooks/main.yml -e "download_artefact=${AMP_DOWNLOAD:-True}"

cd /opt/openstack-ansible/playbooks/

#rebuild neutron-agent container networking if deploying AIO
if [[ "${DEPLOY_AIO}" == "yes" ]]; then
  openstack-ansible lxc-containers-create.yml -e 'lxc_container_allow_restarts=false' --limit neutron_agents_container
  # wire up network
  openstack-ansible os-neutron-install.yml
fi

# build container
openstack-ansible lxc-containers-create.yml -e 'lxc_container_allow_restarts=false' --limit octavia_all

# refresh wheels
openstack-ansible repo-build.yml

# install octavia
# Note: We overwrite how pip is run in os-octavia-install
# This won't configure the event streamer properly right now -- add that if it's needed by cherry-picking the os-octavia patch
# and including the neutron_all variables?
openstack-ansible   os-octavia-install.yml
# add service to haproxy
openstack-ansible haproxy-install.yml
# add filebeat to service so we get logging
cd /opt/rpc-openstack/
openstack-ansible /opt/rpc-openstack/playbooks/filebeat.yml --limit octavia_all
# MaaS
cd /opt/rpc-maas/playbooks && openstack-ansible site.yml
