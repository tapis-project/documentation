.. _etl_creating_a_pipeline:

2. ETL Pipeline Creation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this section we create our ETL Pipeline. Once it's created, we will discuss each part of the ETL Pipeline
schema in detail.

.. note::

    This schema is built using data from resources that were created during the earlier sections of this User Guide.

2.1 Create the ETL Pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /specialized-services/etl/operations/createETLPipeline.rst

.. _etl_remote_outbox:

2.2 Remote Outbox
~~~~~~~~~~~~~~~~~~

The Remote Outbox is the ETL System Configuration that tells Tapis ETL where data files to be processed are staged. Any data files placed
on the Data System in the data directory (after applying the include and exclude pattern filters) are the files that will be processed
during runs of an ETL Job.

How many get processed and in what order is determined by the manifests generated for those data files.
Consider the schema below, specifically the Manifest Configuration.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline-remote-outbox.json.rst

This Manifest Configuration tells Tapis ETL that the user wants Tapis ETL to handle manifests generation.
According to the manifest ``generation policy`` of ``auto_one_per_file``, Tapis ETL will generate one manifest
for each data file that is not currently being tracked in another manifest.

.. warning:: 
    
    Using automatic manifest generation policies without specifying a data integrity profile can beak a pipeline.
    The preferred manifest generation policy for the Remote Inbox is ``manual``. Instructions for generating manifests
    will come in the following sections.
    For more info on other possible configurations, see the :ref:`Manifests Configuration <etl_manifests_configuration>` section

Tapis ETL will perform this operation for every untracked data file for every run of the pipeline. Whether this step
runs or not has no effect on the actual data processing phase of the pipeline run (the phase where the ETL Jobs are run).
If there are no data files to be tracked, Tapis ETL will simply move on to the next step; looking for an unprocessed manifest with a status of ``pending``
and submitting it for processing.

.. _etl_local_inbox:

2.3 Local Inbox
~~~~~~~~~~~~~~~~

Tapis ETL will transfer all of the data files from the Remote Outbox to the data directory of the Local Inbox for processing.

.. note::

    When configuring your Local Inbox, consider that your ETL Jobs should run on a system that has a shared file system with the Local Inbox.
    The data path in the Local Inboxes Data Configuration should be accessible to the first ETL Job.

Notice that this ETL System Configuration has an addition property, ``control``. This is simply a place that
Tapis ETL will write accounting files to ensure the pipeline runs as expected. It is recommended that you use the same
system as in Local Inbox's Manifest System, however any system to which Tapis ETL can write files to would work.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline-local-inbox.json.rst

.. _etl_jobs:

2.4 ETL Jobs
~~~~~~~~~~~~~

ETL Jobs are an ordered list Tapis Job definitions that are dispatched and run serially during a pipeline's transform phase. Tapis ETL
dispatches these Tapis Jobs and uses the data files in a manifest as the inputs for the job. Once all of the ETL Jobs complete, the tranform phase ends.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline-etl-jobs.json.rst

Every ETL Job is furnished with the following envrionment variables which can be accessed at runtime by your Tapis Job.
    * ``TAPIS_WORKFLOWS_TASK_ID`` - The ID of the Tapis Workflows task in the pipeline that is currently being executed
    * ``TAPIS_WORKFLOWS_PIPELINE_ID`` - The ID of the Tapis Workflows Pipeline that is currently running
    * ``TAPIS_WORKFLOWS_PIPELINE_RUN_UUID`` - A UUID given to this specific run of the pipeline
    * ``TAPIS_ETL_HOST_DATA_INPUT_DIR`` - The directory that contains the data files for inital ETL Jobs
    * ``TAPIS_ETL_HOST_DATA_OUTPUT_DIR`` - The directory to which output data files should be persisted
    * ``TAPIS_ETL_MANIFEST_FILENAME`` - The name of the file that contains the manifest
    * ``TAPIS_ETL_MANIFEST_PATH`` - The full path (including the filename) to the manifest file
    * ``TAPIS_ETL_MANIFEST_MIME_TYPE`` - The MIME type of the manifest file (always ``application/json``)

In addition to the envrionment variables, a `fileInput` for the manfiest file is added to the job definition to ensure that is available to the ETL Jobs runtime.
In your application code, you can use the envrionment variables above to locate the manifest file and inspect its contents.
This is useful if your application code does not know where to find its input data. The ``local_files`` array property of the manifest
contains the list of input data files. The files are represented as objects in the ``local_files`` array and take the following form.

.. include:: /specialized-services/etl/includes/schemas/file.json.rst

.. _etl_local_outbox:

2.5 Local Outbox
~~~~~~~~~~~~~~~~~~~

Once the Transform Phase ends, all of the output data files should be in the data directory of the Local Inbox.
These files are then tracked in manifests to be transferred in the Egress Phase of the pipeline.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline-local-outbox.json.rst

.. _etl_remote_inbox:

2.6 Remote Inbox
~~~~~~~~~~~~~~~~~

During the Egress Phase, all of the output data produced by the ETL Jobs is transferred from the Local Outbox to the Remote Inbox.
Once all of the data files from an Egress Manifest are successfully transferred over, Tapis ETL will then transfer that manifest to the
manifests directory of the Remote Inbox system to indicate that files transfers are complete.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline-remote-inbox.json.rst

.. note::
  
  Section 2 Punch List
    * Created an ETL Pipeline
    * Can fetch the pipeline's details from Tapis Workflows