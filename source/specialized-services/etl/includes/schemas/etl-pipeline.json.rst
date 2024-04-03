.. code-block:: json

    {
        "id": "<pipeline_id>",
        "before": {"pipeline_ids": ["test"]},
        "remote_outbox": {
            "data": {
                "system_id": "test.etl.ls6.xfer",
                "path": "/ETL/REMOTE-OUTBOX/DATA",
                "integrity_profile": {
                    "type": "done_file",
                    "done_files_path": "/ETL/REMOTE-OUTBOX/DATA",
                    "include_patterns": ["*.md5"],
                    "exclude_patterns": []
                },
                "include_patterns": ["*.txt"],
                "exclude_patterns": ["*.md5"]
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable",
                "generation_policy": "auto_one_per_file",
                "priority": "oldest",
                "path": "/ETL/REMOTE-OUTBOX/MANIFESTS",
                "include_patterns": [],
                "exclude_patterns": []
            }
        },
        "local_inbox": {
            "control": {
                "system_id": "test.etl.ls6.writable",
                "path": "/ETL/LOCAL-INBOX/CONTROL"
            },
            "data": {
                "system_id": "test.etl.ls6.xfer",
                "path": "/ETL/LOCAL-INBOX/DATA",
                "include_patterns": [],
                "exclude_patterns": []
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable",
                "path": "/ETL/LOCAL-INBOX/MANIFESTS",
                "include_patterns": [],
                "exclude_patterns": []
            }
        },
        "local_outbox": {
            "data": {
                "system_id": "test.etl.ls6.xfer",
                "path": "/ETL/LOCAL-OUTBOX/DATA"
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable",
                "path": "/ETL/LOCAL-OUTBOX/MANIFESTS"
            }
        },
        "remote_inbox": {
            "data": {
                "system_id": "test.etl.ls6.xfer",
                "path": "/ETL/REMOTE-INBOX/DATA"
            },
            "manifests": {
                "system_id": "test.etl.ls6.writable",
                "path": "/ETL/REMOTE-INBOX/MANIFESTS"
            }
        },
        "after": null,
        "jobs": [
            {
                "name": "string-transform",
                "appId": "etl-string-replace-test",
                "appVersion": "dev",
                "execSystemId": "test.etl.ls6.local.inbox",
                "execSystemInputDir": "${JobWorkingDir}/jobs/${JobUUID}/input",
                "nodeCount": 1,
                "coresPerNode": 1,
                "maxMinutes": 10,
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
                    ]
                }
            },
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
        ]
    }