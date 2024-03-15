.. _etl_systems:

1. ETL Systems Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::

  ETL System configurations are by far the most complex part of creating an ETL Pipeline. Do not be discouraged!
  The initial complexity is a small price to pay for the ease with which pipelines are operated with Tapis ETL.

In this section, we discuss how to create and configure all Remote and Local ETL Systems for an ETL Pipeline. 
We consistently refer the each ETL System (Remote Outbox, Remote Inbox, Local Outbox, and Local Inbox)
as singlular systems when they are in fact conceptual entities that may represent one or more real underlying systems.
In practice, all ETL Systems in an ETL Pipeline have one or more corresponding Tapis Systems. One ETL Pipeline may have
two Tapis Systems per ETL System, whereas another ETL Pipeline may have a single
Tapis System representing **all** ETL Systems. Both configurations are valid. When and how to use multiple or single system
setups depends entirely upon where the data is and how you want to process it.

Some important questions to ask yourself regarding your ETL Pipeline:
  * Does the data need to be processed in place?
  * Are any or all of the ETL Systems situated at the same data center?
  * Can Tapis ETL write manifest files to some directory on the Remote ETL Systems? 

Below is an illustration of the most common ETL Systems configuration.

.. image:: ./images/commonetlsetup.png
  :alt: Tapis ETL Systems diagram

Every ETL System has two primary configurations. The Data Configuration and the Manifest Configuration.

Data Configuration
~~~~~~~~~~~~~~~~~~
The Data Configuration informs Tapis ETL where data is (or where it is supposed to go) as well as how to perform integrity
checks on the data.

Manifest Configuration
~~~~~~~~~~~~~~~~~~~~~~


Remote ETL Systems Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Each pipeline must configure a Remote Outbox and a Remote Inbox. These are logical systems where data files that require processing 
are stored and output files from transforms are stored, respectively. Conceptually, the Remote Outbox and Inbox are storage resources
independent of any datacenter, but they must provide programmatic access.

The Remote Outbox and Inbox must be a Tapis System with one of the following types:
  * Linux
  * S3
  * Globus

Local ETL Systems Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~