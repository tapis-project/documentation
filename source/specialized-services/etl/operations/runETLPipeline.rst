**Run an ETL Pipeline (runPipeline)**

To run a pipeline, you must:
    #. Provide the ``id`` of the group that owns the pipeline
    #. Provide the ``id`` of the pipeline
    #. Belong to the group that owns the pipeline


**Pipeline Arguments**

When running an ETL Pipeline with Tapis ETL, you must provide the following arguments:
    * ``TAPIS_USERNAME`` - Username of the Tapis user running the pipeline
    * ``TAPIS_PASSWORD`` - Password of the user
    * ``TAPIS_BASEURL`` - The URL of the Tapis Tenant in which your pipeline should run (should be the same as the base URL you used to create your pipeline)

Save the following Pipeline Args definiton to a file named ``etl-pipeline-args.json`` in your current working directory.

.. include:: /specialized-services/etl/includes/schemas/etl-pipeline-args.json.rst

Then submit the definition.

.. tabs::

    .. code-tab:: python
        
        with open('pipeline-args.json', 'r') as file:
            args = json.load(file)

        t.workflows.runPipeline(group_id=<group_id>, pipeline_id=<pipeline_id>, args=args)
    
    .. code-tab:: bash

        curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/beta/groups/<group_id>/etl -d @etl-pipeline.json