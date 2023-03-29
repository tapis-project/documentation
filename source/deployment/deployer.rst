.. _deployer:

==============
Tapis Deployer
==============

.. note::

    This guide is for users wanting to deploy Tapis software in their own datacenter. Researchers who 
    simply want to make use of the Tapis APIs do not need to deploy any Tapis components and can ignore
    this guide.  


In this section, we cover using Tapis Deployer to generate Tapis deployment files. We cover how 
to get the Tapis deployer software, create configuration for your site using Ansible host_vars, 
and running the generate playbook. Then we describe using the control scripts (``burnup`` and ``burndown``)

Keep in mind that the process of using Deployer involves the following high-level steps:

1. Check out the Tapis Deployer repository 
2. Provide some configuration for your site
3. Run the generate script that will generate a set of "deployment files" that will be used to start and 
   manage the running Tapis services. These deployment files should be checked into a git repository so that 
   they can be versioned as the files are regenerated using newer versions of deployer. 
4. If necessary, check out the deployment files to the deployment 
   environment (for example, the machine that has access to the Kubernetes API).
5. Run deployment scripts to start/update the Tapis services. 

Steps 1, 2 and 3 can be performed on a separate machine from the deployment environment. Steps
4 and 5 must be performed on a machine that has access to the Kubernetes API and the ``kubectl``
program where the Tapis services will be deployed. 


--------------------
Installing Deployer
--------------------
The Tapis Deployer project is hosted on GitHub. Use the 
`tags <https://github.com/tapis-project/tapis-deployer/tags>`_ download page to download a 
specific version of the Deployer software. For example, to get version 1.3.1 of the Deployer
software, we could do the following in a terminal:

.. code-block:: console

  # download the tar archive
  wget https://github.com/tapis-project/tapis-deployer/archive/refs/tags/v1.3.1.tar.gz

  # unpack the directory
  tar -xf v1.3.1.tar.gz

  # produces a new directory, tapis-deployer-1.3.1, in the current working directory 
  ls -l tapis-deployer-1.3.1
  -rw-rw-r-- 1 jstubbs jstubbs 2340 Mar 22 10:13 CHANGELOG.md
  drwxrwxr-x 3 jstubbs jstubbs 4096 Mar 22 10:13 inventory_example
  drwxrwxr-x 3 jstubbs jstubbs 4096 Mar 22 10:13 playbooks
  -rw-rw-r-- 1 jstubbs jstubbs 2014 Mar 22 10:13 README.md

Deployer is based on the Ansible project, and Ansible must be installed as well. For 
Debian/Ubuntu bases distributions, we recommend using the Ansible apt package:

.. code-block:: bash

    apt-get install ansible

Refer to the official 
`Ansible documentation <https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html>`_ 
to get Ansible installed on your machine.  


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Tapis Service & Deployer Versions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
All Tapis software, including all API components, programming language SDKs and libraries, 
deployment jobs and utilities, are versioned using semantic versioning. Tapis Deployer 
itself is versioned using semantic versions, and each version of Deployer is built to work 
with a specific set of Tapis service versions. For this reason, Deployer releases occur 
regularly. 

.. warning::

  While it is technically possible to 
  change the versions of the Tapis components that a specific version of Deployer deploys,
  this should be avoided. Any specific version of Deployer was tested with a specific 
  set of Tapis software versions -- trying to change the versions could result in errors. 



----------------------
Configuring Your Site
----------------------

Deployer relies on a set of configuration files provided by you, the operator, to generate the 
deployment scripts for a given site. Configuring Deployer correctly can be challenging; to simplify 
the process, Deployer bundles a number of default configurations which are suitable for most 
but not all use cases. When planning a Tapis site deployment, be sure to review all required 
and optional configurations to ensure that your generated deployment scripts will be correct. 

There are two primary configuration files -- the Inventory file and the Host Vars file -- 
that must be provided to Tapis Deployer to generate the deployment scripts. Together 
with additional supporting files, such as the TLS certificate files for the site domain, these 
files are then used to deploy Tapis components to the Kubernetes cluster. 


~~~~~~~~~~~~~~
Inventory File
~~~~~~~~~~~~~~

The Tapis Deployer Inventory File is an Ansible inventory file specifying the main configuration 
file to use (called a "host vars" file) for each Tapis installation. Note that more than one
Tapis installation can be specified in the inventory file.
The inventory file also specifies the ``tapisflavor``
variable to use for each Tapis installation specified in the file. Currently, ``tapisflavor``
must be set to the value ``kube`` (for Kubernetes deployments), but a future version of
Deployer will support additional types of deployment targets.

Copy and past the following code snippet into a file and change the highlighted 
``<tapis_installation_name>`` to a name for your Tapis installation, such as "Tapis-test" or
"Tapis-prod". Also, you can name the file anything you like, but a suitable name would be  
``tapis_installations.yml``. 


.. code-block:: yaml
   :linenos:
   :emphasize-lines: 6

    tapis_installs:
      hosts:
       # Replace with a name for your Tapis installation; for example, "Tapis-dev", 
       # "Tapis-prod", etc. By default, Deployer uses this name for the directory 
       # where it writes its output files, though this can be changed.
        <tapis_installation_name>:
          ansible_connection: local
          tapisflavor: kube
       # Add additional installations here...


~~~~~~~~~~~~~~
Host Vars File
~~~~~~~~~~~~~~
Create a directory called ``host_vars`` in the same directory as the inventory file, and 
inside the ``host_vars`` directory, create a file with the same name as the
``<tapis_installation_name>`` used in the inventory file above. The file 
structure should look similar to the following, where we are using the name ``tapis-test.yml``
for the ``<tapis_installation_name>``:

.. code-block:: console

  tapis_installations.yml
  host_vars/
    * tapis-test.yml

The ``<tapis_installation_name>`` will hold all of the configuration, in the form of 
variables and values in YAML format, for that Tapis installation. Broadly, there are 
required fields that every site administrator must provide and there are optional fields 
that can be provided if the defaults set in Deployer are not appropriate. Required and 
optional fields depend, to some extent, on whether a primary or associate site is being 
deployed. 

Below we include the required fields for both primary and associate sites as well as 
a few of the simplest optional fields that can be configured. The Advanced Configuration
Options section goes into detail about additional advanced customizations that can be 
achieved. 

-----------------------------
Required Fields -- All Sites
-----------------------------

The following fields must be configured in the Host Vars file for all sites, including 
associate sites and primary sites. 

* ``global_tapis_domain`` -- Domain name for the site. Must be owned by the 
  institution, resolvable by DNS to a public IP address in the site’s datacenter. See the
  `Public IP Addresses, Domains and TLS Certificates <preliminaries.html#environments-and-capacity-planning>`_ 
  subsection of the Capacity Planning section for more details. Do not include "https://"
  at the beginning of the value. 

  Examples:

  .. code-block:: yaml
    
    global_tapis_domain: tapis.io
    
  .. code-block:: yaml 

    global_tapis_domain: develop.tapis.io

* ``site_type`` -- Whether the site is a primary site or an associate site. The value of 
  should be an integer: ``1`` for a primary site and ``2`` for an associate site.

  Examples:

  .. code-block:: yaml
    
    site_type: 1

* ``global_site_id`` -- The Tapis id for the site being deployed. 
  Notes: for 
  associate sites, the site id must be agreed to with the primary site prior to installation, 
  and the associate site record must be added to the primary site's site table. 

  Examples:

  .. code-block:: yaml

    global_site_id: tacc

  .. code-block:: yaml

    global_site_id: uh

* ``global_storage_class`` -- The storage class, in the Kubernetes cluster, that can be used 
  for creating persistent volumes. Options such as ``rbd`` (for Ceph-based storage), ``nfs``,
  ``cinder``, etc. may be appropriate. The value should be recognized on your Kubernetes cluster.  

  Examples:

  .. code-block:: yaml

    global_storage_class: rbd

* ``global_primary_site_admin_tenant_base_url`` -- The URL to the admin tenant for the 
  primary site associated with the site being deployed. If deploying a primary site, this 
  is likely to have the value ``https://admin.{{ global_tapis_domain }}``; however, for
  associate sites, the value will use a different domain.

  Examples:

  .. code-block:: yaml

    global_primary_site_admin_tenant_base_url: https://admin.tapis.io

* ``proxy_nginx_cert_file`` -- Path to the wildcard certificate file to be used for the site domain and all subdomains.
  Note that this path should be a valid path on the deployment machine, i.e., the machine where the Tapis 
  Deployer output files will be used to deploy the Tapis components to Kubernetes. Note also that this file 
  should contain the host certificate as well as the full CA chain.

  Examples:

  .. code-block:: yaml

    proxy_nginx_cert_file: $HOME/ssl/star.tapis.io.pem

* ``proxy_nginx_cert_key`` -- Path to the wildcard certificate key file to be used for the site domain and all subdomains.
  Note that, just as with ``proxy_nginx_cert_file``, this path should be a valid path on the deployment machine, 
  i.e., the machine where the Tapis 
  Deployer output files will be used to deploy the Tapis components to Kubernetes. 

  Examples:

  .. code-block:: yaml

    proxy_nginx_cert_key: $HOME/ssl/star.tapis.io.key


----------------------------
Optional Fields -- All Sites
----------------------------

The following fields can optionally be provided in the Host Vars file. 

* ``tapisdir`` -- The path on the local machine where Deployer will write the deployment script directory.

  Default Value: ``$HOME/.tapis/{{ inventory_name }}``

  Examples:

  .. code-block:: yaml

    tapisdir: /home/cic/deployments/tapis-test


------------------------------------------------
Generating the Tapis Deployment Script Directory
------------------------------------------------
Once the Tapis Deployer software and dependencies have been installed and the 
inventory and host vars files written, the Tapis deployment script directory can be generated. 
The deployment script directory contains the actual deployment scripts that will be used to 
deploy and manage Tapis components. Tapis Deployer will write the deployment scripts to the ``tapisdir`` 
path, which can optionally be set in the Host Vars file (see previous section).

Generate the Tapis deployment scripts directory using the following command: 

.. code-block:: console

    ansible-playbook -i /path/to/inventory_file.yml /path/to/deployer/playbooks/generate.yml

For example, given a project structure like the following, with the Tapis Deployer 
installation in the same directory as the inventory file and host vars directory:

.. code-block:: console

  tapis_installations.yml
  tapis-deployer-1.3.1/
    * CHANGELOG.md
    * playbooks/
    * inventory_example/
    * README.md
  host_vars/
    * <tapis_installation_name>

we can execute the following command from within the project root directory to generate 
the ``tapis-kube`` directory:

.. code-block:: console

    ansible-playbook -i tapis_installations.yml tapis-deployer-1.3.1/playbooks/generate.yml

.. note::

  When executing `ansible-playbook`, all Tapis installations defined in the inventory
  file will be generated. Use ``-l <tapis_installation_name>`` to only generate one installation. 
  

Generating the deployment script directory takes quite a bit of some time. If you just need to
generate (or regenerate) one directory within the deployment script directory, you can 
issue the following:

.. code-block:: console

    ansible-playbook -i /path/to/inventory_file.yml /path/to/deployer/playbooks/generate-single-component.yml -e comp=<component>

For example, with the same file structure as above, we could regenerate just the `workflows` directory using:

.. code-block:: console

  ansible-playbook -i tapis_installations.yml tapis-deployer-1.3.1/playbooks/generate-single-component.yml -e comp=workflows


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Additional Requirements for an Initial Associate Site Deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* Associate site record added to primary site table
* Associate site tenants created (in DRAFT mode) on primary tenants table  

----------------------------------
Using the Deployer Control Scripts
----------------------------------

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Bootstrapping an Initial Primary Site Deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Bootstrapping an Initial Associate Site Deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

----------------------------------
Advanced Configuration Options
----------------------------------

* Replacing the Vault with an "external" Vault
* Customizing routing in Tapis proxy 
* Configuring custom LDAP servers
* Adding custom (i.e., external) authenticators
