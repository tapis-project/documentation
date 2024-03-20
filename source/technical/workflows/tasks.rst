.. _tasks:

-----
Tasks
-----

Tasks are discrete units of work performed during the execution of a workflow.
They can be represented as nodes on a directed acyclic graph (DAG), with the order of their
execution determined by their dependencies, and where all tasks without dependencies are
executed first.

Tasks can be defined when creating pipeline, or after the pipelines creation. Every task
must have an ``id`` that is unique within the pipeline.

Task may also specify their dependencies in a number of ways. The first way is by 
declaring the dependency explicity in the ``depends_on`` property. This is an *Array* of
**TaskDependency** objects which only have 2 attributes. The ``id``, which is the id of the task
that it depends on, and the ``can_fail`` attribute(Boolean) which specifies whether the dependent
task is allowed to run if that *TaskDependency* fails.

Task Attributes Table
~~~~~~~~~~~~~~~~~~~~~

This table contains all of the properties that are shared by all tasks. Different types
of tasks will have other unique properties in addition to all of the properties in the table
below.

+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| Attribute         | Type                  | Example                                                               | Notes                                                                                                                   |
+===================+=======================+=======================================================================+=========================================================================================================================+
| id                | String                | my-task, my.task, my_task                                             | - Must be unique within the pipeline that it belongs to                                                                 |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| type              | Enum                  | image_build, tapis_job, tapis_actor, request, container_run, function | - Only *image_build* is fully supported. Partial support for the *request* type exists; HTTP GET requests only          |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| depends_on        | Array[TaskDependency] | **see table below**                                                   | - Explicitly declares this task's dependencies. Task with the specified ``id`` must exist or the pipeline will not run. |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| execution_profile | Object                | **see execution profile table in the pipeline section**               | - Inherits the ``execution_profile`` set in the pipeline definition.                                                    |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| description       | String                | My task description                                                   |                                                                                                                         |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| input             | Object                | **see input table below**                                             |                                                                                                                         |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| output            | Object                |                                                                       |                                                                                                                         |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| pipeline          | String(UUIDv4)        | 5bd771ab-8df5-43cd-a059-fbaa2323841b                                  | - UUID of the pipeline that this task is a part of                                                                      |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+
| uuid              | String(UUIDv4)        | 5bd771ab-8df5-43cd-a059-fbaa2323841b                                  | - A globally unique identifier for this task                                                                            |
+-------------------+-----------------------+-----------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------+

Input Object
~~~~~~~~~~~~

Input is an object in which the keys are the id of the input(String) and the value is an
object that defines the type of data, and either the literal value of the data via the *data* property
or a reference to where that data can be found via the *data_from*. 

+---------+------------------+--------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+
| Key-Val | Type             | Example                                          | Notes                                                                                                           |
+=========+==================+==================================================+=================================================================================================================+
| key     | String           | TAPIS_USERNAME, PATH_TO_FILES, _SOME_INPUT, etc. | - Must be an alpha numeric string that conforms to the following regex pattern: ``^[_]?[a-zA-Z]+[a-zA-Z0-9_]*`` |
+---------+------------------+--------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+
| value   | InputValueObject | **see table below**                              |                                                                                                                 |
+---------+------------------+--------------------------------------------------+-----------------------------------------------------------------------------------------------------------------+

InputValue Object
~~~~~~~~~~~~~~~~~

+------------+--------------------+----------------------------------------------------------+--------------------------------------------------------------------------------+
| Attributes | Type               | Example                                                  | Notes                                                                          |
+============+====================+==========================================================+================================================================================+
| type       | Enum               | string, number, tapis_file_input, tapis_file_input_array |                                                                                |
+------------+--------------------+----------------------------------------------------------+--------------------------------------------------------------------------------+
| value      | String, Int, Float | 123, "hello world", 1.23                                 |                                                                                |
+------------+--------------------+----------------------------------------------------------+--------------------------------------------------------------------------------+
| value_from | ValueFrom Object   | **see table below**                                      | - Used to reference data from a workflow definition (env, params, task_output) |
+------------+--------------------+----------------------------------------------------------+--------------------------------------------------------------------------------+

ValueFrom Object
~~~~~~~~~~~~~~~~~

The Value From object is a key value pair in which the *key* is an enum denoting the source object
of the value(pipeline envrionment, workflow submission parmeteters, and task outputs) and 
the *value* is the key on that source where the value data can be found

+---------+--------------------------------------------------+-------------------------------+-------+
| Key-Val | Type                                             | Example                       | Notes |
+=========+==================================================+===============================+=======+
| key     | Enum                                             | env, params, task_output      |       |
+---------+--------------------------------------------------+-------------------------------+-------+
| value   | String or TaskOutput Object(**see table below**) | TAPIS_USERNAME, PATH_TO_FILES |       |
+---------+--------------------------------------------------+-------------------------------+-------+

TaskOutput Object
~~~~~~~~~~~~~~~~~

+------------+--------+--------------------------+-----------------------------------------------+
| Attributes | Type   | Example                  | Notes                                         |
+============+========+==========================+===============================================+
| task_id    | String | task_1, my-task          | - The id of a previously run task             |
+------------+--------+--------------------------+-----------------------------------------------+
| output_id  | String | 123, "hello world", 1.23 | - The id of the output for the specified task |
+------------+--------+--------------------------+-----------------------------------------------+

Example Task Definition with Inputs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. note::
          
  The example below is in yaml format for readability, but the Tapis Workflows API only accepts JSON

.. code-block:: yaml

  tasks:
  - id: generate-manifests-and-process-next
    type: function
    description: |
      Python script that creates manifest files and outputs a
      tapis file inputs array to stdout
    runtime: python3.9
    installer: pip # poetry
    command: ""
    packages: 
      - tapipy==1.2.20
    code: "<base64 encoded user-defined code here>"
    input:
      TAPIS_USERNAME:
        type: string
        value_from:
          env: TAPIS_USERNAME
      TAPIS_PASSWORD:
        type: string
        value_from:
          env: TAPIS_PASSWORD
      TAPIS_SYSTEM_ID:
        type: string
        value: "some-system-id"
      TARGET_DIR:
        type: string
        value: target/dir/for/file-input-array
      INBOX:
        type: string
        value: "/scratch/08294/jplneid/tacc_ep/INBOX"
      MANIFESTS:
        type: string
        value: "/scratch/08294/jplneid/tacc_ep/MANIFESTS"
      TAPIS_BASE_URL:
        type: string
        value_from:
          params: base_url
    output:
      fileInputArrays:
        type: "tapis_file_input_arrays"
      manifestFilePath:
        type: "string"

Task Types
~~~~~~~~~~

There are different types of *tasks* types users can leverage to perform diffent types of work.
These are called task *types* or *primitives*.
Task types include the **image_build** type, the **request** type, the **tapis_job** type, the **tapis_actor** type, the **container_run**
type, and the **function** task.

When defining tasks on a pipeline, the **type** must be present in the task definition
along with all other attributes specific to the task type.

----

.. _tasktypes:

.. tabs:: 

  .. tab:: Function

    **Function**

    Functions enable users to execute arbitrary code in select languages and runtimes as a part of their
    workflow. Functions have access to the Execution Context(**see section below on Execution Context**)
    which enables programmatic access to the state of the current Task Execution and the results of previous
    tasks.

    **Function Task Attributes Table**

    +-----------+---------------+-----------------------------------------------+-----------------------------------------------------------------------+
    | Attribute | Type          | Example                                       | Notes                                                                 |
    +===========+===============+===============================================+=======================================================================+
    | code      | Base64 String |                                               | - The user-defined code to be run during this task                    |
    +-----------+---------------+-----------------------------------------------+-----------------------------------------------------------------------+
    | runtime   | Enum          | python3.9                                     | - The runtime environment in which the user-defined code will be run  |
    +-----------+---------------+-----------------------------------------------+-----------------------------------------------------------------------+
    | packages  | Array<String> | ["tapipy", "numpy"]                           | - The packages to be installed prior to running the user-defined code |
    +-----------+---------------+-----------------------------------------------+-----------------------------------------------------------------------+
    | installer | Enum          | pip                                           | - The installer to install the packages                               |
    +-----------+---------------+-----------------------------------------------+-----------------------------------------------------------------------+
    | command   | String        | mkdir -p /some/dir && apt-get install package | - Bash command to be run before package installation                  |
    +-----------+---------------+-----------------------------------------------+-----------------------------------------------------------------------+

    **Accessing Workflow Execution Context within a Funtion Task**

    The Execution Context is a set of functions to query and mutate the state of the Task Execution.
    The Execution Context is available for use in user-defined code via the Open Workflow Engine SDK.
    This can be imported into all functions and used to get task input values,
    fetch outputs of previously run tasks, set task outputs, and control the termination of the task(stdout, stderr).

    Here is an example of user-defined python code that imports the Execution Context, performs work upon it, then
    terminates the task.

    .. code-block:: python

      import json

      from tapipy.tapis import Tapis
      from owe_python_sdk.runtime import execution_context as ctx


      system_id = ctx.get_input("TAPIS_SYSTEM_ID")
      username = ctx.get_input("TAPIS_USERNAME")
      password = ctx.get_input("TAPIS_PASSWORD")
      manifest_files_path = ctx.get_input("MANIFEST_FILES_PATH")
      base_url = ctx.get_input("tapis_base_url")

      try:
        t = Tapis(
            base_url=base_url,
            username=username,
            password=password
        )

        t.get_tokens()

        files = t.systems.listFiles(systemId=system_id, path=manifest_files_path)
      except Exception as e:
        ctx.stderr(1, "There was an error listing files")

      for file, i in enumerate(files):
        ctx.set_output(f"fileObject{i}", json.dumps(file))

      ctx.stdout("Hello stdout")
      
  .. tab:: Image Build

    **Image Build**

    Builds Docker and Singularity images from recipe files and pushes them to repositories or stores
    the resultant image in some archive(specified in the pipeline definition)

    **Image Build Task Attributes Table**

    +-------------+---------+-------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+
    | Attribute   | Type    | Example                                   | Notes                                                                                                                                |
    +=============+=========+===========================================+======================================================================================================================================+
    | builder     | Enum    | kaniko, singularity                       | - There are two image builders that can be used. Kaniko, which builds docker images, and Singularity, which builds singularity files |
    +-------------+---------+-------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+
    | cache       | Boolean | true, false                               | - Layer caching. Used to make subsequent builds of the same image quicker(if supported by the image builder)                         |
    +-------------+---------+-------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+
    | context     | Object  | **see context table below**               | - Indicates the source of the image to build. Typically that source is a code repository, or an image registry                       |
    +-------------+---------+-------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+
    | destination | Object  | **see destination attribute table below** | - Indicates the destination to which the image will be stored/pushed. Can be local, or an image registry like Dockerhub              |
    +-------------+---------+-------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+

    **Context Attribute Table**
        
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Attribute       | Type           | Example                                | Notes                                                                                                                                                                           |
    +=================+================+========================================+=================================================================================================================================================================================+
    | branch          | String         | main, dev, feature/some-new-feature    | - Branch to pull and build from                                                                                                                                                 |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | build_file_path | String         | src/Dockerfile, src/Singularity.myfile | - Path to the Dockerfile relative to the root directory of the project                                                                                                          |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | sub_path        | String         | /some/sub/path                         | - Equivalent to the build context argument in ``docker push``                                                                                                                   |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | type            | Enum           | github, dockerhub, local(unsupported)  | - Instructs the API and Workflow Executor how fetch the source                                                                                                                  |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | url             | String         | tapis/workflows-api                    | - The url repository(or registry) where the source code(or image) is located                                                                                                    |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | visibility      | Enum           | private, public                        | - Informs that API that credentials are required to access the source                                                                                                           |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | identity_uuid   | String(UUIDv4) | 78aa5231-7075-428c-b94a-a6b971a444d2   | - Optional if ``visibility == "public"``. The identity that contains the set of credentials required to access the source                                                       |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | credentials     | Object         |                                        | - Optional if ``visibility == "public"`` and unneccessary if an ``identity_uuid`` is provided. An object that contains key/value of the credentials needed to access the source |
    +-----------------+----------------+----------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

    **Context Examples**

    .. tabs::

      .. tab:: Github

        .. code-block:: json

          "context": {
            "branch": "main",
            "build_file_path": "src/Singularity.test",
            "sub_path": null,
            "type": "github",
            "url": "nathandf/jscicd-image-demo-private",
            "visibility": "private",
            "identity_uuid": "78aa5231-7075-428c-b94a-a6b971a444d2",
            "credentials": {
              "username": "<username>",
              "personal_access_token": "<token>"
            }
          }

      .. tab:: Dockerhub

        .. code-block:: json 

          "context": {
            "tag": "test",
            "type": "dockerhub",
            "url": "nathandf/jscicd-kaniko-test",
            "visibility": "private",
            "identity_uuid": "fb949e63-a636-4666-980f-c72f8abc2b29"
          }

    **Destination Attribute Table**
        
    +---------------+----------------+--------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
    | Attribute     | Type           | Example                              | Notes                                                                                                                                     |
    +===============+================+======================================+===========================================================================================================================================+
    | type          | Enum           | dockerhub, local                     |                                                                                                                                           |
    +---------------+----------------+--------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
    | tag           | String         | latest, dev, 1.0.0                   | - type ``dockerhub`` only. The tag for the image when pushing to a registry                                                               |
    +---------------+----------------+--------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
    | url           | String         | someaccount/somerepo                 | - type ``dockerhub`` only                                                                                                                 |
    +---------------+----------------+--------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
    | identity_uuid | String(UUIDv4) | 78aa5231-7075-428c-b94a-a6b971a444d2 | - The identity that contains the set of credentials required to access the destination                                                    |
    +---------------+----------------+--------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
    | credentials   | Object         |                                      | - Unneccessary if an ``identity_uuid`` is provided. An object that contains key/value of the credentials needed to access the destination |
    +---------------+----------------+--------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+

    **Destination Examples**

    .. tabs::

      .. tab:: Dockerhub
        
        A destination of type ``dockerhub`` will push the resultant
        image to the specified Dockerhub registry using either the credentials provided in the
        identity(referenced in the request body via the ``identity_uuid``), or by providing a
        credentials object with the necessary username and token required to push to that repository.
        
        .. code-block:: json

          "destination": {
            "tag": "test",
            "type": "dockerhub",
            "url": "nathandf/jscicd-kaniko-test",
            "identity_uuid": "fb949e63-a636-4666-980f-c72f8abc2b29"
          }

        **OR**

        .. code-block:: json

          "destination": {
            "tag": "test",
            "type": "dockerhub",
            "url": "nathandf/jscicd-kaniko-test",
            "credentials": {
              "useranme": "<username>",
              "token": "<token>"
            }
          }

      .. tab:: Local
        
        When a destination of type ``local`` is specified, the image resultant of the image build task will be persisted to
        the workflows local file system. It is only accessible by tasks in this pipeline, and
        only for the duration of this pipeline run.

        .. note::
          
          All files will be deleted at the end of the pipeline run. If files
          needs to be persisted, the pipeline must have an archive selected.

        .. code-block:: json 

          { 
            "destination": {
              "type": "local",
              "filename": "myimage.sif"
            }
          }


  .. tab:: Request (partial support)
    
    **Request**

    Sends requests using various protocols to resources external to the workflow (Only HTTP protocol and GET currently fully supported)

    **Request Task Attributes Table**
    
    +--------------+--------+---------------------+------------------------------------------------------------+
    | Attribute    | Type   | Example             | Notes                                                      |
    +==============+========+=====================+============================================================+
    | protocol     | Enum   | https, ftp          | - Default https                                            |
    +--------------+--------+---------------------+------------------------------------------------------------+
    | http_method  | Enum   | get, post           | - Currently, only get is supported                         |
    +--------------+--------+---------------------+------------------------------------------------------------+
    | url          | String | https://someurl.dev | - The url to which you want to send the request            |
    +--------------+--------+---------------------+------------------------------------------------------------+
    | auth         | Object |                     | - Usernames, passwords, access tokens, access secrets, etc |
    +--------------+--------+---------------------+------------------------------------------------------------+
    | data         | Object |                     | - The payload of the request                               |
    +--------------+--------+---------------------+------------------------------------------------------------+
    | headers      | Object |                     | - The headers of an http request                           |
    +--------------+--------+---------------------+------------------------------------------------------------+
    | query_params | Object |                     | - HTTP only                                                |
    +--------------+--------+---------------------+------------------------------------------------------------+
    
  .. tab:: Tapis Job

    **Tapis Job**

    Submits a *Job* via the **Tapis Jobs Service**

    **Tapis Job Task Attributes Table**

    +---------------+---------+--------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Attribute     | Type    | Example                  | Notes                                                                                                                                                                                                        |
    +===============+=========+==========================+==============================================================================================================================================================================================================+
    | tapis_job_def | Object  | **see the Jobs section** |                                                                                                                                                                                                              |
    +---------------+---------+--------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | poll          | Boolean | true, false              | - Indicates to Workflow Executor that the job should be polled until it reaches a terminal state. Defaults to `true`. If `false`, the Workflow Executor will submit the job and immediately mark the task as |
    +---------------+---------+--------------------------+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

  .. tab:: Tapis Actor (under development)

    **Tapis Actor**

    Executes an *Actor* via the **Abaco Service**

    **Tapis Actor Task Attributes Table**

    +----------------+---------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Attribute      | Type    | Example     | Notes                                                                                                                                                                                                             |
    +================+=========+=============+===================================================================================================================================================================================================================+
    | tapis_actor_id | String  | my_actor_id |                                                                                                                                                                                                                   |
    +----------------+---------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | poll           | Boolean | true, false | - Indicates to Workflow Executor that the actor should be polled until it reaches a terminal state. Defaults to `true`. If `false`, the Workflow executor will trigger the actor and immediately mark the task as |
    +----------------+---------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

  .. tab:: Container Run (under development)
    
    **Container Run**

    Runs a container based on the provided image and tag.

    **Container Run Task Attributes Table**
    
    +-----------+--------+-------------------------+------------------------------------------------------+
    | Attribute | Type   | Example                 | Notes                                                |
    +===========+========+=========================+======================================================+
    | image     | String | somerepo/some_image     |                                                      |
    +-----------+--------+-------------------------+------------------------------------------------------+
    | image_tag | String | latest, 1.0.0, cf3v1em0 |                                                      |
    +-----------+--------+-------------------------+------------------------------------------------------+
    | command   | String | sleep 100               | Overwrites both ENTRYPOINT and CMD(s) in Dockerfiles |
    +-----------+--------+-------------------------+------------------------------------------------------+

----

:ref:`Back to tasks <tasktypes>`

----

Retrieval
~~~~~~~~~

Retrieve details for a specific task in a pipeline

.. tabs::

  .. code-tab:: bash

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/pipelines/<pipeline_id>/tasks/<task_id>

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************'
    t.workflows.getPipeline(group_id="<group_id>", pipeline_id="<pipeline_id>", task_id="<task_id>")

The response should look similar to the following::
 
 {
    "success": true,
    "status": 200,
    "message": "Success",
    "result": {
      "id": "build",
      "cache": false,
      "depends_on": [],
      "description": "Build an image from a repository and push it to an image registry",
      "input": null,
      "invocation_mode": "async",
      "max_exec_time": 3600,
      "max_retries": 0,
      "output": null,
      "pipeline": "ececc546-3ee0-437e-ae50-5882ec03356a",
      "poll": null,
      "retry_policy": "exponential_backoff",
      "type": "image_build",
      "uuid": "01eac121-19bf-4d8e-957e-faa27bdaa1f8",
      "builder": "singularity",
      "context": "ea58c3ef-7175-41b0-9671-e50700a33c77",
      "destination": "6eac73da-5799-4e74-957c-03b5cee97149",
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
  }


Deletion
~~~~~~~~

Deleting a task can only be done by a pipeline administrator. If any tasks depend on the
deleted task, the pipeline will fail when run