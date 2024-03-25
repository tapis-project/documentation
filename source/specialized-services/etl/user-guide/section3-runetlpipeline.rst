.. _etl_running_an_etl_pipeline:

3. Running an ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this section we will make our final preperations and perform our first pipeline run. This ETL Pipeline is 
configured to run HPC jobs that perform sentiment analysis on our data files. It is safe to trigger multiple pipeline
runs with Tapis ETL. Tapis ETL has a system for locking down ETL resources (such as manifests) to prevent race conditions for data files.
In other words, multiple pipelines can be running in parallel, all of which can be guaranteed to be processing entirely
different data files.

3.1 Staging data files to the Remote Outbox 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before running an ETL Pipeline, you must first ensure that there are data files in the data directory of the Remote Outbox.
Running a pipeline before there is any data staged to it would result in a "no-op" for each of the 3 phases of the ETL pipeline.

.. include:: /specialized-services/etl/operations/uploadDataFile.rst

3.2 Manifests
~~~~~~~~~~~~~~~~~~~~~~~~~

.. _etl_manifests:

**Manifests**

Manifests are JSON files that track one or more data files on a Data System as well as those data file's progress through the various ETL Pipeline Phases.
These manifest files contain a single manifest object that conforms to the schema below.

.. include:: /specialized-services/etl/includes/schemas/manifest.json.rst

3.3 Generating Manifests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For each data file or set of data files in the Remote Outbox that you want to run an ETL Job against, you will need to
generate a manifest for them. Each manifest in the Remote Inbox corresponds with a single Transform, or ETL Job.
Each data file in a single manifest will be used as input files for a single ETL Job.

There are two ways to generate manifest files. Manually and automatically. Automatic manifest generation is the simplest
manifest generation policy to use but the least flexible. With automatic manifest generation, you can use the ``auto_one_for_all`` policy and generate a manifest
for **all** untracked files in the data directory, or the ``auto_one_per_file`` and generate **one** manifest per file in the data directory.

For all situations in which you need to generate manifests for arbitrary files in the Remote Inbox, you must use the ``manual`` manifest generation policy


.. note::

    **Coming Soon** - Manual manifest generation 

If you are following the tutorial in the user guide, we previously configured our Remote Inbox to have a manifest generation policy of
``auto_one_per_file`` so Tapis ETL will generate the manifest for our ``data1.txt`` data file that we created in the previous step.

3.4 Run the Pipeline
~~~~~~~~~~~~~~~~~~~~~

Now that we have a data file (``data1.txt``) and a manifest tracking that data file, we can trigger the first run of our ETL Pipeline.

.. include:: /specialized-services/etl/operations/runETLPipeline.rst

3.5 Check the status of the Pipeline Run
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. include:: /specialized-services/etl/operations/getPipelineRun.rst

3.6 Pipeline Run Complete
~~~~~~~~~~~~~~~~~~~~~~~~~

Once the pipeline has gone through the 3 phases, the ETL Pipeline will enter a terminal state of either ``completed`` or ``failed``.

Here are the most common reasons why an ETL Pipeline may fail.
    * Ingress transfer failed (Remote Outbox to Local Inbox)
    * Egress transfer failed (Local Outbox to Remote Inbox)
    * Malformed manifest - This is a critical and unrecoverable error
    * One of the batch compute jobs (ETL Jobs) exited with a non-zero exit code