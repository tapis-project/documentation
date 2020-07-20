.. _systems:

=======================================
Systems
=======================================
Once you are authorized to make calls to the various services, one of first
things you may want to do is to view storage and execution resources available
to you or create your own. In Tapis a storage or execution resource is referred
to as a *system.*

-----------------
Overview
-----------------
In Tapis a system represents a server or collection of servers exposed through a
single host name or IP address. Each system is associated with a specific tenant.
A system can be used for the following purposes:

* Running a job, including:

  * Staging files to an execution system in preparation for running a job.
  * Executing a job on an execution system.
  * Archiving files and data on a remote storage system after job execution.

* Storing and retrieving files and data.

Each system is of a specific type and owned by a specific user who has special
privileges for the system. The system definition also includes the user that is
used to access the system, referred to as *effectiveUserId.* This access user
can be a specific user (such as a service account) or dynamically specified as
``${apiUserId}`` in which case the user name is extracted from the identity associated with the request to the service.

At a high level a system represents the following information:

Type of system
  LINUX or OBJECT_STORE
Owner
  A specific user set at system creation.
Host name or IP address.
  FQDN or IP address
Enabled flag
  Indicates if system is currently considered active and available for use.
  By default the system is enabled when first created.
Effective User
  The user name to use when accessing the system. Referred to as *effectiveUserId.*
  A specific user (such as a service account) or the dynamic user ``${apiUserId}``
Access method
  How access authorization is handled by default. Access method can also be
  specified as part of a request.
  Initially supported: PASSWORD, PKI_KEYS, ACCESS_KEY.
Effective root directory
  Directory to be used when listing files or moving files to and from the system.
Transfer methods
  Supported methods for moving files or objects to and from the system.
  Initially supported: SFTP, S3. Allowable entries are determined by the system
  type.
Various attributes related to job execution
  * Flag indicating if system can be used to run jobs.
  * List of job related capabilities supported by the system.
  * Job related directories: LocalWorkingDir, LocalArchiveDir,
    RemoteArchiveSystem, RemoteArchiveDir

-----------------
Permissions
-----------------
At system creation time the owner is given full system authorization. If the effective
access user *effectiveUserId* is a specific user (such as a service account) then this
user is given the same authorizations. If the effective access user is the dynamic user
``${apiUserId}`` then the authorizations for each user must be granted and access
credentials created in separate API calls.

Permissions for a system may be granted and revoked through the systems API. Please
note that grants and revokes through this service only impact the default role for the
user. A user may still have access through permissions in another role. So even after
revoking permissions through this service when permissions are retrieved the access may
still be listed. This indicates access has been granted via another role.

Permissions are specified as either ``*`` for all permissions or some combination of the
following specific permissions: ``("READ","MODIFY")``. Specifying permissions in all
lower case is also allowed.

------------------
Access Credentials
------------------
At system creation time the access credentials may be specified if the effective
access user *effectiveUserId* is a specific user (such as a service account) and not
a dynamic user, i.e. ``${apiUserId}``. If the effective access user is dynamic then
access credentials for any user allowed to access the system must be registered in
separate API calls. Note that the systems service does not store credentials.
Credentials are persisted by the Security Kernel service.

-----------------
Capabilities
-----------------
Each System definition may contain a list of capabilities supported by that system.
An Application or Job definition may then specify required capabilities. These are
used for determining eligible systems for running an application or job.

-----------------
Deletion
-----------------
A system may be soft deleted. Soft deletion means the system is marked as deleted and
is no longer available for use. It will no longer show up in searches and operations on
the system will no longer be allowed. The system definition is retained for auditing
purposes. Note this means that system names may not be re-used after deletion.

Heading 2
~~~~~~~~~

Heading 3
^^^^^^^^^

