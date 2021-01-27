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
  BATCH or FORK
Owner
  A specific user set at application creation. Default is ``${apiUserId}``, the user making the request to
  create the application.
Enabled flag
  Indicates if application is currently considered active and available for use. Default is true.
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
  *execSystemInputDir*, *execSystemLogicalQueue* *appArgs*, *fileInputs*, etc.

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
    "id":"tacc-sample-app-<userid>",
    "version":"0.1",
    "appType":"FORK",
    "description":"My sample application",
    "runtime":"DOCKER",
    "containerImage":"docker.io/hello-world:latest",
    "jobAttributes": {
      "description": "default job description",
      "execSystemId": "execsystem1"
    }
  }

where <userid> is replaced with your user name and *execSystemId* must already exist.

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

 t.apps.getAppLatestVersion(appId='tacc-sample-app-<userid>')

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/apps/tacc-sample-app-<userid>?pretty=true

The response should look similar to the following::

 {
    "message": "TAPIS_FOUND App found: tacc-sample-app-<userid>",
    "result": {
        "?????????????????????": "???????",
        "description": "??????????",
        "enabled": true,
        "id": "tacc-sample-app-<userid>",
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
When creating an application the required attributes are: *id*, *version* and *appType*.
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
*containerized* is set to true then the attribute *containerImage* must be specified. Tapis will use the appropriate
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
Directory Semantics and Macros
-----------------
At job submission time the Jobs service supports the use of macros based on template variables. These variables may be
referenced when specifying directories in an application definition. For a full list of supported variables please see
the Jobs Service. Here are some examples of variables that may be used when specifying directories for an application:

* *jobId* - The Id of the job determined at job submission.
* *jobOwner* - The owner of the job determined at job submission.
* *jobWorkingDir* - Default parent directory from which a job is run. This will be relative to the effective root
  directory *rootDir* on the execution system. *rootDir* and *jobWorkingDir* are attributes of the execution system.
* *HOST_EVAL($<ENV_VARIABLE>)* - The value of the environment variable *ENV_VARIABLE* when evaluated on the execution
  system host when logging in under the job's effective user ID. This is a dynamic value determined at job submission
  time. The function *HOST_EVAL()* extracts specific environment variable values for use during job setup. In
  particular, the TACC specific values of *$HOME*, *$WORK*, *$SCRATCH* and *$FLASH* can be referenced. The specified
  environment variable name is used **as-is**. It is **not** subject to macro substitution. However, the function call
  can have a path string appended to it, such as in *HOST_EVAL($SCRATCH)/tmp/${jobId}*, and macro substitution will be
  applied to the path string.

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
| id                  | String         | my-ds-app            | - Name of the application. URI safe, see RFC 3986.                                   |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| version             | String         | 0.0.1                | - Version of the application. URI safe, see RFC 3986.                                |
|                     |                |                      | - *tenant* + $version* + *id* must be unique.                                        |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| description         | String         | A sample application | - Description                                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| appType             | enum           | BATCH                | - Type of application.                                                               |
|                     |                |                      | - Types: BATCH, FORK                                                                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| owner               | String         | jdoe                 | - User name of *owner*. Default is *${apiUserId}*.                                   |
|                     |                |                      | - Variable references: *${apiUserId}*                                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enabled             | boolean        | FALSE                | - Indicates if application currently enabled for use. Default is TRUE.               |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| containerized       | boolean        | TRUE                 | - Indicates if application has been fully containerized. Default is TRUE.            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| runtime             | enum           | SINGULARITY          | - Runtime to be used when executing the application. Default is DOCKER.              |
|                     |                |                      | - Runtimes: DOCKER, SINGULARITY                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| runtimeVersion      | String         | 2.5.2                | - Version or range of versions required.                                             |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| containerImage      | String         |docker.io/hello-world | - Reference for the container image. Other examples:                                 |
|                     |                |                      | - Singularity: shub://GodloveD/lolcow                                                |
|                     |                |                      | - Docker: tapis/hello-tapis:0.0.1                                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| isInteractive       | boolean        | FALSE                | - Indicates if application is interactive. Default is FALSE.                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| command             | String         | runMyApp.sh          | - Primary command to execute when running a non-containerized application.           |
|                     |                |                      | - Must be available after staging of *execCodes*.                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| execCodes           | [FileInput]    |                      | - Collection of binary executable and script files that must be in place.            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobs             | int            | 10                   | - Max number of jobs that can be running for this app on an exec system.             |
|                     |                |                      | - Execution system may also limit the number of jobs on the system.                  |
|                     |                |                      | - Set to -1 for unlimited. Default is unlimited.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobsPerUser      | int            | 2                    | - Max number of jobs per job owner.                                                  |
|                     |                |                      | - Execution system may also limit the number of jobs on the system.                  |
|                     |                |                      | - Set to -1 for unlimited. Default is unlimited.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| strictFileInputs    | boolean        | FALSE                | - Indicates if a job request is allowed to have unnamed file inputs.                 |
|                     |                |                      | - If TRUE then a job request may only use named file inputs defined in the app.      |
|                     |                |                      | - Default is FALSE.                                                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobAttributes       | JobAttributes  |                      | - See table below.                                                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tags                | [String]       |                      | - List of tags as simple strings.                                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String         | "{}"                 | - Simple metadata in the form of a Json object.                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| seqId               | int            | 20281                | - Auto-generated by service.                                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| created             | Timestamp      | 2020-06-19T15:10:43Z | - When the app was created. Maintained by service.                                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| updated             | Timestamp      | 2020-07-04T23:21:22Z | - When the app was last updated. Maintained by service.                              |
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
