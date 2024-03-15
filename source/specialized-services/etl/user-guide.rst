.. _etl_user_guide:

User Guide
===============

This section shall serve as the primary technical reference and comprehensive step-by-step guide
for the seting up, creating, and managing ETL Pipelines with Tapis ETL.

.. include:: /specialized-services/etl/user-guide/section0-prerequisites.rst

----

.. include:: /specialized-services/etl/user-guide/section1-etlsystems.rst

----

.. _etl_creating_a_pipeline:

Creating an ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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