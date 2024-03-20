**Create an ETL Pipeline (createETLPipeline)**

Save the following ETL pipeline definiton to a file named ``etl-pipeline.json`` in your current working directory.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline.json.rst

Then submit the definition.

.. tabs::

    .. code-tab:: python

        with open('etl-pipeline.json', 'r') as file:
            pipeline = json.load(file)

            t.workflows.createETLPipeline(group_id=<group_id>, **pipeline)
    
    .. code-tab:: bash

        curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/beta/groups/<group_id>/etl -d @etl-pipeline.json

Once created, you can now fetch and run the pipeline

.. tabs::

    .. code-tab:: python

        t.workflows.getPipeline(group_id=<group_id>, pipeline_id=<pipeline_id>)
    
    .. code-tab:: bash

        curl -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/pipeline/<pipeline_id>