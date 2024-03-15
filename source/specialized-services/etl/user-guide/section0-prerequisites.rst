.. _etl_prerequisites:

0. Prerequisites
^^^^^^^^^^^^^^^^

If you have already satisfied the prerequisites, you can skip to the :ref:`ETL Systems Configuration<etl_systems>` section.

0.1 Data Center Storage and Compute Allocations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Your project may need a storage allocation on some storage resource (for example at TACC: Corral, Stockyard, or one of our
Cloud-based storage resources) to serve as the project's Local Inbox and Outbox. The size of the required allocation greatly 
depends on the size of the files that will be processed in the pipeline.

Your project may also need one or more allocations on a compute system (for example at TACC: such as Frontera, Stampede2,
Lonestar5, or one of cloud computing systems. ETL Jobs run by Tapis ETL will use the allocations specified in the ETL Job definitions.

0.2 Users and Allocations
~~~~~~~~~~~~~~~~~~~~~~~~~~

When Tapis ETL runs an ETL Job, it does so **as the owner** of the ETL Pipeline. This Tapis user must be
mapped to a valid user with a valid allocation on the underlying compute system or the Transform Phase of
the ETL Pipeline will always fail.

.. note::
  
  Punch List
    * Valid allocation for your project on the compute and storage resources
    * Valid user with a valid allocation on the compute resources


0.3 Tapis Workflows Group
~~~~~~~~~~~~~~~~~~~~~~~~~~

Tapis ETL uses Tapis Workflows' Groups to manage access (creating, deleting, running) ETL Pipelines. If you do not
own or belong to a group, create it following the instructions below.

.. include:: /technical/workflows/operations/createGroup.rst

.. note::
  
  Section 0 Punch List
    * Valid allocation for your project on the compute and storage resources
    * Valid user with a valid allocation on the compute resources
    * Create or belong to a valid Tapis Workflows :ref:`Group <groups>`