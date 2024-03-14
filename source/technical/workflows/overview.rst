--------
Overview
--------

Before getting into the details about how to create and run a workflow, here are some important concepts you must understand in order to properly use *Tapis Workflows*

Important Concepts
~~~~~~~~~~~~~~~~~~

* **Group**: A *group* is a collection of Tapis users that own or have access to workflow resources. In order to create your first workflow, you must first belong to, or create your own *group*.
* **Pipeline**: A *pipeline* is a collection of tasks and a set of rules governing how those tasks are to be executed.
* **Archive**: An *archive* is the storage medium for the results created during a pipeline run. By default, the results produced by each task are deleted at the end of a pipeline run.
* **Task**: *Tasks* are discrete units of work performed during the execution of a workflow. They can be represented as nodes on a directed acyclic graph (DAG), with the order of their execution determined by their dependencies, and where all tasks without dependencies are executed first. There are different types of *tasks* that users can leverage to perform diffent types of work. These are called task primitives and they will be discussed in detail later:

  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+
  | Type          | Example                                                                                                                             | Supported |
  +===============+=====================================================================================================================================+===========+
  | image_build   | Builds Docker and Singularity images from recipe files and pushes the to repositories                                               | yes       |
  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+
  | request       | Sends requests using various protocols to resources external to the workflow (Only HTTP protocol and GET currently fully supported) | partial   |
  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+
  | tapis_job     | Submits a *Tapis job*                                                                                                               | yes       |
  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+
  | tapis_actor   | Executes an *Tapis actor*                                                                                                           | no        |
  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+
  | container_run | Runs a container based on the provided image and tag                                                                                | no        |
  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+
  | function      | Runs user-defined code in the language and runtime of their choice                                                                  | yes       |
  +---------------+-------------------------------------------------------------------------------------------------------------------------------------+-----------+

----

.. include:: /technical/workflows/security-note.rst 