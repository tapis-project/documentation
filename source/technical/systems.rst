.. _systems:

=======================================
Systems
=======================================

Once you are authorized to make calls to the various services, one of first
things you may want to do is view storage and execution resources available
to you or create your own. In Tapis a storage or execution resource is referred
to as a **system**.

-----------------
Overview
-----------------
A Tapis system represents a server or collection of servers exposed through a
single host name or IP address. Each system is associated with a specific tenant.
A system can be used for the following purposes:

* Running a job, including:

  * Staging files to a system in preparation for running a job.
  * Executing a job on a system.
  * Archiving files and data on a remote system after job execution.

* Storing and retrieving files and data.

Each system is of a specific type and owned by a specific user who has special
privileges for the system. The system definition also includes the user that is
used to access the system, referred to as *effectiveUserId*. This access user
can be a specific user (such as a service account) or dynamically specified as
``${apiUserId}`` in which case the user name is extracted from the identity
associated with the request to the service.

At a high level a system represents the following information:

Id
  A short descriptive name for the system that is unique within the tenant.
Description
  An optional more verbose description for the system.
Type of system
  LINUX or S3
Owner
  A specific user set at system creation. By default this is ``${apiUserId}``, the user making the request to
  create the system.
Host name or IP address.
  FQDN or IP address
Enabled flag
  Indicates if system is currently considered active and available for use. Default is *true*.
Effective User
  The user name to use when accessing the system. Referred to as *effectiveUserId.*
  A specific user (such as a service account) or the dynamic user ``${apiUserId}``
Default authentication method
  How access authentication is handled by default. Authentication method can also be
  specified as part of a request.
  Supported methods: PASSWORD, PKI_KEYS, ACCESS_KEY.
Bucket name
  For an S3 system this is the name of the bucket.
Effective root directory
  Directory to be used when listing files or moving files to and from the system.
DTN system Id
  An alternate system to use as a Data Transfer Node (DTN).
DTN mount point
  Mount point (aka target) used when running the mount command on this system.
DTN mount source path
  The path exported by *dtnSystemId* that matches the *dtnMountPoint* on this system. This will be relative to
  *rootDir* on *dtnSystemId*.
isDtn flag
  Indicates if system will be used as a data transfer node (DTN). By default this is *false*.
canExec flag
  Indicates if system can be used to execute jobs.
Job related attributes
  Various attributes related to job execution such as *jobRuntimes*, *jobWorkingDir*, *jobIsBatch*,
  *batchScheduler*, *batchLogicalQueues*

When creating a system the required attributes are: *id*, *systemType*, *host*, *defaultAuthnMethod* and *canExec*.
Depending on the type of system and specific values for certain attributes there are other requirements.

--------------------------------
Getting Started
--------------------------------

Before going into further details about Systems, here we give some examples of how to create and view systems.
In the examples below we assume you are using the TACC tenant with a base URL of ``tacc.tapis.io`` and that you have
authenticated using PySDK or obtained an authorization token and stored it in the environment variable JWT,
or perhaps both.

Creating a System
~~~~~~~~~~~~~~~~~

Create a local file named ``system_s3.json`` with json similar to the following::

  {
    "id":"tacc-bucket-sample-<userid>",
    "description":"My Bucket",
    "host":"https://tapis-sample-test-<userid>.s3.us-east-1.amazonaws.com/",
    "systemType":"S3",
    "defaultAuthnMethod":"ACCESS_KEY",
    "effectiveUserId":"${owner}",
    "bucketName":"tapis-tacc-bucket-<userid>",
    "rootDir":"/",
    "canExec": false,
    "authnCredential":
    {
      "accessKey":"***",
      "accessSecret":"***"
    }
  }

where <userid> is replaced with your user name, your S3 host name is updated appropriately and if desired you have
filled in your access key and secret. Note that credentials are stored in the Security Kernel and may also be set or
updated using a separate API call. However, only specific Tapis services are authorized to retrieve credentials.

Using PySDK:

.. code-block:: python

 import json
 from tapipy.tapis import Tapis
 t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
 with open('system_s3.json', 'r') as openfile:
     my_s3_system = json.load(openfile)
 t.systems.createSystem(**my_s3_system)

Using CURL::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems -d @system_s3.json

Viewing Systems
~~~~~~~~~~~~~~~

Retrieving details for a system
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To retrieve details for a specific system, such as the one above:

Using PySDK:

.. code-block:: python

 t.systems.getSystem(systemId='tacc-bucket-sample-<userid>')

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/tacc-bucket-sample-<userid>

The response should look similar to the following::

 {
    "result": {
        "tenant": "dev",
        "id": "tacc-bucket-sample-<userid>",
        "description": "My Bucket",
        "systemType": "S3",
        "owner": "<userid>",
        "host": "tapis-sample-test-<userid>.s3.us-east-1.amazonaws.com",
        "enabled": true,
        "effectiveUserId": "<userid>",
        "defaultAuthnMethod": "ACCESS_KEY",
        "authnCredential": null,
        "bucketName": "tapis-tacc-bucket-<userid>",
        "rootDir": "/",
        "port": 9000,
        "useProxy": false,
        "proxyHost": "",
        "proxyPort": -1,
        "dtnSystemId": null,
        "dtnMountPoint": null,
        "dtnMountSourcePath": null,
        "isDtn": false,
        "canExec": false,
        "jobRuntimes": [],
        "jobWorkingDir": null,
        "jobEnvVariables": [],
        "jobMaxJobs": 2147483647,
        "jobMaxJobsPerUser": 2147483647,
        "jobIsBatch": false,
        "batchScheduler": null,
        "batchLogicalQueues": [],
        "batchDefaultLogicalQueue": null,
        "jobCapabilities": [],
        "tags": [],
        "notes": {},
        "uuid": "f83606bf-7a1a-4ff0-9953-dd732cc07ac0",
        "deleted": false,
        "created": "2021-04-26T18:45:40.771Z",
        "updated": "2021-04-26T18:45:40.771Z"
    },
    "status": "success",
    "message": "TAPIS_FOUND System found: tacc-bucket-sample-<userid>",
    "version": "0.0.1",
    "metadata": null
 }

Note that authnCredential is *null*. Only specific Tapis services are authorized to retrieve credentials.

Retrieving details for all systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To see the current list of systems that you are authorized to view:

(NOTE: See the section below on searching and filtering to find out how to control the amount of information returned)

Using PySDK:

.. code-block:: python

 t.systems.getSystems()

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?select=allAttributes

The response should contain a list of items similar to the single listing shown above.

-----------------------------------
Minimal Definition and Restrictions
-----------------------------------
When creating a system the required attributes are: *id*, *systemType*, *host*, *defaultAuthnMethod* and *canExec*.
Depending on the type of system and specific values for certain attributes there are other requirements.
The restrictions are:

* If *systemType* is S3 then *bucketName* is required, *canExec* and *isDtn* must be false.
* If *systemType* is LINUX then *rootDir* is required.
* If *effectiveUserId* is ``${apiUserId}`` (i.e. it is not static) then *authnCredential* may not be specified.
* If *isDtn* is true then *canExec* must be false and following may not be specified: *dtnSystemId*, *dtnMountSourcePath*, *dtnMountPoint*, all job execution related attributes.
* If *canExec* is true then *jobWorkingDir* is required and *jobRuntimes* must have at least one entry.
* If *jobIsBatch* is true then *batchScheduler* must be specified.
* If *jobIsBatch* is true then *batchLogicalQueues* must have at least one item.

  * If *batchLogicalQueues* has more than one item then *batchLogicalDefaultQueue* must be specified.
  * If *batchLogicalQueues* has exactly one item then *batchLogicalDefaultQueue* is set to that item.

-----------------
Permissions
-----------------
At system creation time the owner is given full system authorization. If the effective
access user *effectiveUserId* is a specific user (such as a service account) then this
user is given the same authorizations. If the effective access user is the dynamic user
``${apiUserId}`` then the authorizations for each user must be granted and credentials created in separate API calls.
Permissions for a system may be granted and revoked through the systems API. Please
note that grants and revokes through this service only impact the default role for the
user. A user may still have access through permissions in another role. So even after
revoking permissions through this service when permissions are retrieved the access may
still be listed. This indicates access has been granted via another role.

Permissions are specified as either ``*`` for all permissions or some combination of the
following specific permissions: ``("READ","MODIFY","EXECUTE")``. Specifying permissions in all
lower case is also allowed. Having ``MODIFY`` implies ``READ``.

--------------------------
Authentication Credentials
--------------------------
At system creation time the authentication credentials may be specified if the effective
access user *effectiveUserId* is a specific user (such as a service account) and not
a dynamic user, i.e. ``${apiUserId}``. If the effective access user is dynamic then
authentication credentials for any user allowed to access the system must be registered in
separate API calls. Note that the Systems service does not store credentials.
Credentials are persisted by the Security Kernel service and only specific Tapis services
are authorized to retrieve credentials.

--------------------------
Runtime
--------------------------
Runtime environment supported by the system that may be used to run applications, such as docker or singularity.
Consists of the runtime type and version.

--------------------------
Logical Batch Queue
--------------------------
A queue that maps to a single HPC queue. Logical batch queues provide a uniform front end abstraction for an HPC queue.
They also provide more features and flexibility than is typically provided by an HPC scheduler. Multiple logical queues
may be defined for each HPC queue. If an HPC queue does not have a corresponding logical queue defined then a user will
not be able use the Tapis system to directly submit a job via Tapis to that HPC queue.

..
    -----------------
    Capabilities
    -----------------
    In addition to the system capabilities reflected in the basic attributes each system
    definition may contain a list of additional capabilities supported by that system.
    An Application or Job definition may then specify required capabilities. These are
    used for determining eligible systems for running an application or job.

-----------------
Deletion
-----------------
A system may be deleted and undeleted. Deletion means the system is marked as deleted and
is no longer available for use. By default deleted systems will not be included in searches and operations on
deleted systems will not be allowed. When listing systems the query parameter *showDeleted* may be used in order
to include deleted systems in the results.

------------------------
System Attributes Table
------------------------

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| tenant              | String         | designsafe           | - Name of the tenant for which the system is defined.                                |
|                     |                |                      | - *tenant* + *id* must be unique.                                                    |
|                     |                |                      | - Determined by the service at system creation time.                                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| id                  | String         | ds1.storage.default  | - Identifier for the system. URI safe, see RFC 3986.                                 |
|                     |                |                      | - *tenant* + *id* must be unique.                                                    |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| description         | String         | Default storage      | - Description                                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| systemType          | enum           | LINUX                | - Type of system.                                                                    |
|                     |                |                      | - Types: LINUX, S3                                                                   |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| owner               | String         | jdoe                 | - User name of *owner*.                                                              |
|                     |                |                      | - Variable references: *${apiUserId}*                                                |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| host                | String         | data.tacc.utexas.edu | - Host name or ip address of the system                                              |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enabled             | boolean        | FALSE                | - Indicates if system currently enabled for use.                                     |
|                     |                |                      | - May be updated using the enable/disable endpoints.                                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| effectiveUserId     | String         | tg869834             | - User to use when accessing the system.                                             |
|                     |                |                      | - May be a static string or a variable reference.                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*                                    |
|                     |                |                      | - On output variable reference will be resolved.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| defaultAuthnMethod  | enum           | PKI_KEYS             | - How access authentication is handled by default.                                   |
|                     |                |                      | - Can be overridden as part of a request to get a system or credential.              |
|                     |                |                      | - Methods: PASSWORD, PKI_KEYS, ACCESS_KEY                                            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| authnCredential     | Credential     |                      | - On input credentials to be stored in Security Kernel.                              |
|                     |                |                      | - *effectiveUserId* must be static, either a string constant or ${owner}.            |
|                     |                |                      | - May not be specified if *effectiveUserId* is dynamic, i.e. *${apiUserId}*.         |
|                     |                |                      | - On output contains credential for *effectiveUserId* and requested *authnMethod*.   |
|                     |                |                      | - Returned credential contains relevant information based on *authnMethod*.          |
|                     |                |                      | - Credentials may be updated using the systems credentials endpoint.                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| bucketName          | String         | tapis-ds1-jdoe       | - Name of bucket for an S3 system.                                                   |
|                     |                |                      | - Required if *systemType* is S3.                                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| rootDir             | String         | /home/${apiUserId}   | - Required if *systemType* is LINUX or *isDtn* = true. Must be an absolute path.     |
|                     |                |                      | - Serves as effective root directory when listing or moving files.                   |
|                     |                |                      | - For DTN must be source location used in mount command.                             |
|                     |                |                      | - Optional for an S3 system but may be used for a similar purpose.                   |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| port                | int            | 22                   | - Port number used to access the system                                              |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| useProxy            | boolean        | TRUE                 | - Indicates if system should be accessed through a proxy.                            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| proxyHost           | String         |                      | - Name of proxy host.                                                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| proxyPort           | int            |                      | - Port number for *proxyHost*                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| dtnSystemId         | String         | default.corral.dtn   | - An alternate system to use as a Data Transfer Node (DTN).                          |
|                     |                |                      | - This system and *dtnSystemId* must have shared storage.                            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| dtnMountPoint       | String         | /gpfs/corral3/repl   | - Mount point (aka target) used when running the mount command on this system.       |
|                     |                |                      | - Base location on this system for files transferred to *rootDir* on *dtnSystemId.*  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| dtnMountSourcePath  | String         | /gpfs/corral3/repl   | - Relative path defining DTN source directory relative to rootDir on *dtnSystemId.*  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| isDtn               | boolean        | FALSE                | - Indicates if system will be used as a data transfer node (DTN).                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| canExec             | boolean        |                      | - Indicates if system will be used to execute jobs.                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobRuntimes         | [Runtime]      |                      | - List of runtime environments supported by the system.                              |
|                     |                |                      | - At least one entry required if *canExec* is true.                                  |
|                     |                |                      | - Each Runtime specifies the Runtime type and version                                |
|                     |                |                      | - Runtime type is required and must be one of: DOCKER, SINGULARITY.                  |
|                     |                |                      | - Runtime version is optional.                                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobWorkingDir       | String         | HOST_EVAL($SCRATCH)  | - Parent directory from which a job is run.                                          |
|                     |                |                      | - Relative to the effective root directory *rootDir*.                                |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobEnvVariables     | [KeyValuePair] |                      | - Environment variables added to the shell environment in which the job is running.  |
|                     |                |                      | - Added to environment variables specified in job and application definitions.       |
|                     |                |                      | - Will overwrite job and application variables with same names.                      |
|                     |                |                      | - Each entry has a *key* (required) and a *value* (optional)                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobMaxJobs          | int            |                      | - Max total number of jobs .                                                         |
|                     |                |                      | - Set to -1 for unlimited.                                                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobMaxJobsPerUser   | int            |                      | - Max total number of jobs associated with a specific user.                          |
|                     |                |                      | - Set to -1 for unlimited.                                                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobIsBatch          | boolean        |                      | - Indicates if system uses a batch scheduler to run jobs.                            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| batchScheduler      | String         | SLURM                | - Type of scheduler used when running batch jobs.                                    |
|                     |                |                      | - Schedulers: SLURM                                                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| batchLogicalQueues  | [LogicalQueue] |                      | - List of logical queues available on the system.                                    |
|                     |                |                      | - Each logical queue maps to a single HPC queue.                                     |
|                     |                |                      | - Multiple logical queues may be defined for each HPC queue.                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
|batchDefaultLogical  | LogicalQueue   |                      | - Default logical batch queue for the system.                                        |
|Queue                |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tags                | [String]       |                      | - List of tags as simple strings.                                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String         | "{}"                 | - Simple metadata in the form of a Json object.                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| uuid                | UUID           |                      | - Auto-generated by service.                                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| deleted             | boolean        | FALSE                | - Indicates if system has been deleted.                                              |
|                     |                |                      | - May be updated using the delete/undelete endpoints.                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| created             | Timestamp      | 2020-06-19T15:10:43Z | - When the system was created. Maintained by service.                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| updated             | Timestamp      | 2020-07-04T23:21:22Z | - When the system was last updated. Maintained by service.                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

..
    | jobCapabilities     | [Capability]   |                      | - List of additional job related capabilities supported by the system.               |
    +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

---------------------------
Credential Attributes Table
---------------------------

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| user                | String         | jsmith               | - User name associated with the credential.                                          |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| authnMethod         | String         | PKI_KEYS             | - Indicates the authentication method associated with a retrieved credential.        |
|                     |                |                      | - When a credential is retrieved it is for a specific authentication method.         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| password            | String         |                      | - Password for when authnMethod is PASSWORD.                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| privateKey          | String         |                      | - Private key for when authnMethod is PKI_KEYS.                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| publicKey           | String         |                      | - Public key for when authnMethod is PKI_KEYS.                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| accessKey           | String         |                      | - Access key used to authenticate to an S3 system.                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| accessSecret        | String         |                      | - Access secret used to authenticate to an S3 system.                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

-----------------------------
LogicalQueue Attributes Table
-----------------------------

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| name                | String         |                      | - Name of the tenant for which the system is defined.                                |
|                     |                |                      | - *tenant* + *id* must be unique.                                                    |
|                     |                |                      | - Determined by the service at system creation time.                                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| hpcQueueName        | String         |                      | - Identifier for the system. URI safe, see RFC 3986.                                 |
|                     |                |                      | - *tenant* + *id* must be unique.                                                    |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobs             | int            |                      | - Maximum total number of jobs that can be queued or running in this queue.          |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobsPerUser      | int            |                      | - Maximum number of jobs associated with a specific user that can be queued.         |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| minNodeCount        | int            |                      | - Minimum number of nodes that can be requested when submitting a job to the queue.  |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxNodeCount        | int            |                      | - Maximum number of nodes that can be requested when submitting a job to the queue.  |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| minCoresPerNode     | int            |                      | - Minimum number of cores per node that can be requested when submitting a job.      |
|                     |                |                      | - Default is 1                                                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxCoresPerNode     | int            |                      | - Maximum number of cores per node that can be requested when submitting a job.      |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| minMemoryMB         | int            |                      | - Minimum memory in megabytes that can be requested when submitting a job.           |
|                     |                |                      | - Default is 0                                                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxMemoryMB         | int            |                      | - Maximum memory in megabytes that can be requested when submitting a job.           |
|                     |                |                      | - Default is unlimited                                                               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| minMinutes          | int            |                      | - Minimum run time in minutes that can be requested when submitting a job.           |
|                     |                |                      | - Default is 0                                                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxMinutes          | int            |                      | - Maximum run time in minutes that can be requested when submitting a job.           |
|                     |                |                      | - Default is unlimited                                                               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

..
    ---------------------------
    Capability Attributes Table
    ---------------------------
..
  +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
  | Attribute           | Type           | Example              | Notes                                                                                |
  +=====================+================+======================+======================================================================================+
  | category            | enum           |                      | - Category for grouping of capabilities                                              |
  |                     |                |                      | - Types: SCHEDULER, OS, HARDWARE, SOFTWARE, JOB, CONTAINER, MISC, CUSTOM             |
  +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
  | name                | String         |                      | - Name for the capability                                                            |
  +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
  | datatype            | enum           |                      | - Datatype for the value. Used for comparison operations and validation.             |
  |                     |                |                      | - Types: STRING, INTEGER, BOOLEAN, NUMBER, TIMESTAMP                                 |
  +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
  | precedence          | int            |                      | - Precedence. Can be used when multiple systems match. 1 is lowest                   |
  |                     |                |                      | - Higher value has higher precedence. Default is 100.                                |
  |                     |                |                      | - Default is 100.                                                                    |
  +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
  | value               | String         |                      | - Value or range of values.                                                          |
  +---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

-----------------------
Searching
-----------------------
The service provides a way for users to search for systems based on a list of search conditions provided either as query
parameters for a GET call or a list of conditions in a request body for a POST call to a dedicated search endpoint.

Search using GET
~~~~~~~~~~~~~~~~
To search when using a GET request to the ``systems`` endpoint a list of search conditions may be specified
using a query parameter named ``search``. Each search condition must be surrounded with parentheses, have three parts
separated by the character ``.`` and be joined using the character ``~``.
All conditions are combined using logical AND. The general form for specifying the query parameter is as follows::

  ?search=(<attribute_1>.<op_1>.<value_1>)~(<attribute_2>.<op_2>.<value_2>)~ ... ~(<attribute_N>.<op_N>.<value_N>)

Attribute names are given in the table above and may be specified using Camel Case or Snake Case.

Supported operators: ``eq`` ``neq`` ``gt`` ``gte`` ``lt`` ``lte`` ``in`` ``nin`` ``like`` ``nlike`` ``between`` ``nbetween``

For more information on search operators, handling of timestamps, lists, quoting, escaping and other general information on
search please see <TBD>.

Example CURL command to search for systems that have ``Test`` in the id, are of type LINUX,
are using a port less than ``1024`` and have a default authentication method of either ``PKI_KEYS`` or ``PASSWORD``::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?search="(id.like.*Test*)~(system_type.eq.LINUX)~(port.lt.1024)~(DefaultAuthnMethod.in.PKI_KEYS,PASSWORD)"

Notes:

* For the ``like`` and ``nlike`` operators the wildcard character ``*`` matches zero or more characters and ``!`` matches exactly one character.
* For the ``between`` and ``nbetween`` operators the value must be a two item comma separated list of unquoted values.
* If there is only one condition the surrounding parentheses are optional.
* In a shell environment the character ``&`` separating query parameters must be escaped with a backslash.
* In a shell environment the query value must be surrounded by double quotes and the following characters must be escaped with a backslash in order to be properly interpreted by the shell:

  * ``"`` ``\`` `````

* Attribute names may be specified using Camel Case or Snake Case.

* Following complex attributes not supported when searching:

   * ``authnCredential`` ``jobRuntimes`` ``jobEnvVariables`` ``batchLogicalQueues``  ``tags``  ``notes``

Dedicated Search Endpoint
~~~~~~~~~~~~~~~~~~~~~~~~~
The service provides the dedicated search endpoint ``systems/search/systems`` for specifying complex queries. Using a GET
request to this endpoint provides functionality similar to above but with a different syntax. For more complex
queries a POST request may be used with a request body specifying the search conditions using an SQL-like syntax.

Search using GET on Dedicated Endpoint
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Sending a GET request to the search endpoint provides functionality very similar to that provided for the endpoint
``systems`` described above. A list of search conditions may be specified using a series of query parameters, one for each attribute.
All conditions are combined using logical AND. The general form for specifying the query parameters is as follows::

  ?<attribute_1>.<op_1>=<value_1>&<attribute_2>.<op_2>=<value_2>)& ... &<attribute_N>.<op_N>=<value_N>

Attribute names are given in the table above and may be specified using Camel Case or Snake Case.

Supported operators: ``eq`` ``neq`` ``gt`` ``gte`` ``lt`` ``lte`` ``in`` ``nin`` ``like`` ``nlike`` ``between`` ``nbetween``

For more information on search operators, handling of timestamps, lists, quoting, escaping and other general information on
search please see <TBD>.

Example CURL command to search for systems that have ``Test`` in the name, are of type ``LINUX``,
are using a port less than ``1024`` and have a default authentication method of either ``PKI_KEYS`` or ``PASSWORD``::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/search/systems?name.like=*Test*\&enabled.eq=true\&system_type.eq=LINUX\&DefaultAuthnMethod.in=PKI_KEYS,PASSWORD

Notes:

* For the ``like`` and ``nlike`` operators the wildcard character ``*`` matches zero or more characters and ``!`` matches exactly one character.
* For the ``between`` and ``nbetween`` operators the value must be a two item comma separated list of unquoted values.
* In a shell environment the character ``&`` separating query parameters must be escaped with a backslash.
* Attribute names may be specified using Camel Case or Snake Case.
* Following complex attributes not supported when searching:

  * ``authnCredential`` ``jobRuntimes`` ``jobEnvVariables`` ``batchLogicalQueues``  ``tags``  ``notes``

Search using POST on Dedicated Endpoint
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
More complex search queries are supported when sending a POST request to the endpoint ``systems/search/systems``.
For these requests the request body must contain json with a top level property name of ``search``. The
``search`` property must contain an array of strings specifying the search criteria in
an SQL-like syntax. The array of strings are concatenated to form the full search query.
The full query must be in the form of an SQL-like ``WHERE`` clause. Note that not all SQL features are supported.

For example, to search for systems that are owned by ``jdoe`` and of type ``LINUX`` or owned by
``jsmith`` and using a port less than ``1024`` create a local file named ``system_search.json``
with following json::

  {
    "search":
      [
        "(owner = 'jdoe' AND system_type = 'LINUX') OR",
        "(owner = 'jsmith' AND port < 1024)"
      ]
  }

To execute the search use a CURL command similar to the following::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/search/systems -d @system_search.json

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

-----------------------
Sort, Limit and Select
-----------------------
When a list of Systems is being retrieved the service provides for sorting and limiting the results. When retrieving
either a list of resources or a single resource the service also provides a way to *select* which fields (i.e.
attributes) are included in the results. Sorting, limiting and attribute selection are supported using query parameters.

Selecting
~~~~~~~~~
When retrieving systems the fields (i.e. attributes) to be returned may be specified as a comma separated list using
a query parameter named ``select``. Attribute names may be given using Camel Case or Snake Case.

Notes:

 * Special select keywords are supported: ``allAttributes`` and ``summaryAttributes``
 * Summary attributes include:

   * ``id``, ``systemType``, ``owner``, ``host``, ``effectiveUserId``, ``defaultAuthnMethod``, ``canExec``

 * By default all attributes are returned when retrieving a single resource via the endpoint systems/<system_id>.
 * By default summary attributes are returned when retrieving a list of systems.
 * Specifying nested attributes is not supported.
 * The attribute ``id`` is always returned.

For example, to return only the attributes ``host`` and ``effectiveUserId`` the
CURL command would look like this::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?select=host,effectiveUserId

The response should look similar to the following::

 {
  "result": [
        {
            "id": "CSys_CltSrchGet_011",
            "host": "hostCltSrchGet_011",
            "effectiveUserId": "effUserCltSrchGet_011"
        },
        {
            "id": "CSys_CltSrchGet_012",
            "host": "hostCltSrchGet_012",
            "effectiveUserId": "effUserCltSrchGet_012"
        },
        {
            "id": "CSys_CltSrchGet_013",
            "host": "hostCltSrchGet_013",
            "effectiveUserId": "effUserCltSrchGet_013"
        }
    ],
    "status": "success",
    "message": "TAPIS_FOUND Systems found: 12 systems",
    "version": "0.0.1-SNAPSHOT",
    "metadata": {
        "recordCount": 3,
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

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?limit=2&orderBy=id(desc)

Response::

 {
  "result": [
    {
      "id": "testMin0",
      "systemType": "S3",
      "owner": "testuser",
      "host": "my.example.host",
      "defaultAccessMethod": "ACCESS_KEY",
      "canExec": false
    },
    {
      "id": "MinSystem1c",
      "systemType": "LINUX",
      "owner": "testuser",
      "defaultAccessMethod": "PASSWORD",
      "host": "data.tacc.utexas.edu",
      "canExec": true
    }
  ],
  "status": "success",
  "message": "TAPIS_FOUND Systems found: 2 systems",
  "version": "0.0.1-SNAPSHOT",
  "metadata": {
    "recordCount": 2,
    "recordLimit": 2,
    "recordsSkipped": 0,
    "orderBy": "id(desc)",
    "startAfter": null,
    "totalCount": -1
  }

Heading 2
~~~~~~~~~

Heading 3
^^^^^^^^^

Heading 4
*********
