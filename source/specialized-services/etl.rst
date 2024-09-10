############
Tapis ETL
############

Tapis ETL is a convenience layer on top of Tapis Workflows that enables users to create automated ETL pipelines with a single
request. Tapis ETL leverages Tapis Workflow resources (:ref:`pipeline <pipelines>` and :ref:`tasks <tasks>`) to manage the entire ETL process; from ingesting data files
from the configured source system, to tracking their status as they are processed by user-defined batch computing jobs and 
transferring the results to the configured destination system.

----

.. include:: ./etl/overview.rst

----

.. include:: ./etl/user-guide.rst

----

.. include:: ./etl/quickstart.rst
