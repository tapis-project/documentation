..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _pods:

####
Pods 
####

Introduction to the Pods Service
================================

The Pods Service is a Tapis (TACC API) service which manages Kubernetes pods for a user. The service 
implements a message broker and processor model that requests pods, alongside a health module to poll for pod
data, including logs, status, and health. The service manages networking, certificates, authentication, and routing.
The primary use of this service is to have quick-to-deploy long-lived services based on Docker images that are 
exposed via HTTP or TCP endpoints listed by the API all running in Kubernetes.

The Pods service provides endpoints for managing pods and their constituant components:
    * **Pods** - The base unit of the service, a pod is a Docker container which a user can manage and interact with.
    * **Templates** - A pod template is a pre-configured pod definition that can be recursively referenced by the definition of a pod.
    * **Images** - Endpoints for managing the allowlist of Docker images that can be used in pods.
    * **Volumes** - Volume endpoints are used to manage storage via networked storage solutions.
    * **Snapshots** - Snapshots are used to save the state of a volume at a given time.
    * **Cluster** - *WIP*

Use Cases
---------

The Pods service is designed to be a flexible and powerful tool for deploying and managing containerized services. Pods are meant
to be easy to use with the ability to reference pre-configured templates alongside a UI component in `TapisUI <https://tacc.tapis.io>`.
Some common use cases for the Pods service include:

    * **Web Services** - Quickly deploy a web service from a Docker image.
    * **Databases** - Postgres, Neo4j, MongoDB, MariaDB*.
    * **Machine Learning** - Deploy inference interfaces like Ollama and OpenWebUI with GPUs.
    * **Development** - Develop and test applications in a containerized environment.
    * **Open-Source Tools** - Jupyter, VSCode, Bookstack, Uptime Kuma, and more.
    * **Authenticated Apps** - Tapis OAuth2/OIDC auth can be configure to secure your pods.

The flexible nature of pods means that most containerized applications can be deployed and managed using the Pods service. The
exception to this are generally either applications with unique networking requirements or truly resource intensive applications
(Multi-GPU + High RAM) due to the shared nature of our Kubernetes cluster.

Feedback and Support
--------------------

Please create issues on our `github repo <https://github.com/tapis-project/pods_service>`_ and report problems to the Tapis team.
The service is available to researchers and students. To learn more about the the system, including getting access, follow the
instructions in :doc:`/getting-started/index`.


----

Getting Started
===============

This Getting Started guide will walk you through the initial steps of setting up the necessary accounts and installing
the required software before moving to the Pods Quickstart, where the guide will walk through creating a first pod. If
you are already using Docker Hub and Tapis, feel free to jump right to the `Pods Quickstart`_ or check
out the `Pods Live Docs <https://tapis-project.github.io/live-docs/?service=Pods>`_ for an OpenAPI V3 specification of the API.


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

Install Tapipy or use cURL
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To interact with the TACC-hosted Abaco platform in Python, we will leverage the Tapis Python SDK, tapipy. To install it,
simply run:

.. code-block:: bash

    $ pip3 install tapipy

Tapipy provides a simple interface to interact with Tapis services. It provides tab-completion and support for all Tapis services. Read
more about Tapipy :doc:`here <pythondev>` (see `Working with TACC OAuth`_).

This documentation will also walk you through using the Pods service with the `cURL <https://curl.se/>`_ command line tool.
If you will use cURL then make use of this guide :ref:`Tapis Quickstart's cURL example <curl-example>` and continue to the `Pods Quickstart`_.


Working with TACC OAuth
-----------------------

Authentication and authorization to the Tapis APIs uses `OAuth2 <https://oauth.net/2/>`_, a widely-adopted web standard.
Our implementation of OAuth2 is designed to give you the flexibility you need to script and automate use of Tapis
while keeping your access credentials and digital assets secure. This is covered in great detail in our
Tenancy and Authentication section, but some key concepts will be highlighted here, interleaved with Python code.


.. _pods-tapipy-quickstart:

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

Registering a Pod via Template
---------------------------

To get started we're going to create a Pod via a Template. You can use ``tapipy`` via Python or ``cURL`` via bash to make requests to the Pods service.
It's good to mention that the service is a RESTful API, so you can use any tool that can make HTTP requests.

Authentication is done via an ``X-Tapis-Token`` header, which is an OAuth2 access token, shown in the cURL flow and done in the background by Tapipy.
Authentication is the first step in using Tapis services and is shown in this step.

.. tabs::

    .. group-tab:: Python

        The ``tapipy`` library is TACC's Python SDK for Tapis. The quickstart was `above <pods-tapipy-quickstart>`_. To get started, you'll need 
        to authenticate with Tapis. Here's an additonal example of how to do that:

        .. code-block:: python

            from tapipy.tapis import Tapis

            t = Tapis(
                base_url='https://tacc.tapis.io',
                username='<userid>',
                password='*********'
            )

            # Makes a request using the user/pass to set an access token.
            t.get_tokens()

    .. group-tab:: Bash

        If you are using cURL you should have an access token from the :ref:`Tapis Quickstart's cURL example <curl-example>`.
        Here's an additional example of how to get an access token using cURL:

        .. code-block:: bash

            $ curl -H "Content-type: application/json" \
                   -d '{"username": "your_tacc_username", \
                        "password": "your_tacc_password", \
                        "grant_type": "password" }' \
                   https://tacc.tapis.io/v3/oauth2/tokens

            $ export JWT=your_access_token_string_from_result_above

Once a user has authenticated, they can create a pod. The Pods service uses a templating system to allow users to create pods from pre-configured, versioned, templates.
Users can view templates via TapisUI or the API. The following example shows how to create a pod using the `neo4j` template. Note that fields that a user specifies will
override any existing fields in the template.

.. tabs::

    .. group-tab:: Python

        Using ``tapipy``, we use the ``t.pods.create_pod()`` method and pass the arguments describing
        the pod we want to register through the function parameters.


        .. code-block:: python

            response = t.pods.create_pod(
                pod_id='docpod',
                template='neo4j',
                description='My example pod!'
            )
            print(response)

    .. code-tab:: bash

        curl --request POST \
             --url https://tacc.tapis.io/v3/pods \
             --header 'Content-Type: application/json' \
             --header 'X-Tapis-Token: $JWT' \
             --data '{
                "pod_id": "docpod",
                "template": "neo4j",
                "description": "My example pod!"
             }'

You should receive a response that looks like this.

.. code-block:: bash

    creation_ts: None
    data_attached: []
    data_requests: []
    description: My example pod!
    environment_variables: 

    pod_id: test
    template: template/neo4j
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
- An ``AVAILABLE`` pod only means the pod itself has started, check pod logs to see what your container is writing to stdout.

At any point we can check the details of our pods, including its status, with the following:

.. tabs::

    .. code-tab:: python

        t.pods.get_pod(pod_id='docpod')
    
    .. code-tab:: bash
        
        curl --request GET \
             --url https://tacc.tapis.io/v3/pods/docpod \
             --header 'Content-Type: application/json' \
             --header 'X-Tapis-Token: $JWT'

The response format is identical to that returned from the ``t.pods.create_pod()`` method.


Accessing a Pod
---------------

Once your pod is in the ``AVAILABLE`` state your pod's specified networking ports should be routed to port 443 at specified urls.
Read more at :ref:`Pod Networking`_.

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


Templates
=========

Tapis Pods supports templating, which allows users to create reusable pod definitions. Users make use of templates and their underlying template tags to define a pod.

Templates
---------
Templates are essentially groups of template tags that are shareable, providing users with access to any associated tag within the template.
Templates facilitate the organization and sharing of pod configurations, allowing users to leverage predefined setups. The only way to currently share pod
configurations is through templates, making them a crucial component for collaborative and consistent deployment practices.


.. list-table::
    :header-rows: 1
    :widths: 24 76

    * - Field
      - Description
    * - template_id
      - **Required**. Name of the template. Type: string.
    * - description
      - Description of the template. Type: string. Default: "".
    * - metatags
      - Metadata tags for additional search/listing functionality for the template. Type: array of strings. Default: [].
    * - archive_message
      - If set, metadata message to give users of this template. Type: string. Default: "".
    * - creation_ts
      - Time (UTC) that this template was created. Type: string <date-time>.
    * - update_ts
      - Time (UTC) that this template was updated. Type: string <date-time>.
    * - tenant_id
      - Tapis tenant used during creation of this template. Type: string. Default: "".
    * - site_id
      - Tapis site used during creation of this template. Type: string. Default: "".
    * - permissions
      - Template permissions in user:level format. Type: array of strings. Default: [].

.. tabs::

    .. group-tab:: Python

        To list available templates, use the following command:

        .. code-block:: python

            templates = t.pods.list_templates()
            print(templates)

        To create a template in Tapis Pods, use the ``tapipy`` and the ``t.pods.create_template()`` function:

        .. code-block:: python

            t.pods.create_template(
                template_id='mongo',
                description="TACC's MongoDB template",
                metatags=['mongo', 'database', 'TACC', 'http']
            )

    .. group-tab:: Bash

        To list available templates, use the following command:

        .. code-block:: bash

            curl --request GET \
                --url https://tacc.tapis.io/v3/pods/templates \
                --header 'Content-Type: application/json' \
                --header 'X-Tapis-Token: $JWT'

        To create a template in Tapis Pods, use the corresponding ``curl`` request:

        .. code-block:: bash

            curl --request POST \
                --url https://tacc.tapis.io/v3/pods/templates \
                --header 'Content-Type: application/json' \
                --header 'X-Tapis-Token: $JWT' \
                --data '{  
                    "template_id": "mongo",  
                    "description": "TACC's MongoDB template",  
                    "metatags": [ "mongo", "database", "TACC", "http" ]  
                }'

Template Tags
-----------------------
Template tags are the underlying definitions within a template, each marked with a ``tag_timestamp`` and immutable once created.
These tags specify the pod configurations and can be overridden with user-defined values at runtime. Template tags can also reference
other template tags, enabling a recursive definition of pod configurations. This flexibility allows users to save and share complex pod setups efficiently.

Each template must have at least one tag, which specifies the pod configuration. If no tags are specified, ``latest`` is used by default.
When a template tag is created a ``tag_timestamp`` field is used to specifically version the tag.

Template tags resolve in the following ways when referenced:

    * ``template:tag@timestamp`` - for a specific version of a template tag.
    * ``template:tag`` - for a template with the newest version of a tag.
    * ``template`` - for a template with the newest version of the ``latest`` tag.


.. list-table::
    :header-rows: 1
    :widths: 24 76

    * - Field
      - Description
    * - template_id
      - **Required**. Name of the template. Type: string.
    * - pod_definition
      - **Required**. Pod definition fields. Type: object. Can be overridden.
    * - commit_message
      - **Required** Commit message for the template tag. Type: string. Default: "".
    * - tag
      - Tag name for the template tag. Type: string. Default: "latest".

The following fields are set on creation and are useful to know:

- **tag_timestamp**: Tag timestamp for this object and used for referencing this tag.
- **added_by**: User who added this template tag.
- **creation_ts**: Time (UTC) that this template tag was created.

This example shows how to create a template tag for the ``mongo`` template:

.. tabs::

    .. code-tab:: python

        t.pods.create_template_tag(
            template_id='mongo',
            pod_definition={
                "image": "mongo:8",
                "networking": {"default": {"port": 27017, "protocol": "tcp"}},
                "time_to_stop_default": -1,
                "environment_variables": {
                    "MONGO_INITDB_ROOT_USERNAME": "<TAPIS_user_username>",
                    "MONGO_INITDB_ROOT_PASSWORD": "<TAPIS_user_password>"
                }
            },
            tag='8',
            commit_message='mongo:8 template'
        )

    .. code-tab:: bash

        curl --request POST \
             --url https://tacc.tapis.io/v3/pods/templates/mongo/tags \
             --header 'Content-Type: application/json' \
             --header 'X-Tapis-Token: $JWT' \
             --data '{  
                 "pod_definition": {  
                     "image": "mongo:8",  
                     "networking": { "default": { "port": 27017, "protocol": "tcp" } },  
                     "time_to_stop_default": -1,  
                     "environment_variables": {  
                         "MONGO_INITDB_ROOT_USERNAME": "<TAPIS_user_username>",  
                         "MONGO_INITDB_ROOT_PASSWORD": "<TAPIS_user_password>"  
                     }  
                 },  
                 "tag": "8",  
                 "commit_message": "mongo:8 template"  
             }'


Using a Template Tag to Create a Pod
--------------------------------

To create a pod from a specific template tag and timestamp, use:

.. tabs::


    .. code-tab:: python

        t.pods.create_pod(
            pod_id='mypod',
            template='neo4j:5.26s3se@2025-01-30-17:14:14',
            time_to_stop_default=-1
        )

    .. code-tab:: bash

        curl --request POST \
             --url https://tacc.tapis.io/v3/pods \
             --header 'Content-Type: application/json' \
             --header 'X-Tapis-Token: $JWT' \
             --data '{  
                 "pod_id": "mypod",  
                 "template": "neo4j:5.26s3se@2025-01-30-17:14:14",  
                 "time_to_stop_default": -1  
             }'


Ensure that the template name and tag match exactly as shown in the Tapis UI or the ``list_templates()`` output.

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
