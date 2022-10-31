..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _sharing:

################
Resource Sharing
################

.. raw:: html

    <style> .red {color:#FF4136; font-weight:bold; font-size:20px} </style>

.. role:: red


----

Introduction to Tapis Access Controls
=====================================

Tapis users define resources such as systems, applications, files, streams, functions and workflows.  These resources can be used to generate other resources, such as job, workflow and function outputs.  The ability to share resources greatly extends their utility and, in general, the usefulness of Tapis.  On the other hand, users need to safeguard their data by controlling access to resources.  To facilitate both sharing and access control, Tapis provides two built-in authorization mechanisms.  

The first facility is implemented using *roles and permissions*.  These controls operate at a low level of abstraction and apply to the individual Tapis resources to which they are associated.  The second facility, *Tapis shared resources* (or simply *shared resources*), operate at a higher level of abstraction by authorizing complex actions in Tapis.  Such actions include running jobs, which authorizes access to an application, execution and archive system.  In this case, the granting of a single share affects multiple Tapis resources.  We explore both roles/permissions and shared resources in the following sections.

Roles and Permissions
=====================

The Security Kernel (SK) implements a distributed, role-based access control (RBAC) facility_ in which users are assigned roles that limit or allow access to resources.  At its most basic, a role is simply a named entity with an owner.  Tenant administrators can manage roles in their tenant and Tapis services can manage roles in any tenant.  Typically, services only create roles in the administrative tenant at a site_ (each site defines a restricted administrative tenant for that site).  

By assigning roles to users access to specific resources can be controlled.  Tapis supports user-based_ APIs that check if a user has a certain role.  Service and other software that performs these checks determines what membership or non-membership in a role means.  

To make managing user authorizations more flexible and convenient, a role can contain zero or more other roles.  The contained role is the *child* of the containing role.  A child role can have any number of *parents*, that is, be contained in any number of other roles.  When checking whether a user has been assigned a particular role, SK APIs check whether the user has that role directly or any of its parent roles.  When a user is assigned a role, the user is also implicitly assigned all the children of that role.

In addition, roles can contain *permissions*, which are case-sensitive strings that follow the format defined by Apache Shiro_.  The permission-creation_ API adds a permission to a role. The permission-checking_ API takes a required permission and determines if a user has a matching permission in any of its roles.  

Below are examples of permissions enforced by the Tapis Systems service.  The first permission allows read/write access to *system1* in the *MyTenant* tenant.  A user assigned a role that contains this permission would have access to *system1*.  Similarly, the second permission allows its assignees to create, read, write and delete any system in the *MyTenant* tenant. 

::

    system:MyTenant:read,write:system1
    system:MyTenant:create,read,write,delete:*

For convenience, each user is automatically assigned a default role that is implicitly created by Tapis.  Assigning a permission to a user really means adding the permission to the user's default role.

Implementations of Roles and Permissions
----------------------------------------

- Systems-rbac_
- Applications-rbac_
- Files-rbac_
- Streams-rbac_
- Actors-rbac_


..  _facility: https://tapis-project.github.io/live-docs/?service=SK#tag/role

..  _site: https://tapis.readthedocs.io/en/latest/technical/authentication.html#sites-tenancy-and-authentication

..  _user-based: https://tapis-project.github.io/live-docs/?service=SK#tag/user

..  _Shiro: https://shiro.apache.org/permissions.html

..  _permission-creation: https://tapis-project.github.io/live-docs/?service=SK#tag/role/operation/addRolePermission

..  _permission-checking: https://tapis-project.github.io/live-docs/?service=SK#tag/user/operation/isPermitted

..  _Systems-rbac: https://tapis-project.github.io/live-docs/?service=Systems#tag/Permissions

..  _Applications-rbac: https://tapis-project.github.io/live-docs/?service=Apps#tag/Permissions

..  _Files-rbac: https://tapis-project.github.io/live-docs/?service=Files#tag/Permissions

..  _Streams-rbac: https://tapis-project.github.io/live-docs/?service=Streams#tag/Roles

..  _Actors-rbac: https://tapis-project.github.io/live-docs/?service=Actors#tag/Permissions



Tapis Shared Resources
======================

The roles and permissions discussed in the last section allow fine-grained authorization to Tapis resources, such as to systems or applications.  Although the semantics of a role or permission can authorize access to multiple resources of the same type, they cannot easily authorize access to all the resources encountered in a complex workflow such as job execution.  To get a deeper understanding of the challenge, let's look at the authorizations needed to run a job.  As job progresses, these Tapis authorizations are needed:

#. Read access to the application definition.
#. Read access to the execution system definition.
#. Read access to each job input's storage system.
#. Read access to each job input's file path or object ID.
#. Read/write access to the execution system's input, output and application staging directories.
#. Read access to the job's archive system definition.
#. Write access to the job's archive system's archive path.

If a user simply wants to share an application with another user so that the latter can execute the application, many individual role or permission grants would have to be in place across multiple services.  

To solve this problem, *Tapis sharing* grants access to all resources needed to perform an action.  Tapis sharing defines a *context* in which Tapis authorization is implicitly granted to users performing an action.  This context can span multiple services.  For example, if a file is shared with a user, then access to Tapis system on which the file resides is implicitly granted when the user attempts access through the Files service.  

An important aspect of sharing is that implicit access applies within a certain context and does not apply outside of that context.  In the case of a shared file, for instance, read access to the required system definition is only valid when accessing that file through the Files API.  If the user tries to access the system definition directly through the Systems API, the request will be rejected as unauthorized (assuming no other authorizations apply).

Another characteristic of sharing is that implicit authorizations apply only to Tapis resources.  In the file sharing scenario, the system definition that is part of the shared context is an artifact defined within and under the complete control of Tapis.  Tapis is the controlling agent.  Access to the file itself, however, is ultimately under the control of the file system on which the file resides, such as a Posix file system.  Tapis sharing has no effect on authorizations enforced by external systems.  For example, a user could share a file in their home directory, but unless a grantee already has Posix access to that file, requests to access it will be denied by the operating system.

In addition to sharing resources with individual users, Tapis sharing also supports granting public access to resources.  The *public-grantee* access designation allows all users in a tenant access to the shared resource.  Where supported, the *public-grantee-no-authn* access designation grants access to all users, even users that have not authenticated with Tapis.  See individual service documentation for details on public access support. 

Shared Application Contexts (SACs)
----------------------------------

The concept of a *Shared Application Context (SAC)* recognizes that applications run in the context of a Tapis job.  This context is leveraged by multiple, cooperating services that to allow implicit access to resources .  Specifically, users are able to access systems and files to which they have not been given explicit Tapis permission when they run in a SAC.

Specifically, when a job runs in a SAC services skip Tapis authorization checking on **resources explicitly referenced in the application definition**.  Important characteristics of a SAC are:

1. The SAC-aware services are Systems, Applications, Jobs and Files.
    a) These services know when they are running in a SAC and how to alter their behavior.
2. SAC-aware services skip Tapis authorization only during Job execution of a shared application.
    a) Users are not conferred any special privileges on application-referenced resources outside of job execution.
    b) Relaxed authorization checking applies only to systems and files referenced in the application definition.
3. SSH authentication to a host is not affected by SAC processing.
    a) The Tapis system definition still determines the credentials used to login to a host.
    b) The host operating system still authorizes access to host resources.
4. File system and object store authorization is not affected by SAC processing.
    a) The authenticated user is still authorized by the actual persistent storage systems.

A user can share an application with another user and the Tapis file and system resources referenced in the application definition are also implicitly shared.  This implicit sharing is implemented by simply not performing Tapis authorization checks on these resources (and only these resources).  The underlying operating systems' and persistent storage systems' authentication and authorization mechanisms are unchanged, so users have no more low-level access than they would otherwise.  We simply remove Tapis access constraints only *during job execution*. 

SAC-Eligible Attributes
^^^^^^^^^^^^^^^^^^^^^^^

The following attributes of application definitions are SAC-eligible, meaning that implicit access to the resources they designate can be granted to jobs running in a SAC.

#. execSystemId
#. execSystemExecDir
#. execSystemInputDir
#. execSystemOutputDir
#. archiveSystemId
#. archiveSystemDir
#. fileInputs sourceUrl
#. fileInputs targetPath

If an execution system, for instance, is specified in a shared application definition, and that *system is not overridden in the job submission request*, then jobs running in a SAC will be granted implicit access to the system's definition.  The same goes for the other SAC-eligible attributes:  If their values are specified in the application and those values are not overridden when a job is submitted, Tapis implicitly grants access to the designated resource. 

Implementations of Tapis Sharing
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Systems-Sharing_
- Applications-Sharing_
- Files-Sharing_
- Jobs-Sharing_


..  _Systems-Sharing: https://tapis-project.github.io/live-docs/?service=Systems#tag/Sharing

..  _Applications-Sharing: https://tapis-project.github.io/live-docs/?service=Apps#tag/Sharing

..  _Files-Sharing: https://tapis-project.github.io/live-docs/?service=Files#tag/Sharing

..  _Jobs-Sharing: https://tapis-project.github.io/live-docs/?service=Jobs#tag/share


   









