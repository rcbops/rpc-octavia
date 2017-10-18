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
function amp_image_artifacts_available {

    CHECK_URL="${HOST_OCTAVIA_REPO}/latest"
    LOCAL_FILE="${MY_BASE_DIR}/amp-image/${RPC_RELEASE}/amphora-x64-haproxy.qcow2"

    # Does the file exist?
    if curl --output /dev/null --silent --head --fail ${CHECK_URL}; then
        # Check if the files are the same. Operating System might have had changes
        online_md5=$(curl -s $CHECK_URL | md5sum | awk '{print $1}')
        local_md5=$(md5sum "${LOCAL_FILE}" | awk '{print $1}')

        if [ "$online_md5" == "$local_md5" ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi

}

echo "Post gate job started"
echo "+-------------------- START ENV VARS --------------------+"
env
echo "+-------------------- START ENV VARS --------------------+"

# We use the sha to determine which folder to put things in
export GIT_SHA=$(cd ${OCTAVIA_TEMP_DIR}/octavia; git rev-parse HEAD)

# If there are artifacts for this release, then set PUSH_TO_MIRROR to NO
if amp_image_artifacts_available; then
  echo "Mirror = NO"
  export PUSH_TO_MIRROR="NO"
fi

# If REPLACE_ARTIFACTS is YES then force PUSH_TO_MIRROR to YES
if [[ "$(echo ${REPLACE_ARTIFACTS} | tr [a-z] [A-Z])" == "YES" ]]; then
  export PUSH_TO_MIRROR="YES"
fi

# Only push to the mirror if PUSH_TO_MIRROR is set to "YES"
#
# This enables PR-based tests which do not change the artifacts
#
if [[ "$(echo ${PUSH_TO_MIRROR} | tr [a-z] [A-Z])" == "YES" ]]; then
    if [ -z ${REPO_USER_KEY+x} ] || [ -z ${REPO_USER+x} ] || [ -z ${REPO_HOST+x} ] || [ -z ${REPO_HOST_PUBKEY+x} ]; then
        echo "Skipping upload to rpc-repo as the REPO_* env vars are not set."
        exit 1
    else

        # Prep the ssh key for uploading to rpc-repo
        mkdir -p ~/.ssh/
        set +x
        REPO_KEYFILE=~/.ssh/repo.key
        cat $REPO_USER_KEY > ${REPO_KEYFILE}
        chmod 600 ${REPO_KEYFILE}
        set -x

        # Ensure that the repo server public key is a known host
        grep "${REPO_HOST}" ~/.ssh/known_hosts || echo "${REPO_HOST} $(cat $REPO_HOST_PUBKEY)" >> ~/.ssh/known_hosts

        # Create the Ansible inventory for the upload
        echo '[mirrors]' > /opt/inventory
        echo "repo ansible_host=${REPO_HOST} ansible_user=${REPO_USER} ansible_ssh_private_key_file='${REPO_KEYFILE}' " >> /opt/inventory

        # Upload the artifacts to rpc-repo
        # Todo: set diretcories properly
        openstack-ansible -i /opt/inventory \
                          ${MY_BASE_DIR}/gating/scripts/amphora-image-push-to-mirror.yml \
                          -e rpc_release=${RPC_RELEASE} \
                          -e git_sha=${GIT_SHA} \
                          -e working_dir=${MY_BASE_DIR} \
                          ${ANSIBLE_PARAMETERS}
    fi
else
    echo "Skipping upload to rpc-repo as the PUSH_TO_MIRROR env var is not set to 'YES'."
fi