..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _actors:

######
Actors
######

----

Introduction to Abaco
=====================

What is Abaco
-------------

**Abaco** is an NSF-funded web service and distributed computing platform providing functions-as-a-service (FaaS)
to the research computing community. Abaco implements functions using the Actor Model of concurrent computation. In
Abaco, each actor is associated with a Docker image, and actor containers are executed in response to messages posted
to their inbox which itself is given by a URI exposed over HTTP.

Abaco will ultimately offer three primary higher-level capabilities on top of the underlying Actor model:

 * *Reactors* for event-driven programming
 * *Asynchronous Executors* for scaling out function calls within running applications, and
 * *Data Adapters* for creating rationalized microservices from disparate and heterogeneous sources of data.

Reactors and Asynchronous Executors are available today while Data Adapters are still under active development.

Using Abaco
-----------

Abaco is in production and has been adopted by several projects. Abaco is available to researchers and students. To
learn more about the the system, including getting access, follow the instructions in :doc:`/getting-started/index`.


----

Getting Started
===============

This Getting Started guide will walk you through the initial steps of setting up the necessary accounts and installing
the required software before moving to the Abaco Quickstart, where you will create and execute your first Abaco actor. If
you are already using Docker Hub and the TACC Cloud APIs, feel free to jump right to the `Abaco Quickstart`_ or check
out the Abaco Live Docs `site <https://tacc.github.io/abaco-live-docs/>`_.


Account Creation and Software Installation
------------------------------------------

Create a TACC account
^^^^^^^^^^^^^^^^^^^^^

The main instance of the Abaco platform is hosted at the Texas Advanced Computing Center (`TACC <https://tacc.utexas.edu>`_).
TACC designs and deploys some of the world's most powerful advanced computing technologies and innovative software
solutions to enable researchers to answer complex questions. To use the TACC-hosted Abaco service, please
create a `TACC account <https://portal.tacc.utexas.edu/account-request>`__ .

Create a Docker account
^^^^^^^^^^^^^^^^^^^^^^^

`Docker <https://www.docker.com/>`__  is an open-source container runtime providing operating-system-level
virtualization. Abaco pulls images for its actors from the public Docker Hub. To register actors
you will need to publish images on Docker Hub, which requires a `Docker account <https://hub.docker.com/>`__ .


Install the Tapis Python SDK
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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

Abaco Quickstart
================

In this Quickstart, we will create an Abaco actor from a basic Python function. Then we will execute our actor on the
Abaco cloud and get the execution results.

A Basic Python Function
-----------------------

Suppose we want to write a Python function that counts words in a string. We might write something like this:

.. code-block:: python

  def string_count(message):
      words = message.split(' ')
      word_count = len(words)
      print('Number of words is: ' + str(word_count))

In order to process a message sent to an actor, we use the ``raw_message`` attribute of the ``context`` dictionary.
We can access it by using the ``get_context`` method from the ``actors`` module in ``tapipy``.

For this example, create a new local directory to hold your work. Then, create a new file in this directory called
``example.py``. Add the following to this file:

.. code-block:: python

  # example.py

  from tapipy.actors import get_context

  def string_count(message):
      words = message.split(' ')
      word_count = len(words)
      print('Number of words is: ' + str(word_count))

  context = get_context()
  message = context['raw_message']
  string_count(message)


Building Images From a Dockerfile
---------------------------------

To register this function as an Abaco actor, we create a docker image that contains the Python function and
execute it as part of the default command.

We can build a Docker image from a text file called a Dockerfile. You can think of a Dockerfile as a recipe for
creating images. The instructions within a Dockerfile either add files/folders to the image, add metadata to the
image, or both.


The FROM Instruction
^^^^^^^^^^^^^^^^^^^^

Create a new file called ``Dockerfile`` in the same directory as your ``example.py`` file.

We can use the ``FROM`` instruction to start our new image from a known image. This should be the first line of our
Dockerfile. We will start an official Python image:

.. code-block:: bash

  FROM python:3.6

The RUN, ADD and CMD Instructions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We can run arbitrary Linux commands to add files to our image. We'll run the ``pip`` command to install the ``tapipy``
library in our image:

.. code-block:: bash

  RUN pip install --no-cache-dir tapipy

(Note: there is a ``abacosample`` image that contains Python and the tapipy library; see the Samples
section for more details, coming soon.)

We can also add local files to our image using the ``ADD`` instruction. To add the ``example.py`` file from our local
directory, we use the following instruction:

.. code-block:: bash

  ADD example.py /example.py

The last step is to write the command from running the application, which is simply ``python /example.py``. We use
the ``CMD`` instruction to do that:

.. code-block:: bash

  CMD ["python", "/example.py"]

With that, our ``Dockerfile`` is now ready. This is what is looks like:

.. code-block:: bash

  FROM python:3.6

  RUN pip install --no-cache-dir tapipy
  ADD example.py /example.py

  CMD ["python", "/example.py"]


Now that we have our ``Dockerfile``, we can build our image and push it to Docker Hub. To do so, we use the
``docker build`` and ``docker push`` commands [note: user is your user on Docker, you must also $ docker login] :

.. code-block:: bash

  $ docker build -t user/my_actor .
  $ docker push user/my_actor

Registering an Actor
--------------------

Now we are going to register the Docker image we just built as an Abaco actor. To do this, we will use the ``Tapis``
client object we created above (see `Working with TACC OAuth`_).

To register an actor using the tapipy library, we use the ``actors.add()`` method and pass the arguments describing
the actor we want to register through the ``body`` parameter. For example:

.. code-block:: python

  my_actor = {"image": "user/my_actor", "name": "word_counter", "description": "Actor that counts words."}
  t.actors.create_actor(**my_actor)

You should see a response like this:

.. code-block:: python

  _links:
  executions: https://tacc.tapis.io/actors/v3/JWpkNmBwKewYo/executions
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  createTime: 2020-10-21T17:20:20.718177
  default_environment:
  description: Actor that counts words.
  hints: []
  id: JWpkNmBwKewYo
  image: abacosamples/wc
  last_update_time: 2020-10-21T17:20:20.718177
  link:
  mounts: [
  container_path: /home/tapis/runtime_files/_abaco_data1
  host_path: /home/apim/staging/runtime_files/data1
  mode: ro,
  container_path: /home/tapis/runtime_files/_abaco_data2
  host_path: /home/apim/staging/runtime_files/data2/master/abaco
  mode: rw]
  owner: abaco
  privileged: False
  queue: default
  state:
  stateless: True
  status: SUBMITTED
  status_message:
  token: false
  type: none
  use_container_uid: False
  webhook:

Notes:

- Abaco assigned an id to the actor (in this case ``JWpkNmBwKewYo``) and associated it with the image (in this case,
  ``abacosamples/wc``) which it began pulling from the public Docker Hub.
- Abaco returned a status of ``SUBMITTED`` for the actor; behind the scenes, Abaco is starting a worker container to
  handle messages passed to this actor. The worker must initialize itself (download the image, etc) before the
  actor is ready.
- When the actor's worker is initialized, the status will change to ``READY``.

At any point we can check the details of our actor, including its status, with the following:

.. code-block:: python

  t.actors.get_actor(actor_id='JWpkNmBwKewYo')

The response format is identical to that returned from the ``.add()`` method.


Executing an Actor
------------------

We are now ready to execute our actor by sending it a message. We built our actor to process a raw message string, so
that is what we will send, but there other options, including JSON and binary data. For more details, see the
:ref:`Messages <target messages>` section.

We send our actor a message using the ``send_message()`` method:

.. code-block:: python

 t.actors.send_message(actor_id='JWpkNmBwKewYo',
                       request_body={'message': 'Actor, please count these words.'})

Abaco queues up an execution for our actor and then responds with JSON, including an id for the execution contained in
the ``execution_id``:

.. code-block:: python

  _links:
  messages: https://tacc.tapis.io/actors/v3/JWpkNmBwKewYo/messages
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  execution_id: kA1P1m8NkkolK
  msg: Actor, please count these words.

In general, an execution does not start immediately but is instead queued until a future time when a worker for the
actor can take the message and start an actor container with the message. We can retrieve the details about an
execution, including its status, using the ``get_execution()`` method:

.. code-block:: bash

  >>> t.actors.get_execution(actor_id='JWpkNmBwKewYo', execution_id='kA1P1m8NkkolK')

The response will be similar to the following:

.. code-block:: python

  _links:
  logs: https://tacc.tapis.io/actors/v3/JWpkNmBwKewYo/executions/kA1P1m8NkkolK/logs
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  actor_id: JWpkNmBwKewYo
  api_server: https://tacc.tapis.io
  cpu: 9678006850
  executor: jstubbs
  exitCode: 1
  final_state:
  Dead: False
  Error:
  ExitCode: 1
  FinishedAt: 2020-10-21T17:26:49.77Z0
  OOMKilled: False
  Paused: False
  Pid: 0
  Restarting: False
  Running: False
  StartedAt: 2020-10-21T17:26:45.24Z0
  Status: exited
  finish_time: 2020-10-21T17:26:49.77Z0
  id: kA1P1m8NkkolK
  io: 152287298
  message_received_time: 2020-10-21T17:26:44.367Z
  runtime: 5
  start_time: 2020-10-21T17:26:44.841Z
  status: COMPLETE
  worker_id: QBmoQx4pOx1oA

Note that a status of ``COMPLETE`` indicates that the execution has finished and we are ready to retrieve our results.


Retrieving the Logs
-------------------

The Abaco system collects all standard out from an actor execution and makes it available via the ``logs`` endpoint.
Let's retrieve the logs from the execution we just made. We use the ``get_execution_logs()``
method, passing out ``actor_id`` and our ``execution_id``:

.. code-block:: python

  t.actors.get_execution_logs(actor_id='JWpkNmBwKewYo', execution_id='kA1P1m8NkkolK')

The response should be similar to the following:

.. code-block:: python

  _links:
  execution: https://tacc.tapis.io/actors/v3/JWpkNmBwKewYo/executions/kA1P1m8NkkolK
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  logs: Number of words is: 5\n

We see our actor output `Number of words is: 5`, which is the expected result!


Conclusion
----------

Congratulations! At this point you have created, registered and executed your first actor, but there is a lot more you
can do with the Abaco system. To learn more about the additional capabilities, please continue on to the Technical Guide.



----

.. _target registration:

Actor Registration
==================

When registering an actor, the only required field is a reference to an image on the public Docker Hub. However,
there are several other properties that can be set. The following table provides a list of the configurable properties
available to all users and their descriptions.

+---------------------+----------------------------------------------------------------------------------+
| Property Name       | Description                                                                      |
+=====================+==================================================================================+
| image               | The Docker image to associate with the actor. This should be a fully qualified   |
|                     | image available on the public Docker Hub. We encourage users to use to image     |
|                     | tags to version control their actors.                                            |
+---------------------+----------------------------------------------------------------------------------+
| name                | A user defined name for the actor.                                               |
+---------------------+----------------------------------------------------------------------------------+
| description         | A user defined description for the actor.                                        |
+---------------------+----------------------------------------------------------------------------------+
| default_environment | The default environment is a set of key/value pairs to be injected into every    |
|                     | execution of the actor. The values can also be overridden when passing a         |
|                     | message to the reactor in the query parameters (see                              |
|                     | :ref:`Messages <target messages>`).                                              |
+---------------------+----------------------------------------------------------------------------------+
| hints               | A list of strings representing user-defined "tags" or metadata about the actor.  |
|                     | "Official" Abaco hints can be applied to control configurable aspects of the     |
|                     | actor runtime, such as the  algorithm used (see                                  |
|                     | :ref:`Autoscaling <target autoscaling>`).                                        |
+---------------------+----------------------------------------------------------------------------------+
| link                | Actor identifier (id or alias) of an actor to "link" this actor's events to.     |
|                     | Requires execute permissions on the linked actor, and cycles are not permitted.  |
|                     | (see :ref:`Actor Links, Events, and Webhooks <target actor links>`).             |
+---------------------+----------------------------------------------------------------------------------+
| privileged          | (True/False) - Whether the actor runs in privileged mode and has access to       |
|                     | the Docker daemon. *Note*: Setting this parameter to True requires elevated      |
|                     | permissions.                                                                     |
+---------------------+----------------------------------------------------------------------------------+
| stateless           | (True/False) - Whether the actor stores private state as part of its execution.  |
|                     | If True, the state API will not be available, but in a future release, the       |
|                     | Abaco service will be able to automatically scale reactor processes to execute   |
|                     | messages in parallel. The default value is False.                                |
+---------------------+----------------------------------------------------------------------------------+
| token               | (True/False) - Whether to generate an OAuth access token for every execution of  |
|                     | this actor. Generating an OAuth token add about 500 ms of time to the execution  |
|                     | start up time.                                                                   |
|                     |                                                                                  |
|                     | *Note: the default value for the ``token`` attribute varies from                 |
|                     | tenant to tenant. Always explicitly set the token attribute when registering     |
|                     | new actors to ensure the proper behavior.*                                       |
+---------------------+----------------------------------------------------------------------------------+
| use_container_uid   | Run the actor using the UID/GID set in the Docker image. *Note*: Setting         |
|                     | this parameter to True requires elevated permissions.                            |
+---------------------+----------------------------------------------------------------------------------+
| run_as_executor     | Run the actor using the UID/GID of the executor rather than the owner            |
|                     | *Note*: this parameter is only available to certain tenants                      |
|                     | *Note*: that this cannot be on while the use_container_uid is also on            |
+---------------------+----------------------------------------------------------------------------------+
| webhook             | URL to publish this actor's events to.                                           |
|                     | (see :ref:`Actor Links, Events, and Webhooks <target actor links>`)              |
+---------------------+----------------------------------------------------------------------------------+
| cron_schedule       | String of 'yyyy-mm-dd hh + <increment>' format. Turns on cron feature for actor  |
|                     | so that at the specified times the actor with execute with a generic static      |
|                     | message. Increment looks like "5 days" or "1 week" (hours, days, weeks, months). |
|                     | There's currently no support for increments shorter that an hour.                |
|                     | (see :ref:`Actor Cron <target actor cron>`)                                      |
+---------------------+----------------------------------------------------------------------------------+
| cron_on             | (True/False) - Whether to turn on or off the cron schedule feature for the actor |
|                     | (see :ref:`Actor Cron <target actor cron>`)                                      |
+---------------------+----------------------------------------------------------------------------------+


Notes
-----

- The ``default_environment`` can be used to provide sensitive information to the actor that cannot be put in the image.
- In order to execute privileged actors or to override the UID/GID used when executing an actor container,
  talk to the Abaco development team about your use case.
- Abaco supports running specific actors within a given tenant on dedicated and/or specialized hardware for performance reasons. It
  accomplishes this through the use of actor ``queues``. If you need to run actors on dedicated resources, talk to the
  Abaco development team about your use case.

Examples
--------

curl
^^^^

Here is an example using curl; note that to set the default environment, we *must* pass content type ``application/json`` and
be sure to pass properly formatted JSON in the payload.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image": "abacosamples/test", "name": "test", "description": "My test actor using the abacosamples image.", "default_environment":{"key1": "value1", "key2": "value2"} }' \
  https://tacc.tapis.io/v3/actors


Python
^^^^^^

To register the same actor using the tapipy library, we use the ``actors.create_actor()`` method and pass the same arguments
through the `request_body` parameter. In this case, the ``default_environment`` is just a standard Python dictionary where the
keys and values are ``str`` type. For example,

.. code-block:: python

  from tapipy.tapis import Tapis
  t = Tapis(api_server='https://tacc.tapis.io', username='<username>', password='<password>')
  t.get_tokens()
  actor = {"image": "abacosamples/test",
           "name": "test",
           "description": "My test actor using the abacosamples image registered using tapipy.",
           "default_environment":{"key1": "value1", "key2": "value2"} }
  t.actors.create_actor(**actor)




----

Abaco Context & Container Runtime
=================================

In this section we describe the environment that Abaco actor containers can utilize during their execution.

.. _target context:

Context
-------

When an actor container is launched, Abaco injects information about the execution into a number of environment
variables. This information is collectively referred to as the ``context``. The following table provides a complete
list of variable names and their description:

+----------------------+-------------------------------------------------------------------------+
| Variable Name        | Description                                                             |
+======================+=========================================================================+
| _abaco_actor_id      | The id of the actor.                                                    |
+----------------------+-------------------------------------------------------------------------+
| _abaco_actor_dbid    | The Abaco internal id of the actor.                                     |
+----------------------+-------------------------------------------------------------------------+
| _abaco_container_repo| The Docker image used to launch this actor container.                   |
+----------------------+-------------------------------------------------------------------------+
| _abaco_worker_id     | The id of the worker for the actor overseeing this execution.           |
+----------------------+-------------------------------------------------------------------------+
| _abaco_execution_id  | The id of the current execution.                                        |
+----------------------+-------------------------------------------------------------------------+
| _abaco_access_token  | An OAuth2 access token representing the user who registered the actor.  |
+----------------------+-------------------------------------------------------------------------+
| _abaco_api_server    | The OAuth2 API server associated with the actor.                        |
+----------------------+-------------------------------------------------------------------------+
| _abaco_actor_state   | The value of the actor's state at the start of the execution.           |
+----------------------+-------------------------------------------------------------------------+
| _abaco_Content-Type  | The data type of the message (either 'str' or 'application/json').      |
+----------------------+-------------------------------------------------------------------------+
| _abaco_username      | The username of the "executor", i.e., the user who sent the message.    |
+----------------------+-------------------------------------------------------------------------+
| _abaco_api_server    | The base URL for the Abaco API service.                                 |
+----------------------+-------------------------------------------------------------------------+
|  MSG                 | The message sent to the actor, as a raw string.                         |
+----------------------+-------------------------------------------------------------------------+


Notes
^^^^^

- The ``_abaco_actor_dbid`` is unique to each actor. Using this id, an actor can distinguish itself from other actors registered with the same function providing for SPMD techniques.
- The ``_abaco_access_token`` is a valid OAuth token that actors can use to make authenticated requests to other TACC Cloud APIs during their execution.
- The actor can update its state during the course of its execution; see the section :ref:`Actor State <target actor state>` for more details.
- The "executor" of the actor may be different from the owner; see :ref:`Sharing <target actor sharing>` for more details.


Access from Python
^^^^^^^^^^^^^^^^^^^

The ``tapipy.actors`` module provides access to the above data in native Python objects.
Currently, the actors module provides the following utilities:

* ``get_context()`` - returns a Python dictionary with the following fields:
    * ``raw_message`` - the original message, either string or JSON depending on the Contetnt-Type.
    * ``content_type`` - derived from the original message request.
    * ``message_dict`` - A Python dictionary representing the message (for Content-Type: application/json)
    * ``execution_id`` - the ID of this execution.
    * ``username`` - the username of the user that requested the execution.
    * ``state`` - (for stateful actors) state value at the start of the execution.
    * ``actor_id`` - the actor's id.
* ``get_client()`` - returns a pre-authenticated ``tapipy.Tapis`` object.
* ``update_state(val)`` - Atomically, update the actor's state to the value ``val``.


Runtime Environment
-------------------

The environment in which an Abaco actor container runs has been built to accommodate a number of typical use cases
encountered in research computing in a secure manner.


Container UID and GID
^^^^^^^^^^^^^^^^^^^^^

When Abaco launches an actor container, it instructs Docker to execute the process using the UID and GID associated
with the TACC account of the owner of the actor. This practice guarantees that an Abaco actor will have exactly the
same accesses as the original author of the actor (for instance, access to files or directories on shared storage)
and that files created or updated by the actor process will be owned by the underlying API user.
Abaco API users that have elevated privilleges within the platform can override the UID and GID used to run the
actor when registering the actor (see :ref:`Registration <target registration>`).


POSIX Interface to the TACC WORK File System
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When Abaco launches an actor container, it mounts the actor owner's TACC WORK file system into the running container.
The owner's work file system is made available at ``/work`` with the container. This gives the actor a POSIX
interface to the work file system.




----

Messages, Executions, and Logs
==============================

Once you have an Abaco actor created the next logical step is to send this actor
some type of job or message detailing what the actor should do. The act of sending
an actor information to execute a job is called sending a message. This sent
message can be raw string data, JSON data, or a binary message.

Once a message is sent to an Abaco actor, the actor will create an execution with
a unique ``execution_id`` tied to it that will show results, time running, and other
stats which will be listed below. Executions also have logs, and when the log are
called for, you'll receive the command line logs of your running execution.
Akin to what you'd see if you and outputted a script to the command line.
Details on messages, executions, and logs are below.

**Note:** Due to each message being tied to a specific execution, each execution
will have exactly one message that can be processed.

.. _target messages:

Messages
--------

A message is simply the message given to an actor with data that can be used to run
the actor. This data can be in the form of a raw message string, JSON, or binary.
Once this message is sent, the messaged Abaco actor will queue an execution of
the actor's specified image.

Once off the queue, if your specified image has inputs for the messaged data,
then that messaged data will be visible to your program. Allowing you to set
custom parameters or inputs for your executions.

Sending a message
^^^^^^^^^^^^^^^^^

cURL
~~~~

To send a message to the ``messages`` endpoint with cURL, you would do the following:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "message=<your content here>" \
  https://tacc.tapis.io/v3/actors/<actor_id>/messages

Python
~~~~~~

To send a message to the ``messages`` endpoint with ``tapipy`` and Python, you would do the following:

.. code-block:: python

  t.actors.send_message(actor_id='<actor_id>',
                        request_body={'message':'<your content here>'})

Results
~~~~~~~

These calls result in a list similar to the following:

.. code-block:: python

  _links:
  messages: https://tacc.tapis.io/actors/v3/NPpjZkmZ4elY8/messages
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  execution_id: WrMk5EPmwYoL6
  msg: <your content here>


Get message count
^^^^^^^^^^^^^^^^^

It is possible to retrieve the current number of messages an actor has with the
``messages`` end point.

cURL
~~~~

The following retrieves the current number of messages an actor has:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/<actor_id>/messages

Python
~~~~~~

To retrieve the current number of messages with ``tapipy`` the following is done:

.. code-block:: python

    t.actors.get_messages(actor_id='<actor_id>')

Results
~~~~~~~

The result of getting the ``messages`` endpoint should be similar to:

.. code-block:: bash

  _links:
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  messages: 12

Binary Messages
^^^^^^^^^^^^^^^

An additional feature of the Abaco message system is the ability to post binary
data. This data, unlike raw string data, is sent through a Unix Named Pipe
(FIFO), stored at /_abaco_binary_data, and can be retrieved from within the
execution using a FIFO message reading function. The ability to read binary
data like this allows our end users to do numerous tasks such as reading in
photos, reading in code to be ran, and much more.

The following is an example of sending a JPEG as a binary message in order to
be read in by a TensorFlow image classifier and being returned predicted image
labels. For example, sending a photo of a golden retriever might yield, 80%
golden retriever, 12% labrador, and 8% clock.

This example uses Python and ``tapipy`` in order to keep code in one script.

Python with Tapipy
~~~~~~~~~~~~~~~~~~

Setting up an ``Tapis`` object with token and API address information:

.. code-block:: python

  from tapipy.tapis import Tapis
  t = Tapis(api_server='https://tacc.tapis.io', username='<username>', password='<password>')
  t.get_tokens()

Creating actor with the TensorFlow image classifier docker image:

.. code-block:: python

  my_actor = {'image': 'abacosamples/binary_message_classifier',
              'name': 'JPEG_classifier',
              'description': 'Labels a read in binary image'}
  actor_data = t.actors.create_actor(**my_actor)

The following creates a binary message from a JPEG image file:

.. code-block:: python

  with open('<path to jpeg image here>', 'rb') as file:
      binary_image = file.read()

Sending binary JPEG file to actor as message with the sendBinaryMessage function (You can
also just set the headers with ``Content-Type: application/octet-stream``):

.. code-block:: python

  result = t.actors.send_binary_message(actor_id = actor_data.id,
                                      request_body = binary_image)

The following returns information pertaining to the execution:

.. code-block:: python

  execution = t.actors.get_execution(actor_id = actor_data.id,
                                     execution_id = result.execution_id)

Once the execution has complete, the logs can be called with the following:

.. code-block:: python

  exec_logs = t.actors.get_execution_logs(actor_id = actor_data.id,
                                          execution_id = result.execution_id)

Sending binary from execution
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Another useful feature of Abaco is the ability to write to a socket connected
to an Abaco endpoint from within an execution. This Unix Domain (Datagram)
socker is mounted in the actor container at /_abaco_results.sock.

In order to write binary data this socket you can use ``tapipy`` functions,
in particular the ``send_bytes_result()`` function that sends bytes as single
result to the socket. Another useful function is the ``send_python_result()``
function that allows you to send any Python object that can be pickled with
``cloudpickle``.

In order to retrieve these results from Abaco you can get the
``/actors/<actor_id>/executions/<execution_id>/results`` endpoint. Each get of
the endpoint will result in exactly one result being popped and retrieved. An
empty result with be returned if the results queue is empty.

As a socket, the maximum size of a result is 131072 bytes. An execution can
send multiple results to the socket and said results will be added to a queue.
It is recommended to to return a reference to a file or object store.

As well, results are sent to the socket and available immediately, an execution
does not have to complete to pop a result. Results are given an expiry time of
60 minutes from creation.

cURL
~~~~

To retrieve a result with cURL you would do the following:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "message=<your content here>" \
  https://tacc.tapis.io/v3/actors/<actor_id>/executions/<execution_id>/results

----

Synchronous Messaging
^^^^^^^^^^^^^^^^^^^^^

.. Important::
   Support for Synchronous Messaging was added in version 1.1.0.

Starting with `1.1.0`, Abaco provides support for sending a synchronous message to an actor; that is, the client
sends the actor a message and the request blocks until the execution completes. The result of the execution is returned
as an HTTP response to the original message request.

Synchronous messaging prevents the client from needing to poll the executions endpoint to determine when an execution
completes. By eliminating this polling and returning the response as soon as it is ready, the overall latency
is minimized.

While synchronous messaging can simplify client code and improve performance, it introduces some additional challenges.
Primarily, if the execution cannot be completed within the HTTP request/response window, the request will time out.
This window is usually about 30 seconds.

.. Warning::
  Abaco strictly adheres to message ordering and, in particular, synchronous messages do not skip to the front of the
  actor's message queue. Therefore, a synchronous message *and all queued messages* must be processed within the HTTP
  timeout window. To avoid excessive synchronous message requests, Abaco will return a 400 level request if the actor
  already has more than 3 queued messages at the time of the synchronous message request.

To send a synchronous message, the client appends `_abaco_synchronous=true` query parameter to the request; the rest of
the messaging semantics follows the rules and conventions of asynchronous messages.

cURL
~~~~

The following example uses the curl command line client to send a synchronous message:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "message=<your content here>" \
  https://tacc.tapis.io/v3/actors/<actor_id>/messages?_abaco_synchronous=true

As stated above, the request blocks until the execution (and all previous executions queued for the actor) completes.
To make the response to a synchronous message request, Abaco uses the following rules:

  1. If a (binary) result is registered by the actor for the execution, that result is returned with along with a content-type `application/octet-stream`.
  2. If no result is available when the execution completes, the logs associated with the execution are returned with content-type `text/html` (charset utf8 is assumed).



Executions
----------

Once you send a message to an actor, that actor will create an execution for the actor
with the inputted data. This execution will be queued waiting for a worker to spool up
or waiting for a worker to be freed. When the execution is initially created it is
given an execution_id so that you can access information about it using the execution_id endpoint.

Access execution data
^^^^^^^^^^^^^^^^^^^^^

cURL
~~~~

You can access the ``execution_id`` endpoint using cURL with the following:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/<actor_id>/executions/<execution_id>

Python
~~~~~~

You can access the ``execution_id`` endpoint using ``tapipy`` and Python with the following:

.. code-block:: python

  t.actors.get_execution(actor_id='<actor_id>',
                         execution_id='<execution_id>')

Results
~~~~~~~

Access the ``execution_id`` endpoint will result in something similar to the following:

.. code-block:: python

  _links:
  logs: https://tacc.tapis.io/actors/v3/JWpkNmBwKewYo/executions/kA1P1m8NkkolK/logs
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  actor_id: JWpkNmBwKewYo
  api_server: https://tacc.tapis.io
  cpu: 9678006850
  executor: jstubbs
  exitCode: 1
  final_state:
  Dead: False
  Error:
  ExitCode: 1
  FinishedAt: 2020-10-21T17:26:49.77Z0
  OOMKilled: False
  Paused: False
  Pid: 0
  Restarting: False
  Running: False
  StartedAt: 2020-10-21T17:26:45.24Z0
  Status: exited
  finish_time: 2020-10-21T17:26:49.77Z0
  id: kA1P1m8NkkolK
  io: 152287298
  message_received_time: 2020-10-21T17:26:44.367Z
  runtime: 5
  start_time: 2020-10-21T17:26:44.841Z
  status: COMPLETE
  worker_id: QBmoQx4pOx1oA

List executions
^^^^^^^^^^^^^^^

Abaco allows users to retrieve all executions tied to an actor with the
``executions`` endpoint.

cURL
~~~~

List executions with cURL by getting the ``executions endpoint``

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/<actor_id>/executions

Python
~~~~~~

To list executions with ``tapipy`` the following is done:

.. code-block:: python

  t.actors.list_executions(actor_id='<actor_id>')

Results
~~~~~~~

Calling the list of executions should result in something similar to:

.. code-block:: python

  _links:
  owner: https://master.staging.tapis.io/profiles/v3/abaco
  actor_id: WP7vMmRvrDXxN
  api_server: https://master.staging.tapis.io
  executions: [
  finish_time: Wed, 21 Oct 2020 17:48:33 GMT
  id: QBmoQx4pOx1oA
  message_received_time: Wed, 21 Oct 2020 17:48:20 GMT
  start_time: Wed, 21 Oct 2020 17:48:20 GMT
  status: COMPLETE,
  finish_time: None
  id: QZY8W1Z30Zmbq
  message_received_time: Wed, 21 Oct 2020 17:49:56 GMT
  start_time: None
  status: SUBMITTED]
  owner: abaco
  totalCpu: 61248097463
  totalExecutions: 2
  totalIo: 752526010
  totalRuntime: 13

Reading message in execution
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

One of the most important parts of using data in an execution is reading said
data. Retrieving sent data depends on the data type sent.

Python - Reading in raw string data or JSON
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To retrieve JSON or raw data from inside of an execution using Python and
``tapipy``, you would get the message context from within the actor and then
get it's ``raw_message`` field.

.. code-block:: python

  from tapipy.actors import get_context

  context = get_context()
  message = context['raw_message']

Python - Reading in binary
~~~~~~~~~~~~~~~~~~~~~~~~~~

Binary data is transmitted to an execution through a FIFO pipe located at
/_abaco_binary_data. Reading from a pipe is similar to reading from a regular
file, however ``tapipy`` comes with an easy to use ``get_binary_message()``
function to retrieve the binary data.

**Note:** Each Abaco execution processes one message, binary or not. This means
that reading from the FIFO pipe will result with exactly the entire sent
message.

.. code-block:: python

  from tapipy.actors import get_binary_message

  bin_message = get_binary_message()



Logs
----

At any point of an execution you are also able to access the execution logs
using the ``logs`` endpoint. This returns information
about the log along with the log itself. If the execution is still in the
submitted phase, then the log will be an empty string, but once the execution
is in the completed phase the log would contain all outputted command line data.

Retrieving an executions logs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

cURL
~~~~

To call the ``log`` endpoint using cURL, do the following:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/<actor_id>/executions/<execution_id>/logs

Python
~~~~~~

To call the ``log`` endpoint using ``tapipy`` and Python, do the following:

.. code-block:: python

  t.actors.get_execution_logs(actor_id='<actor_id>',
                              execution_id='<execution_id>')

Results
~~~~~~~

This would result in data similar to the following:

.. code-block:: bash

  _links:
  execution: https://tacc.tapis.io/actors/v3/JWpkNmBwKewYo/executions/kA1P1m8NkkolK
  owner: https://tacc.tapis.io/profiles/v3/jstubbs
  logs: <command line output here>


----

Database Search
===============

With the introduction of Abaco 1.6.0 database searching has been introduced using
the Mongo aggregation system, full-text searching, and indexing. Searching can be
done on actor, worker, execution, and log information. This feature allows for users
to search based on any information across all objects that they have permission
to view. For example, search would allow checking of all viewable executions for
ERRORS in one easy call. The search currently makes use of logical operators and
datetime to allow for easy searching of any object based on any specific field.

.. attention::
    Search in Abaco was implemented in version 1.6.0.

Search is available on the actors, workers, executions, and logs databases. Search
has been implemented on a new ``{base}/actors/search/{database}`` endpoint alongside being
implemented on the ``{base}/actors``, ``{base}/actors/{actor_id}/workers``,
``{base}/actors/{actor_id}/executions``, and
``{base}/actors/{actor_id}/executions/{execution_id}/logs`` endpoints.

To use search on the ``{base}/actors/search/{database}`` endpoint the database to be searched
must be specified as either ``actors``, ``workers``, ``executions``, or ``logs`` in the URL.
With no query arguments Abaco will return all entries in the database that you have
permission to view. To specify query arguments the user can add a ``?`` to the end of
their url and specify the parameters they are looking to implement.

A table of search parameters, their function, and examples are below.

+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| Parameter   | Function                                                                                                                           | Examples                                |
+=============+====================================================================================================================================+=========================================+
| search      | Completes a fuzzy full-text search based on inputs. Returns results by best accuracy/score.                                        | ?search=stringToSearchFor               |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| exactsearch | Completes a full-text search and looks for exact matches with inputs.                                                              | ?exactsearch=stringToMatchExactly       |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| eq          | Checks if given value is equal to db value matching given key.                                                                     | ?id.eq=AKY5o4Z847lB3                    |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| neq         | Checks if given value is not equal to db value matching given key.                                                                 | ?id.neq=AKY5o4Z847lB3                   |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| gt          | Checks if given value is greater than db value matching given key.                                                                 | ?start_time.gt=2020-04-29+06:00         |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| gte         | Checks if given value is greater than or equal to db value matching given key.                                                     | ?runtime.gte=423                        |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| lt          | Checks if given value is less than db value matching given key.                                                                    | ?message_received_time.lt=2020          |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| lte         | Checks if given value is less than or equal to db value matching given key.                                                        | ?final_state.FinishedAt.lte=2020-04-29  |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| in          | Checks if db value matching given key match any values in the given list of values.                                                | ?status.in=["BUSY","REQUESTED","READY"] |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| nin         | Checks if db value matching given key does not match any values in the given list of values.                                       | ?status.nin=["COMPLETED", "READY"]      |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| like        | Checks if given value in (through regex) db value matching given key.                                                              | ?image.like=abaco_docker_username       |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| nlike       | Checks if given value not in (through regex) db value matching given key.                                                          | ?image.nlike=abaco_test                 |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| between     | Checks if db value matching given key is greater than or equal to first given value, and less than or equal to second given value. | ?start_time.between=                    |
|             |                                                                                                                                    | 2020-04-29T20:15:52:246Z,               |
|             |                                                                                                                                    | 2021-06-24-05:00                        |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| limit       | Sets a limit on total amount of results returned. Defaults to 10 results.                                                          | ?limit=20                               |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
| skip        | Skips a specified amount of results when returning.                                                                                | ?skip=4                                 |
+-------------+------------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------+

You may use as many parameters as you want in one query sans ``limit`` and ``skip``, where each may only be used once.

----

Metadata
--------

Abaco search slightly alters the expected result of a request in the fact that the returned
result from a search now returns two objects, the expected result, ``search``, and ``_metadata``.

This new ``_metadata`` object returns pertinent information about the amount of records returned,
the amount of records the return is limited to, the amount of records skipped (specified in query),
and the total amount of records that match the query searched for. This is useful to implement paging
or to only receive a set amount of records.

.. important::
    A new ``_metadata`` object is now returned alongside the usual result in ``result.``

Example of result with new ``result``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    {'message': 'Executions search completed successfully.',
     'result': {'_metadata': {'count_returned': 1,
                             'record_limit': 10,
                             'records_skipped': 0,
                             'total_count': 1},
                 'search': [{'_links': {'logs': 'https://dev.tenants.aloedev.tacc.cloud/v3/actors/joBjeDkWyBwLx/logs',
                                     'owner': 'https://dev.tenants.aloedev.tacc.cloud/profiles/v3/testuser',
                                     'self': 'https://dev.tenants.aloedev.tacc.cloud/v3/actors/joBjeDkWyBwLx/executions/1JKkQwX75vE56'},
                             'actor_id': 'joBjeDkWyBwLx',
                             'cpu': 444097006,
                             'executor': 'testuser',
                             'exitCode': 0,
                             'final_state': {'Dead': False,
                                         'Error': '',
                                         'ExitCode': 0,
                                         'FinishedAt': '2020-04-29T21:47:21.385Z',
                                         'OOMKilled': False,
                                         'Paused': False,
                                         'Pid': 0,
                                         'Restarting': False,
                                         'Running': False,
                                         'StartedAt': '2020-04-29T21:47:19.382Z',
                                         'Status': 'exited'},
                             'id': '1JKkQwX75vE56',
                             'io': 716,
                             'message_received_time': '2020-04-29T21:47:18.7Z00',
                             'runtime': 2,
                             'start_time': '2020-04-29T21:47:18.954Z',
                             'status': 'COMPLETE',
                             'worker_id': '7kvAAKYKB6Qk6'}]},
     'status': 'success',
     'version': ':dev'}

----


Inputs
------

All inputs are given to the search function as query parameters and thus are converted
to strings. It is then up to Abaco's side to convert these inputs back to the intended
formats. Strings are left untouched. Booleans are expected to be "False" or "false" and
"True" or "true" to be converted. Numbers are converted all to floats, these are still
comparable to database instances of int, so there should be no issue. Lists are parsed
with ``json.loads`` and will accept either ``["test"]`` or ``['test']`` with post-processing
on Abaco's end to convert to lists.

The last consumed input type is datetime objects. Abaco accepts a broad range of ISO 8601
like strings. An example of the most detailed string accepted is ``2020-04-29T20:15:52:246252-06:00``.
``2020-04-29T20:15:52:246Z``, ``2020-04-29T20:15:52-06:00``, ``2020-04-29T20:15-06:00``,
``2020-04-29T20-06:00``, ``2020-04-29-06:00``, ``2020-04Z``, and ``2020`` are also acceptable.

.. attention::
    Abaco stores all times in UTC, so addition of your timezone or conversion to UTC is
    important. If no timezone information is given (``-06:00`` or ``Z`` (to signal UTC))
    the datetime is assumed to be in UTC.

.. important::
    Comparison with datetime rounds to the minimum time possible. For instance if you want
    to see if 2020-12-30 is greater than 2020, you would receive True as 2020 is rounded
    to `2020-01-01T00:00:00Z`. This holds true until you reach millisecond accurate time.

Creating ISO 8601 formatted strings
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Python - String with Timezone
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following gets the current time as an ISO 8601 formatted string with timezone:

.. code-block:: python

    import datetime
    import pytz

    austin_time_zone = pytz.timezone("America/Chicago")
    isoString = datetime.datetime.now(tz=austin_time_zone).isoformat()
    print(isoString)

This prints ``2020-04-29T16:21:34.602078-05:00``.


Python - UTC String
~~~~~~~~~~~~~~~~~~~

The following gets the current UTC time as an ISO 8601 formatted string:

.. code-block:: python

    import datetime

    isoString = datetime.datetime.utcnow().isoformat()
    print(isoString)

This prints ``2020-04-29T21:21:34.602078``. Feel free to add the Z or leave it absent.

----

Searching
---------

Like mentioned above, a search may contain as many parameters as a user wants sans for
``limit`` and ``skip``, where each may only be used once. Search on the new
``{base}/actors/search/{database}`` always takes place and when given no parameters returns
any information the user has access to. To activate on search on the other endpoints, at
least one query parameter must be declared.

.. important::
    ``x-nonce`` queries will still work as expected and do not need any modification.



Performing searches on different endpoints
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

{base}/actors/search/actors
~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can use ``actors``, ``workers``, ``executions``, or ``logs`` as database inputs
for the endpoints. Each queries the specified database.

cURL
~~~~

.. code-block:: text

    $ curl -H "X-Tapis-Token: $TOKEN" \
    https://tacc.tapis.io/v3/actors/search/actors?image=abacosamples/test&create_time.gt=2020-04-29&status.in=["READY", "BUSY"]

Result
~~~~~~

.. code-block:: bash

    {'message': 'Search completed successfully.',
    'result': {'_metadata': {'count_returned': 1,
                            'record_limit': 10,
                            'records_skipped': 0,
                            'total_count': 1},
                'search': [{'_links': {'executions': 'https://dev.tenants.aloedev.tacc.cloud/v3/actors/joBjeDkWyBwLx/executions',
                                    'owner': 'https://dev.tenants.aloedev.tacc.cloud/profiles/v3/testuser',
                                    'self': 'https://dev.tenants.aloedev.tacc.cloud/v3/actors/joBjeDkWyBwLx'},
                            'createTime': '2020-04-29T21:46:53.393Z',
                            'default_environment': {'default_env_key1': 'default_env_value1',
                                                'default_env_key2': 'default_env_value2'},
                            'description': '',
                            'gid': None,
                            'hints': [],
                            'id': 'joBjeDkWyBwLx',
                            'image': 'abacosamples/test',
                            'last_update_time': '2020-04-29T21:46:53.393Z',
                            'link': '',
                            'max_cpus': None,
                            'max_workers': None,
                            'mem_limit': None,
                            'mounts': [{'container_path': '/_abaco_data1',
                                        'host_path': '/data1',
                                        'mode': 'ro'}],
                            'name': 'abaco_test_suite_default_env',
                            'owner': 'testuser',
                            'privileged': False,
                            'queue': 'default',
                            'state': {},
                            'stateless': True,
                            'status': 'READY',
                            'status_message': ' ',
                            'tasdir': None,
                            'token': 'false',
                            'type': 'none',
                            'uid': None,
                            'use_container_uid': False,
                            'webhook': ''}]},
    'status': 'success',
    'version': ':dev'}

{base}/actors/joBjeDkWyBwLx/executions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For a search from an endpoint like this the actor_id will already be in the query,
so for this example you would only receive executions with the actor_id of ``joBjeDkWyBwLx``.
``{base}/actors/joBjeDkWyBwLx/workers`` would result in the same behaviour, but for workers.
This usage means that performing a search on ``{base}/actors/joBjeDkWyBwLx/executions/1JKkQwX75vE56/logs``
would always result in one result. Only search on the ``{base}/actors`` thus is the only full
search available that does not use the ``{base}/actors/search/{database}`` endpoint.

.. attention::
    Use the ``{base}/actors/search/{database}`` endpoint for a full search of the specified
    database.

cURL
~~~~

.. code-block:: text

    $ curl -H "X-Tapis-Token: $TOKEN" \
    https://tacc.tapis.io/v3/actors/search/actors/joBjeDkWyBwLx/executions?status=COMPLETE&start_time.gt=2019

Result
~~~~~~

.. code-block:: bash

    {'message': 'Executions search completed successfully.',
     'result': {'_metadata': {'count_returned': 1,
                             'record_limit': 10,
                             'records_skipped': 0,
                             'total_count': 1},
                 'search': [{'_links': {'logs': 'https://dev.tenants.aloedev.tacc.cloud/v3/actors/joBjeDkWyBwLx/logs',
                                     'owner': 'https://dev.tenants.aloedev.tacc.cloud/profiles/v3/testuser',
                                     'self': 'https://dev.tenants.aloedev.tacc.cloud/v3/actors/joBjeDkWyBwLx/executions/1JKkQwX75vE56'},
                             'actor_id': 'joBjeDkWyBwLx',
                             'cpu': 444097006,
                             'executor': 'testuser',
                             'exitCode': 0,
                             'final_state': {'Dead': False,
                                         'Error': '',
                                         'ExitCode': 0,
                                         'FinishedAt': '2020-04-29T21:47:21.385Z',
                                         'OOMKilled': False,
                                         'Paused': False,
                                         'Pid': 0,
                                         'Restarting': False,
                                         'Running': False,
                                         'StartedAt': '2020-04-29T21:47:19.382Z',
                                         'Status': 'exited'},
                             'id': '1JKkQwX75vE56',
                             'io': 716,
                             'message_received_time': '2020-04-29T21:47:18.7Z00',
                             'runtime': 2,
                             'start_time': '2020-04-29T21:47:18.954Z',
                             'status': 'COMPLETE',
                             'worker_id': '7kvAAKYKB6Qk6'}]},
     'status': 'success',
     'version': ':dev'}




----

.. _target actor cron:

Cron Schedule
=============

.. Note::
  The Abaco Cron Schedule feature was implemented in version 1.7.0.

Abaco's cron schedule is a tool to automatically execute your actor based on a schedule.
Each actor has two user-defined parameters associated with the cron execution: 
``cron_schedule`` and ``cron_on``. The scheduler has another variable, ``cron_next_ex``,
which holds the next execution time of the actor. This is an internal variable 
and cannot be edited by users. 
To create a schedule, set the ``cron_schedule`` parameter when registering a new actor or updating an
existing actor.
The value of ``cron_schedule`` should be a string in the following format:

.. code-block:: bash

  yyyy-mm-dd hh + <number> <unit of time>

where the first part is the datetime when the first execution will happen, and the 
second part is the time increment for each subsequent execution. Note that the spaces,
plus characters (``+``) and dash characters (``-``) in the template above are meaningful and
are a required part of
the format. Abaco's cron schedule also has an alias
called ``now``, which lets you execute the actor at the current UTC time. For example,
if an actor was registered with this schedule

.. code-block:: bash

  "cron_schedule": "now + 1 hour"

the actor would execute at the current time, and then again at the top of the hour every hour.

.. Note::
  The highest granularity is the hour, and the units of time that can be used are hour, day, week, and month.

To create an actor with a schedule, make a request like the following:

.. code-block:: bash

    $ curl -H "X-Tapis-Token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"image": "abacosamples/test", "cron_schedule": "2020-09-28 16 + 1 hour"}' \
    https://tacc.tapis.io/v3/actors

To update the schedule, make a request like the following:

.. code-block:: bash

    $ curl -H "X-Tapis-Token: $TOKEN" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d '{"image": "abacosamples/test", "cron_schedule": "2020-12-11 16 + 3 days"}' \
    https://tacc.tapis.io/v3/actors/<actor_id>

This last request above will update the cron schedule for the actor with id ``<actor_id>`` as
follows: the actor will be scheduled to
automatically execute on December 11th, 2020 at 4 pm, UTC timezone. 
That actor will be executed again 3 days later on the 14th, 
at 4pm, and then 3 days after that, again at 4pm. This execution will 
recur every 3 days until the user changes the cron schedule,
turns off the cron schedule, or deletes the actor.

.. Note::
  The cron schedule runs on the UTC timezone. 

.. Note::
  When making requests to set the cron_schedule, be sure to pass "application/json" content to avoid
  issues requiring escaping characters inside the schedule value.


To turn off the schedule, use the `cron_on` switch like so:

.. code-block:: bash

    $ curl -H "X-Tapis-Token: $TOKEN" \
    -X PUT \
    -H "Content-Type: application/json" \
    -d '{"image": "abacosamples/test", "cron_on": "False"}' \
    https://tacc.tapis.io/v3/actors/<actor_id>


By turning off the schedule, the actor will no longer execute itself at each increment. 
You can turn it on again at any time, and the actor will 
resume incrementing as before. For example, if an actor is set to 
execute every hour, and then the cron switch is turned off, the actor will
stop executing itself. After a week, the switch can be turned back on, and the
actor will resume executing on the hour. 

Cron Schedule - Error Messages
------------------------------
If users supply a value for `cron_schedule` in an incorrect format, they will receive an error
letting them know to check the format. The API also checks that the schedule
sent in has not already past. For example, if you pass in the year 1955, you 
will get an error message saying the cron schedule has already passed. The error 
message will also tell you the current UTC time for reference. 

Cron Message and Execution
--------------------------
When it is time to execute an actor configured with a ``cron_schedule``, Abaco's internal cron agent
simply queues a message on the actor's internal message queue, just as if a client had sent a message
to the actor using the ``/messages`` API. If the actor already has (unprocessed) messages in its queue,
these messages will be processed first before the cron message. This means that there could be some delay
between the time Abaco internally queues the message and the actor starts executing it.

Currently, the cron message sent to the actor is the static string

.. code-block:: bash

  This is your cron execution

Accordingly, the ``_abaco_Content_Type`` context variable is set to ``str``. The rest of the context
variables are set normally, as described in :ref:`context`.


----

.. _target actor state:

Actor State
===========

In this section we describe the state that can persist through Abaco actor container executions.

State
-----

When an actor is registered, its ``stateless`` property is automatically set to ``true``. An actor must be registered with ``stateless=false`` to be stateful (maintain state ass executions).

Once an actor is executed, the associated worker ``GETs`` data from the ``/v3/actors/{actor_id}/state`` endpoint and injects it into the actor's ``_abaco_actor_state`` environment variable. While an actor is executing, the actor can update its state by ``POSTing`` to the aforementioned endpoint.


Notes
^^^^^

- The worker only ``GETs`` data from the state endpoint one time as the actor is initiated. If the actor updates its state endpoint during execution, the worker does not inject the new state until a new execution.
- Stateful actors may only have one associated worker in order to avoid race conditions. Thus generally, stateless actors will execute quicker as they can operate in parallel.
- Issuing a state to a stateless actor will return a ``actor is stateless.`` error.
- The ``state`` variable must be JSON-serializable. An example of passing JSON-serializable data can be found under `Examples <target state examples>` below.

Utilizing State in Actors to Accomplish Something
-------------------------------------------------

**WIP**

.. _target state examples:

Examples
--------

curl
^^^^
Here are some examples interacting with state using curl.


Registering an actor specifying statefulness: ``stateless=false``.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "image=abacosamples/test&stateless=false" \
  https://tacc.tapis.io/v3/actors

POSTing a state to a particular actor; keep in mind we must indicate in the header that we are passing content type ``application/json``.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"some variable": "value", "another variable": "value2"}' \
  https://tacc.tapis.io/v3/actors/<actor_id>/state

GETting information about a particular actor's state.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/<actor_id>/state


Python
^^^^^^

Here are some examples interacting with state using Python. The ``tapipy.actors`` module provides access to an actor's environment data in native Python objects.

Registering an actor specifying statefulness: ``stateless=false``.

.. code-block:: python

  from tapipy.tapis import Tapis
  t = Tapis(api_server='https://tacc.tapis.io', username='<username>', password='<password>')
  t.get_tokens()
  actor = {"image": "abacosamples/test",
           "stateless": "False"}
  actor_res = t.actors.create_actor(**actor)

POSTing a state to a particular actor; again keep in mind we must pass in JSON serializable data.

.. code-block:: python

  state = {"some variable": "value", "another variable": "value2"}
  t.actors.update_state(actor_id = actor_res.id,
                        request_body = state)

GETting information about a particular actor's state. This function returns a Python dictionary with many fields one of which is state.

.. code-block:: python

  from tapipy.actors import get_context
  get_context()
  {'raw_message': '<text>', 'content_type': '<text>', 'execution_id': '<text>', 'username': '<text>', 'state': 'some_state', 'actor_dbid': '<text>', 'actor_id': '<text>', 'raw_message_parse_log': '<text>', 'message_dict': {}}



----

.. _target actor sharing:

Actor Sharing and Nonces
========================

Abaco provides a basic permissions system for securing actors. An actor registered with Abaco starts out as private
and only accessible to the API user who registered it. This API user is referred to as the "owner" of the actor.
By making a POST request to the permissions endpoint for an actor, a user can manage the list of API users who have
access to the actor.

Permission Levels
-----------------

Abaco supports sharing an actor at three different permission levels; in increasing order, they are: `READ`,
`EXECUTE` and `UPDATE`. Higher permission imply lower permissions, so a user with `EXECUTE` also has `READ` while a
user with `UPDATE` has `EXECUTE` and `READ`. The permission levels provide the followig accesses:

  * `READ` - ability to list the actor to see it's details, list executions and retrieve execution logs.
  * `EXECUTE` - ability to send an actor a message.
  * `UPDATE` - ability to change the actor's definition.


cURL
^^^^

To share an actor with another API user, make a POST request to the `/permissions` endpoint; the following example
uses curl to grant READ permission to API user `jdoe`.

.. code-block:: text

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "user=jdoe&level=READ" \
  https://tacc.tapis.io/v3/actors/<actor_id>/permissions

Example response:

.. code-block:: bash

  {
    "message": "Permission added successfully.",
    "result": {
      "jdoe": "READ",
      "testuser": "UPDATE"
    },
    "status": "success",
    "version": "1.0.0"
  }


We can list all permissions associated with an actor at any time using a GET request:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/<actor_id>/permissions

Example response:

.. code-block:: bash

  {
    "message": "Permissions retrieved successfully.",
    "result": {
      "jdoe": "READ",
      "jsmith": "EXECUTE",
      "testuser": "UPDATE"
    },
    "status": "success",
    "version": "1.0.0"
  }

.. Note::
  To remove a user's permission, POST to the permission endpoint and set `level=NONE`


Public Actors
-------------

At times, it can be useful to grant **all** API users access to an actor. To enable this, Abaco recognizes the special
ABACO_WORLD user. Granting a permission to the ABACO_WORLD user will effectively grant the permission to all API users.


cURL
----

The following grants `READ` permission to all API users:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "user=ABACO_WORLD&level=READ" \
  https://tacc.tapis.io/v3/actors/<actor_id>/permissions


Nonces
------

Abaco provides a capability referred to as actor *nonces* to ease integration with third-party systems leveraging
different authentication mechanisms. An actor `nonce` can be used in place of the typical TACC API access token
(bearer token). However, unlike an access token which can be used for any actor the user has access, a nonce can only be
used for a specific actor.

Creating Nonces
^^^^^^^^^^^^^^^

API users create nonces using the nonces endpoint associated with an actor. Nonces can be limited to a specific
permission level (e.g., `READ` only), and can have a finite number of uses or an unlimited number.

The following example uses curl to create a nonce with `READ` level permission and with 5 uses.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "maxUses=5&level=READ" \
  https://tacc.tapis.io/v3/actors/<actor_id>/nonces

A typical response:

.. code-block:: bash

  {
    "message": "Actor nonce created successfully.",
    "result": {
      "_links": {
        "actor": "https://tacc.tapis.io/v3/actors/rNjQG5BBJoxO1",
        "owner": "https://tacc.tapis.io/profiles/v3/testuser",
        "self": "https://tacc.tapis.io/v3/actors/rNjQG5BBJoxO1/nonces/DEV_qBMrvO6Zy0yQz"
      },
      "actor_id": "rNjQG5BBJoxO1",
      "api_server": "http://172.17.0.1:8000",
      "createTime": "2019-06-18 12:20:53.087704",
      "currentUses": 0,
      "description": "",
      "id": "TACC_qBMrvO6Zy0yQz",
      "lastUseTime": "None",
      "level": "READ",
      "maxUses": 5,
      "owner": "testuser",
      "remainingUses": 5,
    },
    "status": "success",
    "version": "1.0.0"
  }


The `id` of the nonce (in the above example, `TACC_qBMrvO6Zy0yQz`) can be used to access the actor in place of the
access token.

.. Note::
  Roles are used throughout the TACC API's to grant users with specific privileges (e.g., administrative access to certain
  APIs). The roles of the API user generating the nonce are captured at the time the nonce is created; when using a nonce,
  a request will have permissions granted via those roles. Most users will not need to worry about TACC API roles.

To create a nonce with unlimited uses, set `maxUses=-1`.


Redeeming Nonces
^^^^^^^^^^^^^^^^

To use a nonce in place of an access token, simply form the request as normal and add the query paramter `x-nonce=<nonce_id>`.

For example

.. code-block:: bash

  $ curl -X POST -d "message=<your content here>" \
  https://tacc.tapis.io/v3/actors/<actor_id>/messages?x-nonce=TACC_vr9rMO6Zy0yHz

The response will be exactly the same as if issuing the request with an access token.



----

Networks of Actors
==================

Working with individual, isolated actors can augment an existing application with a lot of additional functionality, but the
full power of Abaco's actor-based system is realized when many actors coordinate together to solve a common problem.
Actor coordination introduces new challenges that the system designer must address, and Abaco provides
features specifically designed to address these challenges.


Actor Aliases
-------------

An `alias` is a user-defined name for an actor that is managed independently of the actor itself. Put simply, an alias
maps a name to an actor id, and Abaco will replace a reference to an alias in any request with the actor id defined by
the alias at the time. Aliases are useful for insulating an actor from changes to another actor to which it will
send messages.

For example, if actor A sends messages to actor B, the user can create an alias for actor B and configure A to send
messages to that alias. In the future, if changes need to be made to actor B or if messages from actor A need to be
routed to a different actor, the alias value can be updated without any code changes needed on the part of actor A.

Creating and managing aliases is done via the ``/aliases`` collection.

cURL
^^^^

To create an alias, make a POST request passing the alias and actor id. For example, suppose we have an actor that counts
the words sent in a message. We might create an alias for it with the following:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "alias=counter&actor_id=6PlMbDLa4zlON" \
  https://tacc.tapis.io/v3/actors/aliases

Example response:

.. code-block:: bash

  {
    "message": "Actor alias created successfully.",
    "result": {
      "_links": {
        "actor": "https://tacc.tapis.io/v3/actors/6PlMbDLa4zlON",
        "owner": "https://tacc.tapis.io/profiles/v3/jstubbs",
        "self": "https://tacc.tapis.io/v3/actors/aliases/counter"
      },
      "actor_id": "6PlMbDLa4zlON",
      "alias": "counter",
      "owner": "apitest"
    },
    "status": "success",
    "version": "1.1.0"
  }

With the alias ``counter`` created, we can now use it in place of the actor id in any Abaco request. For example, we
can get the actor's details:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  https://tacc.tapis.io/v3/actors/counter

The response returned is identical to that returned when the actor id is used.


Nonces Attached to Aliases
--------------------------

.. Important::
   Support for Nonces attached to aliases was added in version 1.1.0.


.. Important::
   The nonces attached to aliases feature was updated in version 1.5.0, so that 1) ``UPDATE`` permission on the
   underlying actor id is required and 2) It is no longer possible to create an alias nonce for permission level ``UPDATE``.


Nonces can be created for aliases in much the same way as creating nonces for a specific actor id - instead of using
the ``/nonces`` endpoint associated with the actor id, use the ``/nonces`` endpoint associated with the alias instead. The
POST message payload is the same. For example:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -d "maxUses=5&level=READ" \
  https://tacc.tapis.io/v3/actors/aliases/counter/nonces

will create a nonce associated with the ``counter`` alias.

.. Note::
  Listing, creating and deleting nonces associated with an alias requires the analagous permission for both the alias
  **and** the associated actor.

.. _target actor links:

Actor Events, Links and WebHooks
--------------------------------

.. Important::
   Support for Actor events, links and webhooks was added in version 1.2.0.

Abaco captures certain events pertaining to the evolution of the system runtime and provides mechanisms for users to
consume these events in actors as well as in external systems.

First, Abaco provides a facility to automatically send a message to a specified actor whenever certain events occur. This
mechanism is called an actor `link`: if actor A is registered with a ``link`` property specifying actor B, then Abaco will
automatically send actor B a message whenever any of the recognized events occurs.

Second, an actor can be registered with a ``webhook`` property: a single string representing a URL to send an HTTP POST
request to. The Abaco events subsystem will send a POST request **exactly once** to the specified URL whenever a
recognized event occurs.

Webhooks and event messages are guaranteed to be delivered in order relative to the order the events occurred for the
specific actor. Since there is no total ordering on events across different actors, there is no analagous order
guarantee.

Links or Webhooks - Which to use?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In both cases, the details of the event are described in a JSON message (sent to an actor in the case of a link, and
sent in the POST payload in the case of a webhook).

However, the actor link is far more general and flexible since
the user can define arbitrary logic to handle the event. Even when the ultimate goal is a webhook, the user may opt for
defining a link to an actor that performs the webhook. This approach enables users to customtize the webhook processing
in various ways, including retry logic, authentication, etc. In fact, the ``abacosamples/webhook`` image provides a
webhook dispatcher built to parse the Abaco events message with many configurable options.

Use of an actor's ``webhook`` property is really intended for simple use cases or situations missed or dropped events
will not cause a major issue.

Adding a Link
~~~~~~~~~~~~~

Registering an actor with a link (or updating an exisitng actor to add a link property) follows the same semantics as
defined in the :ref:`Registration <target registration>` section; simply add the ``link`` attribute in the payload. For example, the following
request creates an actor with a link to actor id ``6PlMbDLa4zlON``.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image": "abacosamples/test", "name": "test", "link": "6PlMbDLa4zlON", "description": "My test actor using the abacosamples image.", "default_environment":{"key1": "value1", "key2": "value2"} }' \
  https://tacc.tapis.io/v3/actors

It is also possible to link an actor to an alias: just pass ``link=<the_alias>`` in the registration payload.

.. note::
  Setting a link attribute requires ``EXECUTE`` permission for the associated actor.

.. note::
  Defining a link property that would result in a cycle of linked actors is not permitted, as this would result in
  infinite messages. In particular, an actor cannot link to itself.

Adding a WebHook
~~~~~~~~~~~~~~~~
Registering an actor with a webhook is accomplished similarly by setting the ``webhook`` property in the actor
registration (POST) or update (PUT) payload. For example, the following request creates an actor with a webhook
set to the requestbin at ``https://eniih104j4tan.x.pipedream.net``.

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image": "abacosamples/test", "name": "test", "webhook": "https://eniih104j4tan.x.pipedream.net", }' \
  https://tacc.tapis.io/v3/actors

Events and Event Message Format
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Whenever a supported event occurs, Abaco sends a JSON message to the linked actor or webhook with data about the event.
The included data depends on the event type, as documented below.

In the case of a linked actor, all the typical context variables, as
documented in :ref:`Context <target context>`, will be injected as usual, excepted where noted below. In this case, note that there are
details about two actors: the actor for which the event occurred and the linked actor itself (which are always different,
as self-links are not permitted).
The former is described in the message itself with variables such as ``actor_id``, ``tenant_id``, etc., while the
latter is described using the special reserved Abaco variables, e.g., ``_abaco_actor_id``, etc.

+---------------------+--------------------------------------------------------------------------+--------------------+
| Variable Name       | Description                                                              | Event Type         |
+=====================+==========================================================================+====================+
| actor_id            | The id of the actor for which the event occurred.                        | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| tenant_id           | The id of the tenant of the actor for which the event occurred.          | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| actor_dbid          | The internal id of the actor for which the event occurred.               | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| event_type          | The event type associated with the event. (see table below)              | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| event_time_utc      | The time of the event, in UTC, as a float.                               | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| event_time_display  | The time of the event, as a string, formatted for display.               | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| _abaco_link         | The actor id of the linked actor (the actor receiving the event message) | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| _abaco_username     | 'Abaco Event'                                                            | all types          |
+---------------------+--------------------------------------------------------------------------+--------------------+
| status_message      | A message indicating details about the error status.                     | ACTOR_ERROR        |
+---------------------+--------------------------------------------------------------------------+--------------------+
| execution_id        | The id of the completed execution.                                       | EXECUTION_COMPLETE |
+---------------------+--------------------------------------------------------------------------+--------------------+
| exit_code           | The exit code of the completed execution.                                | EXECUTION_COMPLETE |
+---------------------+--------------------------------------------------------------------------+--------------------+
| status              | The final status of the completed execution.                             | EXECUTION_COMPLETE |
+---------------------+--------------------------------------------------------------------------+--------------------+

The following table lists all events by their ``event_type`` value and a brief description. Additional event types
may be added in subsequent releases.

+---------------------+--------------------------------------------------------------------------+
| Event type          | Description                                                              |
+=====================+==========================================================================+
| ACTOR_READY         | The actor is ready to accept messages.                                   |
+---------------------+--------------------------------------------------------------------------+
| ACTOR_ERROR         | The actor is in error status and requires manual intervention.           |
+---------------------+--------------------------------------------------------------------------+
| EXECUTION_COMPLETE  | An actor execution has just completed.                                   |
+---------------------+--------------------------------------------------------------------------+





----

.. _target autoscaling:

Autoscaling Actors
==================

The Abaco platform has an optional autoscaler subsystem for automatically managing the pool of workers associated with
the registered actors. In general, the autoscaler ignores actors that are registered with ``stateless: False``, as it
assumes these actors must process their message queues synchronously. For `stateless` actors without custom
configurations, the austocaling algorithm is as follows:

1. Every 5 seconds, check the length of the actor's message queue.
2. If the queue length is greater than 0, and the actor's worker pool is less than the maximum workers per actor, start a new worker.
3. If the queue length is 0, reduce the actor's worker pool until: a) the worker pool size becomes 0 or b) the actor receives a message.

In particular, the worker pool associated with an actor with 0 messages in its message queue will be reduced to 0 to
free up resources on the Abaco compute cluster.


Official "sync" Hint
--------------------

.. Important::
   Support for actor hints and the official "sync" hint was added in version 1.4.0.

For some use cases, reducing an actor's worker pool to 0 as soon as its message queue is empty is not desirable.
Starting up a worker takes significant time, typically on the order of 10 seconds or more, depending on configuration
options for the actor, and adding this overhead to actors that have low latency requirements can be a serious issue.
In particular, actors that will respond to "synchronous messages" (i.e., ``_abaco_synchronous=true``) have low
latency requirements to respond within the HTTP timeout window.

For this reason, starting in version 1.4.0, Abaco recognizes an "official" actor hint, ``sync``. When registered
with the ``sync`` hint, the Abaco autoscaler will leave at least one worker in the actor's worker pool up to a
configurable period of idle time (specific to the Abaco tenant). For the Abaco public tenant, this period is 60
minutes.

The ``hints`` attribute for an actor is saved at registration time. In the following example, we register an
actor with the ``sync`` hint using curl:

.. code-block:: bash

  $ curl -H "X-Tapis-Token: $TOKEN" \
  -H "Content-type: application/json" \
  -d '{"image": "abacosamples/wc", "hints": ["sync"]}' \
  https://tacc.tapis.io/v3/actors




----

API Reference
=============

The following table lists the public endpoints within the Abaco API.

+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
| GET | POST | PUT | DELETE | Endpoint                                      |  Description                    |
+=====+======+=====+========+===============================================+=================================+
|  X  |      |     |        | /v3/actors/utilization                        | Get high-level usage stats.     |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |  X   |     |        | /v3/actors                                    | List/create actors.             |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |   X  |     |        | /v3/actors/aliases                            | List/create aliases.            |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |   X    | /v3/actors/aliases/{alias}                    | List/delete an alias.           |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |  X  |   X    | /v3/actors/{actor_id}                         | List/update/delete an actor.    |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |  X   |     |        | /v3/actors/{actor_id}/messages                | Get number messages/send message|
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |  X   |     |        | /v3/actors/{actor_id}/nonces                  | List/create actor nonces.       |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |   X    | /v3/actors/{actor_id}/nonces/{nonce_id}       | Get nonce details/delete nonce. |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |  X   |     |        | /v3/actors/{actor_id}/state                   | Retrieve/update actor state.    |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |  X   |     |        | /v3/actors/{actor_id}/workers                 | List/create actor workers.      |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |   X    | /v3/actors/{actor_id}/workers/{worker_id}     | Get worker details/delete worker|
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |  X   |     |        | /v3/actors/{actor_id}/permissions             | List/update actor permissions.  |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |        | /v3/actors/{actor_id}/executions              | Retrieve execution details.     |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|     |      |     |   X    | /v3/actors/{actor_id}/executions/{eid}        | Halt running execution.         |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |        | /v3/actors/{actor_id}/executions/{eid}/logs   | Retrieve execution logs.        |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |        | /v3/actors/{actor_id}/executions/{eid}/results| Retrieve execution results.     |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |        | /v3/actors/search/{database}                  | Searches specified database     |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
|  X  |      |     |        | /metrics                                      |                                 |
+-----+------+-----+--------+-----------------------------------------------+---------------------------------+
