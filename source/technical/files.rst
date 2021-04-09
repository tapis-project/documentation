.. _files:

=====
Files
=====

The files service is the central point of interaction for doing all file operations in the Tapis ecosystem. Users can preform
file listing, uploading, operations such as move/copy/delete and also transfer files between systems.

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
File Listings
^^^^^^^^^^^^^^^^^^^^^^^
To list the files in the root directory of that system:

Using the official Tapis Python SDK:

.. code-block:: python

 t.files.listing(systemId="my-system", path="/")

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/my-system/

And to list a sub-directory in the system, just add the path to the request:


.. code-block:: python

 t.files.listing(systemId="my-system", path="/subDir1/subDir2/subDir3/")


Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/ops/my-system/subDir1/subDir2/subDir3/

Query Parameters

:limit: integer - Max number of results to return, default of 1000
:offset: integer - Skip the first N listings


^^^^^^^^^^^^^^^^^^^^^^^
File Uploads
^^^^^^^^^^^^^^^^^^^^^^^

To upload a new file to the files service, just POST a file to the service. The file will be placed at
the location specified in the `{path}` parameter in the request. For example, given the system `my-system`, and you want to
insert the file in a folder located at `/folderA/folderB/folderC`:

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" -F "file=@someFile.txt" https://tacc.tapis.io/v3/files/content/my-system/folderA/folderB/folderC/someFile.txt

Any folders that do not exist in the specified path will automatically be created.

^^^^^^^^^^^^^^^^^^^^^^^
File Contents - Serving files
^^^^^^^^^^^^^^^^^^^^^^^

To return the actual contents (raw bytes) of a file (Only files can be served, not folders):

Using CURL::

 $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/content/my-system/image.jpg > image.jpg

Query Parameters

:startByte: integer - Start at byte N of the file
:count: integer - Return this number of bytes after startByte

----------
Permissions
----------
The permissions API allows owners of systems to allow other Tapis users to have varying levels of access to the underlying file system resources. Owners can grant either `READ` or `MODIFY`
permissions to a single resource such as a file, or a path to a directory. Any permissions granted to a user on a folder also allow them access to all subpaths.
Only the **owners** of systems are allowed to create, delete or modify permissions on a storage system.

Here are some common scenarios:

    A "shared" storage system in which the data is owned by a single account, and each user gets a directory of their own

    Community data

    Sharing with a single colleague

        Also show how to get the contents after sharing with colleague



----------
Transfers
----------

The Transfers API allows Tapis users to initiated asynchronous tasks to transfer data between systems.





^^^^^^^^^^^^^^^^^^^^^^^
Creating a transfer
^^^^^^^^^^^^^^^^^^^^^^^

^^^^^^^^^^^^^^^^^^^^^^^
Get Transfer info
^^^^^^^^^^^^^^^^^^^^^^^

^^^^^^^^^^^^^^^^^^^^^^^
Get Transfer details
^^^^^^^^^^^^^^^^^^^^^^^

^^^^^^^^^^^^^^^^^^^^^^^
Cancel / Stop a transfer
^^^^^^^^^^^^^^^^^^^^^^^

^^^^^^^^^^^^^^^^^^^^^^^
File Uploads
^^^^^^^^^^^^^^^^^^^^^^^

