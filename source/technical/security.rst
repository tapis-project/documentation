..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _security:

########
Security
########

.. raw:: html

    <style> .red {color:#FF4136; font-weight:bold; font-size:20px} </style>

.. role:: red


----

Introduction to the Security Kernel
===================================


The Security Kernel (SK) microservice provides role-based authorization and secrets management for Tapis.  Authentication is based on JSON Web Tokens (JWTs) managed by the Authentication_ subsystem.

SK uses a PostgreSQL database to store its authorization data and the open source version of HashiCorp Vault_ as its secrets backend.  In the sections that follow, we discuss SK's authorization and secrets model, interfaces and capabilities.  The actual SK REST APIs can be found `here <https://tapis-project.github.io/live-docs/?service=SK>`_.  

.. _SK: https://tapis-project.github.io/live-docs/?service=SK

.. _Authentication: https://tapis.readthedocs.io/en/latest/technical/authentication.html

.. _Shiro: https://shiro.apache.org/

.. _roles: https://shiro.apache.org/java-authorization-guide.html

.. _permissions: http://shiro.apache.org/permissions.html

.. _Tenants: https://tapis.readthedocs.io/en/latest/technical/authentication.html#tenants

.. _Vault: https://www.hashicorp.com/products/vault

Authorization
=============

SK authorization is based on an extended version of the Apache Shiro_ authorization model, which defines both roles_ and permissions_.  

Roles
-----

In a tenant, each role has a unique name and is assigned an owner.  SK provides a set of *role endpoints* to create, update, query and delete roles.  It also provides *user endpoints* to grant users roles, revoke roles from users, and query the roles assigned to a user.  With these primitives, Tapis implements fairly typical role-base access control using a distributed architecture.  Among the most called endpoints is `/user/hasRole <https://tapis-project.github.io/live-docs/?service=SK#operation/hasRole>`_, which checks whether a user has a certain role.  

All role-based authorizations go through SK, which provides site-wide, network access to authorization checking.  A possible downside of this approach is the extra network cost incurred on Tapis calls that authorize users (many service to service calls avoid this overhead).  So far this overhead has had minimal impact.

Built-In Roles
^^^^^^^^^^^^^^

Each tenant has at least one tenant administrator, which is nothing more than a user assigned a distinguished, tightly controlled role (*$!tenant_admin*).  The initial tenant administrator is assigned during tenant creation; see Tenants_ for details.  There are special endpoints for granting and revoking the tenant administrator role, and for validating and listing administrators in a tenant.  Only a tenant administrator can grant or revoke the administrator role to another user.

Each user is implicitly given a default role.  These roles have names that begin with "$$" and end with the user's ID.  Default roles are most commonly used in conjunction permissions, as discussed below. 

Hierarchical Roles
^^^^^^^^^^^^^^^^^^

One feature that distinguishes SK's implementation of role-based authorization is that roles can be arranged in directed acyclic graphs (DAGs) based on parent/child relationships.  We say a parent role *contains* a child role, and a child can have zero or more parents.  The set of roles defined in a tenant can be thought of as a forest of DAGs.

This contains relation allows SK users to define roles with fine granularity and then compose them in flexible ways.  For example, let DirA be the root of a directory subtree that is shared among users.  We could define *DirA_Owner* as a parent role with *DirA_Reader* and *DirA_Writer* as child roles (assume the typical semantics implied by their names).  Users assigned *DirA_Owner* would implicitly also be assigned *DirA_Reader* and *DirA_Writer*.  A user only assigned *DirA_Reader* would not have write privileges.

Taking the example one step further, assume for DirB we define *DirB_Owner* as a parent role with *DirB_Reader* and *DirB_Writer* children.  We could then define another role, *AllDir_Reader*, with *DirA_Reader* and *DirB_Reader* children.  Users assigned *AllDir_Reader* would have read access to both DirA and DirB.  

Permissions
-----------

In addition to checking whether a user has been granted a certain role, SK authorization can also be based on permissions.  SK roles can contain zero or more permission strings.  The syntax and semantics of these permissions are explained in the `Shiro documentation <http://shiro.apache.org/permissions.html>`_.  The `/usr/isPermitted <https://tapis-project.github.io/live-docs/?service=SK#operation/isPermitted>`_ and related SK endpoints are called to determine if a user has a permission matching a required permission string.

Permissions only exist inside roles.  For convenience, SK implements permission endpoints that automatically apply to a user's default role.  See the `/user/grantUserPermission <https://tapis-project.github.io/live-docs/?service=SK#operation/grantUserPermission>`_ endpoint for details.

Extended Permissions
^^^^^^^^^^^^^^^^^^^^

SK implements the full Shiro permission model and extends it to accommodate hierarchical resources such as file systems.  For certain registered permission schemas, the last component of a specification can be treated as *extended path attribute*.  Extended path attributes enhance the standard Shiro matching algorithm with one that treats designated components as hierarchical names, such as Posix file or directory path names.  Consider, for example, permissions that conform to the registered *files* schema:

::

  SCHEMA:    files:<tenant>:<operation>:<systemId>:<path>
  Examples:  files:tacc:read:mysystem:/home/bud/data
             files:mytenant:read,write:mysystem:/home/mary/images

When a user is assigned a role that contains the first example permission string, then that user is authorized to read files in the */home/bud/data* directory subtree.  A user assigned the second permission is authorized to read and write files in the */home/mary/images* directory subtree.  

SK's extended attribute permissions are used to maintain authorization to hierarchical resources *outside of those resources*.  The need for externalized authorization control arises, for instance, when a single service account is used to access data on a system for multiple actual users.  In this case, the host system is always accessed using the same account, but authorization needs to be carried out for different actual Tapis users. 

Secrets
=======

SK uses HashiCorp Vault_ as is backend database for storing and managing secrets.  There is no direct access to Vault for users or services--all access comes through SK.  SK allows secrets to be created, read, versioned, deleted and destroyed by reflecting in its API the capabilities of Vault's version 2 `Key/Value <https://www.vaultproject.io/docs/secrets/kv/kv-v2>`_ secrets engine.  

SK overlays Vault's native capabilities with its own *typed secrets model*.  The basic idea is that SK requires users to provide a *secretType* and *secretName* on most of its calls.  Using this information, SK calculates the virtual paths (i.e., locations) in Vault being referenced.  Users do not need to understand Vault's naming scheme and SK has complete control of where secrets reside inside of Vault.  The following table lists the secret types supported by SK.

  ==================       ===========
  Secret Type              Description
  ==================       ===========
  Service Password         Password used by services to acquire their JWTs
  JWT Signing Key          Tenant-specific JWT signing key used by Tokens service
  DB Credentials           Credentials used by services to access their databases
  System Credentials       Credentials for accessing Tapis systems
  User                     User secrets
  ==================       ===========

Only the User secret type can be used by Tapis users; the rest are reserved for Tapis services only.  Currently, SK only allows a single secret to be referenced by each secretType/secretName combination.  Otherwise, the full capabilities of the underlying Vault secrets engine is reflected in the SK `secrets API <https://tapis-project.github.io/live-docs/?service=SK#tag/vault>`_.

