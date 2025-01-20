.. _apps:

=======================================
Applications
=======================================
In order to run a job on a system you will need to create or have access to a Tapis **application**.

-----------------
Overview
-----------------
A Tapis application represents all the information required to run a Tapis job on a Tapis system and produce useful
results. Each application is versioned and is associated with a specific tenant and owned by a specific user who has
special privileges for the application. In order to support this purpose an application definition includes information
which allows the *Jobs* service to:

* Stage input prior to launching the application
* Launch the application
* Monitor the application during execution
* Archive output after application execution

..
    Dynamic Execution System Selection
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Tapis supports dynamic selection of an execution system at runtime. Each Tapis system has certain capabilities inherent
    in the definition of the system, such as the batch scheduler type, supported container runtimes, certain information
    about the HPC queues, etc. Additional job related capabilities may also be included in a system definition. A job
    request or an application may specify a list of constraints based on these capabilities. These are used for determining
    eligible systems at job execution time.

-----------------
Model
-----------------
At a high level an application contains some information that is independent of the version and some information that
varies by version.

Non-Versioned Attributes
~~~~~~~~~~~~~~~~~~~~~~~~
*id*
  A short descriptive name for the application that is unique within the tenant.
*owner*
  A specific user set at application creation. Default is ``${apiUserId}``, the user making the request to
  create the application.
*enabled*
  Indicates if application is currently considered active and available for use. Default is *true*.
*deleted*
  Indicates if application has been soft deleted.
*created*
  When the application was created. Maintained by service.
*updated*
  When the application was last updated. Maintained by service.

Versioned Attributes
~~~~~~~~~~~~~~~~~~~~
*version*
  Applications are expected to evolve over time. ``Id`` + ``version`` must be unique within a tenant.
*description*
  An optional more verbose description for the application.
*versionEnabled*
  Indicates if specific version is currently considered active and available for use. Default is *true*.
*locked*
  Indicates if version is currently locked. When locked a version may not be modified. Default is *false*.
*runtime*
  Runtime to be used when executing the application. DOCKER, SINGULARITY, ZIP. Default is DOCKER.
  For more information on how Tapis supports the various runtime types, please see JobsRuntimeSupport_.
*runtimeVersion*
  Runtime version to be used when executing the application.
*runtimeOptions*
  Options that apply to the runtime. Currently only applicable for SINGULARITY runtime.

.. warning::
  Please note that use of SINGULARITY_START has been deprecated. Support will be removed in a future release.
  If you have a need for this option please contact Tapis support (cicsupport@tacc.utexas.edu).

*containerImage*
  Reference to be used when running the container image.
*jobType*
  FORK or BATCH. Jobs submitted will be of this type by default. May be overridden in the job submit request.
  This allows an application designer to test an application run as a FORK job, for example, and then move on to
  running as a BATCH job which typically involves further design work. Default is FORK.
*maxJobs*
  Maximum total number of jobs that can be queued or running for this application on a given execution system at
  a given time. Note that the execution system may also limit the number of jobs on the system which may further
  restrict the total number of jobs. Set to -1 for unlimited. Default is unlimited.
*maxJobsPerUser*
  Maximum total number of jobs associated with a specific job owner that can be queued or running for this application
  on a given execution system at a given time. Note that the execution system may also limit the number of jobs on the
  system which may further restrict the total number of jobs. Set to -1 for unlimited. Default is unlimited.
*strictFileInputs*
  Indicates if a job request is allowed to have unnamed file inputs. If set to true then a job request may only use
  the named file inputs defined in the application. See attribute *fileInputs* in the JobAttributes table.
  Default is *false*.
*Job related attributes*
  Various attributes related to job execution such as *execSystemId*, *execSystemExecDir*, *execSystemInputDir*,
  *execSystemLogicalQueue* *archiveSystemId*, *fileInputs*, etc.

.. note::
  Currently dynamic selection of an execution system is not supported. For this reason the job related attribute
  *dynamicExecSystem* should be set to *false* (the default) and *execSystemConstraints* should not be set.

.. _JobsRuntimeSupport: https://tapis.readthedocs.io/en/latest/technical/jobs.html#container-runtimes

Required Attributes
~~~~~~~~~~~~~~~~~~~
When creating a application the required attributes are: ``id``, ``version`` and  ``containerImage``.
Depending on the type of application and specific values for certain attributes there are other requirements.

The restrictions are:

* If ``archiveSystemId`` is specified then ``archiveSystemDir`` must be specified.


Attributes and the Job Execution Environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The runtime environment of a Tapis job is determined by values in the job submit request, the application definition
and the execution system definition. Generally speaking, for values that can be assigned in multiple places, the
values in the job submit request override those in the application definition, which in turn override those in the
system definition. There are special cases, however, where the values from different definitions are merged.

See the jobs/apps/systems parameter matrix_ for a detailed description of how each attribute is handled.

.. _matrix: https://drive.google.com/file/d/1BrY6tHzOegwsgDMrhcKE7RHH7HRAA0Do/view?usp=sharing


--------------------------------
Getting Started
--------------------------------
Before going into further details about applications, here we give some examples of how to create and view applications.
In the examples below we assume you are using the TACC tenant with a base URL of ``tacc.tapis.io`` and that you have
authenticated using PySDK or obtained an authorization token and stored it in the environment variable JWT,
or perhaps both.

Creating an application
~~~~~~~~~~~~~~~~~~~~~~~
Create a local file named ``app_sample.json`` with json similar to the following::

  {
    "id":"tacc-sample-app-<userid>",
    "version":"0.1",
    "description":"My sample application",
    "runtime":"DOCKER",
    "containerImage":"docker.io/hello-world:latest",
    "jobType":"FORK",
    "jobAttributes": {
      "description": "default job description",
      "execSystemId": "execsystem1"
    }
  }

where <userid> is replaced with your user name.

.. note::
  If specified, ``execSystemId`` must reference a system that exists and has ``canExec`` set to true. If
  ``execSystemId`` is not specified, then it must be provided as part of the job submit request.

Using PySDK:

.. code-block:: python

 import json
 from tapipy.tapis import Tapis
 t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
 with open('app_sample.json', 'r') as openfile:
     my_app = json.load(openfile)
 t.apps.createAppVersion(**my_app)

Using CURL::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps -d @app_sample.json

Viewing Applications
~~~~~~~~~~~~~~~~~~~~

Retrieving details for an application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To retrieve details for a specific application, such as the one above:

.. note::
  See the section below on `Selecting`_ to find out how to control the amount of information returned.

Using PySDK:

.. code-block:: python

 t.apps.getAppLatestVersion(appId='tacc-sample-app-<userid>')

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps/tacc-sample-app-<userid>

The response should look similar to the following::

 {
    "result": {
        "tenant": "tacc",
        "id": "tacc-sample-app-<userid>",
        "version": "0.1",
        "description": "My sample application",
        "owner": "<userid>",
        "enabled": true,
        "versionEnabled": true,
        "locked": false,
        "runtime": "DOCKER",
        "runtimeVersion": null,
        "runtimeOptions": [],
        "containerImage": "docker.io/hello-world:latest",
        "jobType": "FORK",
        "maxJobs": 0,
        "maxJobsPerUser": 0,
        "strictFileInputs": false,
        "jobAttributes": {
            "description": "default job description",
            "dynamicExecSystem": false,
            "execSystemConstraints": [],
            "execSystemId": "execsystem1",
            "execSystemExecDir": null,
            "execSystemInputDir": null,
            "execSystemOutputDir": null,
            "dtnSystemInputDir": null,
            "dtnSystemOutputDir": null,
            "execSystemLogicalQueue": null,
            "archiveSystemId": null,
            "archiveSystemDir": null,
            "archiveOnAppError": false,
            "isMpi": false,
            "mpiCmd": null,
            "cmdPrefix": null,
            "parameterSet": {
                "appArgs": [
                  {
                    "arg": "arg1",
                    "name": "appArg1Name",
                    "description": "description for app arg 1",
                    "inputMode": "FIXED",
                    "notes": {
                      "arg1note": "my first arg"
                    }
                  }
                ],
                "containerArgs": [],
                "schedulerOptions": [],
                "envVariables": [
                  {
                    "key": "ENV_1",
                    "value": "env_1_value",
                    "description": "my env var #1",
                    "inputMode": "INCLUDE_BY_DEFAULT",
                    "notes": {}
                  },
                  {
                    "key": "APP_ONLY_FIXED_SET",
                    "value": "app_only_fixed_set",
                    "description": "FIXED env var only in app definition",
                    "inputMode": "FIXED",
                    "notes": {
                      "app_only_fixed_notes": "testing_it"
                    }
                  },
                  {
                    "key": "APP_REQUIRED_SET",
                    "value": "app_required_set",
                    "description": "",
                    "inputMode": "REQUIRED",
                    "notes": {}
                  }
                ],
                "archiveFilter": {
                    "includes": [],
                    "excludes": [],
                    "includeLaunchFiles": true
                }
            },
            "fileInputs": [
              {
                "name": "empty",
                "description": "An empty file",
                "inputMode": "OPTIONAL",
                "autoMountLocal": true,
                "notes": {},
                "sourceUrl": "tapis://test-storage-linux/data_input/empty.txt",
                "targetPath": "empty.txt"
              },
              {
                "name": "file1",
                "description": "A random text file",
                "inputMode": "REQUIRED",
                "autoMountLocal": true,
                "notes": {},
                "sourceUrl": "tapis://test-storage-linux/data_input/file1.txt",
                "targetPath": "file1.txt"
              },
              {
                "name": "s3_ceph_file",
                "description": "A file from an s3 ceph storage system.",
                "inputMode": "REQUIRED",
                "autoMountLocal": true,
                "notes": {},
                "sourceUrl": "tapis://test-storage-s3-ceph/object1",
                "targetPath": "s3_ceph_file.dat"
              },
              {
                "name": "s3_aws_test1",
                "description": "File from an s3 aws storage system.",
                "inputMode": "REQUIRED",
                "autoMountLocal": true,
                "notes": {},
                "sourceUrl": "tapis://test-s3-storage/object2",
                "targetPath": "s3_aws/test1.dat"
              }
            ],
            "fileInputArrays": [
              {
                "name": "fileInputArray1",
                      "description": "A list of files in a single directory",
                "sourceUrls": [
                   "tapis://test-storage-linux/data_input/file1a.txt",
                   "tapis://test-storage-linux/data_input/file2a.txt",
                   "tapis://test-storage-linux/data_input/file3a.txt"
                ],
                "targetDir": "myFileInputArrayDir/subdir1"
              }
            ],
            "nodeCount": 1,
            "coresPerNode": 1,
            "memoryMB": 100,
            "maxMinutes": 10,
            "subscriptions": [
              {
                "description": "Email on job new status",
                "enabled": true,
                "jobEventCategoryFilter": "JOB_NEW_STATUS",
                "deliveryTargets": [
                  {
                    "deliveryMethod": "EMAIL",
                    "deliveryAddress": "me@example.com"
                  }
                ],
                "ttlMinutes": 10080
              }
            ],
            "tags": []
        },
        "tags": [],
        "notes": {},
        "uuid": "40a60a11-41fe-45ea-8674-d2cfe04992f6",
        "deleted": false,
        "created": "2021-04-22T21:30:10.590999Z",
        "updated": "2021-04-22T21:30:10.590999Z"
    },
    "status": "success",
    "message": "TAPIS_FOUND App found: tacc-sample-app-<userid>",
    "version": "0.0.1-SNAPSHOT",
    "metadata": null
 }

Retrieving details for all applications
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To see the list of applications that you own:

Using PySDK:

.. code-block:: python

 t.apps.getApps()

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps?select=allAttributes

The response should contain a list of items similar to the single listing shown above.

.. note::
  See the sections below on `Searching`_, `Selecting`_, `Sorting`_ and `Limiting`_ to find out how to control the
  amount of information returned.

-----------------------------------
Minimal Definition and Restrictions
-----------------------------------
When creating an application the required attributes are: *id*, *version* and *containerImage*
Depending on the type of application and specific values for certain attributes there are other requirements.
The restrictions are:

* If *archiveSystemId* is specified then *archiveSystemDir* is required.

------------------
Version
------------------
The versioning scheme is at the discretion of the application author. The combination of ``tenant+id+version`` uniquely
identifies an application in the Tapis environment. It is recommended that a two or three level form of
semantic versioning be used. The fully qualified application reference within a tenant is constructed by appending
a hyphen to the name followed by the version string. For example, the first two versions of an application might
be *myapp-0.0.1* and *myapp-0.0.2*. If a version is not specified when retrieving an application then by default the
most recently created version of the application will be returned.

-------------------------
Containerized Application
-------------------------
An application that has been containerized is one that can be executed using a single container image. Tapis will use
the appropriate container runtime command and provide support for making the input and output directories available to
the container when running the container image.

.. note::
  Currently only containerized applications are supported

------------------------------
Directory Semantics and Macros
------------------------------
At job submission time the Jobs service supports the use of macros based on template variables. These variables may be
referenced when specifying directories in an application definition. For a full list of supported variables and more
information please see the Jobs Service documentation.
Here are some examples of variables that may be used when specifying directories for an application:

* *JobUUID* - The Id of the job determined at job submission.
* *JobOwner* - The owner of the job determined at job submission.
* *JobWorkingDir* - Default parent directory from which a job is run. This will be relative to the effective root
  directory *rootDir* on the execution system. *rootDir* and *jobWorkingDir* are attributes of the execution system.
* *HOST_EVAL($<ENV_VARIABLE>)* - The value of the environment variable *ENV_VARIABLE* when evaluated on the execution
  system host when logging in under the job's effective user ID. This is a dynamic value determined at job submission
  time. The function *HOST_EVAL()* extracts specific environment variable values for use during job setup. In
  particular, the TACC specific values of *$HOME*, *$WORK*, *$SCRATCH* and *$FLASH* can be referenced. The specified
  environment variable name is used **as-is**. It is **not** subject to macro substitution. However, the function call
  can have a path string appended to it, such as in *HOST_EVAL($SCRATCH)/tmp/${JobUUID}*, and macro substitution will be
  applied to the path string.

--------------------------------
Data Transfer Node (DTN) Support
--------------------------------
Tapis supports the use of a Data Transfer Node (DTN) when running an application. 
There are two fields in *jobAttributes* related to DTN support:

*dtnSystemInputDir*
  Directory relative to *rootDir* to which input files will be transferred prior to launching the application.
*dtnSystemOutputDir*
  Directory relative to *rootDir* from which output files will be transferred during the archiving phase.

By default, these are set to the special value *!tapis_not_set*. This value indicates that, by default,
a DTN system will not be used for file inputs or archive outputs. In order to trigger the use
of a DTN during either file input staging or archive output, these values must be set.
For more information on using a DTN, please see `DTN Configuration`_.

.. _DTN Configuration: https://tapis.readthedocs.io/en/latest/technical/jobs.html#data-transfer-nodes

-----------------
Permissions
-----------------
The permissions model allows for fine grained access control of Tapis applications.

At application creation time the owner is given full access to the application.
Permissions for other users may be granted and revoked through the applications API. Please
note that grants and revokes through this service only impact the default role for the
user. A user may still have access through permissions in another role. So even after
revoking permissions through this service when permissions are retrieved the access may
still be listed. This indicates access has been granted via another role.

Permissions are specified as either ``*`` for all permissions or some combination of the
following specific permissions: ``("READ","MODIFY","EXECUTE")``. Specifying permissions in all
lower case is also allowed. Having ``MODIFY`` implies ``READ``.

-----------------
Sharing
-----------------
In addition to fine grained permissions support, Tapis also supports a higher level approach to granting access.
This approach is known simply as *sharing*. The sharing API allows you to share an application with a set of users
as well as share publicly with all users in a tenant. Sharing grants ``READ+EXECUTE`` access and, more importantly,
facilitates allowing others to run a job using the application.

Sharing an application gives a user certain implicit access to resources in the context of running a job.
When a properly designed application is shared it may be used by many users to run jobs without the need to explicitly
grant permissions to associated resources such as systems and file paths.

For more information on sharing please see :doc:`sharing`

-----------------
Deletion
-----------------
An application may be deleted and undeleted. Deletion means the application is marked as deleted and is no longer
available for use. Note that although this is a soft delete the operation is intended for use when an application
is to be permanently made unavailable for use. To temporarily make an application unavailable for use please use
support for enabling and disabling an application.

By default deleted applications will not be included in searches and operations on deleted applications will not be
allowed. When listing applications the query parameter *showDeleted* may be used in order to include deleted
applications in the results. Note that deletion applies to all version of an application. It is not possible to delete
a specific version.

-----------------------------
Application Attributes Table
-----------------------------
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| tenant              | String         | designsafe           | - Name of the tenant for which the application is defined.                           |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| id                  | String         | my-ds-app            | - Name of the application. URI safe, see RFC 3986.                                   |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
|                     |                |                      | - **Required** at creation time.                                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| version             | String         | 0.0.1                | - Version of the application. URI safe, see RFC 3986.                                |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
|                     |                |                      | - **Required** at creation time.                                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| description         | String         | A sample application | - Optional description                                                               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| owner               | String         | jdoe                 | - User name of *owner*.                                                              |
|                     |                |                      | - Variable references: *${apiUserId}*                                                |
|                     |                |                      | - Default is *${apiUserId}*                                                          |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enabled             | boolean        | FALSE                | - Indicates if application currently enabled for use. Default is TRUE.               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| versionEnabled      | boolean        | FALSE                | - Indicates if specific version is currently enabled for use. Default is TRUE.       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| locked              | boolean        | FALSE                | - Indicates if version is currently locked. Locking disallows updates.               |
|                     |                |                      | - Default is FALSE                                                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| runtime             | enum           | SINGULARITY          | - Runtime to be used when executing the application.                                 |
|                     |                |                      | - Runtimes: DOCKER, SINGULARITY, ZIP                                                 |
|                     |                |                      | - Default is DOCKER                                                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| runtimeVersion      | String         | 2.5.2                | - Optional version or range of versions required.                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| runtimeOptions      | [enum]         |                      | - Options that apply to specific runtimes.                                           |
|                     |                |                      | - Options: NONE, SINGULARITY_START, SINGULARITY_RUN                                  |
|                     |                |                      | - If runtime is SINGULARITY then must have one of SINGULARITY_START, SINGULARITY_RUN |
|                     |                |                      | - **WARNING** Please note that use of SINGULARITY_START has been deprecated.         |
|                     |                |                      | - Support for SINGULARITY_START will be removed in a future release.                 |
|                     |                |                      | - Default is NONE.                                                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| containerImage      | String         |docker.io/hello-world | - Reference for the container image. Other examples:                                 |
|                     |                |                      | - Singularity: shub://GodloveD/lolcow                                                |
|                     |                |                      | - Docker: tapis/hello-tapis:0.0.1                                                    |
|                     |                |                      | - **Required** at creation time.                                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobType             | enum           | BATCH                | - Default job type.                                                                  |
|                     |                |                      | - Types: BATCH, FORK                                                                 |
|                     |                |                      | - Jobs will be of this type by default. May be overridden in the job submit request. |
|                     |                |                      | - Default is FORK.                                                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobs             | int            | 10                   | - Max number of jobs that can be running for this app on a system.                   |
|                     |                |                      | - System may also limit the number of jobs.                                          |
|                     |                |                      | - Set to -1 for unlimited. Default is unlimited.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobsPerUser      | int            | 2                    | - Max number of jobs per job owner.                                                  |
|                     |                |                      | - System may also limit the number of jobs.                                          |
|                     |                |                      | - Set to -1 for unlimited. Default is unlimited.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| strictFileInputs    | boolean        | FALSE                | - Indicates if a job request is allowed to have unnamed file inputs.                 |
|                     |                |                      | - If TRUE then a job request may only use named file inputs defined in the app.      |
|                     |                |                      | - Default is FALSE.                                                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobAttributes       | JobAttributes  |                      | - Various attributes related to job execution.                                       |
|                     |                |                      | - See table below.                                                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tags                | [String]       |                      | - List of tags as simple strings.                                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String         |{"project": "myproj"} | - Simple metadata in the form of a Json object.                                      |
|                     |                |                      | - Not used by Tapis.                                                                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| uuid                | UUID           | 20281                | - Auto-generated by service.                                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| created             | Timestamp      | 2020-06-19T15:10:43Z | - When the app was created. Maintained by service.                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| updated             | Timestamp      | 2020-07-04T23:21:22Z | - When the app was last updated. Maintained by service.                              |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

------------------------
JobAttributes Table
------------------------
..
    | dynamicExecSystem   | boolean        |                      | - Indicates if constraints are to be used to select an execution system.             |
    |                     |                |                      | - The default is FALSE.                                                              |
    +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
    | execSystem          | [String]       | ["A=aval AND",       | - Capability constraints to use when dynamically searching for an execution system.  |
    | Constraints         |                |   "B=bval"]          |                                                                                      |
    +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type             | Example            | Notes                                                                                |
+=====================+==================+====================+======================================================================================+
| description         | String           |                    | - Description to be filled in when this application is used to run a job.            |
|                     |                  |                    | - Macros allow this to act as a template to be filled in at job runtime.             |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| execSystemId        | String           |                    | - Specific system on which the application is to be run.                             |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| execSystemExecDir   | String           |                    | - Directory where application assets are staged.                                     |
|                     |                  |                    | - Current working directory at application launch time.                              |
|                     |                  |                    | - Macro template variables such as ${JobWorkingDir} may be used.                     |
|                     |                  |                    | - Default is ${JobWorkingDir}/jobs/${JobUUID}                                        |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| execSystemInputDir  | String           |                    | - Directory where Tapis is to stage the inputs required by the application.          |
|                     |                  |                    | - Macro template variables such as ${JobWorkingDir} may be used.                     |
|                     |                  |                    | - Default is ${JobWorkingDir}/jobs/${JobUUID}                                        |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| execSystemOutputDir | String           |                    | - Directory where Tapis expects the application to store its final output results.   |
|                     |                  |                    | - Files here are candidates for archiving.                                           |
|                     |                  |                    | - Macro template variables such as ${JobWorkingDir} may be used.                     |
|                     |                  |                    | - Default is ${JobWorkingDir}/jobs/${JobUUID}/output                                 |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| dtnSystemInputDir   | String           |                    | - Directory relative to DTN rootDir to which input files will be transferred.        |
|                     |                  |                    | - Transfer happens prior to launching the application.                               |
|                     |                  |                    | - Can be overriden by job submission request.                                        |
|                     |                  |                    | - Optional. If set will trigger use of DTN.                                          |
|                     |                  |                    | - Default is *!tapis_not_set*                                                        |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| dtnSystemOutputDir  | String           |                    | - Directory relative to DTN rootDir from which output files will be transferred.     |
|                     |                  |                    | - Transfer happens during archiving phase of job execution.                          |
|                     |                  |                    | - Can be overriden by job submission request.                                        |
|                     |                  |                    | - Optional. If set will trigger use of DTN.                                          |
|                     |                  |                    | - Default is *!tapis_not_set*                                                        |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| execSystem          | String           | normal             | - LogicalQueue to use when running the job.                                          |
| LogicalQueue        |                  |                    |                                                                                      |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| archiveSystemId     | String           |                    | - System to use when archiving outputs.                                              |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| archiveSystemDir    | String           |                    | - Directory on *archiveSystemId* where outputs will be placed.                       |
|                     |                  |                    | - This will be relative to the effective root directory defined for archiveSystemId. |
|                     |                  |                    | - Default is ${JobWorkingDir}/jobs/${JobUUID}                                        |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| archiveOnAppError   | boolean          |                    | - Indicates if outputs should be archived if there is an error while running job.    |
|                     |                  |                    | - The default is TRUE.                                                               |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| isMpi               | boolean          |                    | - Indicates that application is to be executed as an MPI job.                        |
|                     |                  |                    | - The default is FALSE.                                                              |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| mpiCmd              | String           |  "mpirun"          | - Command used to launch MPI jobs.                                                   |
|                     |                  |  "ibrun -n 4"      | - Prepended to the command used to execute the application.                          |
|                     |                  |                    | - Conflicts with cmdPrefix if isMpi is set.                                          |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| cmdPrefix           | String           |                    | - String prepended to the application invocation command.                            |
|                     |                  |                    | - Conflicts with mpiCmd if isMpi is set.                                             |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| parameterSet        | ParameterSet     |                    | - Various collections used during job execution.                                     |
|                     |                  |                    | - App arguments, container arguments, scheduler options, environment variables, etc. |
|                     |                  |                    | - See table below.                                                                   |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| fileInputs          | [FileInput]      |                    | - Collection of file inputs that must be staged for the application.                 |
|                     |                  |                    | - Each input must have a name.                                                       |
|                     |                  |                    | - *strictFileInputs* =TRUE means only inputs defined here may be specified for job.  |
|                     |                  |                    | - See table below.                                                                   |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| fileInputArrays     | [FileInputArray] |                    | - Collection of arrays of inputs that must be staged for the application.            |
|                     |                  |                    | - Each input must have a name. All inputs in an array have the same target directory.|
|                     |                  |                    | - *strictFileInputs* =TRUE means only inputs defined here may be specified for job.  |
|                     |                  |                    | - See table below.                                                                   |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| nodeCount           | int              |                    | - Number of nodes to request during job submission.                                  |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| coresPerNode        | int              |                    | - Number of cores per node to request during job submission.                         |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| memoryMB            | int              |                    | - Memory in megabytes to request during job submission.                              |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| maxMinutes          | int              |                    | - Run time to request during job submission.                                         |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| subscriptions       |                  |                    | - Notification subscriptions.                                                        |
|                     |                  |                    | - See table below.                                                                   |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+
| tags                | [String]         |                    | - List of tags as simple strings.                                                    |
+---------------------+------------------+--------------------+--------------------------------------------------------------------------------------+

-----------------------------
ParameterSet Attributes Table
-----------------------------
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| appArgs             | [Arg]          |                      | - Command line arguments passed to the application.                                  |
|                     |                |                      | - See table below for more information on *Arg* type entries.                        |
|                     |                |                      | - For more information on *appArgs* please see the chapter on *Jobs*                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| containerArgs       | [Arg]          |                      | - Command line arguments passed to the container runtime.                            |
|                     |                |                      | - See table below for more information on *Arg* type entries.                        |
|                     |                |                      | - For more information on *containerArgs* please see the chapter on *Jobs*           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| schedulerOptions    | [Arg]          |                      | - Scheduler options passed to the HPC batch scheduler.                               |
|                     |                |                      | - See table below for more information on *Arg* type entries.                        |
|                     |                |                      | - For more information on *schedulerOptions* please see the chapter on *Jobs*        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| envVariables        | [KeyValuePair] |                      | - Environment variables placed into the runtime environment.                         |
|                     |                |                      | - Each entry has *key* (required) and *value* (optional) as well as other attributes.|
|                     |                |                      | - See table *KeyValuePair Attributes* below for more information.                    |
|                     |                |                      | - For more information on *envVariables* please see the chapter on *Jobs*            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| archiveFilter       | ArchiveFilter  |                      | - Sets of files to include or exclude when archiving.                                |
|                     |                |                      | - Default is to include all files in *execSystemOutputDir*.                          |
|                     |                |                      | - See table below for details of *ArchiveFilter* structure.                          |
|                     |                |                      | - For more information on *archiveFilter* support please see the chapter on *Jobs*   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

------------------------------
ArchiveFilter Attributes Table
------------------------------
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| includes            | [String]       |                      | - Files to include when archiving after execution of the application.                |
|                     |                |                      | - excludes list has precedence.                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| excludes            | [String]       |                      | - Files to skip when archiving after execution of the application.                   |
|                     |                |                      | - excludes list has precedence.                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| includeLaunchFiles  | boolean        |                      | - Indicates if Tapis generated launch scripts are to be included when archiving.     |
|                     |                |                      | - The default is TRUE.                                                               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

------------------------
Arg Attributes Table
------------------------
For more information on how the *inputMode* attribute is used during job processing, please see JobsArgProcessing_.

.. _JobsArgProcessing: https://tapis.readthedocs.io/en/latest/technical/jobs.html#argument-processing

+---------------------+------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type       | Example              | Notes                                                                                |
+=====================+============+======================+======================================================================================+
| name                | String     |                      | - Identifying label associated with the argument.                                    |
|                     |            |                      | - **Required** at creation time.                                                     |
+---------------------+------------+----------------------+--------------------------------------------------------------------------------------+
| description         | String     |                      | - Optional description of the argument which may include usage, purpose, etc.        |
+---------------------+------------+----------------------+--------------------------------------------------------------------------------------+
| inputMode           | enum       |                      | - Indicates how argument is to be treated when processing individual job requests.   |
|                     |            |                      | - Modes: REQUIRED, FIXED, INCLUDE_ON_DEMAND, INCLUDE_BY_DEFAULT                      |
|                     |            |                      | - Default is INCLUDE_ON_DEMAND.                                                      |
|                     |            |                      | - REQUIRED: Must be provided in a job request.                                       |
|                     |            |                      | - FIXED: Completely defined in the application and not overridable in a job request. |
|                     |            |                      | - INCLUDE_ON_DEMAND: Included if referenced in a job request.                        |
|                     |            |                      | - INCLUDE_BY_DEFAULT: Included unless *include=false* in a job request.              |
+---------------------+------------+----------------------+--------------------------------------------------------------------------------------+
| arg                 | String     |                      | - Value for the argument                                                             |
|                     |            |                      | - **Required** at creation time.                                                     |
+---------------------+------------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String     | {"fieldType": "int"} | - Metadata in the form of a Json object, such as type, allowed values, etc.          |
|                     |            |                      | - Not used by Tapis.                                                                 |
+---------------------+------------+----------------------+--------------------------------------------------------------------------------------+

-----------------------------
KeyValuePair Attributes Table
-----------------------------

+---------------------+--------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type   | Example              | Notes                                                                                |
+=====================+========+======================+======================================================================================+
| key                 | String |   "INPUT_FILE"       | - Environment variable name. Required.                                               |
+---------------------+--------+----------------------+--------------------------------------------------------------------------------------+
| value               | String |   "/tmp/file.input"  | - Environment variable value                                                         |
+---------------------+--------+----------------------+--------------------------------------------------------------------------------------+
| description         | String |                      | - Description                                                                        |
+---------------------+--------+----------------------+--------------------------------------------------------------------------------------+
| inputMode           | enum   |   REQUIRED           | - Indicates how argument is to be treated when processing individual job requests.   |
|                     |        |                      | - Modes: REQUIRED, FIXED, INCLUDE_ON_DEMAND, INCLUDE_BY_DEFAULT                      |
|                     |        |                      | - Default is INCLUDE_BY_DEFAULT.                                                     |
|                     |        |                      | - REQUIRED: Must be provided in a job request or application definition.             |
|                     |        |                      | - FIXED: Not overridable in application or job request.                              |
|                     |        |                      | - INCLUDE_ON_DEMAND: Included if referenced in a job request.                        |
|                     |        |                      | - INCLUDE_BY_DEFAULT: Included unless *include=false* in a job request.              |
+---------------------+--------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String |  "{}"                | - Simple metadata in the form of a Json object.                                      |
|                     |        |                      | - Not used by Tapis.                                                                 |
+---------------------+--------+----------------------+--------------------------------------------------------------------------------------+

--------------------------
FileInput Attributes Table
--------------------------
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| Attribute       | Type      | Example              | Notes                                                                                |
+=================+===========+======================+======================================================================================+
| name            | String    |                      | - Identifying label associated with the input. Typically used during a job request.  |
|                 |           |                      | - **Required** at creation time.                                                     |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| description     | String    |                      | - Optional description.                                                              |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| inputMode       | enum      |                      | - Indicates how input is to be treated when processing individual job requests.      |
|                 |           |                      | - REQUIRED, OPTIONAL, FIXED                                                          |
|                 |           |                      | - Default is OPTIONAL.                                                               |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| autoMountLocal  | boolean   |                      | - Indicates if Jobs service should automatically mount file paths into containers.   |
|                 |           |                      | - Note that not all container runtimes require this.                                 |
|                 |           |                      | - Setting to FALSE allows user complete control using *containerArg* parameters.     |
|                 |           |                      | - Default is TRUE.                                                                   |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| sourceUrl       | String    |                      | - Source used by Jobs service when staging file inputs.                              |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| targetPath      | String    |                      | - Target path used by Jobs service when staging file inputs.                         |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+

-------------------------------
FileInputArray Attributes Table
-------------------------------
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| Attribute       | Type      | Example              | Notes                                                                                |
+=================+===========+======================+======================================================================================+
| name            | String    |                      | - Identifying label associated with the input. Typically used during a job request.  |
|                 |           |                      | - **Required** at creation time.                                                     |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| description     | String    |                      | - Optional description.                                                              |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| inputMode       | enum      |                      | - REQUIRED, OPTIONAL, FIXED                                                          |
|                 |           |                      | - Default is OPTIONAL.                                                               |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| sourceUrls      | [String]  |                      | - Array of sources used by Jobs service when staging file inputs.                    |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+
| targetDir       | String    |                      | - Target directory used by Jobs service when staging file inputs.                    |
+-----------------+-----------+----------------------+--------------------------------------------------------------------------------------+

-----------------------
Searching
-----------------------
The service provides a way for users to search for applications based on a list of search conditions provided either as query
parameters for a GET call or a list of conditions in a request body for a POST call to a dedicated search endpoint.

Search using GET
~~~~~~~~~~~~~~~~
To search when using a GET request to the ``apps`` endpoint a list of search conditions may be specified
using a query parameter named ``search``. Each search condition must be:

 * surrounded with parentheses
 * have three parts separated by the character ``.``
 * be joined using the character ``~``.

All conditions are combined using logical AND. The general form for specifying the query parameter is as follows::

  ?search=(<attribute_1>.<op_1>.<value_1>)~(<attribute_2>.<op_2>.<value_2>)~ ... ~(<attribute_N>.<op_N>.<value_N>)

Attribute names are given in the table above and may be specified using Camel Case or Snake Case.

Supported operators: ``eq`` ``neq`` ``gt`` ``gte`` ``lt`` ``lte`` ``in`` ``nin`` ``like`` ``nlike`` ``between`` ``nbetween``

..
  For more information on search operators, handling of timestamps, lists, quoting, escaping and other general information on
  search please see <TBD>.

Example CURL command to search for applications that have ``Test`` in the id, are of type FORK and allow for *maxJobs*
greater than ``5``::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps?search="(id.like.*Test*)~(job_type.eq.FORK)~(max_jobs.gt.5)"

Notes:

* For the ``like`` and ``nlike`` operators the wildcard character ``*`` matches zero or more characters and ``!`` matches exactly one character.
* For the ``between`` and ``nbetween`` operators the value must be a two item comma separated list of unquoted values.
* If there is only one condition the surrounding parentheses are optional.
* In a shell environment the character ``&`` separating query parameters must be escaped with a backslash.
* In a shell environment the query value must be surrounded by double quotes and the following characters must be escaped with a backslash in order to be properly interpreted by the shell:

  * ``"`` ``\`` `````

* Attribute names may be specified using Camel Case or Snake Case.
* Following complex attributes not supported when searching:

  * ``jobAttributes`` ``notes``


Dedicated Search Endpoint
~~~~~~~~~~~~~~~~~~~~~~~~~
The service provides the dedicated search endpoint ``apps/search/apps`` for specifying complex queries. Using a GET
request to this endpoint provides functionality similar to above but with a different syntax. For more complex
queries a POST request may be used with a request body specifying the search conditions using an SQL-like syntax.

Search using GET on Dedicated Endpoint
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Sending a GET request to the search endpoint provides functionality very similar to that provided for the endpoint
``apps`` described above. A list of search conditions may be specified using a series of query parameters, one for each attribute.
All conditions are combined using logical AND. The general form for specifying the query parameters is as follows::

  ?<attribute_1>.<op_1>=<value_1>&<attribute_2>.<op_2>=<value_2>)& ... &<attribute_N>.<op_N>=<value_N>

Attribute names are given in the table above and may be specified using Camel Case or Snake Case.

Supported operators: ``eq`` ``neq`` ``gt`` ``gte`` ``lt`` ``lte`` ``in`` ``nin`` ``like`` ``nlike`` ``between`` ``nbetween``

..
  For more information on search operators, handling of timestamps, lists, quoting, escaping and other general information on
  search please see <TBD>.

Example CURL command to search for applications that have ``Test`` in the id, are of type FORK and allow for *maxJobs*
greater than ``5``::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps/search/apps?id.like=*Test*\&job_type.eq=FORK\&max_jobs.gt=5

Notes:

* For the ``like`` and ``nlike`` operators the wildcard character ``*`` matches zero or more characters and ``!`` matches exactly one character.
* For the ``between`` and ``nbetween`` operators the value must be a two item comma separated list of unquoted values.
* In a shell environment the character ``&`` separating query parameters must be escaped with a backslash.
* Attribute names may be specified using Camel Case or Snake Case.
* Following complex attributes not supported when searching:

  * ``jobAttributes`` ``tags``  ``notes``

Search using POST on Dedicated Endpoint
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
More complex search queries are supported when sending a POST request to the endpoint ``apps/search/apps``.
For these requests the request body must contain json with a top level property name of ``search``. The
``search`` property must contain an array of strings specifying the search criteria in
an SQL-like syntax. The array of strings are concatenated to form the full search query.
The full query must be in the form of an SQL-like ``WHERE`` clause. Note that not all SQL features are supported.

For example, to search for apps that are owned by ``jdoe`` and of type ``FORK`` or owned by
``jsmith`` and allow for *maxJobs* less than ``5`` create a local file named ``app_search.json``
with following json::

  {
    "search":
      [
        "(owner = 'jdoe' AND job_type = 'FORK') OR",
        "(owner = 'jsmith' AND max_jobs < 5)"
      ]
  }

To execute the search use a CURL command similar to the following::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps/search/apps -d @app_search.json

Notes:

* String values must be surrounded by single quotes.
* Values for BETWEEN must be surrounded by single quotes.
* Search query parameters as described above may not be used in conjunction with a POST request.
* SQL features not supported include:

  * ``IS NULL`` and ``IS NOT NULL``
  * Arithmetic operations
  * Unary operators
  * Specifying escape character for ``LIKE`` operator


Map of SQL operators to Tapis operators
***************************************
+----------------+----------------+
| Sql Operator   | Tapis Operator |
+================+================+
| =              | eq             |
+----------------+----------------+
| <>             | neq            |
+----------------+----------------+
| <              | lt             |
+----------------+----------------+
| <=             | lte            |
+----------------+----------------+
| >              | gt             |
+----------------+----------------+
| >=             | gte            |
+----------------+----------------+
| LIKE           | like           |
+----------------+----------------+
| NOT LIKE       | nlike          |
+----------------+----------------+
| BETWEEN        | between        |
+----------------+----------------+
| NOT BETWEEN    | nbetween       |
+----------------+----------------+
| IN             | in             |
+----------------+----------------+
| NOT IN         | nin            |
+----------------+----------------+

--------------------------------
Sort, Limit, Select and ListType
--------------------------------
When a list of Applications is retrieved the service provides for sorting, filtering and limiting the results.
By default, only resources owned by you will be included. The service provides a way for you to request that
all resources accessible to you be included. This is determined by the query parameter *listType*.

When retrieving either a list of resources or a single resource the service also provides a way to *select* which
fields (i.e. attributes) are included in the results. Sorting, limiting and attribute selection are supported using
query parameters.

Selecting
~~~~~~~~~
When retrieving applications the fields (i.e. attributes) to be returned may be specified as a comma separated list using
a query parameter named ``select``. Attribute names may be given using Camel Case or Snake Case.

Notes:

 * Special select keywords are supported: ``allAttributes`` and ``summaryAttributes``
 * Summary attributes include:

   * ``id``, ``version``, ``owner``

 * By default all attributes are returned when retrieving a single resource via the endpoint apps/<app_id>.
 * By default summary attributes are returned when retrieving a list of applications.
 * Specifying nested attributes is not supported.
 * The attribute ``id`` is always returned.

For example, to return only the attributes ``version`` and ``containerImage`` the
CURL command would look like this::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps?select=version,containerImage

The response should look similar to the following::

 {
    "result": [
        {
            "id": "TestApp1",
            "version": "0.0.1",
            "containerImage": "containterimage1"
        },
        {
            "id": "JobApp1",
            "version": "0.0.1",
            "containerImage": "containterimage1"
        },
        {
            "id": "JobAppWithInput",
            "version": "0.0.1",
            "containerImage": "containterimage1"
        },
        {
            "id": "SleepSeconds",
            "version": "0.0.1",
            "containerImage": "tapis/testapps:main"
        }
    ],
    "status": "success",
    "message": "TAPIS_FOUND Apps found: 11 applications",
    "version": "0.0.1-SNAPSHOT",
    "metadata": {
        "recordCount": 4,
        "recordLimit": 100,
        "recordsSkipped": 0,
        "orderBy": null,
        "startAfter": null,
        "totalCount": -1
    }
 }


Sorting
~~~~~~~
The query parameter for sorting is named ``orderBy`` and the value is the attribute name to sort on with an optional
sort direction. The general format is ``<attribute_name>(<dir>)``. The direction may be ``asc`` for ascending or
``desc`` for descending. The default direction is ascending.

Examples:

 * orderBy=id
 * orderBy=id(asc)
 * orderBy=name(desc),created
 * orderBy=id(asc),created(desc)

Limiting
~~~~~~~~
Additional query parameters may be used in order to limit the number and starting point for results. This is useful for
implementing paging. The query parameters are:

 * ``limit`` - Limit number of items returned. For example limit=10.

   * Use 0 or less for unlimited.
   * Default is 100.

 * ``skip`` - Number of items to skip. For example skip=10.

   * May not be used with startAfter.
   * Default is 0.

 * ``startAfter`` - Where to start when sorting. For example limit=10&orderBy=id(asc),created(desc)&startAfter=101

   * May not be used with ``skip``.
   * Must also specify ``orderBy``.
   * The value of ``startAfter`` applies to the major ``orderBy`` field.
   * Condition is context dependent. For ascending the condition is value > ``startAfter`` and for descending the condition is value < ``startAfter``.

When implementing paging it is recommend to always use ``orderBy`` and when possible use ``limit+startAfter`` rather
than ``limit+skip``. Sorting should always be included since returned results are not guaranteed to be in the same order
for each call. The combination of ``limit+startAfter`` is preferred because ``limit+skip`` is more likely to result in
inconsistent results as records are added and removed. Using ``limit+startAfter`` works best when the attribute has a
natural sequential ordering such as when an attribute represents a timestamp or a sequential ID.

ListType
~~~~~~~~
By default, you will only see the resources that you own. The query parameter *listType* allows you to see additional
resources that are available to you.

Options:

*OWNED*
  Include only items owned by you (Default)
*SHARED_PUBLIC*
  Include only items shared publicly
*ALL*
  Include all items you are authorized to view.

---------------
Tapis Responses
---------------
For requests that return a list of resources the response result object will contain the list of resource records that
match the user's query and the response metadata object will contain information related to sorting and limiting.

The metadata object will contain the following information:

 * ``recordCount`` - Actual number of records returned.
 * ``recordLimit`` - The limit query parameter specified in the request. -1 if query parameter was not specified.
 * ``recordsSkipped`` - The skip query parameter specified in the request. -1 if query parameter was not specified.
 * ``orderBy`` - The orderBy query parameter specified in the request. Empty string if query parameter was not specified.
 * ``startAfter`` - The startAfter query parameter specified in the request. Empty string if query parameter was not specified.
 * ``totalCount`` - Total number of records that would have been returned without a limit query parameter being imposed. -1 if total count was not computed.

For performance reasons computation of ``totalCount`` is only determined on demand. This is controlled by the boolean
query parameter ``computeTotal``. By default ``computeTotal`` is *false*.

Example query and response:

Query::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps?limit=2&orderBy=id(desc)

Response::

 {
    "result": [
        {
            "id": "TestApp1",
            "version": "0.0.1",
            "owner": "testuser2"
        },
        {
            "id": "tacc-sample-app",
            "version": "0.1",
            "owner": "testuser2"
        }
    ],
    "status": "success",
    "message": "TAPIS_FOUND Apps found: 2 applications",
    "version": "0.0.1-SNAPSHOT",
    "metadata": {
        "recordCount": 2,
        "recordLimit": 2,
        "recordsSkipped": 0,
        "orderBy": "id(desc)",
        "startAfter": null,
        "totalCount": -1
    }
  }

