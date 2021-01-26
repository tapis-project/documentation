.. _apps:

=======================================
Applications
=======================================
**WORK IN PROGRESS**

In order to run a job on a system you will need to create or have access to a Tapis *application*.

-----------------
Overview
-----------------
A Tapis application represents all the information required to run a Tapis job on a Tapis system
and produce useful results. Each application is versioned and is associated with a specific tenant and owned by a
specific user who has special privileges for the application.

At a high level an application contains the following information:

Id
  A short descriptive name for the application that is unique within the tenant.
Version
  Applications are expected to evolve over time. Id + version must be unique within a tenant.
Description
  An optional more verbose description for the application.
Type of application
  DIRECT or FORK
Owner
  A specific user set at application creation. By default this is ``${apiUserId}``, the user making the request to
  create the application.
Enabled flag
  Indicates if application is currently considered active and available for use.
  By default the application is enabled when first created.
Containerized flag
  Indicates if application has been fully containerized. Default is true.
Runtime
  Runtime to be used when executing the application. DOCKER, SINGULARITY. Default is DOCKER.
Runtime version
  Runtime version to be used when executing the application.
Container image
  Reference to be used when running the container image. Required if *containerized* is true.
Interactive flag
  Indicates if the application is interactive. Default is false.
Max jobs
  Maximum total number of jobs that can be queued or running for this application on a given execution system at
  a given time. Note that the execution system may also limit the number of jobs on the system which may further
  restrict the total number of jobs. Set to -1 for unlimited. Default is unlimited.
Max jobs per user
  Maximum total number of jobs associated with a specific job owner that can be queued or running for this application
  on a given execution system at a given time. Note that the execution system may also limit the number of jobs on the
  system which may further restrict the total number of jobs. Set to -1 for unlimited. Default is unlimited.
Strict file inputs flag
  Indicates if a job request is allowed to have unnamed file inputs. If value is true then a job request may only use
  the named file inputs defined in the application. Default is false.
Job related attributes
  Various attributes related to job execution such as *jobDescription*, *execSystemId*, *execSystemExecDir*,
  *execSystemInputDir*, *appArgs*, *fileInputs*, etc.

When creating a application the required attributes are: *id*, *version* and *appType*.
Depending on the type of application and specific values for certain attributes there are other requirements.

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
    "id":"tacc-sample-ls5-<userid>",
    "version":"0.1",
    "appType":"FORK",
    "description":"My sample Lonestar5 application",
    "runtime":"DOCKER",
    "containerImage":"docker.io/hello-world:latest",
    "jobAttributes": {
      "description": "default job description",
      "execSystemId": "execsystem1"
    }
  }

where <userid> is replaced with your user name.

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

Using PySDK:

.. code-block:: python

 t.apps.getAppLatestVersion(appId='tacc-sample-ls5-<userid>')

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps/tacc-sample-ls5-<userid>?pretty=true

The response should look similar to the following::

 {
    "message": "TAPIS_FOUND App found: tacc-sample-ls5-<userid>",
    "result": {
        "?????????????????????": "???????",
        "description": "??????????",
        "enabled": true,
        "id": "tacc-bucket-sample-<userid>",
        "notes": {},
        "owner": "<userid>",
        "refImportId": null,
        "seqId": 2,
        "appType": "FORK",
        "tags": [],
        "tenant": "dev"
    },
    "status": "success",
    "version": "0.0.1"
 }

TBD Note that TBD .

Retrieving details for all applications
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To see the current list of applications that you are authorized to view:

.. comment
.. comment (NOTE: See the section below on searching and filtering to find out how to control the amount of information returned)

Using PySDK:

.. code-block:: python

 t.apps.getApps()

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps?pretty=true

The response should contain a list of items similar to the single listing shown above.

-----------------
Minimal Definition and Restrictions
-----------------
When creating an application the required attributes are: *id*, *systemType*, *host*, *defaultAuthnMethod* and *canExec*.
Depending on the type of application and specific values for certain attributes there are other requirements.
The restrictions are:

* If *containerized* is true then

  * Must be specified: *containerImage*
  * May not be specified: *command*, *execCodes*

* If *containerized* is false then

  * Must be specified: *command*, *execCodes*
  * May not be specified: *containerImage*

* If *dynamicExecSystem* is true then *execSystemConstraints* is required.
* If *archiveSystemId* is specified then *archiveSystemDir* is required.
* If *appType* is FORK then the following attributes may not be specified: *maxJobs*, *maxJobsPerUser*, *nodeCount*,
  *coresPerNode*, *memoryMB*, *maxMinutes*.

------------------
Version
------------------
Versioning scheme is at the discretion of the application author. The combination of tenant+id+version uniquely
identifies an application in the Tapis environment. It is recommended that a two or three level form of
semantic versioning be used. The fully qualified application reference within a tenant is constructed by appending
a hyphen to the name followed by the version string. For example, the first two versions of an application might
be myapp-0.0.1 and myapp-0.0.2. If a version is not specified when retrieving an application then by default the most
recently created version of the application will be returned.

-----------------
Containerized Application
-----------------
An application that has been containerized is one that can be executed using a single container image. When the flag
*containerized* is set to true then the *containerImage* attribute must be specified. Tapis will use the appropriate
container runtime command and provide support for making the input and output directories available to the container
when running the container image.

-----------------
Non-containerized Application
-----------------
An application that has not yet been containerized can still be run via Tapis but it will most likely be less portable.
When the flag *containerized* is set to false then the *command* and *execCodes* attributes must be specified. Tapis
will stage the *execCodes* files to *execSystemExecDir* and use *command* to launch the application. Note that command
must be available after staging of *execCodes*.

-----------------
Permissions
-----------------
At application creation time the owner is given full authorization. Authorizations for other users must be granted
in separate API calls.
Permissions may be granted and revoked through the applications API. Please
note that grants and revokes through this service only impact the default role for the
user. A user may still have access through permissions in another role. So even after
revoking permissions through this service when permissions are retrieved the access may
still be listed. This indicates access has been granted via another role.

Permissions are specified as either ``*`` for all permissions or some combination of the
following specific permissions: ``("READ","MODIFY","EXECUTE")``. Specifying permissions in all
lower case is also allowed.

-----------------
Deletion
-----------------
An application may be soft deleted. Soft deletion means the application is marked as deleted and
is no longer available for use. It will no longer show up in searches and operations on
the application will no longer be allowed. The application definition is retained for auditing
purposes. Note this means that application IDs may not be re-used after deletion.

------------------------
Table of Attributes
------------------------

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| tenant              | String         | designsafe           | - Name of the tenant for which the application is defined.                           |
|                     |                |                      | - *tenant* + $version* + *name* must be unique.                                      |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| id                  | String         | ds1.storage.default  | - Name of the application. URI safe, see RFC 3986.                                   |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| version             | String         | 0.0.1                | - Version of the application. URI safe, see RFC 3986.                                |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| description         | String         | Default storage      | - Description                                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| appType             | enum           | LINUX                | - Type of application.                                                               |
|                     |                |                      | - Types: BATCH, FORK                                                                 |
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
