#!/bin/bash
set +ex
export octavia_tag=12.0

# Copy the queen version of the puppet template
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sudo cp ${DIR}/queen_puppet_octavia-health-manager.yaml /usr/share/openstack-tripleo-heat-templates/puppet/services/octavia-health-manager.yaml

# Copy /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml to
# ~/templates/55-octavia.yaml
# ~/templates is directory the RPC-R install team made and put install heat templates in
# for overcloud install paths in the file needs updated to be fully pathed

cp /usr/share/openstack-tripleo-heat-templates/environments/services-docker/octavia.yaml ~/templates/55-octavia.yaml

sed -i -e 's/\.\.\/\.\.\//\/usr\/share\/openstack-tripleo-heat-templates\//g' ~/templates/55-octavia.yaml
# (optional) remove lbaasv2 from the neutron plugins - uncomment if needed
# sed -i -e 's/,lbaasv2//g' ~/templates/55-octavia.yaml

# Update ~/templates/01-overcloud_images.yaml with Octavia image information
grep -v "Octavia" ~/templates/01-overcloud-images.yaml >~/templates/01-overcloud_images.yaml.bak
cat << EOF >> ~/templates/01-overcloud_images.yaml.bak
  DockerOctaviaApiImage: registry.access.redhat.com/rhosp12/openstack-octavia-api:${octavia_tag}
  DockerOctaviaConfigImage: registry.access.redhat.com/rhosp12/openstack-octavia-api:${octavia_tag}
  DockerOctaviaHealthManagerImage: registry.access.redhat.com/rhosp12/openstack-octavia-health-manager:${octavia_tag}
  DockerOctaviaHousekeepingImage: registry.access.redhat.com/rhosp12/openstack-octavia-housekeeping:${octavia_tag}
  DockerOctaviaWorkerImage: registry.access.redhat.com/rhosp12/openstack-octavia-worker:${octavia_tag}
EOF
sort ~/templates/01-overcloud_images.yaml.bak |sed  '$ d' | awk 'NR==4 {print "parameter_defaults:"} 1' >  ~/tmp-images.yaml

echo "~/tmp-images.yaml"
cat ~/tmp-images.yaml

echo "~/templates/01-overcloud-images.yaml"
cat ~/templates/01-overcloud-images.yaml

read -p "Compare the files. Ok to continue? (Y/N) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

#  Copy new image yaml into place and make a copy for safekeeping
cp ~/templates/01-overcloud-images.yaml ~/templates/01-overcloud_images.yaml.bak
cp ~/tmp-images.yaml ~/templates/01-overcloud-images.yaml

echo "Run install script: ~/scripts/deploy-osp12.sh"