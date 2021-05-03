.. _files:

=====
Files
=====

The files service is the central point of interaction for doing all file operations in the Tapis ecosystem. Users can preform
file listing, uploading, operations such as move/copy/delete and also transfer files between systems. All
Tapis files APIs accept JSON as inputs.

----------
Overview
----------

All file operations act upon *Storage* systems. If you are unfamiliar with the Systems service, please refer to the
:ref:`systems` section.


-----------------
Getting Started
-----------------

Let's assume that you have a system defined in your tenant with an ID of **my-system**

^^^^^^^^^^^^^^^^^^^^^^^
Basic File Operations
^^^^^^^^^^^^^^^^^^^^^^^



++++++++++++++++++
File Listings
++++++++++++++++++

To list the files in the root directory of that system:

Using the official Tapis Python SDK:

.. code-block:: python

 t.files.listing("/")

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/my-system/

And to list a sub-directory in the system, just add the path to the request:

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/my-system/subDir1/subDir2/subDir3/

Query Parameters

:limit: integer - Max number of results to return, default of 1000
:offset: integer - Skip the first N listings


++++++++++++++++++
File Uploads
++++++++++++++++++

To upload a new file to the files service, just POST a file to the service. The file will be placed at
the location specified in the `{path}` parameter in the request. For example, given the system `my-system`, and you want to
insert the file in a folder located at `/folderA/folderB/folderC`:

Using the official Tapis Python SDK:

.. code-block:: python

    with open("experiment-results.hd5", "r") as f:
        t.files.upload("my-system", "/path/to/file", f)


Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" -F "file=@someFile.txt" https://tacc.tapis.io/v3/files/content/my-system/folderA/folderB/folderC/someFile.txt

Any folders that do not exist in the specified path will automatically be created.

++++++++++++++++++++++++
Create a new directory
++++++++++++++++++++++++

For S3 storage systems, an empty key is created ending in `/`

Using CURL::

    $ curl -H "X-Tapis-Token: $JWT" -X POST https://tacc.tapis.io/v3/files/content/my-system/

with a JSON body of

::

    {
        "path": "/path/to/new/directory/"
    }


+++++++++++++++++++++++++++++++
File Contents - Serving files
+++++++++++++++++++++++++++++++

To return the actual contents (raw bytes) of a file (Only files can be served, not folders):

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/content/my-system/image.jpg > image.jpg

Query Parameters

:startByte: integer - Start at byte N of the file
:count: integer - Return this number of bytes after startByte
:zip: boolean - Zip the contents of the folder

Header Parameters

:more: integer - Return 1 KB chunks of UTF-8 encoded text from a file starting after page *more*.  This call can be used to
page through a text based file. Note that if the contents of the file are not textual (such as an image file or other binary
format) the output will be bizarre.


^^^^^^^^^^^^^^^^^^^^^^^
File Permissions
^^^^^^^^^^^^^^^^^^^^^^^

Permissions model - Only the system *owner* may grant or revoke permissions on a storage system. The
Tapis permissions are also *not* duplicated or otherwise implemented in the underlying storage system.


++++++++++++++++++
Grant permissions
++++++++++++++++++

Lets say our user :code:`aturing` has a storage system with ID :code:`aturing-storage`. Alan wishes to allow his collaborator
:code:`aeinstein` to view the results of an experiment located at :code:`/experiment1`

.. code-block:: shell

    $ curl -H "X-Tapis-Token: $JWT" -X POST https://tacc.tapis.io/v3/files/perms/aturing-storage/experiment1/

with a JSON body with the following shape:

.. code-block:: json

    {
        "username": "aeinstein",
        "permission": "READ"
    }




^^^^^^^^^^^^^^^^^^^^^^^
Transfers
^^^^^^^^^^^^^^^^^^^^^^^

File transfers are used to move data between different storage systems, and also for bulk data operations that are too
large for the REST api to perform. Transfers occur *asynchronously*, and are parallelized where possible to increase
performance. As such, the order in which the files are transferred to the target system is somewhat arbitrary.

When a transfer is initiated, a "Bill of materials" is created that creates a record of all the files on the target
system that are to be transferred. Unless otherwise specified, all files in the bill of materials must successfully transfer
for the overall transfer to be completed successfully. A transfer task has a STATUS which is updated as the transfer
progresses. The states possible for a transfer are:

ACCEPTED - The initial request has been processed and saved.
IN_PROGRESS - The bill of materials has been created and transfers are either in flight or awaiting resources to begin
FAILED - The transfer failed. There are many reasons
COMPLETED - The transfer completed successfully, all files have been transferred to the target system

Unauthenticated HTTP endpoints are also possible to use as a source for transfers.




++++++++++++++++++
Create a transfer
++++++++++++++++++


.. code-block:: json

    {
        "tag": "An optional identifier",
        "elements": [
            {
                "sourceUri": "tapis://source-system/path/to/target/"
                "destinationUri": "tapis://dest-system/path/to/destination/"
            }
        ]
    }

