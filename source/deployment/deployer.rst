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


-----------------
Getting Deployer
-----------------


----------------------
Configuring Your Site
----------------------


---------------------------------------
Generating the ``tapis-kube`` Directory
---------------------------------------


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
