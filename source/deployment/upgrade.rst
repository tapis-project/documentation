.. _upgrade:

===============
Upgrading Tapis
===============

.. note::

    This guide is for users wanting to deploy Tapis software in their own datacenter. Researchers who 
    simply want to make use of the Tapis APIs do not need to deploy any Tapis components and can ignore
    this guide.  


In this section, we cover the process of upgrading an existing Tapis installation. In general,
the process of upgrading a Tapis installation involves all of the same steps described in the `Tapis
Deployer <deployer.html>`_ section, but a careful comparison of the new version of the 
generated Tapis deployment script directory against the previous version must be done to 
verify that the changes will work in your environment. At a high level, the process is:

1. Check out the updated version of Tapis Deployer from the repository.
2. Check the Deployer CHANGELOG to compare the current version deployed in your site against the
   newer version. Breaking changes are identified explicitly as are newly required configuration
   variables. 
3. Run the generate script to generate an updated version of the deployment script directory and
   compare the difference between this version and the currently deployed version of the deployment 
   script directory. Note and review any differences.
5. Use the deployment control scripts to start/update the newer versions of the Tapis services in 
   your pre-production environment first. Perform QA in the pre-production environment.
6. Deploy to production. 



Breaking Deployment Changes
---------------------------
In this section, we call out some specific types of breaking changes to be aware of. This section does not 
discuss breaking code changes within the Tapis services themselves, but rather changes within a deployment 
configuration that could break an existing installation. Also, this list is not meant to 
be a comprehensive -- operators should always review the entire list of changes in the Deployer and 
Tapis CHANGLOGs. 


Vault Storage Type
~~~~~~~~~~~~~~~~~~
There are two possible storage types for the Vault database -- *file* and *Raft*. Early versions of 
Deployer defaulted to using "file" storage for Vault, however, this option proved to be suboptimal 
for different reasons (e.g., less amenable to automated backups). Newer versions of Deployer use 
the *Raft* storage type, and we recommend existing deployments that are using *file* to change to 
*Raft*. However, changing from *file* to *Raft* requires a special, manual process to be performed.
We outline the steps involved in the `Tapis Vault <vault.html>`_ section.

The Tapis Deployer variable to look for is ``vault_raft_storage``, a boolean, with default value `true`.
If you need to use the *file* storage type, be sure to override the default in your host vars.

.. warning::

    Attempting to deploy the Tapis Vault with a different storage type could result in secret loss
    and permanent corruption of the Tapis installation.

PVC Names
~~~~~~~~~
Tapis uses Persistent Volument Claims (PVCs) to persist data stored in data bases and message brokers. 
Each Tapis service has a set of these PVCs that it uses. You can see the set of PVCs in your deployment 
by using ``kubectl``:

.. code-block:: console

    kubectl get pvc

    NAME                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    actors-mongo-backup-vol01      Bound    pvc-fbb44e18-0256-4d0b-b799-a703b0f477b6   10Gi       RWO            rbd-new        2d1h
    actors-mongo-vol01             Bound    pvc-d3c224eb-5930-4700-8b8a-5f1ae0f2a921   40Gi       RWO            rbd-new        2d1h
    actors-rabbitmq-vol01          Bound    pvc-20dc6e04-e2bb-48b6-8647-ee28081eb0c3   20Gi       RWO            rbd-new        47h
    apps-postgres-vol01            Bound    pvc-f1320b94-6069-41d3-a26a-91a3ebaaed21   20Gi       RWO            rbd-new        2d1h
    authenticator-ldap-vol01       Bound    pvc-05ae6dbb-e46d-4383-af6b-f1d2726d6529   10Gi       RWO            rbd-new        5d21h
    . . . 

The output above shows the name of each PVC in the first column, e.g., ``actors-mongo-backup-vol01``, 
``apps-postgres-vol01``, ``authenticator-ldap-vol01``, etc. It is very important to check that the 
names of the PVCs specified within the deployment script directory match those within your cluster. 

.. warning::

    Deploying Tapis services with different PVC names could result in data loss. 

