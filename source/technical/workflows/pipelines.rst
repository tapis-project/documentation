.. _pipelines:

---------
Pipelines
---------

A *pipeline* is a collection of tasks and a set of rules governing how those tasks are to be executed.

Pipeline Attributes Table
~~~~~~~~~~~~~~~~~~~~~~~~~

+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| Attribute         | Type           | Example                                      | Notes                                                         |
+===================+================+==============================================+===============================================================+
| id                | String         | my.pipeline                                  | - Must be unique within the group                             |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| uuid              | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789         | - Globally unique identifier for the pipeline                 |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| owner             | String         | jsmith                                       | - The only user that can delete the pipeline                  |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| group             | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789         | - The uuid of the group that owns this pipeline               |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| last_run          | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789         | - The UUID of the previous pipeline run                       |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| current_run       | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789         | - The UUID of the current running pipeline                    |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| tasks             | Array[Task]    | **See the Task section for the Task object** |                                                               |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| execution_profile | Object         | **See table below**                          |                                                               |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+
| env               | Object         | **See Pipeline Envrionment section below**   | - Environment variables to be used by tasks in a pipeline run |
+-------------------+----------------+----------------------------------------------+---------------------------------------------------------------+


Execution Profile Attributes Table
##################################

Overrides the default behavior of the Workflow Executor regarding task retries, 
backoff algorithm, max lifetime of the pipeline, etc. All Execution Profile properties of the
pipeline are inherited by the tasks that belong to the pipeline unless otherwise specified in the
task definition.

+-----------------+------+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Attribute       | Type | Example             | Notes                                                                                                                                                                                                              |
+=================+======+=====================+====================================================================================================================================================================================================================+
| max_retries     | Int  | 0, 3, 10            | - The number of times that the Workflow Executor will try to rerun the task if it fails. Defualts to **0**                                                                                                         |
+-----------------+------+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| invocation_mode | Enum | async, sync         | - Default is "async". When "async" is selected, all tasks will be executed concurrently. Currently, async is the only support option                                                                               |
+-----------------+------+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| retry_policy    | Enum | exponential_backoff | - Dictates which policy to employ when restarting tasks. Default(and only supported option) is exponential_backoff                                                                                                 |
+-----------------+------+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| max_exec_time   | Int  | 60, 3600, 10800     | - The maximum amount of time in seconds that a pipeline(or task) is permitted to run. As soon as the sum of all task runs equals this limit, the pipeline(or task) is terminated. Defaults to 3600 seconds(1 hour) |
+-----------------+------+---------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

Pipeline Envrionment
####################

The Pipeline Envrionment (the *env* property of a pipeline definition) is a mechanism for exposing
static global data to task inputs. The Pipeline Envrionment is an object in which the keys are the 
name of the variables and the value is either a scalar data (string, number, etc) or an object
with a  *value_from* property which references data from a source external to the the 
workflow (ex. Tapis Security Kernel).

.. code-block:: json

  {
    "env": {
      "TAPIS_SYSTEM_ID": "tapisv3-exec",
      "MANIFEST_FILES_DIR": "/path/to/manifest/files",
      "TAPIS_USERNAME": "someusername",
      "TAPIS_PASSWORD": {
        "value_from": {
          "tapis-security-kernel": "some+sk+id"
        }
      }
    }
  }




Retrieval
~~~~~~~~~

Retrieve details for a specific pipeline

.. tabs::

  .. code-tab:: bash

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/pipelines/<pipeline_id>

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************'
    t.workflows.getPipeline(group_id="<group_id>", pipeline_id="<pipeline_id>")

The response should look similar to the following::
 
 {
    "success": true,
    "status": 200,
    "message": "Success",
    "result": {
      "id": "some_pipeline_id",
      "group": "c487c25f-6c6e-457d-a781-85120df9f10b",
      "invocation_mode": "async",
      "max_exec_time": 10800,
      "max_retries": 0,
      "owner": "testuser2",
      "retry_policy": "exponential_backoff",
      "uuid": "e48ada7a-56b4-4d48-974c-7574d51a8789",
      "current_run": null,
      "last_run": null,
      "tasks": [
        {
          "id": "build",
          "cache": false,
          "depends_on": [],
          "description": "Build an image from a repository and push it to an image registry",
          "input": null,
          "invocation_mode": "async",
          "max_exec_time": 3600,
          "max_retries": 0,
          "output": null,
          "pipeline": "e48ada7a-56b4-4d48-974c-7574d51a8789",
          "poll": null,
          "retry_policy": "exponential_backoff",
          "type": "image_build",
          "uuid": "e442b5df-8a9e-4d55-b4da-c51b7241a79f",
          "builder": "singularity",
          "context": "5bd771ab-8df5-43cd-a059-fbaa2323841b",
          "destination": "b34d1439-d2c9-4238-ab74-13b5fd7f3b1f",
          "auth": null,
          "data": null,
          "headers": null,
          "http_method": null,
          "protocol": null,
          "query_params": null,
          "url": null,
          "image": null,
          "tapis_job_def": null,
          "tapis_actor_id": null
        }
      ]
    }
  }


Deletion
~~~~~~~~

Deleting a Pipeline will delete all of it's tasks. This operation
can only be performed the owner of the pipeline.