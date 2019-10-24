.. _octavia-install:

Install OpenStack octavia
~~~~~~~~~~~~~~~~~~~~~~~~~

After you complete all tasks in :ref:`octavia-prepare`
and :ref:`octavia-configure-osa`, you can install OpenStack octavia.
By default, the octavia deployment script places octavia containers
on the RPCO infrastructure nodes where all playbooks are stored in
the ``setup-hosts.yml`` file. We do not recommend changing this
configuration. However, if you have to deploy octavia on separate
nodes because of resource constraints, you need to configure
it accordingly.

To install OpenStack octavia follow these steps:

#. Log in to an RPCO infrastructure node.
#. Clone the ``rpc-octavia`` repository by running:

   .. code-block:: bash

      cd /opt && git clone https://github.com/rcbops/rpc-octavia.git

   *  If you install octavia on any nodes other than the RPCO
      infrastructure nodes, complete the following steps:

      #. Log in to the node from which you deploy the RPCO environment.

      #. Configure octavia to be deployed on separate nodes:

         .. code-block:: bash

           cd /opt/rpc-openstack/openstack-ansible/playbooks
           openstack-ansible --limit '*octavia*' setup-hosts.yml

      The command runs the following playbooks:

      - ``openstack-hosts-setup.yml``
      - ``security-hardening.yml``
      - ``lxc-hosts-setup.yml``
      - ``lxc-containers-create.yml``

#. Run the Octavia installation script:

   .. code-block:: bash

      cd /opt/rpc-octavia && ./scripts/deploy.sh

   The script downloads the octavia amphora image. If the script fails, see
   :ref:`octavia-install-manually`.

.. _octavia-verify-installation:

Verify the octavia installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Verify the octavia installation by creating a load balancer.
Follow these steps:

#. Log in to an RPCO infrastructure node.
#. Attach to the utility container:

   .. code-block:: bash

      lxc-attach -n <utility-container-name>

#. Source your environment file:

   .. code-block:: bash

      source <openrc.sh>

#. If your RPCO environment uses OpenStack Newton,
   install octavia CLI:

   .. code-block:: bash

      pip install --isolated python-octaviaclient

   .. note:: If you run OpenStack Pike or later, skip this step.

#. Create a load balancer:

   .. code-block:: bash

      openstack loadbalancer create --name test-lb --vip-network-id GATEWAY_NET

#. Run the following command to view the list of load balancers:

   .. code-block:: bash

      openstack loadbalancer list

#. Repeat the command above until the load balancer becomes **ACTIVE**.
#. Create a listener for HTTP traffic on port 80:

   .. code-block:: bash

      openstack loadbalancer listener create --name test-listener --protocol HTTP --protocol-port 80 test-lb

#. Verify that the listener operates correctly:

   .. code-block:: bash

      curl -s -o /dev/null -w "%{http_code}" http://$(openstack loadbalancer
      show test-lb -c vip_address -f value)

   This command must return a ``503`` response code.

.. _octavia-verify-network:

Verify the octavia provider network
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

OpenStack octavia uses restrictive security group settings on its virtual
machines list, as well as restrictive ``iptables`` settings on the container.
Therefore, at times, diagnosing network issues might be challenging.

To verify the octavia provider network is operational, try the following
options:

* Ping the octavia bridge (``br-lbaas``) from the octavia container. You
  should see the standard ping output.

* Ping the VLAN (``br-vlan``) from the octavia container. You should
  see the standard ping output.

* Ping the octavia container on a different RPCO infrastructure node. You
  should see ping timeout errors. Verify that ``arp -nif`` returns the MAC
  address of the container from the other RPCO infrastructure node.

* Verify the Neutron configuration:

  #. Verify the VLAN ID, network type, and other parameters by running:

     .. code-block:: bash

        openstack network show lbaas-mgmt

  #. Verify that the IP allocation pool does not overlap with the existing IP
     addresses:

     .. code-block:: bash

        openstack subnet show lbaas-mgmt-subnet

  #. Verify connectivity between the Neutron components on different
     infrastructure nodes:

     #. Attach to the ``neutron-agents`` container on one of the
        infrastructure node:

     .. code-block:: bash

        lxc-attach -n <neutron-agents-container>

     #. Display network namespaces:

        .. code-block:: bash

           ip netns list

        Remember the first DHCP server namespace name.

     #. View the list of IP addresses for the namespace:

       .. code-block:: bash

          ip netns exec <first dhcp namespace> ip addr

       Remember the IP address.

     #. Open a new bash window and connect to a neutron-agent container on a
        different infrastructure node.

     #. Find the corresponding DHCP server namespace:

        .. code-block:: bash

           ip netns list

     #. Run:

        .. code-block:: bash

           ip netns exec <first dhcp namespace> ping <ip from other dhcp serve>r

        You should see the standard ping output. If not, you may need to
        perform more advanced troubleshooting by using ``tcpdump``.

.. seealso::

   `tcpdump <https://www.tcpdump.org>`_

.. _octavia-install-manually:

Install the octavia image manually
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the octavia installation script fails to download the octavia image, you
can install the image manually by following these steps:

#. Download an octavia amphora image from the `Rackspace images repository
   <http://rpc-repo.rackspace.com//images/amphora/r14.3.0/>`_.

   This image is built nightly, tested, and uploaded after the test
   completion.

#. Switch to the OpenStack service tenant.
#. Ensure the OpenStack project ID (``OS_PROJECT_ID``) is set to the GUID
   from the service project. By default, the ``octavia`` user belongs to the
   service tenant.
#. Install the image by running the following script in the service tenant:

   .. code-block:: bash

      openstack image create --file <image-name> --disk-format qcow2 --tag
      octavia-amphora-image --private
