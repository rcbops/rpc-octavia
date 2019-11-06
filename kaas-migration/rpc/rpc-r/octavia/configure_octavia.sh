#!/bin/bash
set -vex

export OCTAVIA_PROJECT_ID="service"
export OCTAVIA_AMP_PATH="/home/stack/images/amphora-x64-haproxy-centos.qcow2"
export OCTAVIA_CERT_DIR="/home/stack/octavia-certs"
export TRIPLEO_CONFIG_DIR="/home/stack/tmp_config_dump/"
export CONFIG_SAVE="/home/stack/configure_octavia.vars"

if [ "$1" != "override" ] && [ -e $CONFIG_SAVE ]; then
    echo "Using $CONFIG_SAVE for variables"
    source $CONFIG_SAVE
else
    echo "Proceeding with user environment variables"
fi

# Check some prereqs
[ -z "$OVERCLOUD_RC" ] && { echo "Need to set OVERCLOUD_RC with the rc file of the overcloud"; exit 1; }
[ -z "$STACK_RC" ] && { echo "Need to set STACK_RC with the rc file of the undercloud"; exit 1; }
[ -z "$TRIPLEO_PLAN_NAME" ] && { echo "Need to set TRIPLEO_PLAN_NAME with the name of the cloud"; exit 1; }
[ -z "$NETWORK_PREFIX"] && { echo "Need to set NETWORK_PREFIX with the prefix of the controller ips to use, e.g. 172.26.232 on lab 3  "; exit 1; }
[ -z "$AMP_NETWORK_NAME" ] && { echo "Need to set AMP_NETWORK_NAME with the name of the amphora network, e.g. ext-net"; exit 1; }
[ -z "$CONTROLLER_REGEX" ] && { echo "Need to set CONTROLLER_REGEX with the regex to determine the controllers inthe undercloud, e.g. export CONTROLLER_REGEX='.*controller.*'"; exit 1; }

#Save the values we used to run this
if [ ! -e $CONFIG_SAVE ]; then
    > $CONFIG_SAVE
    echo "OVERCLOUD_RC=$OVERCLOUD_RC" >> $CONFIG_SAVE
    echo "STACK_RC=$STACK_RC" >> $CONFIG_SAVE
    echo "TRIPLEO_PLAN_NAME=$TRIPLEO_PLAN_NAME" >> $CONFIG_SAVE
    echo "NETWORK_PREFIX=$NETWORK_PREFIX" >> $CONFIG_SAVE
    echo "AMP_NETWORK_NAME=$AMP_NETWORK_NAME" >> $CONFIG_SAVE
    echo "CONTROLLER_REGEX=$CONTROLLER_REGEX" >> $CONFIG_SAVE
fi


# source the overcloud RC
source ${OVERCLOUD_RC}
if [ ! -z $OS_IDENTITY_API_VERSION ] && [ $OS_IDENTITY_API_VERSION == 3 ] ; then
    echo "Please use V2 of OvercloudRC file, exiting"
    exit 1
fi


# Pull images from https://images.rdoproject.org/octavia/queens/
if [ ! -r "${OCTAVIA_AMP_PATH}" ]; then
    curl https://images.rdoproject.org/octavia/queens/amphora-x64-haproxy-centos.qcow2 --output ${OCTAVIA_AMP_PATH}
fi

# Upload image to glance if not alreay uploaded
# Note: replace image manually
openstack image list | grep -q 'amphora-x64-haproxy' || \
openstack image create --container-format bare --disk-format qcow2 \
--file  ${OCTAVIA_AMP_PATH} \
--project ${OCTAVIA_PROJECT_ID} --private --tag "octavia-amphora-image" amphora-x64-haproxy \
&& echo "Skipping image upload since the image already exist."

# Create flavor if not exist
openstack flavor list --all | grep -q 'm1.amphora' || \
openstack flavor create --ram 1024 --disk 3  --project ${OCTAVIA_PROJECT_ID} --private m1.amphora
export OCTAVIA_FLAVOR_ID=$(openstack flavor show m1.amphora -f value -c id)

# Create security group
openstack security group list | grep -q 'octavia_sec_grp' || \
(openstack security group create --description  "security group for octavia amphora" --project ${OCTAVIA_PROJECT_ID} octavia_sec_grp; \
openstack security group rule create --ingress --ethertype=IPv4 --dst-port 9443:9443 --protocol=tcp  octavia_sec_grp)
# openstack security group rule create --ingress --ethertype=IPv4 --dst-port 22:22 --protocol=tcp  octavia_sec_grp
export OCTAVIA_SEC_GRP_ID=$(openstack security group  show octavia_sec_grp -f value -c id)

# figure out network-id
export OCTAVIA_NETWORK_ID=$(openstack network show ${AMP_NETWORK_NAME} -f value -c id)
[ -z "$OCTAVIA_NETWORK_ID" ] && { echo "Failed to set OCTAVIA_NETWORK_ID using ${AMP_NETWORK_NAME}"; exit 1; }

# Configure quotas
openstack quota set \
          --cores "10000" \
          --instances "10000" \
          --ram "10240000" \
          --server-groups "5000" \
          --server-group-members "50" \
          --gigabytes "30000" \
          --volumes "10000" \
          --secgroups "10000" \
          --ports "100000" \
          --secgroup-rules "100000" \
          service

# Create roles
openstack role create --or-show load-balancer_observer
openstack role create --or-show load-balancer_global_observer
openstack role create --or-show load-balancer_member
openstack role create --or-show load-balancer_admin
openstack role create --or-show load-balancer_quota_admin

# Create certs
mkdir -p ${OCTAVIA_CERT_DIR}
export OCTAVIA_CERT_PASSWORD=$(openssl rand -base64 32)
if [ ! -f ${OCTAVIA_CERT_DIR}/passphrase ]; then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    # make generated cert valid for 10 years (3652 days)
    ${DIR}/create_certificates.sh ${OCTAVIA_CERT_DIR} ${DIR}/openssl.conf 3652 ${OCTAVIA_CERT_PASSWORD}
    echo "${OCTAVIA_CERT_PASSWORD}" > ${OCTAVIA_CERT_DIR}/passphrase
else
  export OCTAVIA_CERT_PASSWORD=$(cat ${OCTAVIA_CERT_DIR}/passphrase)
fi

# figure out keystone endpoints
export internal_url=$(openstack endpoint show keystone -f value -c internalurl)
export admin_url=$(openstack endpoint show keystone -f value -c adminurl)
# this will extract the vip from keystone's publicurl for later use by discarding https and the port
export vip=$(openstack endpoint show keystone -f value -c publicurl|sed -E "s/https:\/\/(.*):.*/\1/")

source ${STACK_RC}
#figure out Octavia auth password
mkdir -p ${TRIPLEO_CONFIG_DIR}
openstack overcloud config download --name ${TRIPLEO_PLAN_NAME} --config-dir ${TRIPLEO_CONFIG_DIR}
export OCTAVIA_PWD=$(grep -r "octavia::keystone::auth::password" ${TRIPLEO_CONFIG_DIR} |  rev | cut -d':' -f 1 | rev)
rm -rf ${TRIPLEO_CONFIG_DIR}

# Configure each controller - the dreaded loop pattern
export controllers=$(openstack server list --name ${CONTROLLER_REGEX} -f value -c Networks|cut -d '=' -f2|tr "\n" "\n")
[ -z "$controllers" ] && { echo "Couldn't determine controller hosts. Please check yur regex. Aborting..."; exit 1;}

# Figure out the ips we need to use (assuming they prefix with 172.26.232. )
# Todo abitrary prefix
health_ips=""
for line in $controllers; do
    health_ips+=$(ssh heat-admin@${line} "set -ex; sudo ip a | grep -v ${vip} | grep -Po 'inet \K${NETWORK_PREFIX}.*?(?=/)'"):5555,
done
# remove last comma
export health_ips=$(echo ${health_ips} | rev | cut -c 2- | rev)

for line in $controllers; do
echo "Processing controller ${line}"
# copy certs
scp -o "StrictHostKeyChecking no" \
    ${OCTAVIA_CERT_DIR}/ca_02.pem ${OCTAVIA_CERT_DIR}/private/cakey02.pem \
    ${OCTAVIA_CERT_DIR}/ca_01.pem ${OCTAVIA_CERT_DIR}/client.pem \
    heat-admin@${line}:/home/heat-admin

# configure
ssh -o "StrictHostKeyChecking no" heat-admin@${line} <<EOF
sudo su -
set -ex
mkdir -p /etc/pki/ca-trust/extracted/octavia
mv /home/heat-admin/ca_02.pem /etc/pki/ca-trust/extracted/octavia/
mv /home/heat-admin/cakey02.pem /etc/pki/ca-trust/extracted/octavia/
mv /home/heat-admin/ca_01.pem /etc/pki/ca-trust/extracted/octavia/
mv /home/heat-admin/client.pem /etc/pki/ca-trust/extracted/octavia/
# We know if we append it at the end oslo.config will take it. So add our  configs
cat <<-END >>/var/lib/config-data/puppet-generated/octavia/etc/octavia/octavia.conf

# auto generated config $(date)
[health_manager]
event_streamer_driver = noop_event_streamer
controller_ip_port_list=${health_ips}
bind_ip=0.0.0.0
[keystone_authtoken]
auth_uri=${internal_url}
auth_url=${admin_url}
project_domain_name = Default
user_domain_name = Default
status_update_threads=10 # default 50
[certificates]
ca_certificate = /etc/pki/ca-trust/extracted/octavia/ca_02.pem
ca_private_key = /etc/pki/ca-trust/extracted/octavia/cakey02.pem
ca_private_key_passphrase = ${OCTAVIA_CERT_PASSWORD}
[haproxy_amphora]
client_cert = /etc/pki/ca-trust/extracted/octavia/client.pem
server_ca = /etc/pki/ca-trust/extracted/octavia/ca_02.pem
[controller_worker]
amp_active_retries = 60
amp_active_wait_sec = 10
loadbalancer_topology=ACTIVE_STANDBY
amp_image_tag = octavia-amphora-image
amp_flavor_id=${OCTAVIA_FLAVOR_ID}
amp_boot_network_list = ${OCTAVIA_NETWORK_ID}
amp_secgroup_list = octavia_sec_grp
client_ca = /etc/pki/ca-trust/extracted/octavia/ca_01.pem
amp_ssh_access_allowed=false
[service_auth]
password=${OCTAVIA_PWD}
username=octavia
auth_url=${admin_url}
project_name=${OCTAVIA_PROJECT_ID}
project_domain_name = Default
user_domain_name = Default
auth_type=password
[api_settings]
api_v1_enabled=false
allow_tls_terminated_listeners=false
[nova]
enable_anti_affinity=true

END
EOF
ssh -o "StrictHostKeyChecking no" heat-admin@${line} "set -ex; for i in \$(sudo docker ps |grep octavia |awk -F\" \" '{print \$1}'); do sudo docker restart \$i; sleep 3;done"

done

echo "Octavia set up finished!"
