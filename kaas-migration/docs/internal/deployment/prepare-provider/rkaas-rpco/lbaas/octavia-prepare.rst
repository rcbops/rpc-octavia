.. _octavia-prepare:

========================
Prepare your environment
========================

Before deploying octavia, prepare your RPCO environment by creating an
octavia provider network on each RPCO infrastructure node and configuring
it according to your requirements. This network ensures communication between
the RPCO infrastructure nodes and octavia amphorae.
The following diagram describes the RPCO octavia reference architecture.

.. image:: ./../../../../../figures/d_octavia_network_arch.png
   :width: 100%

To prepare your environment, follow these steps:

#. Verify that RPCO is operational by launching and destroying a few
   virtual machines.

#. Assign the octavia VLAN ID to the environment variable:

   .. code-block:: bash

      export VLAN_ID=111

   Octavia automatically configures the network. If the
   environment needs additional customization, modify the corresponding entries
   in ``/opt/rpc-octavia/playbooks/default/vars/main.yml``.

   .. note::
      If you modify the file mentioned above, update ``rpc-octavia``
      carefully because the values might be lost during the update.

#. Set up the OpenStack octavia container configuration in
   ``/etc/openstack_deploy/conf.d/octavia.yml.``

     **Example:**

   .. code-block:: yaml

      ---

      octavia-infra_hosts:
        infra1:
          ip: 10.0.236.100
          container_vars:
            lxc_container_vg_name: vmvg00
        infra2:
          ip: 10.0.236.101
          container_vars:
            lxc_container_vg_name: vmvg00
        infra3:
          ip: 10.0.236.102
          container_vars:
            lxc_container_vg_name: vmvg00

#. Verify volume groups, such as ``vmvg00``, by running ``vgscan`` on all
   RPCO infrastructure nodes:

   .. code-block:: bash

      vgscan

#. Verify IP addresses for each infrastructure node by running the
   following command:

   .. code-block:: bash

      ip a

.. _octavia-configure-osa:

Configure OpenStack-Ansible
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Configure OSA to deploy OpenStack octavia by adding
the (CIDR) values and reserving
``used_ips`` in the ``/etc/openstack_deploy/openstack_user_config.yml`` file.

To configure OSA, follow these steps:

#. Add the new bridge to ``/etc/openstack_deploy/openstack_user_config.yml``
   along with ``cidr_networks`` and ``used_ips``:

   **Example:**

   .. code-block:: yaml

      cidr_networks:
      lbaas: 172.29.248.0/22

      used_ips:
      - "172.29.248.1,172.29.248.50"
      - "172.29.248.100"

      global_overrides/provider-networks…

      - network:
          container_bridge: "br-lbaas"
          container_type: "veth"
          container_interface: "eth14"
          host_bind_override: "eth14"
          ip_from_q: "lbaas"
          type: "raw"
          net_name: "lbaas"
          group_binds:
              - neutron_linuxbridge_agent
              - octavia-worker
              - octavia-housekeeping
              - octavia-health-manager

#. Configure a new network in octavia by adding and adjusting the following
   values in ``/etc/openstack_deploy/user_osa_variables_overrides.yml``:

   .. list-table:: **octavia network parameters**
      :widths: 10 10
      :header-rows: 1

      * - Parameter
        - Description
      * - ``octavia_neutron_management_network_name``
        - The name of the octavia management network in Neutron.
          Example: ``lbaas-mgmt``.
      * - ``octavia_provider_network_name``
        - The name of the provider network in the system. Example: ``vlan``.
      * - ``octavia_provider_segmentation_id``
        - The provider network segmentation ID (VLAN). Example: ``111``.
      * - ``octavia_container_network_name``
        - The name used in ``openstack_user_config.yml`` with added
          ``_address``. Example: ``lbaas_address``.
      * - ``octavia_provider_network_type``
        - The type of octavia network provider. Example: ``vlan``.
      * - ``octavia_management_net_subnet_cidr``
        - The octavia network CIDR. Example: ``10.0.252.0/22``.
