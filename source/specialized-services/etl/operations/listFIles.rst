**List Files (listFiles)**

.. tabs::

    .. code-tab:: python

        t.files.listFiles(systemId="<system_id>", path="/")
    
    .. code-tab:: bash

        curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/<system_id>/