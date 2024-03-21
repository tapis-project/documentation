**Creating a Linux System for an ETL Pipeline**

Create a file named ``onsite-linux-system.json`` in your current working directory that contains the json schema below.

.. include:: /specialized-services/etl/includes/schemas/onsite-linux-system.json.rst

Use one of the following methods to submit a request to the Systems API to create the Tapis System.

.. tabs::

    .. code-tab:: python

        with open('onsite-linux-system.json', 'r') as file:
            system = json.load(file)

        t.systems.createSystem(**system)

    .. code-tab:: bash

        curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems -d @onsite-linux-system.json


**Register Credentials for the System**

Once you have successfully created the system, you must then register credentials for the system in order for Tapis to access it on your behalf.
Follow the instructions found in the :ref:`Registering Credentials for a System <registering_credentials>` section.

Once you have successfully registered credentials for the system, you should be able to list files on the system.

.. include:: /specialized-services/etl/operations/listFiles.rst