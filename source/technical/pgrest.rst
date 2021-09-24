.. _pgrest

======
PgREST
======

The PgREST service provides an HTTP-based API to a managed Postgres database. As with the other Tapis v3 service, PgREST
utilizes a REST architecture.


Overview
========

There are two primary collections in the PgREST API. The Management API, provided at the URL ``/v3/pgrest/manage``,
includes endpoints for managing the collection of tables, views, stored procedures, and other objects defined in the
hosted Postgres database server. Each Tapis tenant has their own schema within PgREST's managed Postrgres database
in which the tables and other objects are housed. When a table is created, endpoints are generated that allow users
to interact with the data within a table. These endpoints comprise the Data API, available at the URL ``/v3/pgrest/data``.
Each collection, ``/v3/pgrest/data/{collection}``, within the Data API corresponds to a table defined in the Management
API. The Data API is used to create, update, and read the rows within the corresponding tables.


Authentication and Tooling
==========================
PgREST currently recognizes Tapis v2 and v3 authentication tokens and uses these for determining access levels. 
A valid Tapis v2 OAuth token should be passec to all requests to PgREST using the header ``Tapis-v2-token``.
For example, using curl:

.. code-block:: bash

  $ curl -H "Tapis-v2-token: 419465dg63h8e4782057degk20e3371" https://tacc.tapis.io/v3/pgrest/manage/tables

Tapis v3 OAuth authentication tokens should be passed to all requests to PgREST using the header ``X-Tapis-Token``.
For example, using curl:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: TOKEN_HERE" https://tacc.tapis.io/v3/pgrest/manage/tables

Additionally, PgREST should be accessible from the Tapis v3 Python SDK (tapipy) now with the addition of v3 authentication.


Permissions and Roles
=====================
PgREST currently implements a handful of basic, role-based permissions that leverage the Tapis v3 Security Kernel (SK).


Universal Roles
---------------
For now PgREST establishes the following five universal roles:

  * ``PGREST_ADMIN`` -- Grants user read and write access to all objects (e.g., tables, views, roles) in the
    ``/manage`` API as well as read and write access to all associated data in the ``/data`` API.
  * ``PGREST_ROLE_ADMIN`` -- Grants user role creation and management access to roles in the ``/manage/roles`` API.
  * ``PGREST_WRITE`` -- Grants user read and write access to all associated data in the ``/data`` API.
  * ``PGREST_READ`` -- Grants user read access to all associated data in the ``/data`` API.
  * ``PGREST_USER`` -- Grants permission to user ``/views`` API. Each view has additional permission rules though.

Without any of the above roles, a user will not have access to any PgREST endpoints.


Fine-Tuned Role Access
----------------------

Along with the general access to endpoints when a user has a role of ``PGREST_READ`` or above, we have fine-tuned role
access to our get `views` endpoint.

Our get `views` endpoint requires only the ``PGREST_USER`` role. However each view itself when created (or modified) has a
`permission_rules` field. This field is a list of roles that the user must have in order to have access to that view. Thus
it is possible to divy out what information a user in the ``PGREST_USER`` role can get from views by restricting views with
roles created by the ``/manage/roles`` endpoint as a ``PGREST_ADMIN`` or ``PGREST_ROLE_ADMIN``.


Tenant Awareness
----------------

Note that these roles are granted at the *tenant* level, so a user may be authorized at one level in one tenant and at a
different level (or not at all) in another tenant. In PgREST, the base URLs for a given tenant follow the pattern
``<tenant_id>.tapis.io``, just as they do for all other Tapis v3 services. Hence, this request:

.. code-block:: bash

  $ curl -H "Tapis-v2-token: $TOKEN" https://tacc.tapis.io/v3/pgrest/manage/tables

would list tables in the TACC tenant, while

.. code-block:: bash

  $ curl -H "Tapis-v2-token: $TOKEN" https://cii.tapis.io/v3/pgrest/manage/tables

would list tables in the CII tenant.


Table Manage API
====================

Table management is accomplished with the ``/v3/pgrest/manage/tables`` endpoint. Creating a table amounts to
specifying the table name, the columns on the table, including the type of each column, and any additional validation
to be performed when storing data in the column, the root URL where the associated collection will be available within
the Data API, and, optionally, which HTTP verbs should not be available on the collection.


Table Creation Example
----------------------

For example, suppose we wanted to manage a table of "widgets" with four columns. We could create a table by POSTing
the following JSON document to the ``/v3/pgrest/manage/tables`` endpoint:

.. code-block:: bash

    {
      "table_name": "widgets",
      "root_url": "widgets",
      "columns": {
        "name": {
          "data_type": "varchar",
          "char_len": 255,
          "unique": true,
          "null": false
        },
        "widget_type": {
          "data_type": "varchar",
          "char_len": 100,
          "null": true
        },
        "count": {
          "data_type": "integer",
          "null": true
        },
        "is_private": {
          "data_type": "boolean",
          "null": "true",
          "default": "true"
        }
      }
    }


The JSON describes a table with 4 columns, ``name``, ``widget_type``, ``count``, and ``is_private``. The fields within
the JSON object describing each column include its type, defined in the ``data_type`` attribute (and supporting
fields such as ``char_len`` for ``varchar`` columns), as well as optional constraints, such as the NOT NULL and
UNIQUE constraint, an optional ``default`` value, and an optional ``primary_key`` value. Only the ``data_type`` attribute is required.

To create this table and the corresponding ``/data`` API, we can use curl like so:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json"
    -d "@widgets.json" https://dev.develop.tapis.io/v3/pgrest/manage/tables

If all works, the response should look something like this:

.. code-block:: bash

    {
      "status": "success",
      "message": "The request was successful.",
      "version": "dev",
      "result": {
        "table_name": "widgets",
        "table_id": 6,
        "root_url": "widgets",
        "endpoints": [
          "GET_ONE",
          "GET_ALL",
          "CREATE",
          "UPDATE",
          "DELETE"
        ]
      }
    }


Since the ``root_url`` attribute has value ``widgets``, an associated collection at URL ``/v3/pgrest/data/widgets``
is automatically made available for managing and retrieving the data (rows) on the table. See the `Data API`_ section
below for more details.


Table Definition Rules
----------------------

This is a complete list of constraints and properties a table can have in it's table definition. Each table definition has a host of
fields, with the column field have a host of options to delegate how to create the postgres column.

* ``table_name`` - **required**

  * The name of the table in question.
  
* ``root_url`` - **required**
  
  * The root_url for PgRESTs /data endpoint.
  * Ex: root_url "table25" would be accessible via "http://pgrestURL/data/table25".
  
* ``enums``

  * Enum generation is done in table definitions.
  * Provide a dict of enums where the key is enum name and the value is the possible values for the enum.
  * Ex: ``{"accountrole": ["ADMIN", "USER"]}``

    * Creates an "accountrole" enum that can have values of "ADMIN" or "USER"

  * Deletion/Updates are not currently supported. Speak to developer if you're interested in a delete/update endpoint.
  
* ``comments``
  
  * Field to allow for better readability of table json. Table comments are saved and outputted on /manage/tables/ endpoints.
  
* ``constraints``
  
  * Specification of Postgres table constraints. Currently only allows multi-column unique constraints
  * Constraints available:
  
    * ``unique``
  
      * multi-column unique constraint that requires sets of column values to be unique.
      * Ex: ``"constraints": {"unique": {"two_col_pair": ["col_one", "col_two"]}}``

        * This means that col_one and col_two cannot have pairs of values that are identical.
        * The constraint name can be specified as well

* ``columns`` - **required**

  * Column definitions in the form of a dict. Dict key would be column, value would be column definition.
  * Ex: ``{"username": {"unique": true, "data_type": "varchar", "char_len": 255}``
  * Columns arguments are as follows.

    * ``data_type`` - **required**
  
      * Specifies the data type for values in this column.
      * Can be varchar, datetime, {enumName}, text, timestamp, serial, varchar[], boolean, integer, integer[].

        * Note: varchar requires the char_len column definition.
        * Note: Setting a timestamp data_type column default to ``UPDATETIME`` or ``CREATETIME`` has special properties.
  
          * ``CREATETIME`` sets the field to the UTC time at creation. It is then not changed later.
          * ``UPDATETIME`` sets the filed to the UTC time at creation. It is updated to the update time when it is updated.

    * ``char_len`` 

      * Additional argument for varchar data_types. Required to set max value size.
      * Can be any value from 1 to 255.

    * ``unique``

      * Determines whether or not each value in this column is unique.
      * Can be true or false.

    * ``null``

      * States whether or not a value can be "null".
      * Can be true or false.

    * ``comments``

      * Field to allow for better readability of table and column json. Column comments are not saved or used. They are for json readability only.

    * ``default``

      * Sets default value for column to fallback on if no value is given.
      * Must follow the data_type for the column.
      * Note: Setting a timestamp data_type column default to ``UPDATETIME`` or ``CREATETIME`` has special properties.

        * ``CREATETIME`` sets the field to the UTC time at creation. It is then not changed later.
        * ``UPDATETIME`` sets the filed to the UTC time at creation. It is updated to the update time when it is updated.

    * ``primary_key``

      * Specifies primary_key for the table.
      * This can only be used for one column in the table.
      * This primary_key column will be the value users can use to get a row in the table, ``/v3/pgrest/data/my_pk``,.
      * If this is not specified in a table, primary_key defaults to "{table_name}_id".
        * Note that this default cannot be modified and is of data_type=serial.

    * ``foreign_key``

      * Weather or not this key should reference a key in another table, a "foreign key".
      * Can be true or false.
      * If foreign_key is set to true, columns arguments ``reference_table``, ``reference_column``, and ``on_delete`` must also be set.

        * ``reference_table``

          * Only needed in the case that foreign_key is set to true.
          * Specifies the foreign table that the foreign_key is in.
          * Can be set to the table_name of any table.

        * ``reference_column``

          * Only needed in the case that foreign_key is set to true.
          * Specifies the foreign column that the foreign_key is in.
          * Can be set to the key for any column in the reference_table.

        * ``on_delete``

          * Only needed in the case that foreign_key is set to true.
          * Specifies the deletion strategy when referencing a foreign key.
          * Can be set to ``CASCADE`` or ``SET NULL``
          
            * ``CASCADE`` deletes this column if the foreign key's column is deleted.
            * ``SET NULL`` set this column to null if the foreign key's column is deleted.


Retrieving Table Descriptions
-----------------------------

You can list all tables you have access to by making a GET request to ``/v3/pgrest/manage/tables``. For example

.. code-block:: bash

  $ curl -H "tapis-v2-token: $tok" https://dev.tapis.io/v3/pgrest/manage/tables

returns a result like

.. code-block:: bash

    [
       {
          "table_name": "initial_table",
          "table_id": 3,
          "root_url": "init",
          "tenant": "dev",
          "endpoints": [
            "GET_ONE",
            "GET_ALL",
            "CREATE",
            "UPDATE",
            "DELETE"
          ],
          "tenant_id": "dev"
        },
        {
          "table_name": "widgets",
          "table_id": 6,
          "root_url": "widgets",
          "tenant": "dev",
          "endpoints": [
            "GET_ONE",
            "GET_ALL",
            "CREATE",
            "UPDATE",
            "DELETE"
          ],
          "tenant_id": "dev"
        }
    ]

We can also retrieve a single table by ``id``. For example

.. code-block:: bash

  $ curl -H "tapis-v2-token: $tok" https://dev.tapis.io/v3/pgrest/manage/tables/6

    {
        "table_name": "widgets",
        "table_id": 6,
        "root_url": "widgets",
        "endpoints": [
          "GET_ONE",
          "GET_ALL",
          "CREATE",
          "UPDATE",
          "DELETE"
        ],
        "tenant_id": "dev"
    }

We can also pass ``details=true`` query parameter to see the column definitions and validation schema for a particular
table. This can be useful to understand exactly what's happening. The call would be as follows:

.. code-block:: bash

    $ curl -H "tapis-v2-token: $tok" https://dev.tapis.io/v3/pgrest/manage/tables/6?details=true


Example of Complex Table
------------------------

The following is a working complex table definition using all parameters for user reference.

.. code-block:: bash

  {
    "table_name": "UserProfile",
    "root_url": "user-profile",
    "delete": false,
    "enums": {"accountrole": ["ADMIN",
                              "USER",
                              "GUEST"]},
    "comments": "This is the user profile table that keeps track of user profiles and data",
    "constraints": {"unique": {"unique_first_name_last_name_pair": ["first_name", "last_name"]}},
    "columns": {
      "user_profile_id": {
        "data_type": "serial",
        "primary_key": true
      },
      "username": {
        "unique": true,
        "data_type": "varchar",
        "char_len": 255
        "comments": "The username used by *** service"
      },
      "role": {
        "data_type": "accountrole"
      },
      "company": {
        "data_type": "varchar",
        "char_len": 255,
        "foreign_key": true,
        "reference_table": "Companys",
        "reference_column": "company_name",
        "on_delete": "CASCADE"
      },
      "employee_id": {
        "data_type": "integer",
        "foreign_key": true,
        "reference_table": "Employees",
        "reference_column": "employee_id",
        "on_delete": "CASCADE"
      }
      "first_name": {
        "null": true,
        "data_type": "varchar",
        "char_len": 255
      },
      "last_name": { 
        "null": true,
        "data_type": "varchar",
        "char_len": 255
      },
      "created_at": {
        "data_type": "timestamp",
        "default": "CREATETIME"
      },
      "last_updated_at": {
        "data_type": "timestamp",
        "default": "UPDATETIME"
      }
    }
  }




Table User API
==============

The Data API provides endpoints for managing and retrieving data (rows) stored on tables defined through the Management
API. For each table defined through the Management API, there is a corresponding endpoint within the Data API with URL
``/v3/pgrest/data/{root_url}``, where ``{root_url}`` is the associated attribute on the table.

Continuing with our widgets table from above, the associated endpoint within the Data API would have URL
``/v3/pgrest/data/widgets`` because the ``root_url`` property of the widgets table was defined to be ``widgets``.
Moreover, all 5 default endpoints on the ``widgets`` collection are available (none were explicitly restricted when
registering the table). The endpoints within the ``widgets`` can be described as follows:

+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
| GET | POST | PUT | DELETE | Endpoint                                      |  Description                    |
+=====+======+=====+========+===============================================+=================================+
|  X  |  X   |  X  |        | /v3/pgrest/data/widgets                       | List/create widgets; bulk update|
|     |      |     |        |                                               | multiple widgets.               |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |  X  |   X    | /v3/pgrest/data/widgets/{id}                  | Get/update/delete a widget by   |
|     |      |     |        |                                               | id.                             |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+

Note that the ``id`` column is used for referencing a specific row. Currently, PgREST generates this column
automatically for each table and calls it `{table_name}_id`. It is a sql serial data type. To override this
generic ``id`` column, you may assign a key of your choice the ``primary_key`` constraint. We'll then use the
values in this field to get a specified rows. ``primary_key`` columns, must be integers or varchars which are
not null and unique.

Additionally, to find the ``id`` to use for your row, the data endpoints return a ``_pkid`` field in the results
for each row for ease of use. ``_pkid`` is not currently kept in the database, but is added to the result object
between retrieving the database result and returning the result to the user. As such, ``where`` queries will NOT
work on the ``_pkid`` field.


Creating a Row
--------------

Sending a POST request to the ``/v3/pgrest/data/{root_url}`` URL will create a new row on the corresponding table. The
POST message body should be a JSON document providing values for each of the columns inside a single ``data`` object.
The values will first be validated with the json schema generated from the columns data sent in on table creation. This
will enforce data types, max lengths, and required fields. The row is then added to the table using pure SQL format
and is fully ATOMIC.

For example, the following JSON body could be used to create a new row on the widgets example table:

new_row.json:

.. code-block:: bash

    {
        "data": {
          "name": "example-widget",
          "widget_type": "gear",
          "count": 0,
          "is_private": false
        }
    }

The following curl command would create a row defined by the JSON document above

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" -d "@new_row.json" https://<tenant>.tapis.io/v3/pgrest/data/widgets

if all goes well, the response should look like

.. code-block:: bash

    {
      "status": "success",
      "message": "The request was successful.",
      "version": "dev",
      "result": [
        {
          "widgets_id": 1,
          "name": "example-widget",
          "widget_type": "gear",
          "count": 0,
          "is_private": false
        }
      ]
    }

Note that an ``id`` of ``1`` was generated for the new record.


Updating a Row
--------------

Sending a PUT request to the ``/v3/pgrest/data/{root_url}/{id}`` URL will update an existing row on the corresponding
table. The request message body should be a JSON document providing the columns to be updates and the new values. For
example, the following would update the ``example-widget`` created above:

update_row.json

.. code-block:: bash

    {
      "data": {
        "count": 1
      }
    }

The following curl command would update the ``example-widget`` row (with ``id`` of ``i``) using the JSON document above

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" -d "@update_row.json" https://<tenant>.tapis.io/v3/pgrest/data/widgets/1

Note that since only the ``count`` field is provided in the PUT request body, that is the only column that will be
modified.


Updating Multiple Rows
----------------------

Update multiple rows with a single HTTP request is possible using a ``where`` filter (for more details, see the section
`Where Stanzas`_ below), provided in the PUT request
body. For example, we could update the ``count`` column on all rows with a negative count to 0 using the following

update_rows.json

.. code-block:: bash

    {
        "count": 0,
        "where": {
            "count": {
                "operator": "<",
                "value": 0
            }
        }
    }

This update_rows.json would be used in a PUT request to the root ``widgets`` collection, as follows:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" -d "@update_rows.json" https://<tenant>.tapis.io/v3/pgrest/data/widgets


Where Stanzas
-------------

In PgREST, ``where`` stanzas are used in various endpoints throughout the API to filter the collection of results (i.e.,
rows) that an action (such as retrieving or updating) is applied to. The ``where`` stanza should be a JSON object with
each key being the name of a column on the table and the value under each key being a JSON object with two properties:

  * ``operator`` -- a valid operator for the comparison. See the `Valid Operators`_ table below.
  * ``value`` -- the value to compare the row's column to (using the operator).

Naturally, the type (string, integer, boolean, etc.) of the ``value`` property should correspond to the type of the
column specified by the key. Note that multiple keys corresponding to the same column or different columns can be
included in a single ``where`` stanza. For example, the following where stanza would pick out rows whose ``count``
was between ``0`` and ``100`` and whose ``is_private`` property was ``true``:

.. code-block:: bash

    {
        "where": {
            "count": {
                "operator": ">",
                "value": 0
            },
            "count": {
                "operator": "<",
                "value": 100
            },
            "is_private": {
                "operator": "=",
                "value": true
            }
    }


Valid Operators
---------------

PgREST recognizes the following operators for use in ``where`` stanzas.

+-----------+---------------------+---------------------------------+
| Operator  | Postgres Equivalent | Description                     |
+===========+=====================+=================================+
|    <      |         <           |  Less than                      |
+-----------+---------------------+---------------------------------+
|    >      |         >           |  Greater than                   |
+-----------+---------------------+---------------------------------+
|    =      |         =           |  Equal                          |
+-----------+---------------------+---------------------------------+
|  ...      |        ...          |  ...                            |
+-----------+---------------------+---------------------------------+

*Todo... Full table coming soon*


Retrieving Rows
---------------

To retrieve data from the ``/data`` API, make an HTTP GET request to the associated URL; an HTTP GET to
``/v3/pgrest/data/{root_url}`` will retrieve all rows on the associated table, while an HTTP GET to
``/v3/pgrest/data/{root_url}/{id}`` will retrieve the individual row.

For example,

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" https://dev.tapis.io/v3/pgrest/data/init

retrieves all rows of the table "init":

.. code-block:: bash

    [
      {
        "_pkid": 1,
        "initial_table_id": 1,
        "col_one": "col 1 value",
        "col_two": 3,
        "col_three": 8,
        "col_four": false,
        "col_five": null
      },
      {
        "_pkid": 2,
        "initial_table_id": 2,
        "col_one": "val",
        "col_two": 5,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there"
      },
      {
        "_pkid": 3,
        "initial_table_id": 3,
        "col_one": "value",
        "col_two": 7,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there again"
      }
    ]

while the following curl:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" https://dev.tapis.io/v3/pgrest/data/init/3

retrieves just the row with id "3":

.. code-block:: bash

      {
        "_pkid": 3,
        "initial_table_id": 3,
        "col_one": "value",
        "col_two": 7,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there again"
      }

We can also search for specific rows using a ``where`` query parameter appended to the ``/v3/pgrest/data/{root_url}``
endpoint. The ``where`` query parameter takes the form ``where_<column>=<value>``. For instance with the above example,
we can search for all records where "col_four" equals ``true`` with the following:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" https://dev.tapis.io/v3/pgrest/data/init?where_col_four=true

    [
      {
        "_pkid": 2,
        "initial_table_id": 2,
        "col_one": "val",
        "col_two": 5,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there"
      },
      {
        "_pkid": 3,
        "initial_table_id": 3,
        "col_one": "value",
        "col_two": 7,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there again"
      }
    ]

and similarly, we can search for records where "col_four" equals ``false``

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" https://dev.tapis.io/v3/pgrest/data/init?where_col_four=false

    [
      {
        "_pkid": 1,
        "initial_table_id": 1,
        "col_one": "col 1 value",
        "col_two": 3,
        "col_three": 8,
        "col_four": false,
        "col_five": null
      }
    ]

Note that the result is always a JSON list, even when one or zero records are returned:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" https://dev.tapis.io/v3/pgrest/data/init?where_col_two=2


Views Manage API
====================

Views allow admins to create postgres views to cordone off data from users and give users exactly what they need.
These views allow for permission_rules which cross reference a users roles, if a user has all roles in the
permission_rules they have access to view the view.

Admins are able to create views with a post to the ``/v3/pgrest/manage/views`` endpoint. A get to ``/v3/pgrest/manage/views``
returns information regarding the views.


View Definition Rules
---------------------

A post to the ``/v3/pgrest/manage/views`` endpoint to create a view expects a json formatted view definition. Each view
definition can have the following rules.

* ``view_name`` - **required**
  
  * The name of the view in question.

* ``root_url`` - **required**

  * The root_url for PgRESTs /views endpoint.
  * Ex: root_url "view25" would be accessible via "http://pgrestURL/views/table25".

* ``select_query`` - **required**

  * Query to select from the table specified with from_table

* ``from_table`` - **required**

  * Table to read data from

* ``where_query``

  * Optional field that allows you to specify a postgres where clause for the view

* ``comments``

  * Field to allow for better readability of view json. Table comments are saved and outputted on ``/v3/pgrest/manage/views/ endpoints.

* ``permission_rules``

  * List of roles required to view this view.
  * If nothing is given, view is open to all.

View Creation Example
---------------------

.. code-block:: bash

  # new_view.json
  {'view_name': 'test_view', 
   'root_url': 'just_a_cool_url',
   'select_query': '*',
   'from_table': 'initial_table_2',
   'where_query': 'col_one >= 90',
   'permission_rules': ['lab_6_admin', 'cii_rep'],
   'comments': 'This is a cool test_view to view all of
                initial_table_2. Only users with the
                lab_6_admin and cii_rep role can view this.'}

The following code block would then be able to create the new view.

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" \
    -d "@new_view.json" https://<tenant>.tapis.io/v3/pgrest/manage/views

If you then wanted to get information about the view, but not the result of the view itself, you can make a call to the
``/v3/pgrest/manage/views/just_a_cool_url`` endpoint.

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" \
    https://<tenant>.tapis.io/v3/pgrest/manage/views/just_a_cool_url


Views User API
=========

Users have no way to change views or to modify anything dealing with them, but they are able to get views that they have
sufficient permissions to view. The ``/v3/pgrest/views/{view_id}`` requires the user to have at least a PGREST_USER role,
this is to force all users to be in some way identified or managed. The PGREST_USER role grants no permissions except the
permission to call a get on the ``/v3/pgrest/views/{view_id}`` endpoint. This means that admins can assume PGREST_USER users
can only view `views` in which the user satisfies the permissions declared in a `views` ``permission_rules``. This gives
admins fine-tuned controls on postgres data by using solely views.

Users can make a get to ``/v3/pgrest/views/{view_id}`` with the following curl.

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" \
    https://<tenant>.tapis.io/v3/pgrest/views/just_a_cool_url


Role Manage API
===================

Role management is solely allowed for users in the PGREST_ROLE_ADMIN role, or PGREST_ADMIN. These endpoints allow users to
create, grant, and revoke SK roles to users to match `view` ``permission_rules``. Modifiable roles all must start with 
``PGREST_``, this ensures users can't change roles that might matter to other services. Along with that, users cannot manage
the ``PGREST_ADMIN``, ``PGREST_ROLE_ADMIN``, ``PGREST_WRITE``, or ``PGREST_READ`` roles. This might be changed, but for now,
contact an admin to be given these roles. Note, users can grant or revoke the ``PGREST_USER`` role, so that role_admins can
manage who can see views without unnecessary intervention.

Users have no access to these endpoints or anything regarding roles. 

Role Creation
-------------

To create a new role users make a post to ``/v3/pgrest/roles/`` with a body such as:

.. code-block:: bash

  # new_role.json
  {"role_name": "PGREST_My_New_Role", "description": "A new role!"}

The post would then be as follows:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" \
    -d "@new_role.json" https://<tenant>.tapis.io/v3/pgrest/roles

This would result in the creation of the ``PGREST_My_New_Role`` role.

Role Creation Definition
^^^^^^^^^^^^^^^^^^^^^^^^

* ``role_name`` - **required**
  
  * Name of the role to create, must start with ``PGREST_``. 

* ``description`` - **required**

  * A description of the role to be used for future reference in SK.


Role Management
---------------

To grant or revoke a role to a specific username, users can make a post to ``/v3/pgrest/roles/{role_name}`` with a body such as:

.. code-block:: bash

  # grant_role.json
  {"method": "grant", "username": "user3234"}

The post would then be as follows:

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" \
    -d "@grant_role.json" https://<tenant>.tapis.io/v3/pgrest/roles/PGREST_My_New_Role

This would result in the user, ``user3234`` being granted the role, ``PGREST_My_New_Role``.

Role Management Parameters
^^^^^^^^^^^^^^^^^^^^^^^^^^

* ``method`` - **required**
  
  * String of either "grant" or "revoke", specifying whether to revoke or grant the role to a user.

* ``username`` - **required**

  * Username to grant role to, or to revoke role from.



Stored Procedures
=================

*Coming soon*


API Reference
=================

+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
| GET | POST | PUT | DEL | Endpoint                                  | Description                                           |
+=====+======+=====+=====+===========================================+=======================================================+
|  X  |  X   |     |     | /v3/pgrest/manage/tables                  | Get/Create tables for the tenant.                     |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |      |  X  |  X  | /v3/pgrest/manage/tables/{table_id}       | Get/Update/Delete a specified table.                  |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |  X   |  X  |     | /v3/pgrest/data/{table_id}                | Get/Create/Update rows for a specified table.         |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |      |  X  |  X  | /v3/pgrest/data/{table_id}/{row_id}       | Get/Update/Delete specific row for a specified table. |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |  X   |     |     | /v3/pgrest/manage/views                   | Get/Create view for the tenant.                       |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |      |     |  X  | /v3/pgrest/manage/views/{view_id}         | Get/Delete view specified.                            |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |      |     |     | /v3/pgrest/views/{view_id}                | Get results from view specified.                      |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |  X   |     |     | /v3/pgrest/manage/roles                   | Get/Create roles in SK for the tenant.                |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
|  X  |  X   |     |     | /v3/pgrest/manage/roles/{role_name}       | Get/Manage role specified.                            |
+-----+------+-----+-----+-------------------------------------------+-------------------------------------------------------+
