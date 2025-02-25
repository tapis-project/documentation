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
specific version of the Deployer software. For example, to get version 1.3.5 of the Deployer
software, we could do the following in a terminal:

.. code-block:: console

  # download the tar archive
  wget https://github.com/tapis-project/tapis-deployer/archive/refs/tags/tapis-deployer-1.3.1.tar.gz

  # unpack the directory
  tar -xf tapis-deployer-1.3.1.tar.gz

  # produces a new directory, tapis-deployer-1.3.5, in the current working directory 
  ls -l tapis-deployer-1.3.5
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
       # Replace with a name for your Tapis installation; for example, "tapis-dev", 
       # "tapis-prod", etc. By default, Deployer uses this name for the directory 
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

  .. code-block:: yaml
    
    site_type: 2

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

* ``tapisdatadir`` -- The path on the local machine where Deployer & Tapis scripts will write important stateful data.

  Default Value: ``$HOME/.tapis-data/{{ inventory_name }}``

  Examples:

  .. code-block:: yaml

    tapisdirdata: /home/cic/deployments/tapis-test-data

* ``vault_raft_storage`` -- Whether to use Raft storage for Vault. 

  Default Value: ``true``

  Examples:

  .. code-block:: yaml

    vault_raft_storage: false    

.. warning:: 

  Using the *file* storage type for Vault is not considered viable for production environments. At 
  the same time, changing the storage type from *file* to *Raft* requires a manual migration.
  Attempting to change the Tapis Vault with a different storage type without performing the manual 
  migration could result in secret loss and permanent corruption of the Tapis installation.

* ``skadmin_sk_privileged_sa`` -- The name of a service account to use when deploying certain 
  Tapis components. If specified, this service account should have sufficient privileges to create 
  and manage various Kubernetes API objects, including: jobs, pods, PVCs, and secrets. If this variable
  is not set, then no value will be specified for the ``serviceAccountName`` attribute and Kubernetes
  will fall back to using the  ``default`` service account (in which case the default account must have
  sufficient privileges to create and manage the Tapis Kubernetes objects).

  Default Value: None (the value of ``default`` is supplied by Kuberentes).

  Examples:

  .. code-block:: yaml

    skadmin_sk_privileged_sa: tapis-manager    


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
the Tapis deployment script directory:

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


-------------------------------------
Deployment Script Directory Structure
-------------------------------------
The deployment script directory is structured as follows:

.. code-block:: console

  actors/   # the Actors component
    burnup 
    burndown
    # k8s .yml files for actors...

  admin/   # the admin component, not a Tapis service
    backup/
    # . . .
    verification/

  apps/   # the Apps component
    burnup
    burndown
    # k8s .yml files apps...

  # ... additional component directories ...

  burnup     # top-level burnup script
  burndown   # top-level burndown script

  # ... additional component directories ...

At the top level, there is a directory for every Tapis *component* that will be deployed. Note that most
components are Tapis services, such as Actors and Apps, but some components, such as ``admin``, ``skadmin``
and ``vault`` are not Tapis services but are instead components needed to make the deployment work.

Except for ``admin``, each component contains a ``burnup`` and ``burndown`` script, together with some yaml 
files for defining the Kuberentes objects. The ``burnup`` BASH script is a convenience utility for creating
the Kuberentes objects while the ``burndown`` script can be used to remove the objects. Similarly, 
there is a top-level ``burnup`` and ``burndown`` script to create/remove all the Tapis objects. The top-level 
scripts call the individual component ``burnup``and ``burndown`` scripts, respectively.  


----------------------------------
Using the Deployer Control Scripts
----------------------------------

As mentioned above, the deployment script directory contains bash scripts called ``burnup`` 
and ``burndown``, referred to as 
the Deployer control scripts. These scripts provided convenience functions for managing entire sets of 
Tapis components at once.  Deploying Tapis using the control scripts involves a three step process:

1. Initialize the Tapis Deployment
2. Deploy the Primary Tapis Services
3. Deploy the Secondary Tapis Services

We detail each step in the following subsections. 
We recommend proceeding in this order, ensuring that each step finishes to completion and verify that 
it works before moving onto the next step.



--------------------------------
Initialize the Tapis Deployment
--------------------------------

Start by creating the initial Kubernetes objects:

.. code-block:: console

  ./burnup init

You will see a lot of outputs written to the screen. Kubernetes is a declarative system, where API calls
are used to describe the *desired* state on the cluster and Kubernetes works to make the *actual* state 
converge to the desired state. In general there is no problem with re-running a control script step more 
than once, because we are simply re-declaring the desired state to be the same state we declared 
previously. As a result, you can see messages such as:

.. code-block:: console

  service/apps-api unchanged

This just means the command did not change anything about the desired state so Kuberentes made no update.

Also, it is quite normal to see Error messages indicating that some Kuberentes object was not found;
for example:

.. code-block:: console

  Error from server (NotFound): secrets "vault-keys" not found

This could mean that one Kuberentes object definition references another object definition that has yet
to finish creating. 

Finally, you may see related errors such as:

.. code-block:: console

  Error from server (AlreadyExists): secrets "vault-token" already exists


Before moving onto the next step, we should validate that the initial objects all completed. 
Using ``kubectl`` we should check the output of the following commands:


Check the services: 

.. code-block:: console

  kubectl get services
  NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    
  actors-admin                       ClusterIP   10.105.126.200   <none>        5000/TCP   
  actors-events                      ClusterIP   10.110.114.165   <none>        5000/TCP   
  actors-grafana                     ClusterIP   10.105.16.173    <none>        3000/TCP   
  actors-mes                         ClusterIP   10.96.160.55     <none>        5000/TCP   
  actors-metrics                     ClusterIP   10.99.139.105    <none>        5000/TCP                    
  actors-mongo                       NodePort    10.103.92.102    <none>        27017:32340/TCP             
  actors-nginx                       NodePort    10.111.143.102   <none>        80:31633/TCP                
  actors-prometheus                  ClusterIP   10.109.2.194     <none>        9090/TCP                    
  actors-rabbit                      NodePort    10.106.132.99    <none>        5672:31108/TCP               
  actors-rabbit-dash                 ClusterIP   10.105.199.16    <none>        15672/TCP                    
  actors-reg                         ClusterIP   10.107.149.161   <none>        5000/TCP                     
  apps-api                           NodePort    10.110.168.192   <none>        8080:32718/TCP               
  apps-api-debug                     NodePort    10.100.5.250     <none>        8000:30225/TCP               
  apps-pgadmin                       NodePort    10.102.221.245   <none>        80:31458/TCP                 
  apps-postgres                      ClusterIP   10.104.211.25    <none>        5432/TCP                     
  authenticator-api                  NodePort    10.97.35.247     <none>        5000:31167/TCP               
  authenticator-ldap                 ClusterIP   10.97.243.117    <none>        389/TCP                      
  authenticator-postgres             ClusterIP   10.107.198.0     <none>        5432/TCP                     
  chords-app                         NodePort    10.109.154.215   <none>        80:30156/TCP                 
  chords-influxdb2                   ClusterIP   10.100.107.154   <none>        8086/TCP,8083/TCP            
  chords-mysql                       ClusterIP   10.111.198.225   <none>        3306/TCP                     
  files-api                          NodePort    10.101.53.166    <none>        8080:31557/TCP               
  files-debug                        NodePort    10.107.253.44    <none>        8000:32367/TCP               
  files-postgres                     ClusterIP   10.107.1.254     <none>        5432/TCP                     
  files-rabbitmq                     ClusterIP   10.110.250.244   <none>        5672/TCP                     
  globus-proxy                       ClusterIP   10.96.141.179    <none>        5000/TCP                     
  jobs-api                           NodePort    10.110.93.52     <none>        8080:30577/TCP               
  jobs-api-debug                     NodePort    10.100.250.144   <none>        8000:30813/TCP               
  jobs-api-other                     NodePort    10.102.208.122   <none>        6157:30078/TCP               
  jobs-api-ssl                       NodePort    10.105.51.28     <none>        8443:32513/TCP               
  jobs-pgadmin                       NodePort    10.102.30.118    <none>        80:31786/TCP                 
  jobs-postgres                      ClusterIP   10.104.52.113    <none>        5432/TCP                     
  jobs-rabbitmq                      ClusterIP   10.105.69.98     <none>        5672/TCP,15672/TCP           
  jobs-rabbitmq-mgmt                 NodePort    10.101.83.72     <none>        15672:30985/TCP              
  monitoring-exporter                NodePort    10.104.19.250    <none>        8000:32311/TCP               
  monitoring-grafana                 NodePort    10.105.48.54     <none>        3000:32088/TCP               
  monitoring-prometheus              NodePort    10.101.27.134    <none>        9090:32204/TCP               
  notifications-api                  NodePort    10.111.161.227   <none>        8080:31399/TCP               
  notifications-pgadmin              NodePort    10.96.236.253    <none>        80:31703/TCP                 
  notifications-postgres             ClusterIP   10.99.47.18      <none>        5432/TCP                     
  notifications-rabbitmq             ClusterIP   10.107.233.223   <none>        5672/TCP,15672/TCP           
  notifications-rabbitmq-mgmt        NodePort    10.104.109.239   <none>        15672:32511/TCP              
  pgrest-api                         NodePort    10.107.91.195    <none>        5000:30084/TCP               
  pgrest-postgres                    ClusterIP   10.101.255.95    <none>        5432/TCP                     
  pgrest-postgres-nodeport           NodePort    10.103.193.222   <none>        5432:30525/TCP               
  pods-api                           ClusterIP   10.106.237.143   <none>        8000/TCP                     
  pods-postgres                      NodePort    10.100.171.106   <none>        5432:31128/TCP               
  pods-rabbitmq                      ClusterIP   10.111.198.30    <none>        5672/TCP                     
  pods-rabbitmq-dash                 NodePort    10.111.90.160    <none>        15672:30061/TCP              
  pods-traefik                       ClusterIP   10.111.26.233    <none>        80/TCP                       
  pods-traefik-dash                  NodePort    10.105.118.198   <none>        8080:30146/TCP               
  registry                           NodePort    10.97.98.114     <none>        5000:31275/TCP               
  restheart                          ClusterIP   10.107.197.65    <none>        8080/TCP                    
  restheart-debug                    NodePort    10.103.14.131    <none>        8080:32023/TCP               
  restheart-mongo                    NodePort    10.109.224.10    <none>        27017:31792/TCP              
  restheart-security                 NodePort    10.105.16.196    <none>        8080:30792/TCP               
  site-router-api                    NodePort    10.102.33.197    <none>        8000:30063/TCP               
  sk-api                             NodePort    10.107.235.138   <none>        8080:31645/TCP               
  sk-api-debug                       NodePort    10.106.88.188    <none>        8000:31797/TCP               
  sk-api-other                       NodePort    10.105.105.97    <none>        6157:31086/TCP               
  sk-api-ssl                         NodePort    10.99.148.218    <none>        8443:30128/TCP               
  sk-pgadmin                         NodePort    10.101.207.66    <none>        80:30046/TCP                 
  sk-postgres                        ClusterIP   10.96.73.92      <none>        5432/TCP                     
  streams-api                        NodePort    10.98.10.161     <none>        5000:30552/TCP               
  systems-api                        NodePort    10.108.23.253    <none>        8080:32072/TCP               
  systems-api-debug                  NodePort    10.97.231.157    <none>        8000:31973/TCP               
  systems-pgadmin                    NodePort    10.108.234.139   <none>        80:30892/TCP                 
  systems-postgres                   ClusterIP   10.101.21.137    <none>        5432/TCP                     
  tapis-nginx                        NodePort    10.107.224.176   <none>        80:30175/TCP,443:31864/TCP   
  tapisui-service                    NodePort    10.107.80.97     <none>        3000:31766/TCP               
  tenants-api                        NodePort    10.109.125.21    <none>        5000:31327/TCP               
  tenants-postgres                   ClusterIP   10.102.182.23    <none>        5432/TCP                     
  tokens-api                         NodePort    10.110.229.6     <none>        5000:32706/TCP               
  vault                              ClusterIP   10.101.97.112    <none>        8200/TCP                     

**Note:** The number of services will depend on the site type being deployed. 

Check the PVCs:

.. code-block:: console

  kubectl get pvc
  NAME                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  actors-mongo-backup-vol01      Bound    pvc-fbb44e18-0256-4d0b-b799-a703b0f477b6   10Gi       RWO            rbd-new        8h
  actors-mongo-vol01             Bound    pvc-d3c224eb-5930-4700-8b8a-5f1ae0f2a921   40Gi       RWO            rbd-new        8h
  actors-rabbitmq-vol01          Bound    pvc-20dc6e04-e2bb-48b6-8647-ee28081eb0c3   20Gi       RWO            rbd-new        6h19m
  apps-postgres-vol01            Bound    pvc-f1320b94-6069-41d3-a26a-91a3ebaaed21   20Gi       RWO            rbd-new        8h
  authenticator-ldap-vol01       Bound    pvc-05ae6dbb-e46d-4383-af6b-f1d2726d6529   10Gi       RWO            rbd-new        4d4h
  authenticator-postgres-vol01   Bound    pvc-4fa4b8b4-dd31-42f6-afcf-d3fe41eeb723   20Gi       RWO            rbd-new        4d4h
  files-pgdata                   Bound    pvc-8c9b4e7b-feee-4823-96e2-ebe5631cd4ca   10Gi       RWO            rbd-new        8h
  files-rabbitmq-data            Bound    pvc-0f060f7b-53a7-41e5-ae4a-4dcbdcf47eb1   10Gi       RWO            rbd-new        8h
  jobs-postgres-vol01            Bound    pvc-62f74888-028c-4e5f-99c4-a3dd1f16881c   20Gi       RWO            rbd-new        8h
  jobs-rabbitmq-vol01            Bound    pvc-08f6c91c-8797-4515-b6c7-28fb839fc1c2   10Gi       RWO            rbd-new        8h
  notifications-postgres-vol01   Bound    pvc-d1a662de-60fc-4ead-a8c2-a84e4d302b2e   20Gi       RWO            rbd-new        8h
  notifications-rabbitmq-vol01   Bound    pvc-e96e2d73-fe46-4e53-831e-48342715ae72   10Gi       RWO            rbd-new        8h
  site-router-redis-vol01        Bound    pvc-dab2fdc8-d8e1-461a-902b-7f76026a278a   20Gi       RWO            rbd-new        4d4h
  sk-postgres-vol01              Bound    pvc-e304ca96-143a-41e6-901f-b61d14590972   20Gi       RWO            rbd-new        4d4h
  systems-postgres-vol01         Bound    pvc-14e58e3b-876e-4598-b9c2-a31447d3b530   20Gi       RWO            rbd-new        8h
  tenants-postgres-vol01         Bound    pvc-65b83d4e-24a4-42cb-ae9f-5fce41109d4a   20Gi       RWO            rbd-new        4d4h
  vault-vol01                    Bound    pvc-f39851c4-e140-4634-a4e4-441a5b143fd6   10Gi       RWO            rbd-new        4d4h

**Note:** The number of PVCs will depend on the site type being deployed. 

Check the jobs:

.. code-block:: console
  
  kubectl get jobs
  NAME              COMPLETIONS   DURATION   AGE
  renew-sk-secret   1/1           4s         30m
  sk-admin-init     1/1           19s        30m
  sk-presetup       1/1           3s         30m


Check the pods:

.. code-block:: console

  kubectl get pods

  NAME                              READY   STATUS             RESTARTS   AGE
  renew-sk-secret-zz8lm             0/1     Completed          0          2m33s
  site-router-api-784ddbbcc-c456m   1/2     CrashLoopBackOff   4          2m46s
  sk-admin-init-gpnnq               0/1     Completed          0          2m29s
  sk-presetup-nk8ht                 0/1     Completed          0          2m32s
  tapis-nginx-55d47656f8-tvhfk      1/1     Running            0          2m48s
  vault-67b44ff777-vwphn            1/1     Running            0          2m45s

It is expected that the site-router will be in CrashLoopBackOff state; this will automatically 
resolve once the primary services are deployed in the next step. 

.. warning::

  Quickly check that the initialization step compelted and move onto the next step. 
  You have about 10 minutes to deploy the primary services (the topic of the next section)
  after the initialization. This is because a short-lived token for the Vault database is 
  generated in this step and used in the next step. 

----------------------------------
Deploy the Primary Tapis services
----------------------------------

Next, deploy the primary Tapis services:

.. code-block:: console

  ./burnup primary_services

Similarly to the messages discussed in the Tapis initialization section, it is quite normal to 
see some messages like

.. code-block:: console

  error: timed out waiting for the condition on jobs/authenticator-migrations

Condition timeouts can happen when it is taking longer for Kubernetes to complete the deloyment of 
dependent objects, but these should resolve in due time. It is also quite normal to see sets of 
pods where the first several are in ``Error`` state while the last one ``Completed``, 
for example:

.. code-block:: console

  notifications-init-db-25dk8                 0/1     Error              0          109s
  notifications-init-db-gq4lt                 0/1     Completed          0          97s
  notifications-init-db-zqhvt                 0/1     Error              0          107s

The errors above are normal and could be caused for different reasons, but all of them amount to essentially 
the same thing: one or more of the Kubernetes objects that the pod depends on where not ready when the pod
was launched, do the pod crashed, hence the ``Error`` final state. Kubernetes continued to start a new 
instance of the pod until it finally reached the ``Completed`` state when all of the dependent objects where
ready.

It could could several minutes (10 or 20 even) for the deployment to converge. Check that eventually 
there are no pods in CrashLoopBackOff using:

.. code-block:: console

  kubectl get pods


Then, check that a few critical services are healthy using the verification scripts:

.. code-block:: console

  cd admin/verification

Check that the Security Kernel is health (your output should be simialr that below):

.. code-block:: console

  ./sk-test
  hello
  {"result":"Hello from the Tapis Security Kernel.","status":"success","message":"TAPIS_FOUND hello found: 0 items","version":"1.3.0","commit":"ee1b3342","build":"2023-03-01T15:42:55Z","metadata":null}
  ready
  {"result":{"checkNum":1,"databaseAccess":true,"vaultAccess":true,"tenantsAccess":true},"status":"success","message":"TAPIS_READY Readiness check received by Security Kernel.","version":"1.3.0","commit":"ee1b3342","build":"2023-03-01T15:42:55Z","metadata":null}
  healthcheck
  {"result":{"checkNum":1,"databaseAccess":true,"vaultAccess":true,"tenantsAccess":true},"status":"success","message":"TAPIS_HEALTHY Health check received by Security Kernel.","version":"1.3.0","commit":"ee1b3342","build":"2023-03-01T15:42:55Z","metadata":null}


Check that the Tenants service is healthy:

.. code-block:: console

  ./tenants-test 
  {
    "message": "Tenants retrieved successfully.",
    "metadata": {},
    "result": [
      {
        "admin_user": "admin",
        "authenticator": "https://admin.test.tapis.io/v3/oauth2",
  . . .

Check that the Tokens service is healthy:

.. code-block:: console

  ./tokens-test 
  {"message":"Token generation successful.","metadata":{},"result":{"access_token" . . .
  . . .

Check that the Authenticator service is healthy:

.. code-block:: console

  ./authenticator-test
  {"message":"Token created successfully.","metadata":{},"result":{"access_token": . . .
  . . .




------------------------------------
Deploy the Secondary Tapis Services
------------------------------------

Finally, deploy the secondary Tapis services:

.. code-block:: console

  ./burnup secondary_services


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Bootstrapping an Initial Primary Site Deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Bootstrapping an Initial Associate Site Deployment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

------------------------------
Configuring Support for GLOBUS
------------------------------

Inlcuding support for GLOBUS is optional.

In order for a primary or associate site to support Tapis systems of type GLOBUS, a Globus project must be
created and registered. This yields a Globus client ID that must be configured as part of the Tapis environment.
For more information on creating a Globus project, please see the
`Globus Auth Developer Guide <https://docs.globus.org/api/auth/developer-guide>`_.
Each Tapis installation can be configured with it's own Globus client ID.

The resulting client ID must be set in the host_vars file using the field ``systems_globus_client_id``.
This field is referenced as part of the deployment for the Systems and Files services. This is done by adding lines
similar to the following to the host_vars file:

  .. code-block:: yaml

    # Globus client ID for systems and files
    systems_globus_client_id: 868c331e-ab77-4321-bd12-9c85cb0f12aa

To use Globus, an end-user will create a system in Tapis and follow an authentication flow to
register credentials for the system. The Tapis client application uses the Globus OAuth2 Native App
flow to obtain the initial access and refresh tokens for the end-user. Globus’s support for the PKCE
protocol is used to perform a three-legged OAuth2 authorization code grant.

For more information, please see Systems
`Support For Globus <https://tapis.readthedocs.io/en/latest/technical/systems.html#support-for-globus>`_.

---------------------------
Configuring Support for TMS
---------------------------

Inlcuding support for the Trusted Manager System (TMS) is optional.


In order for a primary or associate site to support TMS, the deployment file for the Systems service must be
updated to set the following 5 enviornment variables.

  .. code-block:: yaml

          - name: TAPIS_TMS_ENABLED
            value: "True"
          - name: TAPIS_TMS_SERVER_URL
            value: https://localhost:3000
          - name: TAPIS_TMS_TENANT
            value: default
          - name: TAPIS_TMS_CLIENT_ID
            value: tapis
          - name: TAPIS_TMS_CLIENT_SECRET
            value: ********************


Each Tapis installation can be configured with it's TMS settings.
The service must be restarted after updating the deployment file.

For more information, please see Systems
`Support For TMS <https://tapis.readthedocs.io/en/latest/technical/systems.html#support-for-tms>`_.


-------------------------------------------
Configuring Support for Email Notifications
-------------------------------------------

Including support for notifications by EMAIL is optional.

In order for the Tapis Notifications service to support delivery of notifications by EMAIL, the service deployment
files must be updated to include parameters for an SMTP relay. Parameters for the relay are set as environment variables
to be picked up by the dispatcher service when it is started during a deployment.
Each Tapis installation can be configured with it's own SMTP relay.

For more information on Notifications EMAIL support and a full list of relevant environment variables, please see 
`Notification Delivery <https://tapis.readthedocs.io/en/latest/technical/notifications.html#notification-delivery>`_.

Site specific values must be set in the host_vars file. Values for environment variables ``TAPIS_MAIL_PROVIDER``,
``TAPIS_SMTP_HOST`` must be set. Typically a value for ``TAPIS_SMTP_PORT`` is also included.
These fields are referenced as part of the deployment for the Notifications service. This is done by adding lines
similar to the following to the host_vars file:

  .. code-block:: yaml

    # notifications
    notifications_mail_provider: SMTP
    notifications_mail_host: relay.example.com
    notifications_mail_port: 25
  

----------------------------------
Advanced Configuration Options
----------------------------------

* Replacing the Vault with an "external" Vault
* Customizing routing in Tapis proxy 
* Configuring custom LDAP servers
* Adding custom (i.e., external) authenticators
