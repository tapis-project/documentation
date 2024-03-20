.. code-block:: json

    {
        "id": "etl-userguide-pipeline-<user_id>",
        "before": null,
        "remote_outbox": {
            "data": {
                "system_id": "etl.userguide.systema.<user_id>",
                "path": "/ETL/REMOTE-OUTBOX/DATA",
            },
            "manifests": {
                "system_id": "etl.userguide.systemb.<user_id>",
                "generation_policy": "auto_one_per_file",
                "path": "/ETL/REMOTE-OUTBOX/MANIFESTS"
            }
        },
        "local_inbox": {
            "control": {
                "system_id": "etl.userguide.systemb.<user_id>",
                "path": "/ETL/LOCAL-INBOX/CONTROL"
            },
            "data": {
                "system_id": "etl.userguide.systema.<user_id>",
                "path": "/ETL/LOCAL-INBOX/DATA"
            },
            "manifests": {
                "system_id": "etl.userguide.systemb.<user_id>",
                "path": "/ETL/LOCAL-INBOX/MANIFESTS"
            }
        },
        "jobs": [
            {
                "name": "sentiment-analysis",
                "appId": "etl-sentiment-analysis-test", 
                "appVersion": "dev",
                "nodeCount": 1,
                "coresPerNode": 1,
                "maxMinutes": 10,
                "execSystemId": "test.etl.ls6.local.inbox",
                "execSystemInputDir": "${JobWorkingDir}/jobs/${JobUUID}/input",
                "archiveSystemId": "test.etl.ls6.local.inbox",
                "archiveSystemDir": "ETL/LOCAL-OUTBOX/DATA",
                "parameterSet": {
                    "schedulerOptions": [
                        {
                            "name": "allocation",
                            "arg": "-A TACC-ACI"
                        },
                        {
                            "name": "profile",
                            "arg": "--tapis-profile tacc-apptainer"
                        }
                    ],
                    "containerArgs": [
                        {
                            "name": "input-mount",
                            "arg": "--bind $(pwd)/input:/src/input:ro,$(pwd)/output:/src/output:rw"
                        }
                    ],
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
                "system_id": "etl.userguide.systema.<user_id>",
                "path": "/ETL/LOCAL-OUTBOX/DATA"
            },
            "manifests": {
                "system_id": "etl.userguide.systemb.<user_id>",
                "path": "/ETL/LOCAL-OUTBOX/MANIFESTS"
            }
        },
        "remote_inbox": {
            "data": {
                "system_id": "etl.userguide.systema.<user_id>",
                "path": "/ETL/REMOTE-INBOX/DATA"
            },
            "manifests": {
                "system_id": "etl.userguide.systemb.<user_id>",
                "path": "/ETL/REMOTE-INBOX/MANIFESTS"
            }
        },
        "after": null
    }