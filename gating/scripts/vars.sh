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

# The scripts expects the git clone to be at /opt/rpc-octavia, so we link
# the current folder there.
if [[ "${PWD}" != "/opt/rpc-octavia" ]]; then
  ln -sfn ${PWD} /opt/rpc-octavia
fi

# Set this to YES if you want to replace any existing artifacts for the current
# release with those built in this job.
export REPLACE_ARTIFACTS=${REPLACE_ARTIFACTS:-no}

# Set this to YES if you want to push any changes made in this job to rpc-repo.
export PUSH_TO_MIRROR=${PUSH_TO_MIRROR:-no}

# The MY_BASE_DIR needs to be set to ensure that the scripts
# know it and use this checkout appropriately.
export MY_BASE_DIR=/opt/rpc-octavia/

# We want the role downloads to be done via git
export ANSIBLE_ROLE_FETCH_MODE="git-clone"

# Octavia tmp dir
export OCTAVIA_TEMP_DIR=/var/tmp/

# To provide flexibility in the jobs, we have the ability to set any
# parameters that will be supplied on the ansible-playbook CLI.
export ANSIBLE_PARAMETERS=${ANSIBLE_PARAMETERS:--v}

# Pin RPC-Release to 14.3
export RPC_RELEASE="r14.3.0"
