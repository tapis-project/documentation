.. _etl_overview:

Overview
========

Introduction
^^^^^^^^^^^^

An ETL pipeline (Extract, Trasform, Load) is a workflow pattern commonly used in scientific computing
wherein data is extracted from one or more sources, transformed by some set of processes, and output data
produced by those processes are archived to some final destination.

Tapis ETL is a framework built on top of Tapis Workflows that enables users to create fully automated and parallel ETL Pipelines in the Tapis ecosystem.
Once a pipeline is configured, simply drop off data and manifest files on the source system. Tapis ETL will
run the HPC jobs according to the manifests and archive the results to the configured destination system.
For an example of how to get started, jump to the :ref:`quickstart <etl_quickstart>` section.

Glossary
^^^^^^^^^^^

Here we introduce the Tapis ETL standard terminology for ETL pipelines

.. note::
  **Local** denotes any resource (systems, files, etc) situated at TACC.
  **Remote** denotes any resource (systems, files, etc) **NOT** situated at TACC.
  
* :ref:`Manifests <etl_manifests>` - Files that track the progress of one or more data files through the various phases of an ETL Pipeline. They are responsible for managing and mantaining the state between pipeline runs.
* :ref:`Remote Outbox <etl_remote_outbox>` - The source system that contains the data files you want to process. This system is commonly a Globus endpoint or S3 bucket.
* :ref:`Local Inbox <etl_local_inbox>` - The system where data is processed
* :ref:`ETL Jobs <etl_jobs>` - Batch computing jobs that will be run sequentially on HPC/HTC systems against the data files in a manifest. 
* :ref:`Local Outbox <etl_local_outbox>` - The system where the output will be staged for transfer to the destination system
* :ref:`Remote Inbox <etl_remote_inbox>` - The destination system where output data will be archived
* **ETL System Configuration** - A collection of systems responsible for storage of data and manifest files. It is the general term for remote and local inboxes and outboxes.
* **Data System** - Component system of an ETL System Configuration responsible for the storage of data.
* **Manifests System** - Component system of an ETL System Configuration responsible for the storage of manifests.
* **Phase** - A distinct stage of a single Tapis ETL Pipeline run: ``ingress``, ``transform``, ``egress``
* **Resubmission** - Rerunning a specific phase or phases of an ETL pipeline for a given manifest.
* **Pipeline Run** - A single run of an ETL pipeline

How it works
^^^^^^^^^^^^^^^^^^^^^^^^

.. image:: ./images/tapis-pipelines.webp
  :alt: Tapis ETL diagram

Step 0 must be completed by a user or other external workflow asynchronous Tapis ETL.
  0. Data files to be processed are placed in the data directory of the configured Remote Outbox. A manifest is generated for those files (by a user or a script) and placed in the Remote Outbox's manifest directory

Steps 1-4 are managed by Tapis ETL:
  1. Tapis ETL then checks the Remote Outbox manifests directory for new manifests and transfers them to the manifests directory of the Local Inbox. The files enumerated in the new manifests on the Local Inbox are then transferred over to the data directory of the Local Inbox
  2. A single unprocessed manifest is chosen by the ETL Pipeline (according to the manifest priority) and the files therein are then staged as inputs to the first batch computing jobs. Each batch computing job definied in the ETL Pipeline definition will then be submitted to the Tapis Jobs API; the first of which processes the data files in the manifest.
  3. After all jobs run to completion, a manifest is generated for each of the output files found in the data directory of the Local Outbox.
  4. All data files enumerated in that manifest are then transferred to the data directory of the Remote Inbox.

.. _etl_phases:

Phases
^^^^^^^^

Tapis ETL Pipelines run in 3 seperate phases. The Ingress, Transform, and Egress Phases.
  1. **Ingress Phase** - Tapis ETL inspects the Remote Outbox for new data files and transfers them over to the Local Inbox. 
  2. **Transform Phase** - A single data file or batch of data files is processed by a series of user-defined ETL Jobs
  3. **Egress Phase** - The output data files from the ETL Jobs are tracked and transferred from the Local Outbox to the Remote Inbox