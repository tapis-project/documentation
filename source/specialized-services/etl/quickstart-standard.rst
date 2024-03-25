.. _etl_quickstart_non_interactive:

Step 0: Creating Prerequisite Tapis Resources
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this step, we will create the following prerequisite Tapis resources:

  #. One :ref:`group <groups>` (Workflows API) - A collection of Tapis users that collectively own workflow resources
  #. Two (or more) :ref:`systems <systems>` (Systems API) - Tapis Systems for the Data and Manifests Configuration for the ETL Systems of your pipeline. We will create 1 Globus-type system for data transfers and storage, and 1 Linux-type system that we will use for manifests and compute.

.. include:: /technical/workflows/operations/createGroup.rst

.. include:: /specialized-services/etl/includes/create-globus-system.rst

.. include:: /specialized-services/etl/includes/create-linux-system.rst

Step 1: Creating an ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: /specialized-services/etl/operations/createETLPipeline.rst

Step 2: Running an ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: /specialized-services/etl/operations/runETLPipeline.rst

Step 3: Checking the Pipeline Run status
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: /specialized-services/etl/operations/getPipelineRun.rst





