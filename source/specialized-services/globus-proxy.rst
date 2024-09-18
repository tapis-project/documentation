############
Tapis Globus-Proxy
############

----------
Overview
----------
The Globus-Proxy service allows Tapis to interact with the Globus API in an easy way by abstracting many of the most-used endpoints into a python API, translating Globus messages into Tapis-readable formats, and handling Globus-specific errors that Tapis would otherwise be unable to. 

Globus-Proxy is intented to be an internal Tapis API, and will likely never be used by a user directly except in very specific use-cases. The guide below is for those looking to interface directly with the Globus-Proxy service, or for Tapis developers looking to integrate Globus actions into their service.

Requirements
^^^^^^^^^^^^
In order to use Globus through Tapis, there are a number of requirements that must be met:

.. _create_system: https://tapis.readthedocs.io/en/latest/technical/systems.html#creating-a-system

.. _register_globus_credentials: https://tapis.readthedocs.io/en/latest/technical/systems.html#registering-credentials-for-a-globus-system

.. _get_tapis_jwt: https://tapis.readthedocs.io/en/latest/technical/authentication.html#id2

.. _globus_developers: https://app.globus.org/settings/developers

.. _globus_developers_create: https://app.globus.org/settings/developers/registration/advanced/select-project

.. _tapisv3gpdocs: https://tapis-project.github.io/live-docs/?service=GlobusProxy 

.. _esnetcollections: https://fasterdata.es.net/performance-testing/DTNs/


* `A Tapis system of type Globus <create_system_>`_

* `A valid Tapis JWT <get_tapis_jwt_>`_

* A valid Globus access token and refresh token, `registered to the Tapis system <register_globus_credentials_>`_

* Globus collection ID for the source (And the collection ID of the destination if attemtping to do a transfer). This is the UUID in the collection's overview page.

* A Globus app client id. This is the Client UUID on the App information page in `the Globus developers portal <globus_developers_>`_

Quick Start
^^^^^^^^^^^^
All of TACC's HPC systems run a Globus v5 server. Below are the collection UUIDs for each HPC system:

==========    =====================================   ======================================
System        Collection Name                         Collection UUID
==========    =====================================   ======================================
Corral3       TACC Corral3 GCS v5.4 Collections       14f31f68-1670-4559-9cb1-600c1f9b13d8
Frontera      TACC Frontera GCS v5.4 Filesystems      bec0eec6-d29d-4447-9813-cd9751c199e9
Lonestar 6    TACC Lonestar6 GCS v5.4 Filesystems     24bc4499-6a3a-47a4-b6fd-a642532fd949
Ranch         TACC Ranch GCS v5.4 Tape Archival       e6d7586e-c815-4f11-9a90-37d1747989c1
Stampede 3    TACC Stampede3 GCS v5.4 Filesystems     TACC Stampede3 GCS v5.4 Filesystems
==========    =====================================   ======================================
.. list-table: TACC HPC Globus Servers
    : widths: 25 25 25
    : header-rows: 1

    * - System
      - Collection Name
      - Collection UUID
    * - Corral3
      - TACC Corral3 GCS v5.4 Collections 
      - 14f31f68-1670-4559-9cb1-600c1f9b13d8
    * - Frontera
      - TACC Frontera GCS v5.4 Filesystems 
      - bec0eec6-d29d-4447-9813-cd9751c199e9
    * - Lonestar 6
      - TACC Lonestar6 GCS v5.4 Filesystems
      - 24bc4499-6a3a-47a4-b6fd-a642532fd949
    * - Ranch
      - TACC Ranch GCS v5.4 Tape Archival 
      - e6d7586e-c815-4f11-9a90-37d1747989c1
    * - Stampede 3
      - TACC Stampede3 GCS v5.4 Filesystems
      -   
      
Authorization
~~~~~~~~~~~~~~

Getting a Client
-----------------
In order to make any requests through the Globus-Proxy API, you must have a valid, authorized client within Globus. 

If you don't already have one, create it through the `Globus developers portal <globus_developers_create_>`_ Once created, take note of the client UUID

Getting a Token pair
---------------------
Now that you have a client, you must authorize it to use the endpoint by obtaining an access token and refresh token. This is done through the Globus-Proxy API, using the below command:

.. code-block:: shell

  curl https://tacc.tapis.io/v3/globus-proxy/auth/url/<< client_id >>/<< endpoint_id >> 

This will return both a url and a session_id, like so:

.. code-block:: json

  {
    "message": "Please go to the URL and login.",
    "metadata": {},
    "result": {
      "session_id": "4ke-4...bqsMI", // this is the session id used in the following call
      "url": "https://auth.globus.org/v2/oauth2/authorize?..."
    },
    "status": "success",
    "version": "dev"
  }


Follow the url and login using your Globus credentials. Once complete, this will show you an authorization code.

Take both the authorization code and session_id, then send them both through the Globus-Proxy API using the below call:

.. code-block:: shell

  curl https://tacc.tapis.io/v3/globus-proxy/auth/url/<<client_id>>/<<session_id>>/<<auth_code>> 

which will return an access_token and refresh_token, like so:

.. code-block:: json

  {
      "message": "successfully authorized globus client",
      "metadata": {},
      "result": {
          "access_token": "AgJdY...nvpvM",
          "refresh_token": "AgpO...2ovP"
      },
      "status": "success",
      "version": "dev"
  }


Listing Files in a Globus endpoint
-----------------------------------
The tokens received from the last call can now be used to perform operations using the Globus-Proxy service. for example, listing the files in the Globus collection:

.. code-block:: shell

  curl  "https://tacc.tapis.io/v3/globus-proxy/ops/<<client_id>>/<<endpoint_id>>/<<path>>?access_token=<<access_token>>&refresh_token=<<refresh_token>>"

Which will return something like this:

.. code-block:: json

  {
    "message": "Successfully listed files",
    "metadata": {
      "access_token": "AgJdY...nvpvM"
    },
    "result": {
      "DATA": [
        {
          "DATA_TYPE": "file",
          "group": "<< group_owner >>",
          "last_modified": "<< timestamp >>",
          "link_group": null,
          "link_last_modified": null,
          "link_size": null,
          "link_target": "<< file_path >>",
          "link_user": null,
          "name": "<< file_name >>",
          "permissions": "<< file_permissions >>",
          "size": << file_size >>,
          "type": "<< file_type >>",
          "user": "<< file_owner >>"
        },
        ...
      ],
      "DATA_TYPE": "file_list",
      "absolute_path": requested_path,
      "endpoint": "endpoint_id",
      "length": number_of_files,
      "path": requested_path,
      "rename_supported": true,
      "symlink_supported": false,
      "total": number_of_files
    },
    "status": "success",
    "version": "dev"
  }


Gotchas:

* It's common for multiple query parameters to not be parsed correctly using curl if the url is not wrapped in quotes. If you get an error sending ``curl https...?param=thing&param2=other-thing`` try ``curl "https://...?param=thing&param2=other-thing"`` instead

Initiating a File Transfer 
-----------------------------
The main reason to use Globus is to quickly transfer files between Globus collections. Globus-Proxy offers an API endpoint to do just that. We can use the tokens obtained above to initiate a file transfer.

First, build the post data that we will send with the following format. For this example, the source will be a preconfigured collection within Globus used for testing. More information on these test collections is available on `the ESNet website <esnetcollections_>`_

.. code-block:: json

  {

      "source_endpoint": "78f14af7-a8a3-488f-b42d-8c6fa4dfc2ac",
      "destination_endpoint": "<< destination_endpoint_id >>",
      "transfer_items": 

  [

          {
              "source_path": "/1M.dat",
              "destination_path": "<< destination_path >>",
              "recursive": true
          }
      ]

  }

For ease of use, this will be referred to as $data in the transfer call


.. code-block:: shell

  curl -X POST -d $data "https://tacc.tapis.io/v3/globus-proxy/transfers/<< client_id >>?access_token=<< access_token >>&refresh_token=<< refresh_token >>"

Which will return a transfer task id:

.. code-block:: json

  {
      "message": "Success",
      "metadata": {},
      "result": {
          "DATA_TYPE": "transfer_result",
          "code": "Accepted",
          "message": "The transfer has been accepted and a task has been created and queued for execution",
          "request_id": "<< request_id >>",
          "resource": "/transfer",
          "submission_id": "<< submission_id >>",
          "task_id": "<< task_id >>",
          "task_link": {
              "DATA_TYPE": "link",
              "href": "task/<< task_id >>?format=json",
              "rel": "related",
              "resource": "task",
              "title": "related task"
          }
      },
      "status": "success",
      "version": "dev"
  }


We can check the status of the transfer using the `get` endpoint for transfers:

.. code-block:: shell

  curl "https://tacc.tapis.io/v3/globus-proxy/transfers/<<client_id>>/<<task_id>>?access_token=<<access_token>>&refresh_token=<<refresh_token>>"

Returning something like this:

.. code-block:: json

  {
    "message": "successfully retrieved transfer task",
    "metadata": {},
    "result": {
      "DATA_TYPE": "task",
      "bytes_checksummed": 0,
      "bytes_transferred": 1000000,
      "canceled_by_admin": null,
      "canceled_by_admin_message": null,
      "command": "API 0.10",
      "completion_time": "<<timestamp>>",
      "deadline": "<<timestamp>>",
      "delete_destination_extra": false,
      "destination_base_path": null,
      "destination_endpoint": "<<internal_globus_endpoint_id>>",
      "destination_endpoint_display_name": "TACC Frontera GCS v5.4 Filesystems",
      "destination_endpoint_id": "<<endpoint_id>>",
      "destination_local_user": null,
      "destination_local_user_status": null,
      "directories": 0,
      "effective_bytes_per_second": 200490,
      "encrypt_data": false,
      "fail_on_quota_errors": false,
      "fatal_error": null,
      "faults": 0,
      "files": 1,
      "files_skipped": 0,
      "files_transferred": 1,
      "filter_rules": null,
      "history_deleted": false,
      "is_ok": null,
      "is_paused": false,
      "label": "Tapisv3",
      "nice_status": null,
      "nice_status_details": null,
      "nice_status_expires_in": null,
      "nice_status_short_description": null,
      "owner_id": "<<owner_id>>",
      "preserve_timestamp": false,
      "recursive_symlinks": "ignore",
      "request_time": "<<timestamp>>",
      "skip_source_errors": false,
      "source_base_path": null,
      "source_endpoint": "u_fh4xzyc6hvaw5exadc4d6rjiyq#fdb612cc-be0a-11ed-8cec-f9fa098153fc",
      "source_endpoint_display_name": "ESnet Houston DTN (Anonymous read-only testing)",
      "source_endpoint_id": "78f14af7-a8a3-488f-b42d-8c6fa4dfc2ac",
      "source_local_user": null,
      "source_local_user_status": null,
      "status": "SUCCEEDED",
      "subtasks_canceled": 0,
      "subtasks_expired": 0,
      "subtasks_failed": 0,
      "subtasks_pending": 0,
      "subtasks_retrying": 0,
      "subtasks_skipped_errors": 0,
      "subtasks_succeeded": 2,
      "subtasks_total": 2,
      "symlinks": 0,
      "sync_level": 1,
      "task_id": "<<task_id>>",
      "type": "TRANSFER",
      "username": "<<username>>",
      "verify_checksum": false
    },
    "status": "success",
    "version": "dev"
  }

Alternatively, you can view the transfer status on the Globus portal or simply wait for the email from Globus that our transfer completed or failed.

`see the Tapisv3 Globus-Proxy API spec for the full list of operations that can be performed <tapisv3gpdocs_>`_



