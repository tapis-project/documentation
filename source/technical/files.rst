.. _files:

=====
Files
=====

The files service is the central point of interaction for all file operations in the Tapis ecosystem.

----------
Overview
----------

Through the Files service users can perform file listing, uploading, and various operations such as move, copy, mkdir
and delete. The service also supports transferring files from one Tapis system to another.

Currently, the files service includes support for systems of type LINUX, S3, IRODS and GLOBUS.

Note that supported functionality varies by system type.

.. _Systems: https://tapis.readthedocs.io/en/latest/technical/systems.html

All file operations act upon Tapis *System* resources. [#]_
For more information on the Systems service please see Systems_

---------------------
Basic File Operations
---------------------

Listing
~~~~~~~

Tapis supports listing files or objects on a Tapis system. The type for items listed will depend on system type.
For example, for LINUX they will be posix files and for S3 they will be storage objects. See the next section below for
additional considerations for S3 type systems. On S3 systems, for example, the recurse flag is ignored and all objects
with keys matching the path as a prefix are always included.

For system types that support directory hierarchies the maximum recursion depth is 20.

To list the files in the effective *rootDir* directory of a Tapis system:

Using the official Tapis Python SDK:

.. code-block:: python

    t.files.listFiles(systemId="my-tapis-system", path="/")

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
          "url": "tapis://dev/aturing-storage/file1.txt",
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
          "url": "tapis://dev/aturing-storage/file2.txt",
          "lastModified": "2020-12-17T22:46:29Z",
          "name": "file2.txt",
          "path": "file2.txt",
          "size": 21
        }
    ],
    "version": "1.1-84a31617",
    "metadata": {}
  }

Listings and S3 Support
^^^^^^^^^^^^^^^^^^^^^^^

File listings on S3 type systems have some special considerations. Objects in an S3 bucket do not have a hierarchical
structure. There are no directories. Everything is an object associated with a key.

One thing to note is that, as mentioned above, for S3 the recurse flag is ignored and all objects with keys matching
the path as a prefix are always included.

Note that for S3 this means that when the path is an empty string all objects in the bucket with a prefix matching
*rootDir* will be included. This is especially important to keep in mind when using the delete operation to remove
objects matching a path.

The attribute *rootDir* is optional for S3 type systems. When defined it will be prepended to all paths and the
resulting path will become the key.

.. note::
  When *rootDir* is defined for an S3 system it typically should not begin with ``/``.
  For S3 keys are typically created and manipulated using URLs and do not have a leading ``/``.

Handling of symbolic links on Linux systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If listing contains a symbolic link, it will show type of symbolic link:

.. code-block:: json

        {
            "group": "1002",
            "lastModified": "2023-05-09T19:53:53Z",
            "mimeType": null,
            "name": "x2",
            "nativePermissions": "rwxrwxrwx",
            "owner": "1002",
            "path": "x2",
            "size": 4,
            "type": "symbolic_link",
            "url": "tapis://mysystem/mySymLinkedFileOrDirectory"
        },

If a listing for a path that is a symbolic link is requested, the symbolic link is followed, and the information is 
returned for path that the symbolic link points to.  If the path doesn't exist, and error will be returned.  If the 
link points to a file, the file's information will be returned (the type will be "file").  If the symbolic link 
points to a directory, the contents of that directory will be returned.

Move and Copy
~~~~~~~~~~~~~

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

Handling of symbolic links on Linux systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

During a move or copy, if a symbolic link is encountered, it will be handled as shown in the tables below.  The first and second columns indicate whether the link is the source or target and if it points to a file or directory.

Copy

+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| Symbolic Link | Points To | Notes                                                                                                                     |
+===============+===========+===========================================================================================================================+
| source        | file      | If the destination path is to a file (this means that the path ends in a component that does exist, and it's a file or a  |
|               |           | component that does not exist):                                                                                           |
|               |           |                                                                                                                           |
|               |           |  -  a new symbolic link is created that points to the same place as the source.                                           |
|               |           |  - if the destination path includes directories that do not exist, they will be created.                                  |
|               |           |                                                                                                                           |
|               |           | If the destination path is to a directory (this means that the path ends in a component that does exist and it is a       |
|               |           | directory):                                                                                                               |
|               |           |                                                                                                                           |
|               |           |  - If the path given is to an existing directory,  a new link with the same name will be created in that directory, and   |
|               |           |    it will point to the same place as the source.                                                                         |
|               |           |                                                                                                                           |
|               |           | Note that if the link is to a relative path, moving it could change where it actually points because the exact relative   |
|               |           | path will remain the same.                                                                                                |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| source        | directory | If the destination path is to a file (this means that the path ends in a component that does exist, and it's a file or a  |
|               |           | component that does not exist):                                                                                           |
|               |           |                                                                                                                           |
|               |           |  - a new symbolic link is created that points to the same place as the source.                                            | 
|               |           |  - if the destination path includes directories that do not exist, they will be created.                                  |
|               |           |                                                                                                                           |
|               |           | If the destination path is to a directory (this means that the path ends in a component that does exist and it is a       |
|               |           | directory):                                                                                                               |
|               |           |                                                                                                                           |
|               |           |  - If the path given is to an existing directory,  a new link with the same name will be created in that directory, and   |
|               |           |    it will point to the same place as the source.                                                                         |
|               |           |                                                                                                                           |
|               |           | Note that if the link is to a relative path, moving it could change where it actually points because the exact relative   |
|               |           | path will remain the same.                                                                                                |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| destination   | file      | The destination is replaced by the source.  The source could be a file, directory, or link to a file or directory.        |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| destination   | directory | The new file, directory, or link is created inside of the existing directory.                                             |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+


Move

+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| Symbolic Link | Points To | Notes                                                                                                                     |
+===============+===========+===========================================================================================================================+
| source        | file      | If the destination path is to a file (this means that the path ends in a component that does exist, and it's a file or a  |
|               |           | component that does not exist):                                                                                           |
|               |           |                                                                                                                           |
|               |           |  - the symbolic link is renamed.                                                                                          |
|               |           |  - if the destination path includes directories that do not exist, they will be created, and the new link will be placed  |
|               |           |    there.                                                                                                                 |        
|               |           |                                                                                                                           |
|               |           | If the destination path is to a directory (this means that the path ends in a component that does exist and it is a       |
|               |           | directory):                                                                                                               |
|               |           |                                                                                                                           |
|               |           |  - If the path given is to an existing directory,  the link is moved to that directory.                                   |
|               |           |                                                                                                                           |
|               |           | Note that if the link is to a relative path, moving it could change where it actually points because the exact relative   |
|               |           | path will remain the same.                                                                                                |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| source        | directory |                                                                                                                           |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
|               |           | If the destination path is to a file (this means that the path ends in a component that does exist, and it's a file or a  |
|               |           | component that does not exist):                                                                                           |
|               |           |                                                                                                                           |
|               |           |  - the symbolic link is renamed.                                                                                          |
|               |           |  - if the destination path includes directories that do not exist, they will be created.                                  |
|               |           |                                                                                                                           |
|               |           | If the destination path is to a directory (this means that the path ends in a component that does exist and it is a       |
|               |           | directory):                                                                                                               |
|               |           |                                                                                                                           |
|               |           |  - if the path given is to an existing directory,  the souce link will be moved into that directory, and it will point to |
|               |           |    the same place as the source.                                                                                          |
|               |           |                                                                                                                           |
|               |           | Note that if the link is to a relative path, moving it could change where it actually points because the exact relative   |
|               |           | path will remain the same.                                                                                                |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| destination   | file      | The source link is renamed, to the destination path.  The destination is replaced.  The source could be a file, directory,|
|               |           | or link to a file or directory.                                                                                           |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+
| destination   | directory |  The file, directory, or link is moved inside of the existing directory.                                                  |
+---------------+-----------+---------------------------------------------------------------------------------------------------------------------------+

Making directories
~~~~~~~~~~~~~~~~~~
To create a directory on a tapis system at the given path, issue a mkdir request. This is not supported for all system types. 
The mkdir operation is currently supported for LINUX, IRODS and GLOBUS type systems.

Using the Tapis Python SDK:

.. code-block:: python
   
    t.files.mkdir(systemId="my-system", path="/folderA/folderB/newDirectory")

Using CURL:

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST https://tacc.tapis.io/v3/files/ops/<systemId> -d '{"path":"<directory_path"}'

Uploading
~~~~~~~~~

To upload a file use a POST request. The file will be placed at the location specified in the `{path}` parameter
in the request. Not all system types support this operation.
For example, given the system `my-system`, to upload file `someFile.txt` to directory `/folderA/folderB/folderC`:

Using the official Tapis Python SDK:

.. code-block:: python
   
    t.upload(source_file_path="experiment-results.hd5", system_id="my-system", dest_file_path="/folderA/folderB/folderC/someFile.txt")


.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -F "file=@someFile.txt" https://tacc.tapis.io/v3/files/ops/my-system/folderA/folderB/folderC/someFile.txt


For some system types (such as LINUX) any folders that do not exist in the specified path will automatically be created.

Note that for an S3 system an object will be created with a key of *rootDir*/{path}.


Deleting
~~~~~~~~

To delete a file or folder, issue a DELETE request for the path to be removed.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X DELETE "https://tacc.tapis.io/v3/files/ops/aturing-storage/file1.txt"

The request above would delete :code:`file1.txt`

For an S3 system, the path will represent either a single object or all objects in the bucket with a prefix matching
the system *rootDir* if the path is the empty string.

.. warning::
  For an S3 system if the path is the empty string, then all objects in the bucket with a key matching
  the prefix *rootDir* will be deleted. So if the *rootDir* is also the empty string, then all objects in the
  bucket will be removed.

Handling of symbolic links and special files on Linux Systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If Tapis encounters a symbolic link during a delete operation, the link will be deleted.  The file or directory that the link points to will be 
unaffected.  If the delete encounters a special file (such as a device file or fifo, etc), it will not be deleted, and an error will be returned.  
If this is in the middle of a recursive delete operation, some files may have been already deleted.

Creating a directory
~~~~~~~~~~~~~~~~~~~~

To create a directory, use POST and provide the path to the new directory in the request body. Not all system types
support this operation.

.. code-block:: shell

    $ curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json https://tacc.tapis.io/v3/files/ops/my-system

with a JSON body of

.. code-block:: json

  {
    "path": "path/to/new/directory/"
  }


Getting Linux stat information
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Get native stat information for a file or directory for a system of type LINUX.

For example, for `/subdir/file1.txt`

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" "https://tacc.tapis.io/v3/files/utils/linux/aturing-storage/subdir/file1.txt"


Running a Linux native operation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Run a native operation on a path. Operations are *chmod*, *chown* or *chgrp*. For a system of type LINUX.

For example, to change the owner of a file located at `/file1.txt` to :code:`aeinstein`

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json "https://tacc.tapis.io/v3/files/utils/linux/aturing-storage/file1.txt"

with a JSON body of

.. code-block:: json

  {
    "operation": "CHOWN",
    "argument": "aeinstein"
  }


-------------------------
Content
-------------------------

Get file or directory contents as a stream of data. Not supported for all system types.

File Contents - Serving files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To return the actual contents (raw bytes) of a file:

.. code-block:: shell

    $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/content/my-system/image.jpg > image.jpg

Query Parameters

:startByte: integer - Start at byte N of the file
:count: integer - Return this number of bytes after startByte
:zip: boolean - Zip the contents of a folder

Header Parameters

:more: integer - Return 1 KB chunks of UTF-8 encoded text from a file starting after page *more*. This call can be used to page through a text based file. Note that if the contents of the file are not textual (such as an image file or other binary format), the output will be bizarre.

Download using ZIP
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The query parameter *zip* may be used to request a stream compressed using the ZIP file format. This is not allowed
if system *rootDir* plus *path* would result in all files on the host being included. Please download individual
directories, files or objects.

For example, on a linux system a directory may be downloaded as a compressed archive using a command  similar to the
following:

.. code-block:: shell

    $ curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/content/my-linux-system/my_dir > my_dir.zip

The program *unzip* may then be used to extract the contents.

If the path being downloaded is a single file and the contents are placed in a file ending in the extension *.gz* then
the *gunzip* utility may also be used to extract the contents.


--------------------
Transfers
--------------------

File transfers are used to move data between Tapis systems. They should be used for bulk data operations that are too
large for the REST api to perform. Transfers occur *asynchronously*, and are executed concurrently where possible to
increase performance. As such, the order in which the files are transferred is not deterministic.

When a transfer is initiated, a *bill of materials* is created that creates a record of all the files from the
*sourceURI* that are to be transferred to the *destinationURI*. Unless otherwise specified, all files in the
*bill of materials* must transfer successfully in order for the overall transfer to be considered successful.
A transfer task has an attribute named *status* which is updated as the transfer progresses.
The possible states for a transfer are:

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

.. note::
  For transfers involving Globus, both the source and destination system must be of type GLOBUS.

The number of files included in the *bill of materials* will depend on the system types and the *sourceURI* values
provided in the transfer request. If the source system supports directories and *sourceURI* is a directory then
the directory will be processed recursively and all files will be added to the *bill of materials*. If the source
system is of type S3 then all objects matching the *sourceURI* path as a prefix will be included.

System types and supported functionality
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As discussed above, the files included in a transfer will depend on the source system types and the *sourceURI* values
provided in the transfer request. Here is a summary of the behavior:

*LINUX/IRODS to LINUX/IRODS*
  When the *sourceURI* is a directory a recursive listing is made and the files and directory structure are replicated
  on the *destinationURI* system.

*S3 to LINUX/IRODS*
  All objects matching the *sourceURI* path as a prefix will be created as files on the *destinationURI* system.

*LINUX/IRODS to S3*
  When the *sourceURI* is a directory a recursive listing is made. For each entry in the listing the path relative to
  the source system rootDir is mapped to a key for the S3 destination system. In other words, a recursive listing is
  made for the directory on the *sourceURI* system and for each non-directory entry an object is created on the S3
  *destinationURI* system.

*S3 to S3*
  All objects matching the *sourceURI* path as a prefix will be re-created as objects on the *destinationURI* system.

*HTTP/S to ANY*
  Transfer of a directory is not supported. Destination system may not be of type GLOBUS. The content of the object
  from the *sourceURI* URL is used to create a single file or object on the *destinationURI* system.

*ANY to HTTP/S*
  Transfers not supported. Tapis does not support the use of protocol http/s for the *destinationURI*.


Creating Transfers
~~~~~~~~~~~~~~~~~~

Lets say our user :code:`aturing` needs to transfer data between two systems that are registered in tapis. The source system
has an id of :code:`aturing-storage` with the results of an experiment located in directory :code:`/experiments/experiment-1/`
that should be transferred to a system with id :code:`aturing-compute`

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json https://tacc.tapis.io/v3/files/tranfers

.. code-block:: json

  {
    "tag": "An optional identifier",
    "elements": [
      {
        "sourceURI": "tapis://aturing-storage/experiments/experiment-1/",
        "destinationURI": "tapis://aturing-compute/"
      }
    ]
  }

The request above will initiate a transfer that copies all files and folders in the :code:`experiment-1` folder on the source
system to the root directory of the destination system :code:`aturing-compute`

HTTP Source
^^^^^^^^^^^

Unauthenticated HTTP/S endpoints can also be used as a source for a file transfer request.
This can be useful, for instance, when the inputs for a job are from a separate web service, or perhaps stored in a
public S3 bucket. Note that in this case the *sourceURI* does not refer to a Tapis system.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json https://tacc.tapis.io/v3/files/tranfers

.. code-block:: json

  {
    "tag": "An optional identifier",
    "elements": [
      {
        "sourceURI": "https://some-web-application.io/calculations/12345/results.csv",
        "destinationURI": "tapis://aturing-compute/inputs.csv"
      }
    ]
  }

The request above will place the output of the source URI into a file called  :code:`inputs.csv` in the
:code:`aturing-compute` system.


Getting transfer information
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To retrieve information about a transfer including status and bytes transferred, simply make a GET request to the
transfers API with the UUID of the transfer.

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

Handling of symbolic links on Linux Systems
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Transfer will always "follow links".  If the source of the transfer is a symbolic link to a file or directory, it transfer the file or 
directory that is pointed to.  If it doesn't exist, it will be an error (i.e. the link points to something that doesn't exist).  In 
the case of a directory transfer where one of the entries in the directory encountered is a symbolic link it will be resolved in 
exactly the same way - the file is added to the archive to be downloaded, or the directory is walked, and it's content added to the 
archive.  Symbolic links can create situations where infinite recursion can occur - for example, suppose you have a directory with a 
link that points to "../".  That means that each time it's expanded the current directory will be added, and the link will be 
expanded again.  Transfers (and really all file operations that involve recursing subdirectories) are limited by a recursion depth.  
The current maximum depth is 20.

------------------
Support for Globus
------------------

Please note that your Tapis site installation must have been configured by the site administrator to support
Globus. Please see `Globus_Config`_.

.. _Globus_Config: https://tapis.readthedocs.io/en/latest/deployment/deployer.html#configuring-support-for-globus

The integration of Globus and Tapis allows users to configure and use Globus endpoints and
collections just as they would other types of storage systems defined in Tapis. As mentioned previously, not all operations
are supported for all system types. For systems of type GLOBUS, the following operations are supported:

* listing
* mkdir
* move
* delete
* transfer between GLOBUS systems


For more information on setting up and registering credentials for a system of type GLOBUS,
please see `Systems_Globus`_.

.. _Systems_Globus: https://tapis.readthedocs.io/en/latest/technical/systems.html#registering-credentials-for-a-globus-system#




------------------------------
File Permissions
------------------------------

The permissions model allows for fine grained access control of paths on a Tapis system. The system owner
may grant READ and MODIFY permission to specific users. MODIFY implies READ.

Please note that Tapis permissions are independent of native permissions enforced by the underlying system host.


Getting permissions
~~~~~~~~~~~~~~~~~~~

Get the Tapis permissions for a user for the system and path. If no user specified then permissions are retrieved for
the user making the request.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/perms/aturing-storage/experiment1?username=aeinstein


Granting permissions
~~~~~~~~~~~~~~~~~~~~

Lets say our user :code:`aturing` has a system with ID :code:`aturing-storage`. Alan wishes to allow his collaborator
:code:`aeinstein` to view the results of an experiment located at :code:`/experiment1`


.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json https://tacc.tapis.io/v3/files/perms/aturing-storage/experiment1/

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


Revoking permissions
~~~~~~~~~~~~~~~~~~~~

Our user :code:`aturing` now wishes to revoke his former collaborators access to the folder above. He can
issue a DELETE request on the path and specify the username in order to revoke access:


.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X DELETE https://tacc.tapis.io/v3/files/perms/aturing-storage/experiment1?username=aeinstein


-----------------------------
File Path Sharing
-----------------------------

In addition to fine grained permissions support, Tapis also supports a higher level approach to granting access.
This approach is known simply as *sharing*. The sharing API allows you to share a file path
with a set of users as well as share publicly with all users in a tenant. Sharing provides READ access.
When the system has a dynamic *effectiveUserId*, sharing also allows for MODIFY access to all paths for calls
made through the Files service.

.. note::
  Note that there is one other case when a system is treated as having a dynamic *effectiverUserId* in the
  context of sharing, even with a static *effectiverUserId*. This is when the
  system type is ``IRODS`` and the attribute *useProxy* is set to ``true``. In this case the connection to
  the *IRODS* host is made using a special administrative account which then acts as the Tapis user.
  So please be aware that for this type of system sharing a file path will allow for MODIFY access.

.. warning::
  In the context of using a shared application to run a job, sharing a path will grant users READ and MODIFY
  access to the path, even for the case of a static effectiveUserId.

.. note::
  Tapis permissions and sharing are independent of native permissions enforced by the underlying system host.

For more information on sharing please see :doc:`sharing`

Getting share information
~~~~~~~~~~~~~~~~~~~~~~~~~

Retrieve all sharing information for a path on a system. This includes all users with whom the path has been shared and
whether or not the path has been made publicly available.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/files/share/aturing-storage/experiment1

Sharing a path with users
~~~~~~~~~~~~~~~~~~~~~~~~~

Create or update sharing information for a path on a system. The path will be shared with the list of users provided in
the request body. Requester must be owner of the system. For LINUX systems path sharing is hierarchical.
Sharing a path grants users READ access to the path or, in the context of running a job, it grants users READ
and MODIFY access to the path.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json https://tacc.tapis.io/v3/files/share/aturing-storage/experiment1/

with a JSON body with the following shape:

.. code-block:: json

  {
    "users": [ "aeinstein", "rfeynman" ]
  }

Sharing a path publicly
~~~~~~~~~~~~~~~~~~~~~~~

Share a path on a system with all users in the tenant. Requester must be owner of the system.
Sharing a path grants users READ access to the path or, in the context of running a job, it grants users READ
and MODIFY access to the path.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X POST https://tacc.tapis.io/v3/files/share_public/aturing-storage/experiment1/


Unsharing a path with users
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Update sharing information for a path on a system. The path will be unshared with the list of users provided in the
request body. Requester must be owner of the system.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -H "Content-Type:application/json" -X POST -d @body.json https://tacc.tapis.io/v3/files/unshare/aturing-storage/experiment1/

with a JSON body with the following shape:

.. code-block:: json

  {
    "users": [ "rfeynman" ]
  }

Unsharing a path publicly
~~~~~~~~~~~~~~~~~~~~~~~~~

Remove public sharing for a path on a system. Requester must be owner of the system.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X POST https://tacc.tapis.io/v3/files/unshare_public/aturing-storage/experiment1/

Removing all shares for a path
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Remove all shares for a path on a system including public access.
If the path is a directory this will also be done for all sub-paths.

.. code-block:: shell

    curl -H "X-Tapis-Token: $JWT" -X POST https://tacc.tapis.io/v3/files/unshare_all/aturing-storage/experiment1/

-----------------------------
PostIts
-----------------------------

The PostIts service is a URL service that allows you to create pre-authenticated, disposable
URLs to files, directories, buckets, etc in the Tapis Platform's Files service. You have
control over the lifetime and number of times the URL can be redeemed, and you can expire a
PostIt at any time. The most common use of PostIts is to create URLs to files so that you
can share with others without having to upload them to a third-party service.

Creating PostIts
~~~~~~~~~~~~~~~~~~~

To create a PostIt, send a POST request to the Files service's Create PostIt endpoint.  The url
will contain the systemId and the path that will be shared.  The body of the post will contain
a json document which describes how long the PostIt is valid, and how many times it can be
redeemed.  There are default values for each of these parameters if they are not included.
If the number of times the PostIt may be redeemed (allowedUses) is set to -1, the PostIt may
be redeemed an unlimited number of times. The expiration (validSeconds) must always contain
a value.  If one is not provided, there is a default that is used.  The maximum value of
'validSeconds' is the maximum integer value in Java (Integer.MAX_VALUE = 2147483647).

.. note::
  The maximum value would result in a PostIt that would be valid for nearly 70 years,
  however it is important to remember that the authentication and authorization are built
  into the PostIt redeem url.  This means anyone who has the url could redeem it.  For
  this reason, it's advisable to keep the uses and expiration times to the minimum required.

Default parameters:

* allowedUses:  1 (One use)
* validSeconds: 2592000 (30 days)

APPLICATION/JSON examples

Creating a postit with the default expiration and uses on a system called "tapisv3-storage"
for the path "/myDirectory/myFile.txt"

Using curl

.. code-block:: shell

    curl -X POST "https://tacc.tapis.io/v3/files/postits/tapisv3-storage/myDirectory/myFile.txt" -H "X-Tapis-Token: $JWT" -H "Content-Type: application/json"

Using python

.. code-block:: python

    tapis.files.createPostIt(systemId="tapisv3-storage", path="myDirectory/myFile.txt")

Creating a postit supplying expiration (validSeconds 600) and uses (allowedUses 3) on a
system called "tapisv3-storage" for the path "/myDirectory/myFile.txt"

Using curl

.. code-block:: shell

    curl -X POST "https://tacc.tapis.io/v3/files/postits/tapisv3-storage/myDirectory/myFile.txt" -H "X-Tapis-Token: $JWT" -H "Content-Type: application/json" -d '{"allowedUses": 3, "validSeconds": 600}'

Using python

.. code-block:: python

    tapis.files.createPostIt(systemId="tapisv3-storage", path="myDirectory/myFile.txt", allowedUses=3, validSeconds=600)

Creating a postit supplying allowing unlimited uses (allowedUses -1) and the default value
for expiration (default value for validSeconds is 30 days) on a system called
"tapisv3-storage" for the path "/myDirectory/myFile.txt"

Using curl

.. code-block:: shell

    curl -X POST "https://tacc.tapis.io/v3/files/postits/tapisv3-storage/myDirectory/myFile.txt" -H "X-Tapis-Token: $JWT" -H "Content-Type: application/json" -d '{"allowedUses": -1}'

Using python

.. code-block:: python

    tapis.files.createPostIt(systemId="tapisv3-storage", path="myDirectory/myFile.txt", allowedUses=-1)

Example Postit Creation Response

.. code-block:: shell

 {
   "status": "success",
   "message": "FAPI_POSTITS_OP_COMPLETE Operation completed. jwtTenant: tacc jwtUser: example_user OboTenant: tacc OboUser: examaple_user Operation: createPostIt System: tapisv3-storage Path: myDirectory/myFile.txt Id: e614ce8e-447c-4195-a3f7-55f5dec5d243-010",
   "result": {
     "id": "e614ce8e-447c-4195-a3f7-55f5dec5d243-010",
     "systemId": "tapisv3-storage",
     "path": "myDirectory/myFile.txt",
     "allowedUses": 3,
     "timesUsed": 0,
     "jwtUser": "example_user",
     "jwtTenantId": "tacc",
     "owner": "example_user",
     "tenantId": "tacc",
     "redeemUrl": "https://tacc.tapis.io/v3/files/postits/redeem/e614ce8e-447c-4195-a3f7-55f5dec5d243-010",
     "expiration": "2023-03-08T15:37:28.533641Z",
     "created": "2023-03-08T15:27:28.534250Z",
     "updated": "2023-03-08T15:27:28.534250Z"
   },
   "version": "1.3.1",
   "commit": "0c13ee3c",
   "build": "2023-03-07T21:56:41Z\n",
   "metadata": {}
 }

.. note::
  The PostIt returned by the create will contain the redeemUrl.  This url may be used to download the
  content pointed to by the PostIt.  No Authentication will be done during this call.  The credentials
  used to access this content will be the credentials of the PostIt owner.  If the owner's permissions
  change between creating the PostIt and redeeming the PostIt so that the owner is no longer allowed
  to read the content, redeeming the PostIt will fail.

Create PostIt parameters
^^^^^^^^^^^^^^^^^^^^^^^^

+---------------+---------+----------+------------+--------------------------------------------------------------+
| Name          | Type    | Location | Default    | Description                                                  |
+===============+=========+==========+============+==============================================================+
| systemId      | String  | url      | <none>     | The systemId of the system containing the path to create     |
|               |         |          |            | the PostIt for.                                              |
+---------------+---------+----------+------------+--------------------------------------------------------------+
| path          | String  | url      | <none>     | The path to create the PostIt for.                           |
+---------------+---------+----------+------------+--------------------------------------------------------------+
| allowedUses   | integer | body     | 1          | The number of times a postit can be redeemed. Valid  values  |
|               |         |          |            | are 1 - 2147483647, or -1 for unlimited uses.                |
+---------------+---------+----------+------------+--------------------------------------------------------------+
| validSeconds  | integer | body     | 2147483647 | The number of seconds from creation that the PostIt will be  |
|               |         |          |            | redeemable.  An expiration time is computed by adding this   |
|               |         |          |            | value to the current date and time.                          |
+---------------+---------+----------+------------+--------------------------------------------------------------+


Listing PostIts
~~~~~~~~~~~~~~~~~~~

PostIts can be listed by authenticated users.  By default a listing of all PostIts owned by the authenticated
user will be returned.

Using curl

.. code-block:: shell

    curl "https://tacc.tapis.io/v3/files/postits" -H "X-Tapis-Token: $JWT"

Using python

.. code-block:: python

    tapis.files.listPostIts()

To list all PostIts that are visible to the authenticated user, supply the query parameter
listType and set it's value to ALL.  Typically users will only be able to see PostIts that
they own, however tenant admins will be allowed to see all PostIts in their tenant.

Using curl

.. code-block:: shell

    curl "https://tacc.tapis.io/v3/files/postits?listType=ALL" -H "X-Tapis-Token: $JWT"

Using python

.. code-block:: python

    tapis.files.listPostIts(listType="ALL")

Paging is handled by the query parameters limit, skip, and startAfter.  By default 100
PostIts are returned, however this can be changed by setting the query parameter "limit".
Skip is used to determine how many PostIts to skip.  For example to get the second page
of a list of PostIts containing 10 items per page, you would need to set the limit to
10 (10 items per page), and set skip to 10 (skip the first page).  It's probably a good
practice to set orderBy also, so that the list is ordered in the same way each time.
You could for example set orderBy to id.

Using curl

.. code-block:: shell

    curl "https://tacc.tapis.io/v3/files/postits?listType=ALL&limit=10&skip=10&orderBy=id" -H "X-Tapis-Token: $JWT"

Using python

.. code-block:: python

    tapis.files.listPostIts(listType="ALL", limit=10, skip=10, orderBy="id")

Using startAfter is similar to using skip.  When using startAfter, you must provide a
PostIt id, and the list will start immediately after that PostIt.  You **must** provide
the orderBy parameter.  You may not use skip and startAfter together.

To control which fields are returned, you can supply the select query parameter, and
select only certain fields.  Setting the select query parameter to id, redeemUrl and
expiration would return only those fields (select=id,redeemUrl,expiration).  Setting
"select" to allAttributes will return all attributes, and setting "select" to
summaryAttributes will only return a preset collection of attributes.  The default
is summaryAttributes.  You can also set the value to summaryAttributes with additional
attributes (select=summaryAttributes,updated).

Using curl

.. code-block:: shell

    curl "https://tacc.tapis.io/v3/files/postits?listType=ALL&select=id,redeemUrl,expiration" -H "X-Tapis-Token: $JWT"

Using python

.. code-block:: python

    tapis.files.listPostIts(listType="ALL", select="id,redeemUrl,expiration")

Retrieving a Single PostIt
~~~~~~~~~~~~~~~~~~~~~~~~~~

Retrieving a single PostIt can be done by issuing a GET request containing the id of the PostIt.  This
is **not** the same as redeeming, and does not add to the redeem count.  This will allow the owner of
the PostIt or a tenant admin to view the PostIt.  This could be used to see the number of times it's
been retrieved, total number of uses allowed, expiration date, etc.

Using curl

.. code-block:: shell

    curl "https://tacc.tapis.io/v3/files/postits/e614ce8e-447c-4195-a3f7-55f5dec5d243-010" -H "X-Tapis-Token: $JWT"

Using python

.. code-block:: python

    tapis.files.getPostIt(postitId="e614ce8e-447c-4195-a3f7-55f5dec5d243-010")

For tenant admins, any PostIts in the tenant can be retreived in this way.  For other users only PostIts that
are owned by that user may be retreived, since access to the redeem url allows redemption of the PostIt.

.. _Updating PostIts:

Updating PostIts
~~~~~~~~~~~~~~~~~~~

The creator of a PostIt and tenant admins can update a PostIt.  When updating a PostIt, the id of the posted
is sent as part of the url, and a body containing allowedUses and/or validSeconds can be specified.

.. note::
  The validSeconds parameter will add to the date and time as of the update request to compute the new
  expiration.  It does **not** extend the current expiration by that many seconds.

If you need to update the url, you will need to delete or expire this PostIt and create
a new one.

Update a PostIt to allow for 10 uses and to expire in 1 hour

Using curl / PATCH

.. code-block:: shell

    curl -X PATCH "https://tacc.tapis.io/v3/files/postits/e614ce8e-447c-4195-a3f7-55f5dec5d243-010" -H "Content-Type: application/json" -H "X-Tapis-Token: $JWT" -d '{ "allowedUses":10, "validSeconds":3600 }'

Using curl / POST

.. code-block:: shell

    curl -X POST "https://tacc.tapis.io/v3/files/postits/e614ce8e-447c-4195-a3f7-55f5dec5d243-010" -H "Content-Type: application/json" -H "X-Tapis-Token: $JWT" -d '{ "allowedUses":10, "validSeconds":3600 }'

Using python

.. code-block:: python

    tapis.files.updatePostIt(postitId="e614ce8e-447c-4195-a3f7-55f5dec5d243-010", allowedUses=10, validSeconds=3600)

Redeeming PostIts
~~~~~~~~~~~~~~~~~~~

To redeem a PostIt, use the redeemUrl from the PostIt to make a non-authenticated HTTP GET request.

Using curl

.. code-block:: shell

    curl -JO "https://tacc.tapis.io/v3/files/postits/redeem/e614ce8e-447c-4195-a3f7-55f5dec5d243-010"

.. note::
  The options -J and -O (specified above as -JO) tell curl to download the file content and use the
  filename in the content-disposition header.  It's worth noting that using this filename is not
  entirely without risk as it could overwrite a file of the same name. If you would prefer to use
  a name that you specify, you could replace -JO with \-\-output filename

Using python

.. code-block:: python

    tapis.files.redeemPostIt(postitId="e614ce8e-447c-4195-a3f7-55f5dec5d243-010")

By default if the PostIt you are redeeming points to a path that is a directory, you will get a
zip file, and if it's a regular file, you will get an uncompressed file.  If you want to force
a file to be compressed, you can specify the query parameter zip and set it to true.

Using curl

.. code-block:: shell

    curl -JO "https://tacc.tapis.io/v3/files/postits/redeem/e614ce8e-447c-4195-a3f7-55f5dec5d243-010?zip=true"

Using python

.. code-block:: python

    tapis.files.redeemPostIt(postitId="e614ce8e-447c-4195-a3f7-55f5dec5d243-010", zip=True)

.. note::
  If you specify zip=false for a PostIt that points to a directory, you will get an error.  Directories
  can't be returned unless they are compressed.

The redeem URL can also be pasted into the address bar of your favorite browser, and it will download
the file pointed to by the PostIt.

Handling of symbolic links on Linux Systems
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Redeeming PostIts handles symbolic links exactly the same as Transfers_

Expiring PostIts
~~~~~~~~~~~~~~~~~~~
There is no special endpoint for expiring a PostIt.  To Expire a PostIt just update see
:ref:`Updating PostIts` and set validSeconds to 0, or allowedUses to 0.

Deleting PostIts
~~~~~~~~~~~~~~~~~~~
PostIts can be deleted by specifying the PostIt id in the url.  This is a hard delete, and
cannot be undone.  Only an owner or tenant admin can delete a PostIt.

Using curl

.. code-block:: shell

    curl -X DELETE "https://tacc.tapis.io/v3/files/postits/e614ce8e-447c-4195-a3f7-55f5dec5d243-010" -H "X-Tapis-Token: $JWT"

Using python

.. code-block:: python

    tapis.files.deletePostIt(postitId="e614ce8e-447c-4195-a3f7-55f5dec5d243-010")

.. rubric:: Footnotes

.. [#] With the exception of the *sourceURI* in a transfer request when the protocol is *http* or *https*.

