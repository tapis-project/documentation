..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _jobs:

####
Jobs 
####

.. raw:: html

    <style> .red {color:#FF4136; font-weight:bold; font-size:20px} </style>

.. role:: red


----

Introduction to Jobs
====================

The Tapis v3 Jobs service is specialized to run containerized applications on any host that supports container runtimes.  Currently, Docker and Singularity containers are supported.  The Jobs service uses the Systems, Apps, Files and Security Kernel services to process jobs.  

Implementation Status
---------------------
The following table describes the current state of the Beta release of Jobs.  All UrlPaths shown start with /v3/jobs.  The unauthenticated health check, ready and hello APIs do not require a Tapis JWT in the request header.

============     ======   ====================   ===========
Name             Method   UrlPath                Status
============     ======   ====================   ===========
Submit           POST     /submit                Implemented
Resubmit         POST     /{jobUuid}/resubmit    Implemented
Get              GET      /{jobUuid}             Implemented
Get Status       GET      /{jobUuid}/status      Implemented
\ 
Health Check     GET      /healthcheck           Implemented
Ready            GET      /ready                 Implemented
Hello            GET      /hello                 Implemented
============     ======   ====================   ===========


Job Processing Overview
-----------------------

Before discussing the details of how to construct a job request, we take this opportunity to describe overall lifecycle of a job.  When a job request is recieved as the payload of an POST call, the following steps are taken:

#. **Request authorization** - The tenant, owner, and user values from the request and Tapis JWT are used to authorize access to the application, execution system and, if specified, archive system.  

#. **Request validation** - Request values are checked for missing, conflicting or improper values; all paths are assigned; required paths are created on the execution system; and macro substitution is performed to finalize all job parameters.

#. **Job creation** - A Tapis job object is written to the database.

#. **Job queuing** - The Tapis job is queue on an internal queue serviced by one or more Job Worker processes.

#. **Response** - The initial Job object is sent back to the caller in the response.  This ends the synchronous portion of job submission.

Once a response to the submission request is sent to the caller, job processing proceeds asynchronously.  Job worker processes read jobs from their work queues.  The number of workers and queues is limited only by hardware resource constraints.  Each job is assigned a worker thread.  This thread shepards a job through its lifecycle until the job completes, fails or becomes blocked due to a transient resource constraint.  The job lifecycle is reflected in the `Job Status`_ and generally progresses as follows:

::

    a) Stage inputs to execution system
    b) Stage application artifacts to execution system
    c) Queue or invoke job on execution system
    d) Monitor job until it terminates
    e) Collect job exit code
    f) Archive job output


Simple Job Submission Example
-----------------------------

The POST payload for the simplest job submission request looks like this:

::

    {
     "name": "myJob"
     "appId": "myApp"
     "appVersion": "1.0"
    }

In this example, all input and output directories are either specified in the *myApp* definition or are assigned their default values.  Currently, the execution system on which an application runs must be specified in either the application definition or job request.  Our example assumes that *myApp* assigns the execution system.  Future versions of the Jobs service will support dynamic execution system selection.

An archive system can also be specified in the application or job request; the default is to be the same as the execution system.

-----------------------

The Job Submission Request
==========================

A job submission request must contain the name, appId and appVersion values as shown in the `Simple Job Submission Example`_.  Those values are marked *Required* in the list below, a list of all possible values allowed in a submission request.  If a parameter has a default value, that value is also shown.  

In addition, some parameters can inherit their values from the application or system definitions as discussed in `Parameter Precedence`_.  These parameters are marked *Inherit*.  Parameters that merge inherited values (rather than override them) are marked *InheritMerge*.  

Parameters that do not need to be set are marked *Not Required*.  Finally, parameters that allow macro substitution are marked *MacroEnabled* (see `Macro Substitution`_ for details).

**name**
  The user chosen name of the job.  *MacroEnabled*, *Required.* 
**appId**
  The Tapis application to execute. *Required.*
**appVersion**
  The version of the application to execute. *Required.*
**owner**
  User ID under which the job runs.  Administrators can designate a user other than themselves.
**tenant**
  Tenant of job owner.  Default is job owner's tenant.
**description**
  Human readable job description.  *MacroEnabled*, *Not Required*
**archiveOnAppError**
  Whether archiving should proceed even when the application reports an error.  Default is *true*.
**dynamicExecSystem**
  Whether the best fit execution system should be chosen using *execSystemConstraints*.  Default is *false*.
**execSystemId**
  Tapis execution system ID.  *Inherit*.
**execSystemExecDir**
  Directory into which application assets are staged.  *Inherit*, see `Directories`_ for default.
**execSystemInputDir**
  Directory into which input files are staged.  *Inherit*, see `Directories`_ for default.
**execSystemOutputDir**
  Directory into which the application writes its output.  *Inherit*, see `Directories`_ for default.
**execSystemLogicalQueue**
  Tapis-defined queue that corresponds to a batch queue on the execution system.  *Inherit* when applicable.
**archiveSystemId**
  Tapis archive system ID.  *Inherit*, defaults to *execSystemId*.
**archiveSystemDir**
  Directory into which output files are archived after application execution.  *Inherit*, see `Directories`_ for default.
**nodeCount**
  Number of nodes required for application execution.  *Inherit*, default is 1.
**coresPerNode**
  Number of cores to use on each node.  *Inherit*, default is 1.
**memoryMB**
  Megabytes of memory to use on each node.  *Inherit*, default is 100.
**maxMinutes**
  Maximum number of minutes allowed for job execution.  *Inherit*, default is 10.
**fileInputs**
  Input files that need to be staged for the application.  *InheritMerge*.
**parameterSet**
  Runtime parameters organized by category.  *Inherit*.
**execSystemConstraints**
  Constraints applied against execution system capabilities to validate application/system compatibility. *InheritMerge*.
**subscriptions**
  Subscribe to the job's events.  *InheritMerge*.
**tags**
  An array of user-chosen strings that are associated with a job.  *InheritMerge*.

The following subsections discuss the meaning and usage of each of the parameters available in a job request.  The schema_ and its referenced library_ comprise the actual JSON schema definition for job requests.

..  _schema: https://github.com/tapis-project/tapis-java/blob/dev/tapis-jobsapi/src/main/resources/edu/utexas/tacc/tapis/jobs/api/jsonschema/SubmitJobRequest.json

..  _library: https://github.com/tapis-project/tapis-shared-java/blob/dev/tapis-shared-lib/src/main/resources/edu/utexas/tacc/tapis/shared/jsonschema/defs/TapisDefinitions.json

Parameter Precedence
--------------------

The runtime environment of a Tapis job is determined by values in system definitions, the app definition and the job request, in low to high precedence order as listed.  Generally speaking, for values that can be assigned in multiple definitions, the values in job requests override those in app definitions, which override those in system definitions.  There are special cases, however, where the values from different definitions are merged.

See the jobs/apps/systems parameter matrix_ for a detailed description of how each parameter is handled.

.. _matrix: https://drive.google.com/file/d/1cPwZl9V0u0FvuQTBrPK6TA5sNYs2fsfB/view?usp=sharing


Directories
-----------

The execution and archive system directories are calculated before the submission response is sent.  This calculation can include the use of macro definitions that get replaced by values at submission request time.  The `Macro Substitution`_ section discusses what macro defintions are available and how substitution works.  In this section, we document the default directory assignments which may include macro definitions.

Directory Definitions
^^^^^^^^^^^^^^^^^^^^^

The directories assigned when a system is defined:

::

  rootDir - the root of the file system that is accessible through this Tapis system.
  jobWorkingDir - the default directory for temporary files used or created during job execution.
  dtnMountPoint - the path relative to the execution system's rootDir where the DTN file system is mounted.

An execution system may define a *Data Transfer Node* (DTN).  A DTN is a high throughput node used to stage job inputs and to archive job outputs.  The goal is to improve transfer performance.  The execution system mounts the DTN's file system at the *dtnMountPoint* so that executing jobs have access to its data, but Tapis will connect to the DTN rather than the execution system during transfers.  See `Data Transfer Nodes`_ for details. 

The directories assigned in application definitions and/or in a job submission requests: 

::

   execSystemExecDir
   execSystemInputDir
   execSystemOutputDir
   archiveSystemDir

Directory Assignments
^^^^^^^^^^^^^^^^^^^^^

The rootDir and jobWorkingDir are always assigned upon system creation, so they are available for use as macros when assigning directories in applications or job submission requests.  

When a job request is submitted, each of the job's four execution and archive system directories are assigned as follows: 

#. If the job submission request assigns the directory, that value is used.  Otherwise,
#. If the application definition assigns the directory, that value is used.  Otherwise,
#. The default values shown below are assigned:  

::

   No DTN defined:
     execSystemExecDir:    ${jobWorkingDir}/jobs/${jobUUID}
     execSystemInputDir:   ${jobWorkingDir}/jobs/${jobUUID}
     execSystemOutputDir:  ${jobWorkingDir}/jobs/${jobUUID}/output
     archiveSystemDir:     /jobs/${JobUUID}/archive                 (if archiveSystemId is set)
   DTN defined:
     execSystemExecDir:    ${dtnMountPoint}/jobs/${jobUUID}
     execSystemInputDir:   ${dtnMountPoint}/jobs/${jobUUID}
     execSystemOutputDir:  ${dtnMountPoint}/jobs/${jobUUID}/output
     archiveSystemDir:     ${dtnMountPoint}/jobs/${JobUUID}/archive (if archiveSystemId is set)

FileInputs
----------

The *fileInputs* in application definitions are merged with those in job submission requests to produce a complete list of input files that need to be staged for a job.  The fileInputs array contains elements that conform to the following JSON schema.

::
  
   "InputSpec": {
       "$comment": "Used to specify file inputs on Jobs submission requests",
       "type": "object",
           "properties": {
               "sourceUrl":  {"type": "string", "minLength": 1, "format": "uri"},
               "targetPath": {"type": "string", "minLength": 0},
               "inPlace":    {"type": "boolean"},
               "meta":       {"type": "object", "$ref": "#/$defs/ArgMetaSpec"}             
           },
       "required": ["sourceUrl"],
       "additionalProperties": false
   }   

Since all input directories or files are staged to the *execSystemInputDir*, the only required field is the *sourceUrl*.  Any URL protocol accepted by the Tapis Files_ service can be used here.  The most common protocols used are tapis, http, and https.  The standard tapis URL format is *tapis://<tapis-system>/<path>*; please see the Files_ service for the complete list of supported protocols.

If provided, the *targetPath* indicates a path relative to the *execSystemInputDir* into which the input is copied.  When not provided, the  directory or file named in *sourceUrl* is copied directly into *execSystemInputDir*. 

The *inPlace* value defaults to false when not provided.  When true, it instructs the Jobs service to **not** copy the input.  This setting is used to indicate that the input has already been put in place in the *execSystemInputDir* subtree by some means outside of Tapis, so no copying is needed.  The use of *inPlace* documents all inputs, even those that do not need to be transferred. 

See the `ArgMetaSpec`_ for a discussion of the *meta* field, which allows one to name the input, designate the input as optional, and attach arbitrary key/value pairs.


.. _Files: https://tapis.readthedocs.io/en/latest/technical/files.html

ParameterSet
------------

The job *parameterSet* argument is comprised of these objects:

================    =====================   ===================================================
Name                JSON Schema Type        Description
================    =====================   =================================================== 
appArgs             `ArgSpec`_ array        Arguments passed to user's application
containerArgs       `ArgSpec`_ array        Arguments passed to container runtime
schedulerOptions    `ArgSpec`_ array        Arguments passed to HPC batch scheduler
envVariables        `KeyValuePair`_ array   Environment variables injected into application container
archiveFilter       object                  File archiving selector
================    =====================   ===================================================

Each of these objects can be specifed in Tapis application definitions and/or in job submission requests.  In addition, the execution system can also specify environment variable settings.

appArgs
^^^^^^^

Specify one or more command line arguments for the user application using the *appArgs* parameter.  Arguments specified in the application definition are appended to those in the submission request.  Metadata can be attached to any argument.

containerArgs
^^^^^^^^^^^^^

Specify one or more command line arguments for the container runtime using the *containerArgs* parameter.  Arguments specified in the application definition are appended to those in the submission request.  Metadata can be attached to any argument.

schedulerOptions
^^^^^^^^^^^^^^^^

Specify HPC batch scheduler arguments for the container runtime using the *schedulerOptions* parameter.  Arguments specified in the application definition are appended to those in the submission request.  The arguments for each scheduler are passed using that scheduler's conventions.  Metadata can be attached to any argument.

envVariables
^^^^^^^^^^^^

Specify key/value pairs that will be injected as environment variables into the application's container when it's launched.  Key/value pairs specified in the execution system definition, application definition, and job submission request are aggregated using precedence ordering (system < app < request) to resolve conflicts.  

archiveFilter
^^^^^^^^^^^^^

The *archiveFilter* conforms to this JSON schema:

::

   "archiveFilter": {
      "type": "object",
      "properties": {
         "includes": {"type": "array", "items": {"type": "string", "minLength": 1}, "uniqueItems": true},
         "excludes": {"type": "array", "items": {"type": "string", "minLength": 1}, "uniqueItems": true},
         "includeLaunchFiles": {"type": "boolean"}
      },
      "additionalProperties": false 
   }

An *archiveFilter* can be specified in the application definition and/or the job submission request.  The *includes* and *excludes* arrays are merged by appending entries from the application definition to those in the submission request.  

The *excludes* filter is applied first, so it takes precedence over *includes*.  If *excludes* is empty, then no output file or directory will be explicitly excluded from archiving.  If *includes* is empty, then all files in *execSystemOutputDir* will be archived unless explicitly excluded.  If *includes* is not empty, then only files and directories that match an entry and not explicitly excluded will be archived.
 
Each *includes* and *excludes* entry is a string, a string with wildcards or a regular expression.  Entries represent directories or files.  The wildcard semantics are that of glob (*), which is commonly used on the command line.  Tapis implements Java glob_ semantics.  To filter using a regular expression, construct the pattern using Java regex_ semantics and then preface it with **REGEX:** (case sensitive).  Here are examples of globs and regular expressions that could appear in a filter: 

::

                  "myfile.*"
                  "*2021-*-events.log"
                  "REGEX:^[\\p{IsAlphabetic}\\p{IsDigit}_\\.\\-]+$"
                  "REGEX:\\s+"

When *includeLaunchFiles* is true (the default), then the script (*tapisjob.sh*) and environment (*tapisjob.env*) files that Tapis generates in the *execSystemExecDir* are also archived.  These launch files provide valuable information about how a job was configured and launched, so archiving them can help with debugging and improve reproducibility.  Since these files may contain application secrets, such database passwords or other credentials, care must be taken to not expose private data through archiving.  

If no filtering is specified at all, then all files in *execSystemOutputDir* and the launch files are archived.

.. _regex: https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/util/regex/Pattern.html

.. _glob: https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob

ExecSystemConstraints
---------------------

Not implementated yet.

Subscriptions
-------------

Not implementated yet.

Shared Components
-----------------

ArgSpec
^^^^^^^

The JSON schema for defining elements in various `ParameterSet`_ components is below.

::

   "ArgSpec": {
       "$comment": "Used to specify parameters on Jobs submission requests",
       "type": "object",
           "properties": {
               "arg":  {"type": "string", "minLength": 1},
               "meta": {"type": "object", "$ref": "#/$defs/ArgMetaSpec"}
           },
       "required": ["arg"],
       "additionalProperties": false
   }

The required *arg* value is an arbitrary string and is used as-is.  See the `ArgMetaSpec`_ for a discussion of the *meta* field, which allows one to name arguments, designate them as optional, and attach arbitrary key/value pairs to them.


ArgMetaSpec
^^^^^^^^^^^

The JSON schema for metadata objects used in `FileInputs`_ and other job parameters is below.

::
 
   "ArgMetaSpec": {
       "$comment": "An open-ended way to name and annotate arguments",
       "type": "object",
           "properties": {
               "description": {"type": "string", "minLength": 1, "maxLength": 8096},
               "name":        {"type": "string", "minLength": 1},
               "required":    {"type": "boolean"},
               "kv":          {"type": "array",
                               "items": {"$ref": "#/$defs/KeyValuePair"},
                               "uniqueItems": true}
           },
        "required": ["name", "required"],
        "additionalProperties": false
   }
   
The *ArgMetaSpec* is always a child its enclosing job parameter.  The *ArgMetaSpec* requires that a name be assigned it parent and that whether the parent parameter is required or not.  Optionally, a description and a map of key/value strings can be included.  The complete *ArgMetaSpec* object is saved in the job, so the key/value pairs can be used to pass arbitrary information to any program that queries the job.  For example, a web application might submit a job request and embed display information in the metadata for use whenever the job is queried. 

KeyValuePair
^^^^^^^^^^^^

The JSON schema for defining key/value pairs of strings in various `ParameterSet`_ components is below.

::

   "KeyValuePair": {
       "$comment": "A simple key/value pair",
       "type": "object",
           "properties": {
               "key":   {"type": "string", "minLength": 1},
               "value": {"type": "string", "minLength": 0}
           },
        "required": ["key", "value"],
        "additionalProperties": false
   }

Both the *key* and *value* are required, though the *value* can be an empty string.


-------------------------------------------------

Job Execution
=============

Environment Variables
---------------------

The following standard environment variables are passed into each application container run by Tapis as long as they have been assigned a value.

::

    _tapisAppId - Tapis app ID 
    _tapisAppVersion - Tapis app version
    _tapisArchiveOnAppError - true means archive even if the app returns a non-zero exit code
    _tapisArchiveSystemDir - the archive system directory on which app output is archived    
    _tapisArchiveSystemId - Tapis system used for archiving app output
    _tapisCoresPerNode - number of cores used per node by app
    _tapisDtnMountPoint - the mountpoint on the execution system for the source DTN directory
    _tapisDtnMountSourcePath - the directory exported by the DTN and mounted on the execution system
    _tapisDtnSystemId - the Data Transfer Node system ID
    _tapisDynamicExecSystem - true if dynamic system selection was used
    _tapisEffeciveUserId - the user ID under which the app runs
    _tapisExecSystemExecDir - the exec system directory where app artifacts are staged
    _tapisExecSystemHPCQueue - the actual batch queue name on an HPC host
    _tapisExecSystemId - the Tapis system where the app runs
    _tapisExecSystemInputDir - the exec system directory where input files are staged
    _tapisExecSystemLogicalQueue - the Tapis queue definition that specifies an HPC queue
    _tapisExecSystemOutputDir - the exec system directory where the app writes its output
    _tapisJobCreateDate - ISO 8601 date, example: 2021-04-26Z
    _tapisJobCreateTime - ISO 8601 time, example: 18:44:55.544145884Z
    _tapisJobCreateTimestamp - ISO 8601 timestamp, example: 2021-04-26T18:44:55.544145884Z
    _tapisJobName - the user-chosen name of the Tapis job
    _tapisJobOwner - the Tapis job's owner
    _tapisJobUUID - the UUID of the Tapis job
    _tapisJobWorkingDir - exec system directory that the app should use for temporary files
    _tapisMaxMinutes - the maximum number of minutes allowed for the job to run
    _tapisMemoryMB - the memory required per node by the app
    _tapisNodes - the number of nodes on which the app runs
    _tapisSysBatchScheduler - the HPC scheduler on the execution system
    _tapisSysBucketName - an object store bucket name
    _tapisSysHost - the IP address or DNS name of the exec system 
    _tapisSysRootDir - the root directory on the exec system
    _tapisTenant - the tenant in which the job runs

Macro Substitution
------------------

Tapis defines macros or template variables that get replaced with actual values at well-defined points during job creation.  The act of replacing a macro with a value is often called macro substitution or macro expansion.  The complete list of Tapis macros can be found at JobTemplateVariables_.  

There is a close relationship between these macro definitions and the Tapis environment variables just discussed:  Macros that have values assigned are passed as environment variables into application containers.  This makes macros used during job creation available to applications at runtime.

Most macro definitions are *ground* definitions because their values do not depend on any other macros.  On the other hand, *derived* macro definitions can include other macro definitions.  For example, in `Directory Assignments`_ we that that the default input file directory is constructed with two macro definitions:

::

   execSystemInputDir = ${jobWorkingDir}/jobs/${jobUUID}

Macro values are referenced using the ${macro-name} notation.  Since derived macro definitions reference other macros, there is the possibility of circular references.  Tapis detects these errors and aborts job creation.  

Below is the complete, ordered list of derived macros.  Each macro in the list can be defined using any ground macro and any macro that preceeds it in the list.  Result are undefined if a derived macro references a macro that follows it in the derived list.

#. JobName
#. JobWorkingDir
#. ExecSystemInputDir
#. ExecSystemExecDir
#. ExecSystemOutputDir
#. ArchiveSystemDir 

Finally, macro substitution is applied to the job *description* field, whether the description is specified in an application or a submission request.   

Macro Functions
^^^^^^^^^^^^^^^

Directory assignments in systems, applications and job requests can also use the **HOST_EVAL($var)** function at the beginning of their path assignments.  This function dynamically extracts the named environment variable's value from an execution or archive host *at the time the job request is made*.  Specifically, the environment variable's value is retrieved by logging into the host as the Job owner and issuing "echo $var".  The example in `Data Transfer Nodes`_ uses this function.

To increase application portability, an optional default value can be passed into the **HOST_EVAL** function.  The function's complete signature with the optional path parameter is:

        **HOST_EVAL($VAR, path)** 

If the environment variable VAR does not exist on the host, then the literal path parameter is returned by the function.  This added flexibility allows applications to run in different environments, such as on TACC HPC systems that automatically expose certain environment variables and VMs that might not.  If the environment variable does not exist and no optional path parameter is provided, the job fails due to invalid input. 


.. _JobTemplateVariables: https://github.com/tapis-project/tapis-java/blob/dev/tapis-jobslib/src/main/java/edu/utexas/tacc/tapis/jobs/model/enumerations/JobTemplateVariables.java


Job Status
----------  

The list below contains all possible states of a Tapis job, which are indicated in the *status* field of a job record.  The initial state is PENDING.  Terminal states are FINISHED, CANCELLED and FAILED.  The BLOCKED state indicates that the job is recovering from a resource constraint, network problem or other transient problem.  When the problem clears, the job will restart from the state in which blocking occurred.  
::

    PENDING - Job processing beginning
    PROCESSING_INPUTS - Identifying input files for staging
    STAGING_INPUTS - Transferring job input data to execution system
    STAGING_JOB - Staging runtime assets to execution system
    SUBMITTING_JOB - Submitting job to execution system
    QUEUED - Job queued to execution system queue
    RUNNING - Job running on execution system
    ARCHIVING - Transferring job output to archive system
    BLOCKED - Job blocked
    PAUSED - Job processing suspended
    FINISHED - Job completed successfully
    CANCELLED - Job execution intentionally stopped
    FAILED - Job failed

Normal processing of a successfully executing job proceeds as follows:      

::

    PENDING->PROCESSING_INPUTS->STAGING_INPUTS->STAGING_JOB->SUBMITTING_JOB->
      QUEUED->RUNNING->ARCHIVING->FINISHED

Notifications
-------------

Not implemented yet.


Dynamic Execution System Selection
----------------------------------

Not implementated yet.

Data Transfer Nodes
-------------------

A Tapis system can be designated as a Data Transfer Node (DTN) as part of its definition.  When an execution system specifies DTN usage in its definition, then the Jobs service will use the DTN to stage input files and archive output files.

The DTN usage pattern is effective when (1) the DTN has high performance network and storage capabilities, and (2) an execution system can mount the DTN's file system.  In this situation, bulk data transfers performed by Jobs benefit from the DTN's high performance capabilities, while applications continue to access their execution system's files as usual.  From an application's point of view, its data are simply where they are expected to be, though they may have gotten there in a more expeditious manner.

DTN usage requires the coordinated configuration of a DTN, an execution system and a job.  In addition, outside of Tapis, a system administrator must mount the exported DTN file system at the expected mountpoint on an execution system.  We use the example below to illustrate DTN configuration and usage.

::

   System: ds-exec
     rootDir: /execRoot
     dtnMountSourcePath: tapis://corral-dtn/
     dtnMountPoint: /corral-repl
     jobWorkingDir: HOST_EVAL($SCRATCH)

   System: corral-dtn
     host: cic-dtn01
     isDtn: true
     rootDir: /gpfs/corral3/repl

   Job Request effective values:
     execSystemId:         ds-exec
     execSystemExecDir:    ${jobWorkingDir}/jobs/${jobUUID} 
     execSystemInputDir:   ${dtnMountPoint}/projects/NHERI/shared/{$jobOwner}/jobs/${jobUUID} 
     execSystemOutputDir:  ${dtnMountPoint}/projects/NHERI/shared/{$jobOwner}/jobs/${jobUUID}/output

   NFS Mount on ds-exec (done outside of Tapis):
     mount -t nfs cic-dtn01:/gpfs/corral3/repl /execRoot/corral-repl

The example execution system, **ds-exec**, defines two DTN related values (both required to configure DTN usage):

**dtnMountSourcePath** 
  The tapis URL specifying the exported DTN path; the path is relative to the DTN system's rootDir (which is just "/" in this example).
**dtnMountPoint**
  The path relative to the execution system's rootDir where the DtnMountSourcePath is mounted.

The execution system's jobWorkingDir is defined to be the runtime value of the $SCRATCH environment variable; its rootDir is defined at /execRoot.

The Tapis DTN system, **corral-dtn**, host machine is cic-dtn01.  The DTN's rootDir (/gpfs/corral3/repl) is the directory prefix used on all mounts.  Mounting takes place outside of Tapis by system administrators.  The actual NFS mount command has this general format:

::

     mount -t nfs <dtn_host>:/<dtn_root_dir>/<path> <exec_system_mount_point>

The Job Request effective values depend on the DTN configuration are also shown.  These values could have been set in the application definition, the job request or in both.  Values set in the job request are given priority.  The execSystemId refers to the **ds-exec** system, which in this case specifies a DTN.

Continuing with the above example, let's say user *Bud* issues an Opensees job request that creates a job with id 123.  The Jobs service will stage the application's input files using the DTN.  The transfer request to the Files_ service will write to this target URL:

          tapis://corral-dtn/gpfs/corral3/repl/projects/NHERI/shared/Bud/jobs/123

This is the standard tapis URL format:  tapis://<tapis-system>/<path>.  After inputs are staged, the Job service will inject this environment variable value (among others) into the launched job's container:

          execSystemInputDir=/corral-repl/projects/NHERI/shared/Bud/jobs/123

Since **ds-exec** mounts the corral root directory, the files staged to corral /gpfs/corral3/repl are accessible at execSystemInputDir on **ds-exec**, relative to rootDir /execRoot. A similar approach would be used to transfer files to an archive system using the DTN, except this time **corral-dtn** is the source of the file transfers rather than the target. 

------------------------------------------------------------

Container Runtimes
==================

Docker
------

Singularity
-----------

tbd

------------------------------------------------------------

Querying Jobs
=============

tbd

------------------------------------------------------------

Job Actions
===========



