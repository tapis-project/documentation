Save the following text to a file named ``data1.txt`` in your current working directory.

.. code-block:: text

    I am very happy!

Then upload this file to your Remote Inbox's data directory.

.. tabs::

    .. code-tab:: python

        with open('data1.txt', 'rb') as file:
            t.files.insert(systemId=<system_id>, path=<path>, file=file)
    
    .. code-tab:: bash

        curl -H "X-Tapis-Token: $JWT" -X POST -F "file=@data1.txt" https://tacc.tapis.io/v3/files/ops/<system_id>/<path_to_data_directory>/data1.txt