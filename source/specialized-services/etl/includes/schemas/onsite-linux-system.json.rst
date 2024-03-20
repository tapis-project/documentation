.. code-block:: json

  {
    "id": "etl.userguide.systemb.<user_id>",
    "description": "Tapis ETL Linux System on LS6 for manifests and compute",
    "systemType": "LINUX",
    "host": "ls6.tacc.utexas.edu",
    "defaultAuthnMethod": "PKI_KEYS",
    "rootDir": "HOST_EVAL($SCRATCH)",
    "canExec": true,
    "canRunBatch": true,
    "jobRuntimes": [
      {
        "runtimeType": "SINGULARITY",
        "version": null
      }
    ],
    "batchLogicalQueues": [
      {
        "name": "ls6-normal",
        "hpcQueueName": "normal",
        "maxJobs": 1,
        "maxJobsPerUser": 1,
        "minNodeCount": 1,
        "maxNodeCount": 2,
        "minCoresPerNode": 1,
        "maxCoresPerNode": 2,
        "minMemoryMB": 0,
        "maxMemoryMB": 4096,
        "minMinutes": 10,
        "maxMinutes": 100
      },
      {
        "name": "ls6-development",
        "hpcQueueName": "development",
        "maxJobs": 1,
        "maxJobsPerUser": 1,
        "minNodeCount": 1,
        "maxNodeCount": 2,
        "minCoresPerNode": 1,
        "maxCoresPerNode": 2,
        "minMemoryMB": 0,
        "maxMemoryMB": 4096,
        "minMinutes": 10,
        "maxMinutes": 100
      }
    ],
    "batchDefaultLogicalQueue": "ls6-development",
    "batchScheduler": "SLURM",
    "batchSchedulerProfile": "tacc-apptainer"
  }