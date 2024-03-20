.. code-block:: json

    {
        "remote_outbox": {
            "data": {
                "system_id": "etl.userguide.systema.<user_id>",
                "path": "/ETL/REMOTE-OUTBOX/DATA",
                "integrity_profile": {
                    "type": "checksum"
                },
                "include_patterns": ["*.txt"],
                "exclude_patterns": []
            }
            "manifests": {}
        }
    }