.. _deploy-lbaas:

=======================================================
Deploy a Load Balancer as a Service (OpenStack octavia)
=======================================================

Rackspace Private Cloud Powered by OpenStack (RPCO) supports
OpenStack octavia, a Load Balancer as a Service program
that provides enhanced workload distribution across RPCO infrastructure
nodes, as well as simplifies the scalability and reliability of your cloud.
Therefore, a load balancer is an essential part of any efficient and high
performance cloud infrastructure. In the current implementation, octavia
is required for the Rackspace KaaS solution.

This section describes how to prepare your RPCO environment for
OpenStack octavia LBaaS installation,
how to configure and deploy octavia using OpenStack-Ansible (OSA),
and how to verify the installation.

.. note::
   These instructions describe how to deploy octavia on
   OpenStack Newton and specifically focus on the Rackpace
   KaaS product requirements. For instructions on
   how to deploy octavia on OpenStack Pike or later, see
   the `RPCO Installation Guide
   <https://pages.github.rackspace.com/rpc-internal/docs-rpc/rpc-install-internal/index.html#rpc-install-internal>`_.

For more information, see the
`OpenStack-Ansible Deployment Guide
<http://docs.openstack.org/project-deploy-guide/openstack-ansible/newton/>`_.

For more information about OpenStack octavia, see the `Octavia documentation
<https://docs.openstack.org/octavia/latest/reference/introduction.html>`_.

For the latest information about how the RPCO octavia LBaaS implementation
might differ from upstream, see the
`RPCO Release Notes <https://developer.rackspace.com/docs/private-cloud/rpc/v17/rpc-releasenotes>`__.

.. note::

   RPCO provides LBaaS as a technical preview, which should not be
   used for production workloads. For more information about LBaaS
   limitations and restrictions, see the RPCO Release Notes.

.. toctree::
   :maxdepth: 2

   lbaas/octavia-prepare.rst
   lbaas/octavia-install.rst
