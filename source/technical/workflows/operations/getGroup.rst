Retrieval (getGroup)
~~~~~~~~~~~~~~~~~~~~

Retrieve details for a specific group

.. tabs::

  .. code-tab:: bash

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************'
    t.workflows.getGroup(group_id="<group_id>")