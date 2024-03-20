.. code-block:: json

    {
        "remote_outbox": {
            "data": {}
            "manifests": {
                "system_id": "etl.userguide.systema.<user_id>",
                "generation_policy": "auto_one_per_file",
                "priority": "oldest",
                "path": "/ETL/REMOTE-OUTBOX/MANIFESTS",
                "include_patterns": [],
                "exclude_patterns": []
            }
        }
    }