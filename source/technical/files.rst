.. _files:

=====
Files
=====

The files service is the central point of interaction for all file operations in the Tapis ecosystem. Users can
perform file listing, uploading, and various operations such as move, copy, mkdir and delete.
The service also supports transferring files from one Tapis system to another.

Currently the files service includes support for systems of type LINUX, S3 and IRODS. Other system types such as
GLOBUS will be included in future releases.

Note that supported functionality varies by system type.

----------
Overview
----------
.. _Systems: https://tapis.readthedocs.io/en/latest/technical/systems.html

All file operations act upon Tapis *System* resources. For more information on the Systems service please see Systems_

^^^^^^^^^^^^^^^^^^^^^^^
Basic File Operations
^^^^^^^^^^^^^^^^^^^^^^^

++++++++++++++++++
File Listings
++++++++++++++++++

Tapis supports listing files or objects on a Tapis system. The type for items listed will depend on system type.
For example for LINUX they will be posix files and for S3 they will be storage objects. See section below for
additional considerations for S3 type systems. For example, for S3 systems the recurse flag is ignored and all objects
with keys matching the path as a prefix are always included.

To list the files in the root directory of a system:

Using the official Tapis Python SDK:

.. code-block:: python

    t.files.listing("/")

Or using curl:

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/my-system/

And to list a sub-directory in the system, just add the path to the request:

Using CURL

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/aturing-storage/subDir1/subDir2/subDir3/

Query Parameters

:limit: integer - Max number of results to return, default of 1000
:offset: integer - Skip the first N listings

The JSON response of the API will look something like this:

.. code-block:: json

  {
    "status": "success",
    "message": "ok",
    "result": [
        {
            "mimeType": "text/plain",
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "drwxrwxr-x",
            "uri": "tapis://dev/aturing-storage/file1.txt",
            "lastModified": "2021-04-29T16:55:57Z",
            "name": "file1.txt",
            "path": "file1.txt",
            "size": 313
        },
        {
            "mimeType": "text/plain",
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "-rw-rw-r--",
            "uri": "tapis://dev/aturing-storage/file2.txt",
            "lastModified": "2020-12-17T22:46:29Z",
            "name": "file2.txt",
            "path": "file2.txt",
            "size": 21
        }
    ],
    "version": "1.1-84a31617",
    "metadata": {}
  }

File Listings and S3 Support
+++++++++++++++++++++++++++++

File listings on S3 type systems have some special considerations. Objects in an S3 bucket do not have a hierarchical
structure. There are no directories. Everything is an object associated with a key.

One thing to note is that, as mentioned above, for S3 the recurse flag is ignored and all objects with keys matching
the path as a prefix are always included.

Another item to note is how posix style paths and S3 keys are related in Tapis. Tapis uses the concept of a posix style
absolute path where the path always starts with a "/" character. These paths are mapped to S3 keys by removing the
initial "/" character. Put another way, the final fully resolved key to an object is absolute path with the
initial "/" stripped off.

Tapis does not support S3 keys beginning with a "/". Such objects may be shown in a listing but it will not be
possible through Tapis to reference the object directly using the key.

Note that for S3 this means a path of "/" or the empty string indicates all objects in the bucket with a prefix matching
*rootDir*, with any preceding "/" stripped off of *rootDir*. This is especially important to keep in mind when using
the delete operation to remove objects matching a path.


Move/Copy
++++++++++++++++++

To move or copy a file or directory using the files service, make a PUT request using the path to the current location
of the file or folder.

For example, to copy a file located at `/file1.txt` to `/subdir/file1.txt`

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X PUT -d @body.json "https://tacc.tapis.io/v3/files/ops/aturing-storage/file1.txt"

with a JSON body of

.. code-block:: json

    {
        "operation": "COPY",
        "newPath": "/subdir/file1.txt"
    }


Delete
++++++++++++++++++

To delete a file or folder, issue a DELETE request for the path to be removed.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X DELETE "https://tacc.tapis.io/v3/files/ops/aturing-storage/file1.txt"

The request above would delete :code:`file1.txt`

For an S3 system, the path will represent either a single object or all objects in the bucket with a prefix matching
the system *rootDir* if the path is "/" or the empty string.

**WARNING** For an S3 system if the path is "/" or the empty string then all objects in the bucket with a key matching
the prefix *rootDir* will be deleted. So if the *rootDir* is "/" or the empty string then all objects in the
bucket will be removed.


File Uploads
++++++++++++++++++

To upload a file use a POST request. The file will be placed at the location specified in the `{path}` parameter
in the request. Not all system types support this operation.
For example, given the system `my-system`, to insert a file in a folder located at `/folderA/folderB/folderC`:

Using the official Tapis Python SDK:

.. code-block:: python

    with open("experiment-results.hd5", "r") as f:
        t.files.upload("my-system", "/folderA/folderB/folderC/someFile.txt", f)



.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X POST -F "file=@someFile.txt" https://tacc.tapis.io/v3/files/ops/my-system/folderA/folderB/folderC/someFile.txt

Any folders that do not exist in the specified path will automatically be created.

Note that for an S3 system an object will be created with a key of *rootDir*/{path} without a preceding "/" character.


Create a new directory
++++++++++++++++++++++++

To create a directory, use POST and provide the path to the new directory in the request body. Not all system types
support this operation.

.. code-block:: shell

    $ curl -H "X-Tapis-Token: $JWT" -X POST -d @body.json -X POST https://tacc.tapis.io/v3/files/ops/my-system

with a JSON body of

.. code-block:: json

    {
        "path": "/path/to/new/directory/"
    }


+++++++++++++++++++++++++++++++
File Contents - Serving files
+++++++++++++++++++++++++++++++

To return the actual contents (raw bytes) of a file (Only files can be served, not folders):

.. code-block:: shell

    $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/content/my-system/image.jpg > image.jpg

Query Parameters

:startByte: integer - Start at byte N of the file
:count: integer - Return this number of bytes after startByte
:zip: boolean - Zip the contents of a folder

Header Parameters

:more: integer - Return 1 KB chunks of UTF-8 encoded text from a file starting after page *more*. This call can be used to page through a text based file. Note that if the contents of the file are not textual (such as an image file or other binary format), the output will be bizarre.


^^^^^^^^^^^^^^^^^^^^^^^
File Permissions
^^^^^^^^^^^^^^^^^^^^^^^

Permissions model - Only the system *owner* may grant or revoke Tapis permissions for paths on a system.
The Tapis permissions are also *not* duplicated or otherwise implemented in the underlying storage system.


++++++++++++++++++
Grant permissions
++++++++++++++++++

Lets say our user :code:`aturing` has a system with ID :code:`aturing-storage`. Alan wishes to allow his collaborator
:code:`aeinstein` to view the results of an experiment located at :code:`/experiment1`


.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -d @body.json -X POST https://tacc.tapis.io/v3/files/perms/aturing-storage/experiment1/

with a JSON body with the following shape:

.. code-block:: json

    {
        "username": "aeinstein",
        "permission": "READ"
    }

Other users can also be granted permission to write to the system by granting the :code:`MODIFY` permission.
The JSON body would then be:

.. code-block:: json

    {
        "username": "aeinstein",
        "permission": "MODIFY"
    }


++++++++++++++++++
Revoke permissions
++++++++++++++++++

Our user :code:`aturing` now wishes to revoke his former collaborators access to the folder he shared above. He can
issue a DELETE request on the path that was shared and specify the username in order to revoke access:


.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X DELETE https://tacc.tapis.io/v3/files/perms/aturing-storage/experiment1?username=aeinstein


^^^^^^^^^^^^^^^^^^^^^^^
Transfers
^^^^^^^^^^^^^^^^^^^^^^^

File transfers are used to move data between Tapis systems, and also for bulk data operations that are too
large for the REST api to perform. Transfers occur *asynchronously*, and are parallelized where possible to increase
performance. As such, the order in which the files are transferred to the target system is somewhat arbitrary.

Notice in the above examples that the Files services works identically regardless of whether
the source is a file or directory. If the source is a file, it will copy the file.
If the source is a directory, it will recursively process the contents until
everything has been copied.

When a transfer is initiated, a "Bill of materials" is created that creates a record of all the files on the target
system that are to be transferred. Unless otherwise specified, all files in the bill of materials must successfully transfer
for the overall transfer to be completed successfully. A transfer task has a STATUS which is updated as the transfer
progresses. The states possible for a transfer are:

ACCEPTED
  The initial request has been processed and saved.
IN_PROGRESS
  The bill of materials has been created and transfers are either in flight or waiting to begin.
FAILED
  The transfer failed.
COMPLETED
  The transfer completed successfully, all files have been transferred to the target system.

Unauthenticated HTTP endpoints are also possible to use as a source for transfers.
This method can be utilized to include outputs from other APIs into Tapis jobs.


++++++++++++++++++
Creating Transfers
++++++++++++++++++

Lets say our user :code:`aturing` needs to transfer data between two systems that are registered in tapis. The source system
has an id of :code:`aturing-storage` with the results of an experiment located in directory :code:`/experiments/experiment-1/`
that should be transferred to a system with id :code:`aturing-compute`

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X POST -d @body.json https://tacc.tapis.io/v3/files/tranfers

.. code-block:: json

    {
        "tag": "An optional identifier",
        "elements": [
            {
                "sourceUri": "tapis://aturing-storage/experiments/experiment-1/",
                "destinationUri": "tapis://aturing-compute/"
            }
        ]
    }

The request above will initiate a transfer that copies all files and folders in the :code:`experiment-1` folder on the source
system to the root directory of the destination system :code:`aturing-compute`

HTTP Inputs
++++++++++++++++++++++++++

Unauthenticated HTTP endpoints can also be used as a source to a file transfer. This can be useful when, for instance, the inputs for
a job to run are from a separate web service, or perhaps stored in an S3 bucket on AWS.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X POST -d @body.json https://tacc.tapis.io/v3/files/tranfers

.. code-block:: json

    {
        "tag": "An optional identifier",
        "elements": [
            {
                "sourceUri": "https://some-web-application.io/calculations/12345/",
                "destinationUri": "tapis://aturing-compute/inputs.csv"
            }
        ]
    }

The request above will place the output of the source URI into a file called  :code:`inputs.csv` in the
:code:`aturing-compute` system.


++++++++++++++++++++++++++
Get transfer information
++++++++++++++++++++++++++

To retrieve information about a transfer such as its status, bytes transferred, etc
just make a GET request to the transfers API with the UUID of the transfer.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT"  https://tacc.tapis.io/v3/files/tranfers/{UUID}


The JSON response should look something like :

.. code-block:: json

    {
        "status": "success",
        "message": "ok",
        "result": {
            "id": 1,
            "username": "aturing",
            "tenantId": "tacc",
            "tag": "some tag",
            "uuid": "b2dcf71a-bb7b-409a-8c01-1bbs97e749fb",
            "status": "COMPLETED",
            "parentTasks": [
                {
                    "id": 17,
                    "tenantId": "tacc",
                    "username": "aturing",
                    "sourceURI": "tapis://sourceSystem/file1.txt",
                    "destinationURI": "tapis://destSystem/folderA/",
                    "totalBytes": 100000,
                    "bytesTransferred": 100000,
                    "taskId": 1,
                    "children": null,
                    "errorMessage": null,
                    "uuid": "8fdccda6-a504-4ddf-9464-7b22sa66bcc4",
                    "status": "COMPLETED",
                    "created": "2021-04-22T14:21:58.933851Z",
                    "startTime": "2021-04-22T14:21:59.862356Z",
                    "endTime": "2021-04-22T14:22:09.389847Z"
                }
            ],
            "estimatedTotalBytes": 100000,
            "totalBytesTransferred": 100000,
            "totalTransfers": 1,
            "completeTransfers": 1,
            "errorMessage": null,
            "created": "2021-04-22T14:21:58.933851Z",
            "startTime": "2021-04-22T14:21:59.838928Z",
            "endTime": "2021-04-22T14:22:09.376740Z"
        },
        "version": "1.1-094fd38d",
        "metadata": {}
    }
