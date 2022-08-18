--------
Archives
--------

Archives are the storage mechanisms for pipeline results. Without an archive, 
the results produced by each task will be permanently deleted at the end of each pipeline run.
By default, archiving occurs at the end of a pipeline run when all tasks have reached a terminal state.

Archive Attributes Table
~~~~~~~~~~~~~~~~~~~~~~~~

This table contains all of the properties that are shared by all archives. Different types
of archives will have other unique properties in addition to all of the properties in the table
below.

+-------------+--------+---------------------------+------------------------------------------------------------------------+
| Attribute   | Type   | Example                   | Notes                                                                  |
+=============+========+===========================+========================================================================+
| id          | String | my-task, my.task, my_task | - Must be unique within the group that it belongs to                   |
+-------------+--------+---------------------------+------------------------------------------------------------------------+
| archive_dir | String | path/to/archive/dir       | - Relative to either the "root directory" of the archive's file system |
+-------------+--------+---------------------------+------------------------------------------------------------------------+
| type        | Enum   | system, S3                |                                                                        |
+-------------+--------+---------------------------+------------------------------------------------------------------------+

Archive Types
~~~~~~~~~~~~~

.. _archivetypes:

.. tabs::

  .. tab:: Tapis System
    
    **Tapis System**

    Store the results of a pipeline run to a specific system. The owner of the archive
    must have ``MODIFY`` permissions on the system. Permission will be checked at the time
    the archive is created and every time before archiving.

    .. note::

      The archiving process does **NOT** interfere with the task execution process. If archiving
      fails, the pipeline run can still complete successfully.

    **Tapis System Archive Attributes Table**
        
    +-----------+--------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Attribute | Type   | Example             | Notes                                                                                                                                                |
    +===========+========+=====================+======================================================================================================================================================+
    | system_id | String | somerepo/some_image | - Must have ``MODIFY`` permissions on this system. Also, by default, the system is assumed to be in the same tenant as the group to which it belongs |
    +-----------+--------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------------------+

    **Tapis System Archive Example**::

      {
        "id": "my.archive",
        "type": "system",
        "system_id": "my.system",
        "archive_dir": "workflows/archive/"
      }
  
  .. tab:: S3 (unsupported)

    **S3 (currently unsupported)**

----

:ref:`Back to archives <archivetypes>`