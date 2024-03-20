**Creating a Globus System for an ETL Pipeline**

Create a file named ``onsite-globus-system.json`` in your current working directory that contains the json schema below.

.. include:: /specialized-services/etl/includes/schemas/onsite-globus-system.json.rst

.. tabs::

    .. code-tab:: python

        import json
        from tapipy.tapis import Tapis


        t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
        t.tokens.get_tokens()

        with open('onsite-globus-system.json', 'r') as file:
            system = json.load(file)

        t.systems.createSystem(**system)

    .. code-tab:: bash

        curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems -d @onsite-globus-system.json


**Register Globus Credentials for the System**

Once you have successfully created the system, you must then register credentials for the system in order for Tapis to access it on your behalf.
Follow the instructions found in the :ref:`Registering Globus Credentials for a System <registering_globus_credentials>` section.

Once you have successfully registered credentials for the system, you should be able to list files on the system.

.. include:: /specialized-services/etl/operations/listFiles.rst