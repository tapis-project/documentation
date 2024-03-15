.. _etl_quickstart:

Quick Start
===========

In this section we will be constructing an ETL pipeline that:
  #. Detects the presence of data files and manifests on some remote system
  #. Transfers those manifests and data files to a local system
  #. Performs sentiment analysis on the text content of the data files and generates a result file for each analysis
  #. Transfers the results files to a remote system for archiving


.. tabs::

    .. tab:: Bash | Python

        .. include:: /specialized-services/etl/quickstart-standard.rst

    .. tab:: TapisV3 CLI (interactive)

        .. include:: /specialized-services/etl/quickstart-interactive.rst