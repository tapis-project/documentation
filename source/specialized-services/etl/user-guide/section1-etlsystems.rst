.. _etl_systems:

1. ETL Systems Configurations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In this section, we discuss ETL System Configurations. At the end of this section, we will explain 
how to create and configure all Remote and Local ETL System Configruations for an ETL Pipeline.

.. note::

  ETL System Configurations are by far the most complex part of creating an ETL Pipeline. Do not be discouraged!
  The initial complexity is a small price to pay for the ease with which ETL Pipelines are operated with Tapis ETL.

An **ETL System Configuration** is a collection of systems that are responsible for the storage of data files (Data System) and the storage of manifest files (Manifest System).

There are 4 ETL System Configurations for every ETL Pipeline:
  * **The Remote Outbox** - Where input data files to be processed are staged
  * **The Local Inbox** - Where input data files are processed
  * **The Local Outbox** - Where output data files are staged
  * **The Remote Inbox** - Where output data files are transferred

Every ETL System Configuration is composed of 2 systems: A Data System and a Manifests System. These systems generally have a one-to-one
correspondence with a :ref:`Tapis Systems <systems_overview>`.

.. note::

  There are many different possible ETL System Confguration setups for an ETL Pipeline. It is entirely
  possible to have a single Tapis System representing **all** systems in an ETL Pipeline.
  How you set up your ETL System Configurations depends entirely upon where the data is and how you want to process it.

**Common ETL System Configurations Setup**

.. image:: /specialized-services/images/commonetlsetup.png
  :alt: Tapis ETL System Configurations diagram

Above is an illustration of the most common ETL System Configuration setup. You will notice that there are four
distinct Tapis Systems; System(A) System(C) are Globus endpoints, System(B) is a Linux system, and System(D) is 
the ETL Job execution system (also Linux) that shares a file system with Systems(C). It is worth noting that some of the
:ref:`Data and Manifests Systems <etl_data_and_manifests_systems>` for some ETL System Configurations (Remote Inbox, Remote Outbox, etc.) have
corresponding Tapis System that are located at entirely different data centers.

1.1 Create Tapis Systems for the ETL System Configurations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Before we discuss ETL System Configurations in depth, we will first create all of the Tapis Systems that will be used by Tapis ETL
to run our ETL Pipeline. We will be using a simplified single-data center model for this pipeline. In this setup, the Local Inbox, Local Outbox,
and compute system will use LoneStar6 (LS6) as the host and the Remote Inbox and Remote Outbox will use the LS6 Globus Endpoint as the host.

**Simplified ETL System Configurations Setup**

.. image:: /specialized-services/images/simplifiedetlsetup.png
  :alt: Simplified Tapis ETL System Configurations diagram

Follow the instructions below to create the necessary Tapis Systems for your ETL Pipeline.

.. tabs::

  .. tab:: System (A)

    This ``globus`` Tapis System will be used as the Data System for both of the Remote ETL System Configurations (Remote Inbox, Remote Outbox) in our pipeline.
    
    .. include:: /specialized-services/etl/includes/create-globus-system.rst

    Once you have succesfully listed files for this system, move onto the instructions for System (B)
        

  .. tab:: System (B)

    This ``linux`` Tapis System will be used as the Manifests System for all ETL System Configurations in our pipeline. It will also serve as the exec system on which we will run our pipelines ETL Jobs.

    .. include:: /specialized-services/etl/includes/create-linux-system.rst

.. _etl_data_and_manifests_systems:

1.2 ETL System Confguration Components
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Every ETL System Configuration is composed of two parts. The Data System and the Manifests System.

.. _etl_data_configuation:

1.2.1 Data System
~~~~~~~~~~~~~~~~~~~~~~~~

The Data System is a collection of properties that define where
where data files are located (or where data files are supposed to be transferred)
as well as how to perform integrity checks on that data. Below is an example of the Data System
of a Remote Inbox ETL System Configuration (Manifests System ignored to simplify the schema)

.. include:: /specialized-services/etl/includes/schemas/data-config.json.rst

* ``system_id`` - The ID of Tapis System on which:

  * data files are stored (Outbox systems)
  * data files are to be transferred (Inbox systems)
* ``path`` - The path to the directory on the Tapis System where data files are staged
* ``include_patterns`` - An array of glob patterns that are used to filter filenames. All files matching the glob patterns are considered by Tapis ETL to be data files.
* ``exclude_patterns`` - An array of glob patterns that are used to filter filenames. All files matching the glob patterns are considered by Tapis ETL to be **non**-data files.

**1.2.1.1 Data Integrity Profile**

Every Data System has a Data Integrity Profile. The Data Integrity Profile is a set of instructions
that informs Tapis ETL on how it should check the validity of all data files in the data path.
There are 3 ways in which Tapis ETL can perform data integrity checks:

* ``byte_check`` - Checks the actual size (in bytes) of a data file against it's recored size in a manifest
* ``checksum`` - Takes the hash of a data file according to the specified hashing algorithm and checks that value against the value of the checksum in a manifest. This is an expensive process for large data files. The data integrity check type should only be used if data files are small or if absolutely necessary. 
* ``done_files`` - Checks that a data file has a corresponding done file in which:

  * the done file matches a set of glob patterns
  * the done file's filename contains the corresponding data file's filename as a substring

Below are some example schemas of Data Systems with different Data Integrity Profiles

.. tabs::

    .. tab:: Byte Check
      
      .. include:: /specialized-services/etl/includes/schemas/data-integrity-byte-check.json.rst

    .. tab:: Checksum

      .. include:: /specialized-services/etl/includes/schemas/data-integrity-checksum.json.rst

    .. tab:: Done Files

      .. include:: /specialized-services/etl/includes/schemas/data-integrity-done-files.json.rst

.. _etl_manifests_configuration:

1.2.2 Manifests System
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Manfests System is a is a collection of properties that define where
manifests for a given system are located as well as how to generate manifests.
Below is an example of the Manifests System of a Remote Inbox ETL System Configuration (Data System ignored to simplify the schema)

.. include:: /specialized-services/etl/includes/schemas/manifests-config.json.rst

* ``system_id`` - The ID of Tapis System on which manifest files are stored or created
* ``path`` - The path to the directory on the Tapis System where the manifest files are stored or created
* ``include_patterns`` - An array of glob patterns that are used to filter filenames. All files matching the glob patterns are considered by Tapis ETL to be manifest files.
* ``exclude_patterns`` - An array of glob patterns that are used to filter filenames. All files matching the glob patterns are considered by Tapis ETL to be **non**-manifest files.
* ``generation_policy`` - Indicates how manifests will be generated for data files on the Manifests System. Must be one of the following values:
  
  * ``manual`` - A user must manually generate the manifests for the data files that they want their ETL Pipeline to process
  * ``auto_one_per_file`` - Generates one manifest per data file found in the data directory
  * ``auto_one_for_all`` - Generates one manifests for all data files found in the data directory
* ``priority`` - The order in which manifests should be processed. Must be one of the following values
  
  * ``oldest`` - Tapis ETL will process the oldest manifest in the manifests path
  * ``newest`` - Tapis ETL will process the newest manifest in the manifests path
  * ``any`` - Tapis ETL determine which manifests in the manifests path to process first

.. note::
  
  Section 1 Punch List
    * Created 1 Globus system with Tapis
    * Registered credentials with Tapis for the Globus system
    * Successully peformed a file listing with Tapis on the Globus system
    * Created 1 Linux system with Tapis
    * Registered credentials with Tapis for the Linux system
    * Successully peformed a file listing with Tapis on the Linux system
