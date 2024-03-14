.. code-block:: json

    {
        "id": "<pipeline_id>",
        "before": null,
        "remote_outbox": {
            "data": {...},
            "manifests": {...}
        },
        "local_inbox": {
            "control": {...},
            "data": {...},
            "manifests": {...}
        },
        "jobs": [
            {
                "name": "sentiment-analysis",
                "appId": "etl-sentiment-analysis-test", 
                "appVersion": "dev",
                ...
            }
        ],
        "local_outbox": {
            "data": {...},
            "manifests": {...}
        },
        "remote_inbox": {
            "data": {...},
            "manifests": {...}
        },
        "after": null
    }