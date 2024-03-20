Run a Pipeline (runPipeline)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/pipelines/<pipeline_id>/run -d "{}"

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    t.workflows.runPipeline(group_id="<group_id>", pipeline_id="<pipeline_id>")
