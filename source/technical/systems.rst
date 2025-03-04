..
    Comment: Hierarchy of headers:
    1: === over and under
    2: --- over and under
    3: ~~~ under
    4: ^^^ under

.. _systems:

=======================================
Systems
=======================================

Once you are authorized to make calls to the various services, one of first things you may want to do is view
storage and execution resources available to you or create your own. In Tapis a storage or execution resource
is referred to as a **system**.

.. _systems_overview:

-----------------
Overview
-----------------

A Tapis system represents a server or collection of servers exposed through a single host name or IP address.
Each system is associated with a specific tenant. A system can be used for the following purposes:

* Running a job, including:

  * Staging files to a system in preparation for running a job.
  * Executing a job on a system.
  * Archiving files and data on a remote system after job execution.

* Storing and retrieving files and data.

Each system is of a specific type (such as LINUX or S3) and owned by a specific user who has special
privileges for the system. The system definition also includes the user that is used to access the system,
referred to as *effectiveUserId*. This access user can be a static specific user (such as a service account)
or dynamically specified as ``${apiUserId}``. For the case of ``${apiUserId}``, the username is extracted
from the identity associated with the request to the service. For more information related to
*effectiveUserId* please see the section below on `Effective User Id and Host Login`_ .

-----------------
Model
-----------------

At a high level a system represents the following information:

*id*
  A short descriptive name for the system that is unique within the tenant.
*description*
  An optional more verbose description for the system.
*systemType* - Type of system
  LINUX, S3, IRODS or GLOBUS
*owner*
  A specific user set at system creation. By default this is the resolved value for ``${apiUserId}``, the user making
  the request to create the system.
*host* - Host name, IP address or Globus ID
  FQDN, IP address, Globus endpoint ID or Globus collection ID.
*enabled* - Enabled flag
  Indicates if system is currently considered active and available for use. By default this is *true*.
*effectiveUserId* - Effective User
  The username to use when accessing the system. A specific user (such as a service account) or the dynamic
  user ``${apiUserId}``. By default this is ``${apiUserId}``. For more information please see the section below
  on `Effective User Id and Host Login`_ .
*defaultAuthnMethod* - Default authentication method
  How access authentication is handled by default. Authentication method can also be
  specified as part of a request.
  Supported methods: PASSWORD, PKI_KEYS, ACCESS_KEY, TOKEN, TMS_KEYS.
*bucketName* - Bucket name
  For an S3 system this is the name of the bucket.
*rootDir* - Effective root directory
  Directory to be used when listing files or moving files to and from the system.
  All paths are relative to this directory when using Files to list, copy, move, mkdir, etc.
  For more information please see `Effective Root Directory`_.
  May not be updated. Contact support to request a change.
*dtnSystemId* - DTN system Id
  A system that can be used during job execution as a Data Transfer Node (DTN). Use is optional. The DTN is used
  if the job submission request or the application defintion specify *dtnSystemInputDir* or *dtnSystemOutputDir*.
  *canExec* must be true. This execution system and the DTN system must have the same *rootDir* and the file
  system must be shared storage. Please see `DTN Configuration`_.
*canExec*
  Indicates if system can be used to execute jobs.
*canRunBatch*
  Indicates if system supports running jobs using a batch scheduler. By default this is *false*.
*enableCmdPrefix*
  Indicates if system allows a job submission request to specify a *cmdPrefix*. Since *cmdPrefix* is a free form
  command it is a security concern. By default this is *false*.
*allowChildren*
  Indicates if system supports creating child systems using this system as the parent. By default this is *false*.
Job related attributes
  Various attributes related to job execution such as *jobRuntimes*, *jobWorkingDir*,
  *batchScheduler*, *batchSchedulerProfile*, *batchLogicalQueues*

.. _DTN Configuration: https://tapis.readthedocs.io/en/latest/technical/jobs.html#data-transfer-nodes

When creating a system the required attributes are: *id*, *systemType*, *host*, *defaultAuthnMethod* and *canExec*.
Depending on the type of system and specific values for certain attributes there are other requirements.

Note that a system may be created as a storage-only resource (*canExec=false*) or as a system that can be used for both
execution and storage (*canExec=true*).

Dynamically Determined System Attributes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When fetching a system or list of systems, some attributes are computed dynamically and shown in the results.
The dynamically determined attributes are:

*effectiveUserId*
  The resolved username to use when accessing the host or service. If system is defined with a dynamic
  user, i.e. ``effectiveUserId = ${apiUserId}``, this is filled in based on the identity of the user
  making a request. For more information please see the section below on `Effective User Id and Host Login`_ .
*isDynamicEffectiveUser*
  Indicates if *effectiveUserId* was resolved using ``${apiUserId}``.
*isPublic*
  Indicates if the system has been shared publicly. For more information please see the section below
  on `Sharing`_ .
*sharedWithUsers*
  The list of users with whom the system has been shared.

--------------------------------
Getting Started
--------------------------------

Before going into further details about Systems, here we give some examples of how to create and view systems.
In the examples below we assume you are using the TACC tenant with a base URL of ``tacc.tapis.io`` and that you have
authenticated using PySDK or obtained an authorization token and stored it in the environment variable JWT,
or perhaps both.

Creating a System
~~~~~~~~~~~~~~~~~

Create a local file named ``system_example.json`` with json similar to the following::

  {
    "id":"tacc-sample-<userid>",
    "description":"My storage system",
    "host":"tapis-vm.tacc.utexas.edu",
    "systemType":"LINUX",
    "defaultAuthnMethod":"PKI_KEYS",
    "effectiveUserId":"${apiUserId}",
    "rootDir":"/",
    "canExec": false
  }

where *<userid>* is replaced with your username, and your host name is updated appropriately. Note that although
credentials may be included in the definition we have not done so here. For security reasons, it is recommended that
login credentials be updated using a separate API call as discussed below.

Using PySDK:

.. code-block:: python

 import json
 from tapipy.tapis import Tapis
 t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
 with open('system_example.json', 'r') as openfile:
     my_storage_system = json.load(openfile)
 t.systems.createSystem(**my_storage_system)

Using CURL::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems -d @system_example.json

.. _effective_root_dir:

Effective Root Directory
~~~~~~~~~~~~~~~~~~~~~~~~

Correctly defining the system attribute *rootDir* is critical because it serves as an effective root directory
when referencing file paths through the Tapis Files or Jobs services. All paths are relative to this directory
when using Files to list, copy, move, mkdir, etc. When creating a system there are certain restrictions for
this attribute that should be kept in mind:

* Once a system is created, *rootDir* may not be updated. Contact support to request a change.
* Required for systems of type LINUX or IRODS. Must begin with ``/``.
* Optional for systems of type S3 or GLOBUS.
* For S3 type systems, typically will not begin with ``/``.

  * S3 keys are usually created and manipulated using URLs and do not have a leading ``/``.

* Support is provided for resolving the following variables at create time: *${apiUserId}*, *${tenant}* and *${owner}*.

Use of HOST_EVAL at System Creation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There is also a special macro available for *rootDir* that may be used under certain conditions when a system
is first created. The macro name is ``HOST_EVAL``.
The syntax for the macro is ``HOST_EVAL($var)``, where ``var`` is the environment variable to be evaluated
on the system host when the create request is made.
Note that the ``$`` character preceding the environment variable name is optional.
If after resolution the final path does not have the required leading slash (``/``) to make it an absolute path,
then one will be prepended.
The following conditions must be met in order to use the macro

* System must be of type LINUX
* Credentials must be provided when system is created.
* Macro ``HOST_EVAL()`` must only appear once and must be the first element of the path. Including a leading slash is optional.
* The *effectiveUserId* for the system must be static. Note that *effectiveUserId* may be set to ``${owner}``.

Here are some examples

* HOST_EVAL($SCRATCH)
* HOST_EVAL($HOME)
* /HOST_EVAL(MY_ROOT_DIR)/scratch
* /HOST_EVAL($PROJECT_HOME)/projects/${tenant}/${owner}

.. _registering_credentials:

Effective User Id and Host Login
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The attribute *effectiveUserId* determines the host login user, the user used to access the underlying host or service.
The attribute can be set to a static string indicating a specific user (such as a service account) or dynamically
specified as ``${apiUserId}``. For the case of ``${apiUserId}``, the service resolves the variable by extracting the
identity from the request to the service (i.e. the JWT) and applying a mapping to a host login user if such a mapping
has been provided. If no mapping is provided, then the extracted identity is taken to be the host login user.

Host Login User Mapping
^^^^^^^^^^^^^^^^^^^^^^^
A mapping between a Tapis user and a host login user is created when the system has a dynamic *effectiveUserId*
and the attribute *loginUser* is included when registering credentials. Please see the section below on
`Registering Credentials for a System`_.

For example, if my user id when logging into Tapis is ``jdoe`` and my host login user id is ``jdoe3``, then a
login user mapping would be required if the system is defined using a dynamic *effectiveUserId*.
Note that if my Tapis user id happened to also be ``jdoe3`` then no mapping would be required.

Please note that if the system is defined using a static *effectiveUserId*, then there is no need for a mapping.
In this case the *effectiveUserId* is logically independent of the Tapis identity and may be set to any valid
host username value.

Registering Credentials for a System
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Now that you have registered a system you will need to register credentials so you can use Tapis to access the host.
Various authentication methods can be used to access a system. Supported methods are PASSWORD, PKI_KEYS, ACCESS_KEY,
TOKEN and TMS_KEYS. The process of registering credentials can vary significantly depending on the authentication method.
For more information please see the appropriate section below under `Authentication Credentials`_.

Please note that there is support for only one set of credentials per user per system. Updating credentials overwrites
previously registered data.

Here we will cover registering PKI_KEYS (i.e. ssh keys) as an example.
Please note that registering ssh keys requires special care when translating the generated keypair information to json format.
For more information please see `Use of PKI_KEYS as credentials`_ under the section on `Authentication Credentials`_.

Create a local file named ``cred_tmp.json`` with json similar to the following::

  {
    "publicKey": "<ssh_public_key>",
    "privateKey": "<ssh_private_key>"
  }

where *<ssh_public_key>* and *<ssh_private_key>* are replaced with your keys. The keys must be encoded on a single line
with embedded newline characters. You may find the following linux command useful in converting a multi-line private
key into a single line::

  cat $privateKeyFile | awk -v ORS='\\n' '1'

Using PySDK:

.. code-block:: python

 t.systems.createUserCredential(systemId='tacc-sample-<userid>', userName='<userid>', publicKey='<ssh_public_key>', privateKey='<ssh_private_key>'))

Using CURL::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/credential/tacc-sample-<userid>/user/<userid> -d @cred_tmp.json

An optional attribute *loginUser* may be included in the request body in order to map the Tapis user to a username to
be used when accessing the system. If the login user is not provided then there is no mapping and the Tapis user is
always used when accessing the system. When a *loginUser* is provided the json would be similar to the following::

  {
    "publicKey": "<ssh_public_key>",
    "privateKey": "<ssh_private_key>",
    "loginUser": "<linux_host_username>"
  }

Note that credentials are stored in the Security Kernel.
Only specific Tapis services are authorized to retrieve credentials.

Viewing Systems
~~~~~~~~~~~~~~~

Retrieving details for a system
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To retrieve details for a specific system, such as the one above:

.. note::
  See the section below on `Selecting`_ to find out how to control the amount of information returned.

Using PySDK:

.. code-block:: python

 t.systems.getSystem(systemId='tacc-sample-<userid>')

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/tacc-sample-<userid>

The response should look similar to the following::

 {
    "result": {
        "tenant": "dev",
        "id": "tacc-sample-<userid>",
        "description": "My storage system",
        "systemType": "LINUX",
        "owner": "<userid>",
        "host": "tapis-vm.tacc.utexas.edu",
        "enabled": true,
        "effectiveUserId": "<userid>",
        "defaultAuthnMethod": "PKI_KEYS",
        "authnCredential": null,
        "rootDir": "/",
        "port": 22,
        "useProxy": false,
        "proxyHost": "",
        "proxyPort": -1,
        "dtnSystemId": null,
        "canExec": false,
        "canRunBatch": false,
        "enableCmdPrefix": false,
        "allowChildren": false,
        "jobRuntimes": [],
        "jobWorkingDir": null,
        "jobEnvVariables": [],
        "jobMaxJobs": 2147483647,
        "jobMaxJobsPerUser": 2147483647,
        "batchScheduler": null,
        "batchSchedulerProfile": null,
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
    "message": "TAPIS_FOUND System found: tacc-sample-<userid>",
    "version": "0.0.1",
    "metadata": null
 }

Note that authnCredential is *null*. Only specific Tapis services are authorized to retrieve credentials.

Retrieving details for all systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To see the list of systems that you own:

Using PySDK:

.. code-block:: python

 t.systems.getSystems()

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems?select=allAttributes

The response should contain a list of items similar to the single listing shown above.

.. note::
  See the sections below on `Searching`_, `Selecting`_, `Sorting`_ and `Limiting`_ to find out how to control the
  amount of information returned.

Child Systems
~~~~~~~~~~~~~~~~~~~~~~

Creating Child Systems
^^^^^^^^^^^^^^^^^^^^^^

A system that has *allowChildren* set to *true* allows for creation of child systems based on it.
This ability provides a way to easily clone and manage systems based on existing systems.
Child systems allow a user to set only a few fields, and use all other values from an existing parent system.
This can reduce the difficulty in managing systems. It allows for all child systems to be updated when the
parent is updated.

To create a child system, first ensure that the system intended to serve as the parent as *allowChildren* set to *true*.
Next, create a local file (for example child_system_example.json) similar to the following::

 {
    "id": "my-child-<userid>",
    "effectiveUserId": "${apiUserId}",
    "rootDir": "/home/<userid>"
 }

Where *<userid>* is replaced with your username. Also ensure that the root directory path is correct. Now use the
create child system REST endpoint to create the child system. Let's assume that the new child system will be a
child of a parent system called *parent-system*.

Using PySDK::

 import json
 from tapipy.tapis import Tapis
 t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
 with open('child_system_example.json', 'r') as openfile:
     child_system = json.load(openfile)
 t.systems.createChildSystem(parentId="parent-system", **child_system)

Using CURL::

 $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/parent-system/createChildSystem -d @child_system_example.json


These fields are maintained
independently for child systems:

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| id                  | String         | ds1.storage.default  | - Identifier for the system. URI safe, see RFC 3986.                                 |
|                     |                |                      | - *tenant* + *id* must be unique.                                                    |
|                     |                |                      | - Allowed characters: Alphanumeric [0-9a-zA-Z] and special characters [-._~].        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| owner               | String         | jdoe                 | - username of *owner*.                                                               |
|                     |                |                      | - Variable references: *${apiUserId}*. Resolved at create time.                      |
|                     |                |                      | - By default this is the resolved value for *${apiUserId}*.                          |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enabled             | boolean        | FALSE                | - Indicates if system currently enabled for use.                                     |
|                     |                |                      | - May be updated using the enable/disable endpoints.                                 |
|                     |                |                      | - By default this is *true*.                                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| effectiveUserId     | String         | tg869834             | - User to use when accessing the system.                                             |
|                     |                |                      | - May be a static string or a variable reference.                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*                                    |
|                     |                |                      | - On output variable reference will be resolved.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| rootDir             | String         | /home/${apiUserId}   | - Required if *systemType* is LINUX or IRODS.                                        |
|                     |                |                      | - For LINUX or IRODS must begin with ``/``.                                          |
|                     |                |                      | - Optional for S3 and GLOBUS. For S3 will typically not begin with ``/``.            |
|                     |                |                      | - Variable references are resolved at create time.                                   |
|                     |                |                      | - Serves as effective root directory when listing or moving files.                   |
|                     |                |                      | - May not be updated. Contact support to request a change.                           |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| deleted             | boolean        | FALSE                | - Indicates if system has been deleted.                                              |
|                     |                |                      | - May be updated using the delete/undelete endpoints.                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| created             | Timestamp      | 2020-06-19T15:10:43Z | - When the system was created. Maintained by service.                                |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| updated             | Timestamp      | 2020-07-04T23:21:22Z | - When the system was last updated. Maintained by service.                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

During the creation of a child system, any of these fields may be specified except for created, updated and deleted.
All other fields are taken from the parent system.


Updating a Child System
^^^^^^^^^^^^^^^^^^^^^^^

Updates are done just like any other system, however, only the following fields may be updated for a child system.

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| effectiveUserId     | String         | tg869834             | - User to use when accessing the system.                                             |
|                     |                |                      | - May be a static string or a variable reference.                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*                                    |
|                     |                |                      | - On output variable reference will be resolved.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

Some other fields can be updated through special endpoints. For example deleted and enabled are updated through the endpoints for
deleting, undeleting, enabling and disabling.

Child System Operations
^^^^^^^^^^^^^^^^^^^^^^^
Most operations other than update are the same for child systems as they are for parent systems. For more information
see the appropriate section of the document for the operation.

* Delete   - see `Deletion`_
* Undelete - see `Deletion`_
* Enable   - see "enabled" in `System Attributes Table`_
* Disable  - see "enabled" in `System Attributes Table`_

Unlinking a Child System from it's Parent System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A child system may be unlinked from it's parent. This is a permanent operation, and cannot be undone. This will make the child a standalone
system with all of it's current settings. When the unlink happens any fields that had previously been linked to the parent will be copied to
the child, and it will be as if the child was created as in independent system with those values.

If the owner of the child system wants to unlink the child from it's parent, the owner may use the *unlinkFromParent* endpoint.

Using PySDK::

 import json
 from tapipy.tapis import Tapis
 t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
 t.systems.unlinkFromParent(childSystemId="<child-system-id>")

Using CURL::

 $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/<child-system-id>/unlinkFromParent

Replace *<child-system-id>* with the id of the child system.

The owner of a parent system can also decide to unlink child systems from the parent. In that case the parent system owner would use
the *unlinkChildren* endpoint. The child systems to unlink may be specified in the request body. First create a json file (for example children_to_unlink.json)::

 {
    "childSystemIds":
    [
      "<child-system-1-id>",
      "<child-system-2-id>"
      ...
    ]
 }

Using PySDK::

  import json
  from tapipy.tapis import Tapis
  t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
  with open('children_to_unlink.json', 'r') as openfile:
      children_to_unlink = json.load(openfile)
  t.systems.unlinkChildren(parentSystemId="<parent-system-id>", **children_to_unlink)

Using CURL::

 $curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/<parent-system-id>/unlinkChildren -d @./children_to_unlink.json

Or all child systems using *all=True* (no json file required)

Using PySDK::

 import json
 from tapipy.tapis import Tapis
 t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
 t.systems.unlinkChildren(parentSystemId="<parent-system-id>", all=True)

Using CURL::

 $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" "https://tacc.tapis.io/v3/systems/<parent-system-id>/unlinkChildren?all=true"

-----------------------------------
Minimal Definition and Restrictions
-----------------------------------
When creating a system the required attributes are: *id*, *systemType*, *host*, *defaultAuthnMethod* and *canExec*.
Depending on the type of system and specific values for certain attributes there are other requirements.
The restrictions are:

* If *systemType* is S3 then *bucketName* is required and *canExec* must be false.
* If *systemType* is LINUX or IRODS then *rootDir* is required and must begin with ``/``.
* If *effectiveUserId* is ``${apiUserId}`` (i.e. it is not static) then *authnCredential* may not be specified.
* If *canExec* is true then *jobWorkingDir* is required and *jobRuntimes* must have at least one entry.
* If *canRunBatch* is true then *batchScheduler* must be specified.
* If *canRunBatch* is true then *batchLogicalQueues* must have at least one item.

  * If *batchLogicalQueues* has more than one item then *batchLogicalDefaultQueue* must be specified.
  * If *batchLogicalQueues* has exactly one item then *batchLogicalDefaultQueue* is set to that item.

-----------------
Permissions
-----------------
The permissions model allows for fine grained access control of Tapis systems.

At system creation time the owner is given full access to the system.
Permissions for other users may be granted and revoked through the systems API. Please
note that grants and revokes through this service only impact the default role for the
user. A user may still have access through permissions in another role. So even after
revoking permissions through this service, when permissions are retrieved the access may
still be listed. This indicates access has been granted via another role.

Permissions are specified as either ``*`` for all permissions or some combination of the
following specific permissions: ``("READ","MODIFY","EXECUTE")``. Specifying permissions in all
lower case is also allowed. Having ``MODIFY`` implies ``READ``.

-----------------
Sharing
-----------------
In addition to fine grained permissions support, Tapis also supports a higher level approach to granting access.
This approach is known simply as *sharing*. The sharing API allows you to share a system with a set of users
as well as share publicly with all users in a tenant. Sharing provides ``READ+EXECUTE`` access.
When the system has a dynamic *effectiveUserId*, sharing also allows for MODIFY access to all file paths for
calls made through the Files service.

.. note::
  Note that there is one other case when a system is treated as having a dynamic *effectiverUserId* in the
  context of sharing, even with a static *effectiverUserId*. This is when the
  system type is ``IRODS`` and the attribute *useProxy* is set to ``true``. In this case the connection to
  the *IRODS* host is made using a special administrative account which then acts as the Tapis user.
  So please be aware that for this type of system sharing the system or a file path will allow for
  MODIFY access.

The most common use case for sharing a system is to publicly share the system with all users in the tenant.
This would allow any user to use the system for execution or storage when running an application.


.. note::
  If a system has a dynamic *effectiveUserId* and has been shared publicly or with specific users,
  then those users will have Tapis permissions to operate on on any files without explicitly sharing any paths
  through the Files service. This includes file listing, upload, download and delete.

  If a system has a static *effectiveUserId*, then file paths will need to be explicitly shared using the
  Files service in order to allow users READ access. Having READ access allows users to list and download files.

  These restrictions are in place in order to reduce the risks associated with sharing a system. With a dynamic
  *effectiveUserId* users are always logging in to the host as themselves. With a static *effectiveUserId*
  there is a privilege escalation security risk. 

.. warning::
  In the context of using a shared application to run a job, sharing a system (and hence all file paths
  on the system) will grant users READ and MODIFY access to the file paths, even for the case of a
  static effectiveUserId.

.. note::
  Tapis permissions and sharing are independent of native permissions enforced by the underlying system host.

For more information on sharing please see :doc:`sharing`


--------------------------
Authentication Credentials
--------------------------
At system creation time the authentication credentials may be specified if the effective
access user *effectiveUserId* is a specific user (such as a service account) and not
a dynamic user (i.e. not equal to ``${apiUserId}``).

If the effective access user is dynamic (i.e. equal to ``${apiUserId}``) then authentication credentials for any
user allowed to access the system must be registered in separate API calls. In this case the payload provided may
contain the optional attribute *loginUser* which will be used to map the Tapis user to a username to be used when
accessing the system. If the login user is not provided then there is no mapping and the Tapis user is always used
when accessing the system.

Note that the Systems service does not store credentials. Credentials are persisted by the Security Kernel service
and only specific Tapis services are authorized to retrieve credentials.

Also, note that there is support for only one set of credentials per user per system. Updating credentials
overwrites previously registered data.

By default any credentials provided for LINUX and S3 type systems are verified. The query parameter
*skipCredentialCheck=true* may be used to bypass the initial verification of credentials.

Use of PKI_KEYS as credentials
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When using an ssh keypair as credentials there are several important points to keep in mind. As discussed above, the
public key and private key must be encoded on a single line. This can sometimes be challenging. For example, copying
and pasting may convert newline characters in a way that is not compatible with processing in Tapis. You may find the
following linux command useful in converting a multi-line private key into a single line::

  cat $privateKeyFile | awk -v ORS='\\n' '1'

When generating the keypair, do not use a passphrase. This can interfere with non-interactive use of the keypair.

Finally, please be aware that if the host has multi-factor authentication (MFA) enabled this may prevent Tapis from
communicating with the host. Tapis does not currently support MFA.

If problems are encountered here are some suggestions on what to check:

* Public and private keys are each on one line in the json file. Newline characters in private key are properly encoded.
* Keypair does not have a passphrase
* Public key has been added to the authorized_keys file for the target user. File ~/.ssh/authorized_keys
* File ~/.ssh/authorized_keys has proper permissions.
* MFA is not enabled for the target host.

If problems persist you can also attempt to manually validate the keypair using a command similar to this::

  ssh -i /tmp/my_private_key testuser@myhost.com

where /tmp/my_private_key contains the original multi-line private key. If everything is set up correctly and the
keypair is valid you should be logged into the host without being prompted for a password.

Use of TMS_KEYS for credentials
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Tapis supports the use of the Trust Manager System (TMS) for managing credentials.
For more information on TMS refer to `TMS_Documentation`_.

.. _TMS_Documentation: https://tms-documentation.readthedocs.io/en/latest/#

Please note that your Tapis site installation must have been configured by the site administrator to support TMS.
See `TMS_Config`_.

.. _TMS_Config: https://tapis.readthedocs.io/en/latest/deployment/deployer.html#configuring-support-for-tms

Also, any target hosts defined in Tapis systems must be configured to use the TMS KeyCmd program for ssh connections.
Please refer to the TMS documentation for details.

The integration of Tapis with TMS allows users to have Tapis automatically create and use SSH keypairs rather
than having to provide their own. In order to register TMS credentials for a system, begin by making sure the
system is defined with *defaultAuthnMethod* set to TMS_KEYS. Then when creating credentials simply add the flag
``createTmsKeys=true``.

For example, the CURL command to create TMS keys for a system might look as follows::

   $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/credential/tms-test/user/<userid>?createTmsKeys=true -d @cred_tmp.json

Note that the request body may be empty.

Please note that the following restrictions apply:

* Tapis installation for your site must be configured to support the Trust Manager System (TMS).
* The host for the system must have the sshd configuration set up to use TMS.
* The *effectiveUserId* must be dynamic.
* Mapping of user using *loginUser* is not supported.


.. _registering_globus_credentials:

Registering Credentials for a Globus System
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Registering credentials for a GLOBUS type system is a special case that involves multiple steps and is significantly
different compared to registering other types of credentials.
For a GLOBUS type system, the user will need to use the TOKEN authentication method and generate
an ``accessToken`` and ``refreshToken`` using two special-purpose System service endpoints.

Please note that your Tapis site installation must have been configured by the site administrator to support
Globus. See `Globus_Config`_.

.. _Globus_Config: https://tapis.readthedocs.io/en/latest/deployment/deployer.html#configuring-support-for-globus

Obtain Globus Authorization Code
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first step in generating Globus credentials is for the user to call the systems *authUrl* credential endpoint
to obtain a Globus authorization code.

Using CURL, the request would look something like this::

 $curl -H "X-Tapis-Token: $JWT" https://dev.tapis.io/v3/systems/credential/<system>/globus/authUrl

The response should look similar to the following. Note that for brevity and readability, only the result portion of the
response is shown, the response has been split into multiple lines and various IDs are not filled in::

 {
   "url": "https://auth.globus.org/v2/oauth2/authorize?client_id=<client_id>
       &redirect_uri=https%3A%2F%2Fauth.globus.org%2Fv2%2Fweb%2Fauth-code
       &scope=openid+profile+email+urn%3Aglobus%3Aauth%3Ascope%3Atransfer.api.globus.org%3Aall
       &state=_default&response_type=code&code_challenge=<challenge_id>
       &code_challenge_method=S256&access_type=offline",
   "sessionId": "<session_id>"
 }

The user should copy the url (as a single string, no line breaks) and make note of the session Id for later use.
The user then visits the provided URL and is presented with a Globus logon page that will allow them
to authenticate using one of thousands of supported identity providers, including through their existing organization
using CILogon.

The user must use the following flow to obtain an authorization code:

1. Visit the provided URL and authenticate through Globus. After authentication, user is re-directed back to a
   Globus page showing the access being requested by Tapis.
2. Fill in a label for future reference and click *Allow* to authorize Tapis to access Globus on their behalf.
3. Copy the provided authorization code in preparation for the final step. Note that the code is valid for a short time
   (as of this writing it is valid for 10 minutes).

Exchange Authorization Code for Tokens
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The final step is for the user to call the systems credential endpoint to exchange the authorization code and session ID
for tokens which are stored by the Systems service in a credentials record.

Using CURL, the request would look something like this::

 $curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT"
        https://dev.tapis.io/v3/systems/credential/<system>/user/<user>/globus/tokens/<authCode>/<sessionId>

The response should look similar to the following::

 {
   "result": null,
   "status": "success",
   "message": "SYSAPI_CRED_UPDATED Credential updated. ...",
   "version": "1.3.1",
   "commit": "619aa7ce",
   "build": "2023-04-02T19:06:38Z",
   "metadata": null
 }

At this point the user will have registered credentials for a Tapis system that can be used as a source or destination
for Globus operations.

Registering Credentials for an AWS S3 System
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Registering credentials for a Tapis S3 type system referencing an AWS bucket is a special case that is significantly
different compared to registering other types of credentials. For such a system, the user will need to first manage
the S3 bucket and IAM access tokens within AWS, then register the AWS access token with Tapis as a key pair.

Creating the S3 Bucket within AWS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first step in registering S3 as a storage solution with Tapis is creating the S3 bucket.
Tapis does not require any special considerations to be taken when creating the bucket, 
but you will need to keep track of the bucket's name.

Obtaining an Access Key Pair from AWS
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. _IAM_docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html?icmpid=docs_iam_console 

Although creating an IAM user is not strictly necessary, it is highly recommended. 
You can create an access token for the root user by going to 'my security credentials' in the IAM console
in AWS but this is not recommended for security reasons. Instead, it is recommended to create an IAM user
for Tapis access. Make sure that when you create the user, you explicitly give it permissions to access S3.
Refer to the `IAM documentation <IAM_DOCS_>`_ for instructions on assigning permissions.

Take the following steps to obtain an access token pair for an IAM user:

1. In the IAM console in AWS, select the user who will be registered in the Tapis system.
2. Navigate to the 'Security Credentials' tab, and select 'Create access key'.
3. Go through the creation wizard, making sure that you save both the access key and the secret access key on the last page. You will need both of these in the next step to register the credentials with Tapis.

Create the S3 System in Tapis
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. _create_system: https://tapis.readthedocs.io/en/latest/technical/systems.html#creating-a-system

Now that you have everything you need from AWS, create the Tapis system. 
Refer to the `Creating a System <create_system_>`_ section for instructions, 
making sure to use S3 for systemType and the name of the bucket for host. 

The system definition should look something like this::

    {
      "id": "demo-aws-s3-bucket",
      "description": "Demo S3 AWS acct.",
      "host":"tapisdemo-bucket.s3.amazonaws.com",
      "systemType": "S3",
      "effectiveUserId": "tapisdemo",
      "defaultAuthnMethod": "ACCESS_KEY",
      "bucketName": "tapisdemo-bucket",
      "rootDir": "",
      "canExec": false
    }

Registering AWS Credentials with Tapis
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we have a bucket, AWS tokens, and a Tapis system, the last step is to register the AWS credentials with Tapis. 

using CURL, we can do something like::

  $curl -X POST -H "content-type:applications/json" -H "X-Tapis-Token: $JWT"
    -d {
      "accessKey":"< AWS access key name >",
      "accessSecret":"< AWS access key secret >"
    }
    https://dev.tapis.io/v3/systems/credential/<system>/user/<user>

Which should return a response similar to ::

  {
  "result": null,
  "status": "success",
  "message": "SYSAPI_CRED_UPDATED Credential updated. ...",
  "version": "1.8.2",
  "commit": "9e30ecbf",
  "build": "2025-02-25T14:24:36Z",
  "metadata": null
  }

--------------------------
Runtime
--------------------------
Runtime environment supported by the system that may be used to run applications, such as docker, singularity or ZIP.
Consists of the runtime type and version.

--------------------------
Logical Batch Queue
--------------------------
A queue that maps to a single HPC queue. Logical batch queues provide a uniform front end abstraction for an HPC queue.
They also provide more features and flexibility than is typically provided by an HPC scheduler. Multiple logical queues
may be defined for each HPC queue. If an HPC queue does not have a corresponding logical queue defined then a user will
not be able use the Tapis system to directly submit a job via Tapis to that HPC queue.

-----------------------
Batch Scheduler Profile
-----------------------
The Systems service supports managing Tapis scheduler profiles. An HPC center often has certain conventions
and restrictions around the use of batch schedulers. A scheduler profile resource can be defined to provide the
Tapis Jobs service with additional site specific information to be used when executing applications using a
scheduler. A scheduler profile contains information on options that should be hidden from the scheduler,
the module load command to use and which modules should be loaded by default when running a job. Anyone in a
tenant may create a scheduler profile for use by all users in the tenant. The owner of a profile or a
tenant administrator may modify or delete a profile. A profile may be referenced in a system definition using the
attribute *batchSchedulerProfile*. The profile to be used may also be set in the job submit request using the
special scheduler option *\-\-tapis-profile*. The value in the job submit request takes precedence over a value
defined for the execution system.

For example, at TACC there is a certain module that must be loaded when running Slurm jobs via singularity. Also, use of
the Slurm option *\-\-mem* is prohibited. In support of this, most of the tenants at TACC make use of a profile similar
to the following::

    {
        "name": "tacc",
        "owner": "testuser1",
        "description": "Profile for TACC Slurm",
        "moduleLoads": [
            {
                "moduleLoadCommand": "module load",
                "modulesToLoad": ["tacc-singularity"]
            }
        ],
        "hiddenOptions": ["MEM"]
    }

The *moduleLoads* array contains one or more entries. Each entry contains a *moduleLoadCommand*, which specifies the
local command used to load each of the modules (in order) in its *modulesToLoad* list.

The *hiddenOptions* array identifies scheduler options that the local implementation prohibits.
Options specified here will have the corresponding Slurm option suppressed.
Supported options are "MEM" for *\-\-mem* and "PARTITION" for *\-\-partition*.
Including an option in the array indicates that the corresponding Slurm option should never be
passed through to Slurm.

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
|                     |                |                      | - Types: LINUX, S3, IRODS, GLOBUS                                                    |
|                     |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| owner               | String         | jdoe                 | - username of *owner*.                                                               |
|                     |                |                      | - Variable references: *${apiUserId}*. Resolved at create time.                      |
|                     |                |                      | - By default this is the resolved value for *${apiUserId}*.                          |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| host                | String         | data.tacc.utexas.edu | - Host name, ip address, Globus endpoint ID or Globus collection ID.                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enabled             | boolean        | FALSE                | - Indicates if system currently enabled for use.                                     |
|                     |                |                      | - May be updated using the enable/disable endpoints.                                 |
|                     |                |                      | - By default this is *true*.                                                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| effectiveUserId     | String         | tg869834             | - User to use when accessing the system.                                             |
|                     |                |                      | - May be a static string or a variable reference.                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*                                    |
|                     |                |                      | - On output variable reference will be resolved.                                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| defaultAuthnMethod  | enum           | PKI_KEYS             | - How access authentication is handled by default.                                   |
|                     |                |                      | - Can be overridden as part of a request to get a system or credential.              |
|                     |                |                      | - Methods: PASSWORD, PKI_KEYS, ACCESS_KEY, TOKEN, TMS_KEYS                           |
|                     |                |                      | - See table *Credential Attributes* below for more information.                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| authnCredential     | Credential     |                      | - On input credentials to be stored in Security Kernel.                              |
|                     |                |                      | - *effectiveUserId* must be static, either a string constant or ${owner}.            |
|                     |                |                      | - May not be specified if *effectiveUserId* is dynamic, i.e. *${apiUserId}*.         |
|                     |                |                      | - On output contains credential for *effectiveUserId* and requested *authnMethod*.   |
|                     |                |                      | - Returned credential contains relevant information based on *authnMethod*.          |
|                     |                |                      | - Credentials may be updated using the systems credentials endpoint.                 |
|                     |                |                      | - By default for LINUX the credentials are verified during create or update.         |
|                     |                |                      | - Use query parameter skipCredentialCheck=true to bypass initial verification.       |
|                     |                |                      | - See table *Credential Attributes* below for more information.                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| bucketName          | String         | tapis-ds1-jdoe       | - Name of bucket for an S3 system.                                                   |
|                     |                |                      | - Required if *systemType* is S3.                                                    |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| rootDir             | String         | /home/${apiUserId}   | - Required if *systemType* is LINUX or IRODS.                                        |
|                     |                |                      | - For LINUX or IRODS must begin with ``/``.                                          |
|                     |                |                      | - Optional for S3 and GLOBUS. For S3 will typically not begin with ``/``.            |
|                     |                |                      | - Variable references are resolved at create time.                                   |
|                     |                |                      | - Serves as effective root directory when listing or moving files.                   |
|                     |                |                      | - May not be updated. Contact support to request a change.                           |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| port                | int            | 22                   | - Port number used to access the system                                              |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| useProxy            | boolean        | TRUE                 | - Indicates if system should be accessed through a proxy.                            |
|                     |                |                      | - Currently only supported for IRODS type systems.                                   |
|                     |                |                      | - Indicates if an IRODS proxy administrative user should be used.                    |
|                     |                |                      | - *effectiveUserId* is the IRODS proxy admin user.                                   |
|                     |                |                      | - Tapis user making the request is the IRODS user who will be impersonated.          |
|                     |                |                      | - For this case *effectiveUserId* is considered dynamic in context of sharing.       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| proxyHost           | String         |                      | - Name of proxy host.                                                                |
|                     |                |                      | - Not currently supported. Please contact support if needed.                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| proxyPort           | int            |                      | - Port number for *proxyHost*                                                        |
|                     |                |                      | - Not currently supported. Please contact support if needed.                         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| dtnSystemId         | String         | default.corral.dtn   | - A system that can be used as a Data Transfer Node (DTN). Use is optional.          |
|                     |                |                      | - This system and *dtnSystemId* must have the same *rootDir* and shared storage.     |
|                     |                |                      | - Used if job submission or application specify a DTN input or output directory.     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| canExec             | boolean        |                      | - Indicates if system will be used to execute jobs.                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| canRunBatch         | boolean        |                      | - Indicates if system supports running jobs using a batch scheduler.                 |
|                     |                |                      | - By default this is *false*.                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| enableCmdPrefix     | boolean        |                      | - Indicates if system allows a job submission request to specify a cmdPrefix.        |
|                     |                |                      | - By default this is *false*.                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| allowChildren       | boolean        |                      | - Indicates if system supports creating child systems using this system as parent.   |
|                     |                |                      | - By default this is *false*.                                                        |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobRuntimes         | [Runtime]      |                      | - List of runtime environments supported by the system.                              |
|                     |                |                      | - At least one entry required if *canExec* is true.                                  |
|                     |                |                      | - Each Runtime specifies the Runtime type and version                                |
|                     |                |                      | - Runtime type is required and must be one of: DOCKER, SINGULARITY, ZIP.             |
|                     |                |                      | - Runtime version is optional.                                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobWorkingDir       | String         | workdir              | - Parent directory from which a job is run.                                          |
|                     |                |                      | - Relative to the effective root directory *rootDir*.                                |
|                     |                |                      | - Required if *canExec* is true.                                                     |
|                     |                |                      | - Variable references: *${apiUserId}*, *${owner}*, *${tenant}*                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobEnvVariables     | [KeyValuePair] |                      | - Environment variables added to the shell environment in which the job is running.  |
|                     |                |                      | - Added to environment variables specified in job and application definitions.       |
|                     |                |                      | - Each entry has *key* (required) and *value* (optional) as well as other attributes.|
|                     |                |                      | - See table *KeyValuePair Attributes* below for more information.                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobMaxJobs          | int            |                      | - Max total number of jobs .                                                         |
|                     |                |                      | - Set to -1 for unlimited.                                                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| jobMaxJobsPerUser   | int            |                      | - Max total number of jobs associated with a specific user.                          |
|                     |                |                      | - Set to -1 for unlimited.                                                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| batchScheduler      | String         | SLURM                | - Type of scheduler used when running batch jobs.                                    |
|                     |                |                      | - Schedulers: SLURM                                                                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
|batchSchedulerProfile| String         |                      | - Default Tapis scheduler profile for batch jobs.                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| batchLogicalQueues  | [LogicalQueue] |                      | - List of logical queues available on the system.                                    |
|                     |                |                      | - Each logical queue maps to a single HPC queue.                                     |
|                     |                |                      | - Multiple logical queues may be defined for each HPC queue.                         |
|                     |                |                      | - See table *LogicalQueue Attributes* below for more information.                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
|batchDefaultLogical  | LogicalQueue   |                      | - Default logical batch queue for the system.                                        |
|Queue                |                |                      |                                                                                      |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tags                | [String]       |                      | - List of tags as simple strings.                                                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| notes               | String         | "{}"                 | - Simple metadata in the form of a Json object.                                      |
|                     |                |                      | - Not used by Tapis.                                                                 |
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
| user                | String         | jsmith               | - Username associated with the credential.                                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| authnMethod         | String         | PKI_KEYS             | - Indicates the authentication method associated with a retrieved credential.        |
|                     |                |                      | - When a credential is retrieved it is for a specific authentication method.         |
|                     |                |                      | - Methods: PASSWORD, PKI_KEYS, ACCESS_KEY, TOKEN, TMS_KEYS                           |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| loginUser           | String         |                      | - Optional native username valid on the system.                                      |
|                     |                |                      | - May be used to map a Tapis user to a native login user.                            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| password            | String         |                      | - Password for when authnMethod is PASSWORD. For LINUX and IRODS systems.            |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| privateKey          | String         |                      | - Private key for when authnMethod is PKI_KEYS. For LINUX systems.                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| publicKey           | String         |                      | - Public key for when authnMethod is PKI_KEYS. For LINUX systems.                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| accessKey           | String         |                      | - Access key for when authnMethod is ACCESS_KEY. For S3 systems.                     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| accessSecret        | String         |                      | - Access secret for when authnMethod is ACCESS_KEY. For S3 systems.                  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| accessToken         | String         |                      | - Access token for when authnMethod is TOKEN. For GLOBUS systems.                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| refreshToken        | String         |                      | - Refresh token for when authnMethod is TOKEN. For GLOBUS systems.                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tmsPrivateKey       | String         |                      | - Private key for when authnMethod is TMS_KEYS. For LINUX systems.                   |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tmsPublicKey        | String         |                      | - Public key for when authnMethod is TMS_KEYS. For LINUX systems.                    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| tmsFingerprint      | String         |                      | - Fingerprint of public key for when authnMethod is TMS_KEYS. For LINUX systems.     |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+

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

-----------------------------
LogicalQueue Attributes Table
-----------------------------

+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| Attribute           | Type           | Example              | Notes                                                                                |
+=====================+================+======================+======================================================================================+
| name                | String         |   tapisNormal        | - Name for logical queue. Typically will match or be a variant of HPC queue name.    |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| hpcQueueName        | String         |   normal             | - Name of the HPC queue for which this logical queue is a front end.                 |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobs             | int            |                      | - Maximum total number of jobs that can be queued or running in this queue.          |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxJobsPerUser      | int            |                      | - Maximum number of jobs associated with a specific user that can be queued.         |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| minNodeCount        | int            |                      | - Minimum number of nodes that can be requested when submitting a job to the queue.  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxNodeCount        | int            |                      | - Maximum number of nodes that can be requested when submitting a job to the queue.  |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| minCoresPerNode     | int            |                      | - Minimum number of cores per node that can be requested when submitting a job.      |
|                     |                |                      | - Default is 1                                                                       |
+---------------------+----------------+----------------------+--------------------------------------------------------------------------------------+
| maxCoresPerNode     | int            |                      | - Maximum number of cores per node that can be requested when submitting a job.      |
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

----------------------------------
Scheduler Profile Attributes Table
----------------------------------

+---------------+----------+---------+-----------------------------------------------------------------------------+
| Attribute     | Type     | Example | Notes                                                                       |
+===============+==========+=========+=============================================================================+
| name          | String   | tacc    | - Name. Required. *tenant* + *name* uniquely identifies the profile.        |
+---------------+----------+---------+-----------------------------------------------------------------------------+
| owner         | String   | jdoe    | - Tapis user that created the profile.                                      |
+---------------+----------+---------+-----------------------------------------------------------------------------+
| description   | String   |         | - Description                                                               |
+---------------+----------+---------+-----------------------------------------------------------------------------+
| moduleLoads   | Array    |         | - Each entry contains a module command and a list of modules to load.       |
+---------------+----------+---------+-----------------------------------------------------------------------------+
| hiddenOptions | String[] | ["MEM"] | - List of locally prohibited scheduler options that should be filtered out. |
|               |          |         | - Allowed values: MEM, PARTITION                                            |
+---------------+----------+---------+-----------------------------------------------------------------------------+

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

..
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

   * ``authnCredential`` ``jobRuntimes`` ``jobEnvVariables`` ``batchLogicalQueues``  ``notes``

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

..
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

--------------------------------
Sort, Limit, Select and ListType
--------------------------------
When a list of Systems is retrieved the service provides for sorting, filtering and limiting the results.
By default, only resources owned by you will be included. The service provides a way for you to request that
all resources accessible to you be included. This is determined by the query parameter *listType*.

When retrieving either a list of resources or a single resource the service also provides a way to *select* which
fields (i.e. attributes) are included in the results. Sorting, limiting and attribute selection are supported using
query parameters.

Selecting
~~~~~~~~~
When retrieving systems the fields (i.e. attributes) to be returned may be specified as a comma separated list using
a query parameter named ``select``. Attribute names may be given using Camel Case or Snake Case.

Notes:

 * Special select keywords are supported: ``allAttributes`` and ``summaryAttributes``
 * Summary attributes include:

   * ``id``, ``systemType``, ``owner``, ``host``, ``effectiveUserId``, ``defaultAuthnMethod``, ``canExec``

 * By default all attributes are returned when retrieving a single resource via the endpoint *systems/<system_id>*.
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
    "version": "1.0.0",
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
  "version": "1.0.0",
  "metadata": {
    "recordCount": 2,
    "recordLimit": 2,
    "recordsSkipped": 0,
    "orderBy": "id(desc)",
    "startAfter": null,
    "totalCount": -1
  }

