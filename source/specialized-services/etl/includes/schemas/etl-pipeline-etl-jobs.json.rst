.. code-block:: json
    
    [
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