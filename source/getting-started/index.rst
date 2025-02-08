.. _getting-started:

###############
Getting Started
###############

This Getting Started guide will walk you through the initial steps of setting up
the necessary accounts and installing
the required software before moving to the Tapis Quickstart. If
you are already using Docker Hub and the TACC Cloud APIs, feel free to jump
right to the `Tapis Quickstart`_ or check
out the Tapis Live Docs `site <https://tapis-project.github.io/live-docs/>`_.

.. contents:: :local:

Getting Ready
=============

cURL or Python: Pick Your Path
------------------------------

This guide provides examples in both the command line web interface *cURL* and the Python SDK. cURL is a command line tool for transferring data via URLs and receiving responses; cURL is available in your terminal (for MacOS, Linux, and Unix users), and transfers data from or to a server using one of a number of internet protocols. You could also choose to use a tool like
`Postman <https://www.postman.com>`_ which which provides a nice GUI on top of cURL.

To run the Python examples you will need a functioning Python3 environment and the Tapis Python APIs installed on your system (read more about the tapispy project at `PyPi <https://pypi.org/project/tapipy/>`_).

Amazon S3
---------

In either case you will be accessing an Amazon AWS S3 storage bucket in this Tapis example. In the code we assume you have created an S3 bucket with URL *https://<your_bucket_name>.s3.amazonaws.com/*
and that you have access to the bucket via an AWS user identity with ``accessKey`` and ``accessSecret``. If you are new to Amazon's S3 service, you can get started for free to complete this tutorial. Check out their `Getting Started Guide <https://docs.aws.amazon.com/AmazonS3/latest/userguide/GetStartedWithS3.html>`_ and follow the tutorial through *Step 2: Upload an object to your bucket*. Our example will list the files stored in this bucket, so you may want to upload a file to your bucket so you can verify that your code works; a small image file would do the trick. In the examples below we have created an S3 bucket called *tapisbucket* and uploaded a single file to it called *test_image.jpg*.

A TACC Account
--------------

The main instance of the Tapis platform is hosted at the Texas Advanced
Computing Center (`TACC <https://tacc.utexas.edu>`_).
TACC designs and deploys some of the world's most powerful advanced computing
technologies and innovative software solutions to enable researchers to answer
complex questions.  To follow along with this Quickstart and use the
TACC-hosted Tapis platform, please
create a `TACC account <https://portal.tacc.utexas.edu/account-request>`__ .


Tapis Quickstart
================

In this guide, we will use the Tapis APIs to list files on the Amazon AWS S3 storage system using the
*tacc* instance of Tapis (an instance of Tapis is called a **tenant**; since Tapis is open source any organization can install it and run their own tenant) with base URL *https://tacc.tapis.io*. We will work the example in two ways: using cURL from the command line and using a Python script. Pick the path that most closely matches your needs.

Python Example
---------------------


Getting a Tapis Token
^^^^^^^^^^^^^^^^^^^^^

To begin we use our TACC account credentials to get a Tapis token from the authenticator. A valid token is needed
to interact with Tapis. You will note that your token is returned with an expiration date and time. If
you want to continue to use Tapis after your token expires, you will need to get a new one following the same
steps.

For the purpose of this tutorial, we will be using the base_url of ``https://tacc.tapis.io``. 
To discover other tenants, and find the details specific to that tenant, such as owner, base_url, tenant_id, etc. you can use following curl command in your terminal window. 

.. code-block:: text

    curl https://admin.tapis.io/v3/tenants | jq

Note that ``jq`` is a command-line JSON formatter. Checking out their `download instructions <https://jqlang.github.io/jq/download/>`_.

From here, you will use the ``ctrl-F`` function in your terminal window to search for your base_url. 
A note of caution, be sure to verify if you are using the DEV or PROD tenants; DEV tenants will be labeled with a delineation of -dev and noted in the description as such.

For more information about tenant listing and search techniques please see the `Tenancy, Sites and Authentication <https://tapis.readthedocs.io/en/latest/technical/authentication.html>`_.

In Python code below you will replace *your_tacc_username* and *your_tacc_password* with your TACC username and password, preserving the quotation marks shown in the command below. See more about the Tapis Python SDK, ``tapipy``, including how to install it, from `here <https://tapis.readthedocs.io/en/latest/technical/pythondev.html>`_.

.. include:: /includes/tapipy-init.rst

This call does not produce output. However you can use the following code to see the access token you just created.

.. code-block:: python

    t.access_token

The output should look similar to the following; it describes the access token that was just created.

.. code-block:: text

    access_token: *very long string of alphanumeric characters*
    claims: {'jti': '007fa9e6-f044-4817-a812-12292b2bdbe3', 'iss': 'https://tacc.tapis.io/v3/tokens', 'sub': 'your_tacc_username', 'tapis/tenant_id': 'tacc', 'tapis/token_type': 'access', 'tapis/delegation': False, 'tapis/delegation_sub': None, 'tapis/username': 'your_tacc_username', 'tapis/account_type': 'user', 'exp': 1657686889, 'tapis/client_id': None, 'tapis/grant_type': 'password'}
    expires_at: 2022-07-13 04:34:49+00:00
    expires_in: <function Tapis.add_claims_to_token.<locals>._expires_in at 0x10a070280>
    jti: 007fa9e6-f044-4817-a812-12292b2bdbe3
    original_ttl: 14400

Where you will have your own access token and the placeholder *your_tacc_username* will be replaced with the username you used.

Register the S3 Storage with Tapis
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we have an access token, we are ready to create a Tapis ``system`` object. Remember that the Tapis APIs are a framework for accessing a wide variety of computational resources: for this example, we will register the S3 bucket we pre-created with Amazon's AWS S3 service (if this is unfamiliar to you, refer back to the `Getting Ready`_ section above). This step registers the S3 bucket with Tapis so it can access the bucket on your behalf. Note that the value of ``id`` needs to be unique within the Tapis tenant you are using; for this example we show the string *your_tapis_system_id*, but you'll need to choose your own globally (within the Tapis tenant you are using) unique id (possibly including your user name, for example, or some other unique id; for example, something like *username.tapis_test_v1*). The values for ``host`` and ``bucketName`` are set based on the values you used when you set up your own AWS S3 bucket, as discussed above. In this example they are

.. code-block:: python

    # To register the S3 bucket with Tapis
    # the description of an S3 bucket
    s3_bucket = {
      "id":"your_tapis_system_id",
      "description":"Tapis Test Bucket",
      "host":"tapisbucket.s3.amazonaws.com",
      "systemType":"S3",
      "defaultAuthnMethod":"ACCESS_KEY",
      "bucketName":"tapisbucket",
      "canExec": False,
    }

    # create the system in Tapis
    t.systems.createSystem(**s3_bucket)

The output of the command will show the URL to the system you just created in the Tapis tenant.

Create an Access Credential
^^^^^^^^^^^^^^^^^^^^^^^^^^^

With our system created and linked to the S3 storage bucket, we need to create an access credential for Tapis to access our bucket on our behalf. Note that in this example we have created an access key and secret for the IAM user in our AWS instance; when substituting your own access key and secret into the code below, remember to preserve the single quotation marks enclosing these pieces of data.

.. code-block:: python

    t.systems.createUserCredential(systemId='your_tapis_system_id',
                                   userName='your_tacc_username',
                                   accessKey='IAM user access key that you created in the AWS interface',
                                   accessSecret='access secret from the AWS interface for the key you created')

The output of the command should look similar to the text below.

.. code-block:: text

    {'result': None,
    'status': 'success',
    'message': 'SYSAPI_CRED_UPDATED Credential updated. jwtTenant: tacc jwtUser: your_tacc_username OboTenant: tacc OboUser: your_tacc_username System: your_tapis_system_id User: your_tacc_username',
    'version': '1.2.1',
    'metadata': None}

Access the files in our S3 Bucket
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We are now able to list files in our bucket using the Files API (you can also use the API to add new files, delete files, rename files, and so on; but since this is a example, we've just selected a file listing as the example operation).

.. code-block:: python

  t.files.listFiles(systemId="your_tapis_system_id", path="/")

The output should include a list of all files in the bucket. For this example we only put one file in our bucket, test_image.jpg. The listing returns the name of that file along with some metadata:

.. code-block:: text

    [
    group: None
    lastModified: 2022-05-20T19:24:24Z
    mimeType: image/jpg
    name: test_image.jpg
    nativePermissions: None
    owner: None
    path: /test_image.jpg
    size: 87060
    type: file
    url: tapis://your_tapis_system_id/test_image.jpg]

.. _curl-example:

cURL Example
----------------------

As with the Python example, we will use the Tapis APIs to list files on the Amazon AWS S3 storage system using the *tacc* tenant with base URL *https://tacc.tapis.io*.


Getting a Tapis Token
^^^^^^^^^^^^^^^^^^^^^

To begin we use our TACC account credentials to get a Tapis token from the authenticator. A valid token is needed
to interact with Tapis. You will note that your token is returned with an expiration date and time. If
you want to continue to use Tapis after your token expires, you will need to get a new one following the same
steps.

Type the curl command below into your terminal window, replacing *your_tacc_username* and *your_tacc_password* with your TACC user name and password, preserving the quotation marks.

 .. code-block:: text

      $ curl -H "Content-type: application/json" -d '{"username": "your_tacc_username", "password": "your_tacc_password", "grant_type": "password" }' https://tacc.tapis.io/v3/oauth2/tokens

The output of this operation will look like the following (line breaks have been added for clarity in reading; your
response string will not have line breaks); the phrase *<your access token string will be here>* will be replaced with your token access string, which is an 834 character alphanumeric string. Notice the expiration time in the return string.

.. code-block:: text

      {“message”:”Token created successfully.”,
       ”metadata”:{},
       ”result”:{“access_token”:{“access_token”:”<your access token string will be here>”,
          ”expires_at”:”2022-05-05T19:53:03.801252+00:00”,
          ”expires_in”:14400,”jti”:”8ef1d271-b923-49af-b2dd-ae05cc5da1ed”}},
       ”status”:”success”,
       ”version”:”dev”}

To work through the rest of the examples in this guide, you will need to add the token from the curl command to your environment using the variable name ``JWT``. The example below shows how I added it to zsh (a bash variant); the precise method may vary with your shell:

 .. code-block:: text

    $ export JWT=your_access_token_string


Register the S3 Storage with Tapis
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we have an access token, we are ready to create a Tapis ``system`` object. Remember that the Tapis APIs are a framework for accessing a wide variety of computational resources: for this example, we will register the S3 bucket we pre-created with Amazon's AWS S3 service (if this is unfamiliar to you, refer back to the `Getting Ready`_ section above). This step registers the S3 bucket with Tapis so it can access the bucket on your behalf. Note that the value of ``id`` needs to be unique within the Tapis tenant you are using; for this example we show the string *your_tapis_system_id*, but you'll need to choose your own globally (within the Tapis tenant you are using) unique id (possibly including your user name, for example, or some other unique id; for example, something like *username.tapis_test_v1*, but you'll need to select your own ). The values for ``host`` and ``bucketName`` are set based on the you used when you set up your own AWS S3 bucket, as discussed above.

To keep the cURL command (relatively) readable, you first need to create a file in your path with the details of your S3 storage and Tapis system formatted as a JSON object; in this example we use the filename *system_s3.json*, with the following contents:

.. code-block:: text

  {
    "id":"your_tapis_system_id",
    "description":"Tapis cURL Test Bucket",
    "host":"tapisbucket.s3.amazonaws.com",
    "systemType":"S3",
    "defaultAuthnMethod":"ACCESS_KEY",
    "bucketName":"tapisbucket",
    "canExec": False
  }

Then you'll execute the following cURL command, being sure to specify the name of the file you created if you chose a different name:

.. code-block:: text

  $ curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems -d @system_s3.json

The output of the command will show the URL to the system you just created in the Tapis tenant.

.. code-block:: text

  {
    "result": {
      "url": "http://tacc.tapis.io/v3/systems/your_tapis_system_id"
    },
    "status": "success",
    "message": "SYSAPI_CREATED New system created. jwtTenant: tacc jwtUser: your_tacc_username OboTenant: tacc OboUser: your_tacc_username System: your_tapis_system_id",
    "version": "1.2.3",
    "metadata": null
  }

Create an Access Credential
^^^^^^^^^^^^^^^^^^^^^^^^^^^

With our system created and linked to the S3 storage bucket, we need to create an access credential for Tapis to access our bucket on our behalf. Note that in this example we have created an access key and secret for the IAM user in our AWS instance; when substituting your own access key and secret into the code below, remember to preserve the single quotation marks enclosing these pieces of data.

Again, to keep the cURL command (relatively) readable, you first need to create a file in your path with the details of your S3 access key formatted as a JSON object; in this example we use the filename cred_tmp.json, with the following contents:

.. code-block:: text

  {
    "accessKey":"IAM user access key that you created in the AWS interface",
    "accessSecret":"access secret from the AWS interface for the key you created"
  }

Then you'll execute the following cURL command, being sure to specify the name of the file you created if you chose a different name:

.. code-block:: text

  $curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/systems/credential/your_tapis_system_id/user/your_tacc_username -d @cred_tmp.json

The output of the command will show will look similar to that below.

.. code-block:: text

  {
    "result": null,
    "status": "success",
    "message": "SYSAPI_CRED_UPDATED Credential updated. jwtTenant: tacc jwtUser: your_tacc_username OboTenant: tacc OboUser: your_tacc_username System: your_tapis_system_id User: your_tacc_username",
    "version": "1.2.3",
    "metadata": null
  }


Access the files in our S3 Bucket
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We are now able to list files in our bucket using the Files API. If you look closely at the URL you'll see that we are using the *files* access point -- this URL returns a listing of the files in your bucket along with some metadata. Recall that for our example the bucket has a single image in it.

.. code-block:: text

  curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/your_tapis_system_id/

The output of the command will show will look similar to that below, where the path and file name will reflect how you set up your own S3 bucket and the file(s) you put in it. We added line breaks to the output below for readability.

.. code-block:: text

  {
    "status":"success",
    "message":"ok",
    "result":
    [
      {
        "mimeType":"image/jpg",
        "type":"file",
        "owner":null,
        "group":null,
        "nativePermissions":null,
        "url":"tapis://your_tapis_system_id/test_image.jpg",
        "lastModified":"2022-05-20T19:24:24Z",
        "name":"test_image.jpg",
        "path":"/test_image.jpg",
        "size":87060
      }
    ],
    "version":"1.2.2","metadata":{}
  }


Sentiment-Analysis Application Tutorial
--------------------------------------------

For those of you that want to dive straight into Tapis and begin to explore it's possibilites, this is our tutorial. 
In this tutorial you will create a system, sentiment-analysis application, and run a job with it. For the sake of brevity and speed, we will complete this tutorial utilizing the Python SDK, Tapipy.

Pre-requisites: Active TACC account, Tapipy installed, Access to Stampede3, Frontera, or non-MFA system.                         

Create A Tapis Token
^^^^^^^^^^^^^^^^^^^^^

.. include:: /includes/tapipy-init.rst

Next you will need to gather your access token. 

.. code-block:: python

    t.access_token

The output should look similar to the following; it describes the access token that was just created.

.. code-block:: text

    access_token: *very long string of alphanumeric characters*
    claims: {'jti': '007fa9e6-f044-4817-a812-12292b2bdbe3', 'iss': 'https://tacc.tapis.io/v3/tokens', 'sub': 'your_tacc_username', 'tapis/tenant_id': 'tacc', 'tapis/token_type': 'access', 'tapis/delegation': False, 'tapis/delegation_sub': None, 'tapis/username': 'your_tacc_username', 'tapis/account_type': 'user', 'exp': 1657686889, 'tapis/client_id': None, 'tapis/grant_type': 'password'}
    expires_at: 2022-07-13 04:34:49+00:00
    expires_in: <function Tapis.add_claims_to_token.<locals>._expires_in at 0x10a070280>
    jti: 007fa9e6-f044-4817-a812-12292b2bdbe3
    original_ttl: 14400

Where you will have your own access token and the placeholder *your_tacc_username* will be replaced with the username you used.

Create a system
^^^^^^^^^^^^^^^^^^^^^

Next you will need to create a system. Your system must be hosted on a machine that you can SSH to. There are a variety of authentication methods such as PASSWORD, PKI_KEYS (SSH Keys: Private, Public pair), ACCESS_KEYS (S3), and TOKENS (GLOBUS).
If you are using PKI_KEYS please be aware that they will only work if MFA is NOT enabled on that system. Also, you must place the public key on that system. The Public and Private key on your system and the Public key on the host system must be formatted for one line. 

.. code-block:: text

    system_def = {
    “id": “<YOUR_SYSTEM_ID>”,
    "description": "test system",
    "systemType": "LINUX",
    "host”:”<HOST>,
    "defaultAuthnMethod": "PASSWORD",
    "rootDir": "/",
    "canExec": True,
    "jobRuntimes": [ { "runtimeType": "SINGULARITY" } ],
    "jobWorkingDir": "workdir",
  }

  t.systems.createSystem(**system_def)

When defining a HOST, it's important to remember that it should be defined by the URL without the "https://"

This will return: 

.. code-block:: text

  url: http://tacc.tapis.io/v3/systems/<YOUR_SYSTEM_ID>


Create An Application
^^^^^^^^^^^^^^^^^^^^^

Now that you have a system to run your jobs, you must create an application. Here is an example of an application definition:

.. code-block:: text

    app_def = {
      "id": <app_id>,
      "version": "0.2",
      "description": "Application utilizing the sentiment analysis model from Hugging Face.",
      "jobType": "FORK",
      "runtime": "DOCKER",
      "containerImage": "tapis/sentiment-analysis:1.0.0",
      "jobAttributes": {
          "parameterSet": {
              "archiveFilter": {
                  "includeLaunchFiles": False
              }
          },
          "memoryMB": 1,
          "nodeCount": 1,
          "coresPerNode": 1,
          "maxMinutes": 10
      }
  }

With a system now created, we need to register this application to make it accessible on this tenant. 

.. code-block:: text

    t.apps.createAppVersion(**app_def)

Application Arguments
^^^^^^^^^^^^^^^^^^^^^

With appArgs parameter you can specify one or more command line arguments for the user application.
Arguments specified in the application definition are appended to those in the submission request. Metadata can be attached to any argument:



.. code-block:: text

  # Modify Job submission arguments 
    pa = {
        "parameterSet": {
        "appArgs": [
                {"arg": "--sentences"},
                {"arg": "\"This is great\" \"This is not fun\""}
            ]
        }}

Submitting a job
^^^^^^^^^^^^^^^^^^^^^

Running a job only requires 3 items: a Job name (name), an app_id, and the app_id version. If you have not specified the Execution System in your application, you will need to specify it when submitting a job. 

A simple submission would look like this:

.. code-block:: text

  job_response = t.jobs.submitJob(
      name='sentiment analysis', 
      appId=app_id,appVersion='0.2',
      execSystemId=system_def, 
      **pa #reintroducing modified job submission arguments
    )

All of the Job Submission Parameters can be found here `Job Submission Parameters <https://tapis.readthedocs.io/en/latest/technical/jobs.html#the-job-submission-request>`_.

Everytime a job is submitted, a unique job_id (uuid) is generated. We will use this job_id with tapipy to get the job status and download the job output.

.. code-block:: text

    # Get job uuid from the job submission response
  print("****************************************************")
  job_uuid = job_response.uuid
  print("Job UUID: " + job_uuid)
  print("****************************************************")

Jobs List
^^^^^^^^^^^^^^^^^^^^^

When you do a jobs list now, you can see your jobUuid.

.. code-block:: text

  t.jobs.getJobList()

Jobs Output
^^^^^^^^^^^^^^^^^^^^^

To download the output of a job you need to give it the jobUuid and output path. You can download a directory in the jobs’ outputPath in zip format. The outputPath is relative to archive system specified.

.. code-block:: text

    # Download output of the job
  print("Job Output file:")

  print("****************************************************")
  jobs_output = t.jobs.getJobOutputDownload(jobUuid=job_uuid,outputPath='stdout')
  print(jobs_output)
  print("****************************************************")






Next Steps
^^^^^^^^^^^^^^^^^^^^^


This concludes the Sentiment-Analysis tutorial. This tutorial was presented at `PEARC'24 <https://tapis-project.github.io/pearc24-tapis-tutorial/>`_. Please feel free to explore and read more of the Tapis documentation.
If you would like to see more recent Tapis tutorials, please see `Tapis Tutorials <https://tapis-project.github.io/tutorials/>`_.