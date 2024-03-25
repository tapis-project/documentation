**Fetch Pipeline Run Details (getPipelineRun)**

Fetch the details of a single pipeline run. You will need the following data.
* ``group_id`` - id of the group that owns the pipeline
* ``pipeline_id`` - id of the pipeline
* ``pipeline_run_uuid`` - UUID of the pipeline run

.. tabs::

    .. code-tab:: python

        t.workflows.getPipelineRun(group_id=<group_id>, pipeline_id=<pipeline_id>)
    
    .. code-tab:: bash

        curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/pipeline/<pipeline_id>/runs/<pipeline_run_uuid>