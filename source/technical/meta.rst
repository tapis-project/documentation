.. _meta:

=============================
Meta   -  Under construction.
=============================

Root
----
The Root resource space represents the root namespace for databases on the MongoDb host. All databases are located here.

**List DB Names**

A request to the Root resource will list Database names found on the server. This request has been limited to those Users with Administrative roles.

With pySDK operation:

.. code-block:: plaintext

        $ t.meta.listDBNames()

With CURL:

.. code-block:: plaintext

        $ curl -v -X GET -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
            "StreamsDevDB",
            "v1airr"
        ]

Database
---------
The Database resource is the top level for many tenant projects. The resource maps directly to a MongoDb named database in the database server.
Case matters for matching the name of the database.

**Get DB Metadata**

This request will return the metadata properties associated with the database. The core server generates an etag in the _properties collection for a database
that is necessary for future deletion.

With SDK operation:

.. code-block:: plaintext

        $ t.meta.getDBMetadata()

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}/_meta

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        {
           "_id": "_meta",
           "_etag": { "$oid": "5ef6232b296c81742a6a3e02" }
        }



**List Collection Names**

This request will return a list of Collection names from the specified database {db}.

With pySDK operation:

.. code-block:: plaintext

        $ t.meta.listCollectionNames

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
          "streams_alerts_metadata",
          "streams_channel_metadata",
          "streams_instrument_index",
          "streams_project_metadata",
          "streams_templates_metadata",
          "tapisKapa-local"
        ]


**Create DB**

TODO: this is implementation is not exposed.

This request will create a new named database in the MongoDb root space.

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X PUT -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Get DB Metadata**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete DB**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


Collection
----------
TODO introduction for Collection resource.

**List Documents**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Get Collection Metadata**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Get Collection Size**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Create Collection**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Collection**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


Document
---------
TODO introduction for Document resource.

**Create Document**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Get Document**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Replace Document**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Modify Document**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Document**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


Index
-----
TODO introduction for Index resource.

**List Indexes**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Create Index**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Index**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


Aggregation
-----------
TODO introduction for Document resource.


**Execute Aggregation**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Create Aggregation**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Aggregation**

With SDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json