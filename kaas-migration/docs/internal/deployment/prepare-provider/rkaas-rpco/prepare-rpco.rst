. _prepare-rpco:

================================
Prepare the OpenStack components
================================

Before deploying a Kubernetes cluster, complete
all tasks in this section.

.. _rpco-envs:

Environments
~~~~~~~~~~~~

If you need to create a new cloud environment, see
:ref:`create-env`.

.. _rpco-requirements:

Requirements
~~~~~~~~~~~~

Before you can deploy Rackspace KaaS, verify
that you have installed and configured all components described in
:ref:`rkaas-rpco-rpcr-predeployment`.

* This list provides the links to the installation instructions
  for the major components:

  * OpenStack DNS service (designate)
     ``kaasctl`` creates DNS records during the installation.
     Designate is required to create an isolated DNS zone for Kubernetes.
     For more information, see
     `Designate Installation Guide <https://pages.github.rackspace.com/rpc-internal/docs-rpc-designate/internal/installing/index.html#designate-ig>`_.

     * For deployments on OpenStack Newton, follow the instructions described
       in the `Designate documentation
       <https://github.com/rcbops/rpc-designate/blob/master/INSTALLATION.md>`__.
       Deployments on OpenStack Queens or later have designate installed
       as part of the OpenStack deployment.

  * OpenStack Load Balancing service (octavia)
     Octavia enables Kubernetes workload distribution across Kubernetes master
     nodes for optimal use of resources and increased service reliability.

    * For deployments on OpenStack Newton, follow the instructions described
      in :ref:`deploy-lbaas`. Deployments on OpenStack Queens or later
      have octavia installed as part of the OpenStack deployment.

    * If installing OpenStack octavia in a Newton All-In-One (AIO) environment,
      follow instructions in `Set up an AIO
      <https://github.com/rcbops/rpc-octavia#setup-an-aio>`__.

  * Ceph storage cluster
     Ceph provides persistent block storage for Kubernetes users, as well as
     for Kubernetes Managed Services internal data.
     For more information, see
     `Deploy a Ceph storage cluster <https://pages.github.rackspace.com/rpc-internal/docs-rpc/rpc-ceph-internal/ops/deployments/index.html>`_.

.. _configure-client-machine:

Configure your client machine
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before you can deploy a Kubernetes cluster, configure your client
machine to work with Kubernetes. You must have the
following things in place on your client machine (Mac OSX or Ubuntu):

.. note::
   When you are deploying KaaS on an RPCO infrastructure node,
   Docker creates a ``172.17.0.1/16`` bridge by default.
   You can customize this network if it is already being used on the host by
   following `these instructions <https://docs.docker.com/v17.09/engine/userguide/networking/default_network/custom-docker0>`__
   in the Docker documentation.

* `Docker Community Edition <https://www.docker.com/community-edition>`__
* `kubectl <https://kubernetes.io/docs/tasks/tools/install-kubectl/>`__
* Access to the Kubernetes
  `mk8s repository <https://github.com/rackerlabs/kaas>`__.
