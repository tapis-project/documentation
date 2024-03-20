.. code-block:: json

    {
        "remote_outbox": {
            "data": {
                "system_id": "etl.userguide.systema.<user_id>",
                "path": "/ETL/REMOTE-OUTBOX/DATA",
                "integrity_profile": {
                    "type": "done_file",
                    "done_files_path": "/ETL/REMOTE-OUTBOX/DATA",
                    "include_patterns": ["*.md5"],
                    "exclude_patterns": []
                },
                "include_patterns": ["*.txt"],
                "exclude_patterns": []
            }
            "manifests": {}
        }
    }