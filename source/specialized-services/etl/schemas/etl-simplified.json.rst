.. code-block:: json

    {
        "id": "simpe-pipeline",
        "before": null,
        "remote_outbox": {
            "data": {
                "system_id": "test.etl.ls6.xfer"
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable"
            }
        },
        "local_inbox": {
            "control": {
                "system_id": "test.etl.ls6.writable",
                "path": "/ETL/LOCAL-INBOX/CONTROL"
            },
            "data": {
                "system_id": "test.etl.ls6.xfer"
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable"
            }
        },
        "jobs": [
            {
                "name": "sentiment-analysis",
                "appId": "etl-sentiment-analysis-context-aware", 
                "appVersion": "dev",
                "execSystemId": "test.etl.ls6.writable",
                "archiveSystemId": "test.etl.ls6.local.writable",
                "archiveSystemDir": "ETL/LOCAL-OUTBOX/DATA",
                "parameterSet": {
                        "archiveFilter": {
                        "includes": [],
                        "excludes": ["tapisjob.out"],
                        "includeLaunchFiles": false
                    }
                }
            }
        ],
        "local_outbox": {
            "data": {
                "system_id": "test.etl.ls6.xfer"
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable"
            }
        },
        "remote_inbox": {
            "data": {
                "system_id": "test.etl.ls6.xfer"
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable"
            }
        },
        "after": null
    }