.. _systems:

=======================================
Systems
=======================================

**WORK IN PROGRESS**

Once you are authorized to make calls to the various services, one of first
things you may want to do is view storage and execution resources available
to you or create your own. In Tapis a storage or execution resource is referred
to as a *system*.

-----------------
Overview
-----------------
A Tapis system represents a server or collection of servers exposed through a
single host name or IP address. Each system is associated with a specific tenant.
A system can be used for the following purposes:

* Running a job, including:

  * Staging files to an execution system in preparation for running a job.
  * Executing a job on an execution system.
  * Archiving files and data on a remote storage system after job execution.

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
  LINUX or OBJECT_STORE
Owner
  A specific user set at system creation. By default this is ``${apiUserId}``, the user making the request to
  create the system.
Host name or IP address.
  FQDN or IP address
Enabled flag
  Indicates if system is currently considered active and available for use. Default is true.
Effective User
  The user name to use when accessing the system. Referred to as *effectiveUserId.*
  A specific user (such as a service account) or the dynamic user ``${apiUserId}``
Default authorization method
  How access authorization is handled by default. Authorization method can also be
  specified as part of a request.
  Supported methods: PASSWORD, PKI_KEYS, ACCESS_KEY.
Bucket name
  For an object storage system this is the name of the bucket.
Effective root directory
  Directory to be used when listing files or moving files to and from the system.
Transfer methods
  Supported methods for moving files or objects to and from the system. Allowable entries are determined by the system
  type. Initially supported: SFTP, S3.
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
  *batchScheduler*, *batchLogicalQueues* and *jobCapabilities*

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
    "systemType":"OBJECT_STORE",
    "defaultAuthnMethod":"ACCESS_KEY",
    "effectiveUserId":"${owner}",
    "bucketName":"tapis-tacc-bucket-<userid>",
    "rootDir":"/",
    "canExec": false,
    "transferMethods":["S3"],
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

 t.systems.getSystemById(systemId='tacc-bucket-sample-<userid>')

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/tacc-bucket-sample-<userid>?pretty=true

The response should look similar to the following::

 {
    "message": "TAPIS_FOUND System found: tacc-bucket-sample-<userid>",
    "result": {
        "authnCredential": null,
        "batchDefaultLogicalQueue": null,
        "batchLogicalQueues": [],
        "batchScheduler": null,
        "bucketName": "tapis-tacc-bucket-<userid>",
        "canExec": false,
        "defaultAuthnMethod": "ACCESS_KEY",
        "description": "My Bucket",
        "dtnMountPoint": null,
        "dtnMountSourcePath": null,
        "dtnSystemId": null,
        "effectiveUserId": "<userid>",
        "enabled": true,
        "host": "https://tapis-sample-test-<userid>.s3.us-east-1.amazonaws.com/",
        "id": "tacc-bucket-sample-<userid>",
        "isDtn": false,
        "jobCapabilities": [],
        "jobEnvVariables": [],
        "jobIsBatch": false,
        "jobMaxJobs": -1,
        "jobMaxJobsPerUser": -1,
        "jobRuntimes": [],
        "jobWorkingDir": null,
        "notes": {},
        "owner": "<userid>",
        "port": -1,
        "proxyHost": "",
        "proxyPort": -1,
        "refImportId": null,
        "rootDir": "/",
        "seqId": 2,
        "systemType": "OBJECT_STORE",
        "tags": [],
        "tenant": "dev",
        "transferMethods": [
            "S3"
        ],
        "useProxy": false
    },
    "status": "success",
    "version": "0.0.1"
 }

Note that authnCredential is null. Only specific Tapis services are authorized to retrieve credentials.

Retrieving details for all systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To see the current list of systems that you are authorized to view:

.. comment
.. comment (NOTE: See the section below on searching and filtering to find out how to control the amount of information returned)

Using PySDK:

.. code-block:: python

 t.systems.getSystems()

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?pretty=true

The response should contain a list of items similar to the single listing shown above.

-----------------
Minimal Definition and Restrictions
-----------------
When creating a system the required attributes are: *id*, *systemType*, *host*, *defaultAuthnMethod* and *canExec*.
Depending on the type of system and specific values for certain attributes there are other requirements.
The restrictions are:

* If *systemType* is OBJECT_STORE then *bucketName* is required and *canExec* must be false.
* If *systemType* is LINUX then *rootDir* is required.
* If *effectiveUserId* is ``${apiUserId}`` (i.e. it is not static) then *authnCredential* may not be specified.
* If *isDtn* is true then *canExec* must be false and following may not be specified: *dtnSystemId*, *dtnMountSourcePath*, *dtnMountPoint*, all job execution related attributes.
* Allowable entries for transferMethods vary by the *systemType*.
* If *canExec* is true then *jobWorkingDir* is required and *jobRuntimes* must have at least one entry.
* If *jobIsBatch* is true then *batchScheduler* must be specified.
* If *jobIsBatch* is true and the *batchLogicalQueues* list is not empty then *batchLogicalDefaultQueue* must be specified.

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
lower case is also allowed.

------------------
Authorization Credentials
------------------
At system creation time the authorization credentials may be specified if the effective
access user *effectiveUserId* is a specific user (such as a service account) and not
a dynamic user, i.e. ``${apiUserId}``. If the effective access user is dynamic then
authorization credentials for any user allowed to access the system must be registered in
separate API calls. Note that the Systems service does not store credentials.
Credentials are persisted by the Security Kernel service and only specific Tapis services
are authorized to retrieve credentials.

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
A system may be soft deleted. Soft deletion means the system is marked as deleted and
is no longer available for use. It will no longer show up in searches and operations on
the system will no longer be allowed. The system definition is retained for auditing
purposes. Note this means that system IDs may not be re-used after deletion.

------------------------
Table of Attributes
------------------------

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| tenant              | String         | designsafe           | - Name of the tenant for which the system is defined.                                |
|                     |                |                      | - *tenant* + *name* must be unique.                                                  |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| id                  | String         | ds1.storage.default  | - Name of the system. URI safe, see RFC 3986.                                        |
|                     |                |                      | - *tenant* + *id* must be unique.                                                    |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| description         | String         | Default storage      | - Description                                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| systemType          | enum           | LINUX                | - Type of system.                                                                    |
|                     |                |                      | - Types: LINUX, OBJECT_STORE                                                         |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| owner               | String         | jdoe                 | - User name of *owner*.                                                              |
|                     |                |                      | - Variable references: *${apiUserId}*                                                |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| host                | String         | data.tacc.utexas.edu | - Host name or ip address of the system                                              |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enabled             | boolean        | FALSE                | - Indicates if system currently enabled for use.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| effectiveUserId     | String         | tg869834             | - User to use when accessing the system.                                             |
|                     |                |                      | - May be a static string or a variable reference.                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*                                    |
|                     |                |                      | - On output variable reference will be resolved.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| defaultAuthnMethod  | enum           | PKI_KEYS             | - How access authorization is handled by default.                                    |
|                     |                |                      | - Can be overridden as part of a request to get a system or credentials.             |
|                     |                |                      | - Methods: PASSWORD, PKI_KEYS, ACCESS_KEY                                            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| authnCredential     | Credential     |                      | - On input credentials to be stored in Security Kernel.                              |
|                     |                |                      | - *effectiveUserId* must be static, either a string constant or ${owner}.            |
|                     |                |                      | - May not be specified if *effectiveUserId* is dynamic, i.e. *${apiUserId}*.         |
|                     |                |                      | - On output contains credentials for *effectiveUserId*.                              |
|                     |                |                      | - Returned credentials contain relevant information based on *systemType*.           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| bucketName          | String         | tapis-ds1-jdoe       | - Name of bucket for OBJECT_STORAGE system.                                          |
|                     |                |                      | - Required if *systemType* is OBJECT_STORAGE.                                        |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| rootDir             | String         | $HOME                | - Required if *systemType* is LINUX or *isDtn* = true. Must be an absolute path.     |
|                     |                |                      | - Serves as effective root directory when listing or moving files.                   |
|                     |                |                      | - For DTN must be source location used in mount command.                             |
|                     |                |                      | - Optional for an OBJECT_STORE system but may be used for a similar purpose.         |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| transferMethods     | [enum]         |                      | - Supported methods for moving files or objects to and from the system.              |
|                     |                |                      | - Allowable entries are determined by *systemType*.                                  |
|                     |                |                      | - Methods: SFTP, S3                                                                  |
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
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobWorkingDir       | String         | HOST_EVAL($SCRATCH)  | - Parent directory from which a job is run.                                          |
|                     |                |                      | - Relative to the effective root directory *rootDir*.                                |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobEnvVariables     | [String]       |                      | - Environment variables added to the shell environment in which the job is running.  |
|                     |                |                      | - Added to environment variables specified in job and application definitions.       |
|                     |                |                      | - Will overwrite job and application variables with same names.                      |
|                     |                |                      | - Each string in the list must have the format *<env_name>=<env_value>*              |
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
| jobCapabilities     | [Capability]   |                      | - List of additional job related capabilities supported by the system.               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tags                | [String]       |                      | - List of tags as simple strings.                                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String         | "{}"                 | - Simple metadata in the form of a Json object.                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| seqId               | int            | 20281                | - Auto-generated by service.                                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| created             | Timestamp      | 2020-06-19T15:10:43Z | - When the system was created. Maintained by service.                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| updated             | Timestamp      | 2020-07-04T23:21:22Z | - When the system was last updated. Maintained by service.                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

-----------------------
Searching
-----------------------
The service provides a way for users to search for systems based on a list of search conditions.

.. comment The service provides a way for users to search for systems based on a list of search conditions and to filter
.. comment (i.e. select) which attributes are returned with the results. Searching and filtering can be combined.

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
are using a port less than ``1024`` and have a default authorization method of either ``PKI_KEYS`` or ``PASSWORD``::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?search="(id.like.*Test*)~(system_type.eq.LINUX)~(port.lt.1024)~(DefaultAuthnMethod.in.PKI_KEYS,PASSWORD)"

Notes:

* For the ``like`` and ``nlike`` operators the wildcard character ``*`` matches zero or more characters and ``!`` matches exactly one character.
* For the ``between`` and ``nbetween`` operators the value must be a two item comma separated list of unquoted values.
* If there is only one condition the surrounding parentheses are optional.
* In a shell environment the character ``&`` separating query parameters must be escaped with a backslash.
* In a shell environment the query value must be surrounded by double quotes and the following characters must be escaped with a backslash in order to be properly interpreted by the shell:  ``"`` ``\`` `````
* Attribute names may be specified using Camel Case or Snake Case.
* Following complex attributes not supported when searching: ``authnCredential`` ``transferMethods`` ``jobCapabilities`` ``tags``  ``notes``


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
are using a port less than ``1024`` and have a default authorization method of either ``PKI_KEYS`` or ``PASSWORD``::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/search/systems?name.like=*Test*\&enabled.eq=true\&system_type.eq=LINUX\&DefaultAuthnMethod.in=PKI_KEYS,PASSWORD

Notes:

* For the ``like`` and ``nlike`` operators the wildcard character ``*`` matches zero or more characters and ``!`` matches exactly one character.
* For the ``between`` and ``nbetween`` operators the value must be a two item comma separated list of unquoted values.
* In a shell environment the character ``&`` separating query parameters must be escaped with a backslash.
* Attribute names may be specified using Camel Case or Snake Case.
* Following complex attributes not supported when searching: ``authnCredential`` ``transferMethods`` ``jobCapabilities`` ``tags``  ``notes``

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


Filter using GET
~~~~~~~~~~~~~~~~
TBD


Heading 2
~~~~~~~~~

Heading 3
^^^^^^^^^

Heading 4
*********
