# Notes:

This repo is not currently being developed or tested. Deployment tools
for both OSP and openstack-ansible support octavia, but this could change
in the future.  This repo is only valid for the older installs referenced
below.

# rpc-octavia

* Branch master is for the managed k8s install against Newton
* Branch pike and pike-rc are for Pike
* For Queens and beyond this repository is retired and installs will be using the upstream OSA os_octavia with some RPC-O specific tuning

# Installation instructions
* managed k8s - newton: Docs are in the k8s repos
* Pike: draft installation.md

# Kaas migration

We are moving the octavia setup scripts and docs from the kaas repo to this EOL repo to save the
information on older installs if needed. 

This repo(rpc-octavia) was referenced by kubernetes to install octavia pre-queens in the docs.  For queens
and later, the deploy docs for support will be updated.  I'm keeping the same kaas directory structure under
kaas-migration to match the currentl kaas repo locations for those who are already familiar. 

* A copy of the kaas rpco quota fix playbook can be found [here](kaas-migration/rpc/rpc-o/playbooks/setup_octavia.yml).
* A copy of the kaas rpco deployment docs have been placed [here](kaas-migration/docs/internal/deployment/prepare-provider/rkaas-rpco/).

