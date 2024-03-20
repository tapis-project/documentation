.. code-block:: json

    {
        "data": {
            "system_id": "etl.userguide.systema.<user_id>",
            "path": "/ETL/REMOTE-OUTBOX/DATA"
        },
        "manifests": {
            "system_id": "etl.userguide.systemb.<user_id>",
            "generation_policy": "auto_one_per_file",
            "path": "/ETL/REMOTE-OUTBOX/MANIFESTS"
        }
    }
        