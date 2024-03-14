.. _etl_quickstart_non_interactive:

Step 0: Creating Prerequisite Tapis Resources
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You must create the following Tapis resources before creating your ETL Pipeline

  #. One :ref:`group <groups>` (Workflows API) - A collection of Tapis users that collectively own workflow resources
  #. Two (or more) :ref:`systems <systems>` (Systems API) - Tapis representations of the ETL Systems of your pipeline. For each ETL system 

.. include:: /technical/workflows/operations/createGroup.rst

Step 1: Creating the ETL Pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: /specialized-services/etl/operations/createETLPipeline.rst




