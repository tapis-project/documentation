-----------
Quick start
-----------

.. warning::
  This Quick Start is deprecated.
  There is a new one comming soon!


We will be creating a pipeline that
  * pulls code from a private Github repository
  * builds an image from a Dockerfile located in that source code
  * then pushes the resultant image to a Dockerhub image registry
  
In the examples below we assume you are using the TACC tenant with a base URL of ``tacc.tapis.io`` and that you have
authenticated using PySDK or obtained an authorization token and stored it in the environment variable JWT,
or perhaps both.

Summary of Steps
~~~~~~~~~~~~~~~~
1. Create a *Group*
2. Create an *Archive* to which the results of the pipeline run will be persisted
3. Create the *Pipeline* and its *Tasks* which act as instructions to the workflow executor

Creating a Group
~~~~~~~~~~~~~~~~~~~

Create a local file named ``group.json`` with json similar to the following:

.. code-block:: json

  {
    "id": "<group_id>",
    "users": [
        {
          "username":"<user_id>",
          "is_admin": true
        }
    ]
  }

.. note:: You do not need to add your own Tapis id to the users list. The owner of the Group is added by default. 

Replace *<group_id>* with your desired group id and *<user_id>* in the user objects with
the tapis user ids of the other users that you want to grant access to this group's workflow resources.

Submit the definition.

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups -d @group.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    with open('group.json', 'r') as openfile:
      group = json.load(openfile)

    t.workflows.createGroup(**group)

----

Creating Identities
~~~~~~~~~~~~~~~~~~~~~~
We will be creating 2 identity mappings. One for Github and one for Dockerhub. After creating 
the identities, we will need to retrieve the UUIDs of the newly created identities. You can do
this in a separate call, or simple grab the UUID from the url in the result after each operation.

.. warning::
  Do **NOT** commit these files to source control!

Create the first file named ``github-identity.json`` with the following json:

.. code-block:: json

  {
    "type": "github",
    "name": "my-github-identity",
    "description": "My github identity",
    "credentials": {
      "username": "<github_username>",
      "personal_access_token": "<github_personal_access_token>"
    }
  }

Then submit the definition

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/identities -d @github-identity.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    with open('github-identity.json', 'r') as openfile:
      identity = json.load(openfile)

    t.workflows.createIdentity(**identity)

Create the second file named ``dockerhub-identity.json`` with the following json

.. code-block:: json
  
  {
      "type": "dockerhub",
      "name": "my-dockerhub-identity",
      "description": "My Dockerhub identity",
      "credentials": {
        "username": "<docerkhub_username>",
        "token": "<dockerhub_access_token>"
      }
  }

Then submit the definition

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/identities -d @dockerhub-identity.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    with open('dockerhub-identity.json', 'r') as openfile:
      identity = json.load(openfile)

    t.workflows.createIdentity(**identity)

----

Creating an Archive
~~~~~~~~~~~~~~~~~~~~~~

In this step, we create the Archive. The results of the pipeline run will be persisted to the archive.

.. note:: This step requires that you have "**MODIFY**" permissions on some Tapis System. If you do not have access to one, you can create it following the instruction in the "Systems" section.

Create a local file named ``archive.json`` with json similar to the following:

.. code-block:: json

  {
    "id": "my-sample-archive",
    "type": "system",
    "system_id": "<your-tapis-system-id>",
    "archive_dir": "/workflows/archive/"
  }

.. note:: The archive_dir is relative to your system's rootDir. You can change this value to whatever you like.

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/archives -d @archive.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    with open('archive.json', 'r') as openfile:
      archive = json.load(openfile)

    t.workflows.createArchive(
      group_id="<group_id>"
      **archive
    )

----

Creating a Pipeline
~~~~~~~~~~~~~~~~~~~~~~

In this step, we define the pipeline. There are many more properties that can be defined
at both the pipeline and task level, but for simplicity, we will be leaving them out.

Create a local file named ``pipeline.json`` with json similar to the following:

.. code-block:: json

  {
    "id": "my-sample-workflow",
    "archives": [ "<archive_id>" ]
    "tasks": [
      {
        "id": "my-image-build",
        "type": "image_build",
        "builder": "kaniko",
        "context": {
            "branch": "main",
            "build_file_path": "<path/to>/Dockerfile",
            "sub_path": null,
            "type": "github",
            "url": "<account>/<repo>",
            "visibility": "private",
            "identity_uuid": "<github_identity_uuid>"
        },
        "destination": {
            "tag": "<some_image_tag>",
            "type": "dockerhub",
            "url": "<account>/<registry>",
            "identity_uuid": "<dockerhub_identity_uuid>"
        }
      }
    ]
  }

Go through the definition above and replace all of the placeholders with the correct values.

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups/<group_id>/pipelines -d @pipeline.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    with open('pipeline.json', 'r') as openfile:
      pipeline = json.load(openfile)

    t.workflows.createPipeline(
      group_id="<group_id>"
      **pipeline
    )

----

Now it's time to run the pipeline.

.. include:: /technical/workflows/operations/runPipeline.rst

After the pipeline has finished running, take a look in your Dockerhub image repository
and you will find your newly pushed image.

If you SSH into the *Tapis System* that you selected as your archive, you will also find 
that you have some new directories and files in your **rootDir**;

``/workflows/archive/<UUID of the pipeline run>/my-image-build/output/.stdout``.

If you want to find the output for any task for a given pipeline run, simply navigate
to the archive directory, ``cd`` into directory with the pipline run UUID, then ``cd`` into
the directory with that task's name. Inside the ``output/`` directory, you will find all of
the data created by that task.