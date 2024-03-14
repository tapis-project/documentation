.. _groups:

------
Groups
------

A *group* is a collection of Tapis users that own or have access to workflow resources.
In order to create your first workflow, you must first belong to, or create a *group*. A group
and all of its resources are tied to a particular tenant which is resolved from the url of the
request to create the group.

Groups have an *id* which must be unique within the tenant to which it belongs. Groups
also have *users*. This is a simple list of user objects where ``user.username`` is the Tapis
username/id and ``is_admin`` is a Boolean. Users with **admin** permissions i.e. ``is_admin == true`` are able to add and
remove users from a group. Only the **owner** of a group may add or delete other admin users.

Group Attributes Table
~~~~~~~~~~~~~~~~~~~~~~

+-----------+----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------+
| Attribute | Type           | Example                              | Notes                                                                                                      |
+===========+================+======================================+============================================================================================================+
| id        | String         | my.group                             | - Must be unique within the tenant.                                                                        |
+-----------+----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------+
| owner     | String         | someuser                             | - Cannot be removed from group unless ownership is transferred.                                            |
+-----------+----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------+
| tenant_id | String         | tacc                                 | - Automatically set at create-time. Determined from the url of the request. Does not need to be specified. |
+-----------+----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------+
| uuid      | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789 | - Automatically set at create-time                                                                         |
+-----------+----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------+
| users     | Array(Users)   |                                      |                                                                                                            |
+-----------+----------------+--------------------------------------+------------------------------------------------------------------------------------------------------------+

GroupUser Attributes Table
##########################

+-----------+----------------+--------------------------------------+----------------------------------------------------------+
| Attribute | Type           | Example                              | Notes                                                    |
+===========+================+======================================+==========================================================+
| username  | String         | jsmith                               | - Must be unique within the group.                       |
+-----------+----------------+--------------------------------------+----------------------------------------------------------+
| is_admin  | Boolean        | True                                 | - Must be an admin or group owner to add a user as admin |
+-----------+----------------+--------------------------------------+----------------------------------------------------------+
| uuid      | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789 | - Automatically set at create-time                       |
+-----------+----------------+--------------------------------------+----------------------------------------------------------+
| group     | String(UUIDv4) | e48ada7a-56b4-4d48-974c-7574d51a8789 | - Automatically set at create-time                       |
+-----------+----------------+--------------------------------------+----------------------------------------------------------+

.. include:: /technical/workflows/operations/getGroup.rst

.. code:: json
  
  { 
    "success": true,
    "status": 200,
    "message": "Success",
    "result": {
      "id": "my.group",
      "owner": "someuser",
      "tenant_id": "tacc",
      "uuid": "f60fdf8a-4ceb-4273-b49f-4c0dd94111c3",
      "users": [
        {
          "group": "f60fdf8a-4ceb-4273-b49f-4c0dd94111c3",
          "username": "someuser",
          "is_admin": true,
          "uuid": "c6b7acfd-da4b-4a1d-acbd-adbfa6aa4057"
        },
        {
          "group": "f60fdf8a-4ceb-4273-b49f-4c0dd94111c3",
          "username": "anotheruser",
          "is_admin": false,
          "uuid": "d6ca476a-2c19-4168-8054-264bcaaa70e7"
        }
      ]
    }
  }

Deletion
~~~~~~~~

Groups may only be deleted by the group **owner**. Upon deletion of a group, every workflow
object owned by the group will also be deleted; pipelines, tasks, archives, etc.