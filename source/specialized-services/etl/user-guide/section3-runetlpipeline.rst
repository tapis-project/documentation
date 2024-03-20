.. _etl_running_an_etl_pipeline:

3. Running an ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this section we will discuss running our ETL Pipeline using Tapis Workflows.


.. _etl_manifests:

Manifests
^^^^^^^^^^^^^

Manifests are JSON files that track one or more files on an ETL system and their progress through the various ETL Phases.
These manifest files contain a single manifest object that conforms to the schema below.

.. include:: /specialized-services/etl/includes/schemas/manifest.json.rst

There are 4 different types of manifests in an ETL Pipeline:
  * **Ingress Manifests** - A user-generated manifests situated on the Remote Outbox that contains a collection of files that:
    * are all ready to be transferred from the Remote Outbox to the Local Inbox
    * are all to be staged as input to the first ETL Job to run in the **Transform** phase.
  * **Root Manifest** - A system-generated manifest situated on the Local Inbox whose sole purpose is to keep track of Ingress Manifests.
  * **Transform Manifests** - System-generated manifests that track the status of data files in the *transform* phase. These are essentially 1-to-1 copies of the Ingress Manifests only minor variations.
  * **Egress Manifests** - System-generated manifests that track the output files in the Local Outbox and their transfer status to the Remote Inbox
