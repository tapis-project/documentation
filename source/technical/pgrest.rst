.. _pgrest

======
PgREST
======

The PgREST service provides an HTTP-based API to a managed Postgres database. As with the other Tapis v3 service, PgREST
utilizes a REST architecture.


Overview
--------

There are two primary collections in the PgREST API. The Management API, provided at the URL ``/v3/pgrest/manage``,
includes endpoints for managing the collection of tables, views, stored procedures, and other objects defined in the
hosted Postgres database server. Each Tapis tenant has their own schema within PgREST's managed Postrgres database
in which the tables and other objects are housed. When a table is created, endpoints are generated that allow users
to interact with the data within a table. These endpoints comprise the Data API, available at the URL ``/v3/pgrest/data``.
Each collection, ``/v3/pgrest/data/{collection}``, within the Data API corresponds to a table defined in the Management
API. The Data API is used to create, update, and read the rows within the corresponding tables.


Authentication and Tooling
--------------------------
PgREST currently recognizes Tapis v2 authentication tokens and uses these for determining access levels. A valid
Tapis v2 OAuth token should be passes to all requests to PgREST using the header ``Tapis-v2-token``.

For example, using curl:

.. code-block:: bash

  $ curl -H "Tapis-v2-token: 419465dg63h8e4782057degk20e3371" https://tacc.tapis.io/v3/pgrest/manage/tables

Note that Tapis v3 tokens are not recognized by PgREST at this time, and as a result the official Tapis v3 Python SDK
(tapipy) and other tooling will not work properly with PgREST. We are working on implementing v3 authentication in
PgREST and expect to have support for it soon.


Permissions and Roles
---------------------
PgREST currently implements a basic, role-based permissions system that leverages the Tapis v3 Security Kernel (SK). We
plan to expand on this system in the future to provide more fine-grained authorization controls. For now, three roles
are recognized:

  * ``PGREST_ADMIN`` -- Grants user read and write access to all objects (e.g., tables) in the ``/manage`` API
    as well as read and write access to all associated data in the ``/data`` API.
  * ``PGREST_WRITE`` -- Grants user read and write access to all associated data in the ``/data`` API.
  * ``PGREST_READ`` -- Grants user read access to all associated data in the ``/data`` API.

Without any of the above roles, a user will not have access to any PgREST endpoints.

Note that these roles are granted at the *tenant* level, so a user may be authorized at one level in one tenant and at a
different level (or not at all) in another tenant. In PgREST, the base URLs for a given tenant follow the pattern
``<tenant_id>.tapis.io``, just as they do for all other Tapis v3 services. Hence, this request:

.. code-block:: bash

  $ curl -H "Tapis-v2-token: $TOKEN" https://tacc.tapis.io/v3/pgrest/manage/tables

would list tables in the TACC tenant, while

.. code-block:: bash

  $ curl -H "Tapis-v2-token: $TOKEN" https://cii.tapis.io/v3/pgrest/manage/tables

would list tables in the CII tenant.


Management API
--------------

The Management API includes subcollections for each of the primary Postgres objects supported by PgREST.

Tables
^^^^^^

Table management is accomplished with the ``/v3/pgrest/manage/tables`` endpoint. Creating a table amounts to
specifying the table name, the columns on the table, including the type of each column, and any additional validation
to be performed when storing data in the column, the root URL where the associated collection will be available within
the Data API, and, optionally, which HTTP verbs should not be available on the collection.

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
          "default": "sprocket",
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

The JSON describes a table with 4 columns, ``name``, ``widget_type``, ``count``, and ``is_prviate``. The fields within
the JSON object describing each column include its type, defined in the ``data_type`` attribute (and supporting
fields such as ``char_len`` for ``varchar`` columns), as well as optional constraints, such as the NOT NULL and
UNIQUE constraint, and an optional ``default`` value. Only the ``data_type`` attribute is required.

Since the ``root_url`` attribute has value ``widgets``, an associated collection at URL ``/v3/pgrest/data/widgets``
is automatically made available for managing and retrieving the data (rows) on the table. See the `Data API`_ section
below for more details.


Supported Data Types
--------------------

Currently, PgREST supports the following column types:

 * ``varchar`` -- Variable length character field; Attribute ``char_len`` specifying max length is required.
 * ``text`` -- Variable length character field with no max length.
 * ``boolean`` -- Standard SQL boolean type.
 * ``integer`` -- 4 bytes integer field.

*Todo... Complete list of supported column types coming soon*

The project will be adding support for additional data types in subsequent releases.

Supported Constraints
---------------------

Currently, PgREST supports the following SQL constraints:

 * ``unique`` -- PgREST supports specifying a single column as unique.
 * ``null`` -- If a column description includes ``"null": false``, then the SQL ``NOT NULL`` constraint will be applied
to the table.


Views
^^^^^

*Coming soon*

Stored Procedures
^^^^^^^^^^^^^^^^^

*Coming soon*


Data API
--------

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
automatically for each table, but the semantics around this will be changed in a future release.


Creating a Row
^^^^^^^^^^^^^^
Sending a POST request to the ``/v3/pgrest/data/{root_url}`` URL will create a new row on the corresponding table. The
POST message body should be a JSON document providing values for each of the columns. The data will first be validated
with the json schema generated from the columns data sent in on table creation. This will enforce data types, max
lengths, and required fields. The data is added to the table using pure SQL format and is fully ATOMIC.

For example, the following JSON body could be used to create a new row on the widgets example table:

new_row.json:

.. code-block:: bash

    {
      "name": "example-widget",
      "widget_type": "gear",
      "count": 0,
      "is_private": false
    }

The following curl command would create a row defined by the JSON document above

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" -d "@new_row.json" https://<tenant>.tapis.io/v3/pgrest/data/widgets



Updating a Row
^^^^^^^^^^^^^^

Sending a PUT request to the ``/v3/pgrest/data/{root_url}/{id}`` URL will update an existing row on the corresponding
table. The request message body should be a JSON document providing the columns to be updates and the new values. For
example, the following would update the ``example-widget`` created above:

update_row.json

.. code-block:: bash

    {
        "count": 1
    }

The following curl command would update the ``example-widget`` row using the JSON document above

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" -H "Content-type: application/json" -d "@update_row.json" https://<tenant>.tapis.io/v3/pgrest/data/widgets/example-widget

Note that since only the ``count`` field is provided in the PUT request body, that is the only column that will be
modified.

Updating Multiple Rows
^^^^^^^^^^^^^^^^^^^^^^

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
^^^^^^^^^^^^^

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
^^^^^^^^^^^^^^^

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
^^^^^^^^^^^^^^^

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
        "initial_table_id": 1,
        "col_one": "col 1 value",
        "col_two": 3,
        "col_three": 8,
        "col_four": false,
        "col_five": null
      },
      {
        "initial_table_id": 2,
        "col_one": "val",
        "col_two": 5,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there"
      },
      {
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
        "initial_table_id": 2,
        "col_one": "val",
        "col_two": 5,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there"
      },
      {
        "initial_table_id": 3,
        "col_one": "value",
        "col_two": 7,
        "col_three": 9,
        "col_four": true,
        "col_five": "hi there again"
      }
    ]

and similarly, we can search for records where "col_4" equals ``false``

.. code-block:: bash

  $ curl -H "tapis-v2-token: $TOKEN" https://dev.tapis.io/v3/pgrest/data/init?where_col_four=false

    [
      {
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
    []


