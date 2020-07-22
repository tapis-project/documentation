.. _meta:

=============================
Meta   -  Under construction.
=============================
Meta V3 is a REST API Microservice for MongoDB which provides server-side Data, Identity and Access Management for Web and Mobile applications.

Meta V3 is:

A Stateless Microservice.
With Meta V3 teams can focus on building Angular or other frontend applications, because most of the server-side
logic necessary to manage database operations, authentication / authorization and related APIs is automatically handled,
without the need to write any server-side code except for the UX/UI.

For example, to insert data into MongoDB a developer has to just create client-side JSON documents and then execute POST operations via HTTP to Meta V3.
Other functionality of a modern MongoDB installation will be made available as the need presents itself.

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

With pySDK operation:

.. code-block:: plaintext

        $ t.meta.getDBMetadata()

With CURL:

.. code-block:: plaintext

        $ curl -v -X GET -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}/_meta

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

        $ curl -v -X GET -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}

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

TODO: this implementation is not exposed.

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

        { }


**Delete DB**



With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X DELETE -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

     { }


Collection
----------
The Collection resource allows requests for managing and querying json documents.

**Create Collection**



With pySDK operation:

.. code-block:: plaintext

        $ t.meta.createCollection

With CURL:

.. code-block:: plaintext

        $ curl -v -X PUT -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}/{collection}

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**List Documents**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X GET -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/{db}/{collection}

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Collection**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Get Collection Size**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

**Get Collection Metadata**

With pySDK operation:

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

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Get Document**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Replace Document**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Modify Document**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Document**

With pySDK operation:

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

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Create Index**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Index**

With pySDK operation:

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

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Create Aggregation**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


**Delete Aggregation**

With pySDK operation:

.. code-block:: plaintext

        $ t.meta

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '' $BASE_URL/v3/meta/

The response will look something like the following:

.. container:: foldable

     .. code-block:: json