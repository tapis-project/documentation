..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _pods:

######
Pods 
######

----

Introduction to the Pods Service
================================

What is the Pods Service
------------------------

The Pods Service is a web service and distributed computing platform providing pods-as-a-service (PaaS). The service 
implements a message broker and processor model that requests pods, alongside a health module to poll for pod
data, including logs, status, and health. The primary use of this service is to have quick to deploy long-lived
services based on Docker images that are exposed via HTTP or TCP endpoints listed by the API.

The Pods service provides functionality for two types of pod solutions:
    * *Templated Pods* for run-as-is popular images. Neo4J is one example, the template manages TCP ports, user creation, and permissions.
    * *Custom Pods* for arbitrary docker images with less functionality. In this case we will expose port 5000 and do nothing else.


Using the Pods Service
----------------------

Please create issues on our `github repo <https://github.com/tapis-project/pods_service>`_ and report problems to Christian R. Garcia.
The service is available to researchers and students. To learn more about the the system, including getting access, follow the
instructions in :doc:`/getting-started/index`.


----

Getting Started
===============

This Getting Started guide will walk you through the initial steps of setting up the necessary accounts and installing
the required software before moving to the Pods Quickstart, where you will create your first Pods service pod. If
you are already using Docker Hub and the TACC TAPIS APIs, feel free to jump right to the `Pods Quickstart`_ or check
out the `Pods Live Docs <https://tapis-project.github.io/live-docs/?service=Pods>`_.


Account Creation and Software Installation
------------------------------------------

Create a TACC account
^^^^^^^^^^^^^^^^^^^^^

The main instance of the Pods platform is hosted at the Texas Advanced Computing Center (`TACC <https://tacc.utexas.edu>`_).
TACC designs and deploys some of the world's most powerful advanced computing technologies and innovative software
solutions to enable researchers to answer complex questions. To use the TACC-hosted Pods service, please
create a `TACC account <https://portal.tacc.utexas.edu/account-request>`_.

Create a Docker account
^^^^^^^^^^^^^^^^^^^^^^^

`Docker <https://www.docker.com/>`_ is an open-source container runtime providing operating-system-level
virtualization. The Pods service pulls images for its pods from the public Docker Hub. To register pods
you will need to publish images on Docker Hub, which requires a `Docker account <https://hub.docker.com/>`_ .

Install the Tapis Python SDK
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To interact with the TACC-hosted Abaco platform in Python, we will leverage the Tapis Python SDK, tapipy. To install it,
simply run:

.. code-block:: bash

    $ pip3 install tapipy

.. attention::
    ``tapipy`` works with Python 3.



Working with TACC OAuth
-----------------------

Authentication and authorization to the Tapis APIs uses `OAuth2 <https://oauth.net/2/>`_, a widely-adopted web standard.
Our implementation of OAuth2 is designed to give you the flexibility you need to script and automate use of Tapis
while keeping your access credentials and digital assets secure. This is covered in great detail in our
Tenancy and Authentication section, but some key concepts will be highlighted here, interleaved with Python code.


Create an Tapis Client Object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first step in using the Tapis Python SDK, tapipy, is to create a Tapis Client object. First, import
the ``Tapis`` class and create python object called ``t`` that points to the Tapis server using your TACC
username and password. Do so by typing the following in a Python shell:

.. Important::
   Support for Pods service in Tapipy was added in version 1.2.3.


.. code-block:: python

    # Import the Tapis object
    from tapipy.tapis import Tapis

    # Log into you the Tapis service by providing user/pass and url.
    t = Tapis(base_url='https://tacc.tapis.io',
              username='your username',
              password='your password')


Generate a Token
^^^^^^^^^^^^^^^^

With the ``t`` object instantiated, we can exchange our credentials for an access token. In Tapis, you
never send your username and password directly to the services; instead, you pass an access token which
is cryptographically signed by the OAuth server and includes information about your identity. The Tapis
services use this token to determine who you are and what you can do.

.. code-block:: python

    # Get tokens that will be used for authenticated function calls
    t.get_tokens()
    print(t.access_token.access_token)

    Out[1]: eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...

Note that the tapipy ``t`` object will store and pass your access token for you, so you don't have to manually provide
the token when using the tapipy operations. You are now ready to check your access to the Tapis APIs. It will
expire though, after 4 hours, at which time you will need to generate a new token. If you are interested, you
can create an OAuth client (a one-time setup step, like creating a TACC account) that can be used to generate
access and refresh tokens. For simplicity, we are skipping that but if you are interested, check out the Tenancy and
Authentication section.

Check Access to the Tapis APIs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The tapipy ``t`` object should now be configured to talk to all Tapis APIs on your behalf. We can check that the client is
configured properly by making any API call. For example, we can use the authenticator service to retrieve the full
TACC profile of our user. To do so, use the ``get_profile()`` function associated with the ``authenticator`` object on
the ``t`` object, passing the username of the profile to retrieve, as follows.

.. code-block:: python

    t.authenticator.get_profile(username='apitest')

    Out[1]:
    create_time: None
    dn: cn=apitest,ou=People,dc=tacc,dc=utexas,dc=edu
    email: aci-cic@tacc.utexas.edu
    username: apitest

----

Pods Quickstart
================

In this Quickstart, we will create an Pods service pod from a basic Python function. Then we will get pod credentials and logs.

Registering a templated Pod
---------------------------

To get started we're going to create a templated Pod. To do this, we will use the ``Tapis`` client object we created above
(see `Working with TACC OAuth`_).


To register an pod using the tapipy library, we use the ``pods.create_pod()`` method and pass the arguments describing
the pod we want to register through the function parameters. For example:

.. code-block:: python

    from tapipy.tapis import Tapis

    t = Tapis(
        base_url='https://tacc.tapis.io',
        username='<userid>',
        password='*********'
    )

    t.pods.create_pod(
        pod_id='docpod',
        pod_template='template/neo4j',
        description='My example pod!'
    )

As you can see, we're using pod_template equal to `template/neo4j`, template being the namespace for our templated pods.
You should see a response like this:

.. code-block:: bash

    creation_ts: None
    data_attached: []
    data_requests: []
    description: My example pod!
    environment_variables: 

    pod_id: test
    pod_template: template/neo4j
    roles_inherited: []
    roles_required: []
    status: REQUESTED
    status_container: 

    status_requested: ON
    update_ts: None
    url: docpod.pods.tacc.develop.tapis.io

Notes:

- The `pod_id` given will be the id used by you to access the pod at all times. It must be lowercase and alphanumeric.
  It also must be unique within the tenant.
- Pods returned a status of ``REQUESTED`` for the pod; behind the scenes, the Pods service has sent a message requesting
  the pod described to our backend `spawner` infrastructure. The pod's image must be pulled, a pod service must be created
  (for networking), and the networking changes must propagate to the Pod's proxy before the Pod is ready for use.
- When the pod itself has began running, the status will change to ``AVAILABLE``. Networking takes time to propagate (expect <1 minute).
- An ``AVAILABLE``` pod only means the pod itself has started, check pod logs to see what your container is writing to stdout.

At any point we can check the details of our pods, including its status, with the following:

.. code-block:: python

    t.pods.get_pod(pod_id='docpod')

The response format is identical to that returned from the ``t.pods.create_pod()`` method.


Accessing a Pod
---------------

Once your pod is in the ``AVAILABLE`` state your pod's specified networking ports should be routed to port 443 at specified urls.
Read more at #`Pod Networking`_.

A pod's access urls specified in the pod's `networking` attribute. A pod can have multiple urls, each with different protocols and ports.

Retrieving the Logs
-------------------

The Pods service collects the latest 10 MB of logs from the pod when running and makes them available
via the ``logs`` endpoint. Let's retrieve the logs from the pod we just made. We use the ``get_pod_logs()`` method,
passing in ``pod_id``:

.. code-block:: python

    t.pods.get_pod_logs(pod_id='docpod')

The response should be similar to the following:

.. code-block:: python

    logs:
    Fetching versions.json for Plugin 'apoc' from https://neo4j-contrib.github.io/neo4j-apoc-procedures/versions.json
    Installing Plugin 'apoc' from https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.4.0.6/apoc-4.4.0.6-all.jar to /var/lib/neo4j/plugins/apoc.jar 
    Applying default values for plugin apoc to neo4j.conf
    Fetching versions.json for Plugin 'n10s' from https://neo4j-labs.github.io/neosemantics/versions.json
    Installing Plugin 'n10s' from https://github.com/neo4j-labs/neosemantics/releases/download/4.4.0.1/neosemantics-4.4.0.1.jar to /var/lib/neo4j/plugins/n10s.jar 
    Applying default values for plugin n10s to neo4j.conf
    2022-06-16 00:36:14.423+0000 INFO  Starting...
    2022-06-16 00:36:15.602+0000 INFO  This instance is ServerId{eba2fb15} (eba2fb15-713d-47ba-92a5-0a688696264d)
    2022-06-16 00:36:17.468+0000 INFO  ======== Neo4j 4.4.8 ========
    2022-06-16 00:36:21.713+0000 INFO  [system/00000000] successfully initialized: CREATE USER podsservice SET PLAINTEXT PASSWORD 'servicepass' SET PASSWORD CHANGE NOT REQUIRED
    2022-06-16 00:36:21.734+0000 INFO  [system/00000000] successfully initialized: CREATE USER test SET PLAINTEXT PASSWORD 'userpass' SET PASSWORD CHANGE NOT REQUIRED
    2022-06-16 00:36:30.268+0000 INFO  Upgrading security graph to latest version
    2022-06-16 00:36:30.268+0000 INFO  Setting version for 'security-users' to 2
    2022-06-16 00:36:30.270+0000 INFO  Upgrading 'security-users' version property from 2 to 3
    2022-06-16 00:36:30.556+0000 INFO  Called db.clearQueryCaches(): Query caches successfully cleared of 1 queries.
    2022-06-16 00:36:30.667+0000 INFO  Bolt enabled on [0:0:0:0:0:0:0:0%0]:7687.
    2022-06-16 00:36:31.745+0000 INFO  Remote interface available at http://pods-tacc-tacc-docpod:7474/
    2022-06-16 00:36:31.750+0000 INFO  id: B1F0F170083249DAAF9127203310961EF79B262C90EA04D9F08EB7F077DF19E7
    2022-06-16 00:36:31.750+0000 INFO  name: system
    2022-06-16 00:36:31.751+0000 INFO  creationDate: 2022-06-16T00:36:19.073Z
    2022-06-16 00:36:31.751+0000 INFO  Started.

We can see logs from our Neo4j image during the initialization process.

Conclusion
----------

Congratulations! You've now created, registered, and accessed your first pod. There is a lot more you can do with
the Pods service though. To learn more about the additional capabilities, please continue on to the Technical Guide.

----

Neo4j
=====

Assuming the user has created a Neo4j pod and retrieved credentials (user/pass), the user can now connect to the DB with the Neo4j browser interface or Python Neo4j driver.

.. tabs::

    .. tab:: Python

        .. code-block:: python

            from neo4j import GraphDatabase

            url = "bolt+s://podId.pods.tacc.tapis.io:443"
            user = "podId"
            passw = "autoRandomizedPassword"

            neo = GraphDatabase.driver(url,
                                        auth = (user, passw),
                                        max_connection_lifetime=30)

        Use the neo driver as follows to match and return number of nodes in DB.

        .. code-block:: python

            with neo.session() as session:
                result = session.run("MATCH (n) RETURN n")
                for record in result:
                    print(f"Number of nodes in the database: {record}")
    
    .. tab:: Neo4j Browser

        Neo4j has a browser based interface that can be used to interact with remote DBs.
        With this users can use the browser interface here: https://browser.neo4j.io/ with the Pods service.

        Simple provide the following url and credentials to connect to the DB in browser. 
        
        .. code-block:: python

            url = "bolt+s://podId.pods.tacc.tapis.io:443"
            user = "podId"
            passw = "autoRandomizedPassword"

        Users are able to runt he browser interface themselves, but that is not in scope for these docs.


Postgres
========

Assuming the user has created a Postgres pod and retrieved credentials (user/pass), the user can now connect to the
DB with the Postgres' PgAdmin interface or Python Postgres drivers.

.. tabs::
    
    .. tab:: Python
        To note, psycopg2 will be the Postgres driver used, there are more, use your preference.

        .. code-block:: python

            import psycopg2

            db_login = {
                "host": "podId.pods.tacc.tapis.io",
                "port":  443,
                "database": "postgres",
                "user": "podId",
                "password": "autoRandomizedPassword"
            }

            conn = psycopg2.connect(**db_login)
            pg_cursor = conn.cursor()
            
        At this point the user will have a Python postgres driver with a pg_cursor tied to their DB. 

        For example, to get all tables in the DB, the user can run the following with the pg_cursor.

        .. code-block:: python

            # get all tables
            pg_cursor.execute("select relname from pg_class where relkind='r' and relname !~ '^(pg_|sql_)';")
            print(pg_cursor.fetchall())
    
    .. tab:: PgAdmin
            
            PgAdmin is an installable interface that can be used to interact with remote DBs.
            Simple provide the following url and credentials to connect to the DB in browser. 
            
            .. code-block:: python
    
                url = "podId.pods.tacc.tapis.io"
                port = 443
                user = "podId"
                passw = "autoRandomizedPassword"

            To note:
                - PgAdmin can work through the browser.
                - PgAdmin GUI can be hosted by the Pods service, it just hasn't been tried yet.





----

Future work. Only quickstart is currently complete.
===================================================
Please view our API Reference to see what additional functionality is currently available.

----

API Reference
=============

The following link is to our live-documentation that takes our OpenAPI v3 specification that is automatically
generated and gives users the public endpoints available within the Pods API along with request body expected
and descriptions for each field.

https://tapis-project.github.io/live-docs/?service=Pods
