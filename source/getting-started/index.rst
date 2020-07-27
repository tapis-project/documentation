.. _getting-started:

===============
Getting Started
===============

This Getting Started guide will walk you through the initial steps of setting up the necessary accounts and installing
the required software before moving to the Tapis Quickstart. If
you are already using Docker Hub and the TACC Cloud APIs, feel free to jump right to the `Tapis Quickstart`_ or check
out the Tapis Live Docs `site <https://tapis-project.github.io/live-docs/>`_.

.. contents:: :local:

------------------------------------------
Account Creation and Software Installation
------------------------------------------

Create a TACC account
^^^^^^^^^^^^^^^^^^^^^

The main instance of the Tapis platform is hosted at the Texas Advanced Computing Center (`TACC <https://tacc.utexas.edu>`_).
TACC designs and deploys some of the world's most powerful advanced computing technologies and innovative software
solutions to enable researchers to answer complex questions. To use the TACC-hosted Tapis platform, please
create a `TACC account <https://portal.tacc.utexas.edu/account-request>`__ .


----------------
Tapis Quickstart
----------------

In this Quickstart, we will use the Tapis APIs to manage files on a TACC storage system. To begin we use our credentials
to get a Tapis token from the authenticator. For this quickstart, we will be using the ``tacc`` tenant with base URL
``https://tacc.tapis.io``.

With CURL:

.. code-block:: plain-text

 $ curl -H "Content-type: application/json" -d '{"username": "apitest", "password": "abcde123", "grant_type": "password" }' \
 https://tacc.tapis.io/v3/oauth2/tokens

Be sure to export the access token returned from the above CURL command as an environment variable:

.. code-block:: plaintext

 $ export JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJqdGkiOiJmN2....


With PySDK

.. code-block:: plain-text

    from tapipy.tapis import Tapis
    # Create python Tapis client for user
    t = Tapis(base_url= "https://tacc.tapis.io", username="your_tacc_username", password="your_tacc_password")
    # Call to Tokens API to get access token
    t.get_tokens()


Now that we have an access token, we are ready to create a Tapis system. For this quick-start, we will register an S3 bucket
we have pre-create with Amazon's AWS S3 service.

We assume an S3 bucket has been registered with AWS with URL ``https://<your_bucket_id>.s3.us-east-1.amazonaws.com/``
and that you have access to the bucket ``accessKey`` and ``accessSecret``.

To register the S3 bucket with Tapis we do the following:

With PySDK

.. code-block:: plain-text

    # the description of an S3 bucket
    s3_bucket = {
      "name":"my.test.bucket",
      "description":"Test Tapis Bucket",
      "host":"https://<your_bucket_id>.s3.us-east-1.amazonaws.com/",
      "systemType":"OBJECT_STORE",
      "defaultAccessMethod":"ACCESS_KEY",
      "effectiveUserId":"<your_tacc_username>",
      "bucketName":"tapis-files-bucket",
      "rootDir":"/",
      "jobCanExec": False,
      "transferMethods":["S3"],
      "accessCredential":
      {
        "accessKey":"***",
        "accessSecret":"***"
      }
    }

    # create the system in Tapis
    t.systems.createSystem(**s3_bucket)

The output should look similar to the following; it describes the System that was just created:

.. code-block:: plain-text

    accessCredential: None
    bucketName: my.test.bucket
    created: 2020-06-25T16:11:52.543Z
    defaultAccessMethod: ACCESS_KEY
    deleted: False
    description: Test Tapis Bucket
    effectiveUserId: <your_tacc_username>
    enabled: False
    host: https://tapis-demo.s3.us-east-1.amazonaws.com/
    id: 2
    jobCanExec: False
    jobCapabilities: []
    jobLocalArchiveDir: None
    jobLocalWorkingDir: None
    jobRemoteArchiveDir: None
    jobRemoteArchiveSystem: None
    name: tapis-demo
    notes:

    owner: <yout_tacc_username>
    port: 0
    proxyHost:
    proxyPort: 0
    rootDir: /
    systemType: OBJECT_STORE
    tags: []
    tenant: dev
    transferMethods: ['S3']
    updated: 2020-06-25T16:11:52.543Z
    useProxy: False

We are now able to list files in our bucket using the Files API.

With PySDK

.. code-block:: plain-text

  permitted_client.files.listFiles(systemId="my.test.bucket", path="/")

The output should include a list of all files in the bucket; for example

.. code-block:: plain-text

    [
     lastModified: 2020-06-12T16:29:10Z
     name: Bora2.jpg
     path: Bora2.jpg
     size: 390672,

     lastModified: 2020-07-21T16:27:53Z
     name: plot_2020-07-21T01:29:26.640144Z.png
     path: plot_2020-07-21T01:29:26.640144Z.png
     size: 31211
]

