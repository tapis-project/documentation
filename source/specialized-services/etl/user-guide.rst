.. _etl_user_guide:

User Guide
===============

This section shall serve as the primary technical reference for the creating and managing ETL Pipelines. 

Prerequisites
^^^^^^^^^^^^^

Data Center Storage and Compute Allocations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Your project may need a storage allocation on some storage resource (for example at TACC: Corral, Stockyard, or one of our
Cloud-based storage resources) to serve as the project's Local Inbox and Outbox. The size of the required allocation greatly 
depends on the size of the files that will be processed in the pipeline.

Your project may also need one or more allocations on a computing system (for example at TACC: such as Frontera, Stampede2,
Lonestar5, or one of cloud computing systems. The allocation will be used to run ETL Jobs.

ETL Systems Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^

In this section, we discuss the configuration options for both the Remote and Local ETL Systems for a pipeline.

Remote ETL Systems Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each pipeline must configure a Remote Outbox and a Remote Inbox. These are logical systems where data files that require processing 
are stored and output files from transforms are stored, respectively. Conceptually, the Remote Outbox and Inbox are storage resources
independent of any datacenter, but they must provide programmatic access.

The Remote Outbox and Inbox must be a Tapis System with one of the following types:
  * Linux
  * S3
  * Globus

A path on a Tapis System, including POSIX (SSH/SFTP) and Object storage (S3-compatible).

A Globus endpoint.

With Option 1, the Tapis Pipelines software will be able to utilize Tapis transfers to move data to/from the Remote Outbox and Inbox to any TACC resource. This is the recommended option.

With Option 2, the Tapis Pipelines software utilizes Globus Personal Connect to move data to/from the Remote Outbox and Inbox to the Local Outbox and Inbox. From there, Tapis transfers will be utilized, as needed.

Local ETL Systems Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Creating an ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^
In this section you will learn how to contruct and deploy an ETL Pipeline.
Below is an example defintion of an ETL Pipeline. We will go into detail about each of the properies and their purpose. 

.. include:: /specialized-services/etl/schemas/etl-detailed.json.rst

#. A user submits an ETL pipeline definition detailing their ETL systems as well as one or more ETL Jobs
#. The user can then set up a cron to run the pipeline at the desired interval or run it manually with an API call.
#. When new data files are added to the Remote Inbox, the user generates manifests in the Remote Outbox's 'manifests' directory. These manifests tell Tapis ETL which data file(s) should be used for a single batch computing job.
#. When the pipeline is run (by cron or manually via API call) it will discover any new manifests and transfer over to the Local Inbox's 'manifests' directory
#. Once all manifests are transfered, the pipeline will then transfer all of the data files listed in the manifest(s) from the Remote Outbox to the data directory of the Remote Inbox.
#. Once all remote data files have been transferred, the pipeline will then generate a 

.. _etl_manifests:

Manifests
^^^^^^^^^^^^^

Manifests are JSON files that track one or more files on an ETL system and their progress through the various ETL Phases.
These manifest files contain a single manifest object that conforms to the schema below.

.. include:: /schemas/manifest.json.rst

There are 4 different types of manifests in an ETL Pipeline:
  * **Ingress Manifests** - A user-generated manifests situated on the Remote Outbox that contains a collection of files that:
    * are all ready to be transferred from the Remote Outbox to the Local Inbox
    * are all to be staged as input to the first ETL Job to run in the **Transform** phase.
  * **Root Manifest** - A system-generated manifest situated on the Local Inbox whose sole purpose is to keep track of Ingress Manifests.
  * **Transform Manifests** - System-generated manifests that track the status of data files in the *transform* phase. These are essentially 1-to-1 copies of the Ingress Manifests only minor variations.
  * **Egress Manifests** - System-generated manifests that track the output files in the Local Outbox and their transfer status to the Remote Inbox

.. _etl_systems:

ETL Systems
^^^^^^^^^^^^^

.. _etl_remote_outbox:

Remote Outbox
^^^^^^^^^^^^^
The Remote Outbox is the system from which data is ingested 

.. _etl_remote_inbox:

Remote Inbox
^^^^^^^^^^^^

.. _etl_local_inbox:

Local Inbox
^^^^^^^^^^^^^

.. _etl_jobs:

Jobs
^^^^^^^^^^^^^

.. _etl_local_outbox:

Local Outbox
^^^^^^^^^^^^^