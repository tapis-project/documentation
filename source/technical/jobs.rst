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

:red:`*** WORK IN PROGRESS ***`

----

Introduction to Jobs
====================

The Tapis v3 Jobs service is specialized to run containerized applications on any host that supports container runtimes.  Currently, Docker and Singularity containers are supported.  The Jobs service uses the Systems, Apps, Files and Security Kernel services to process jobs.  

Implementation Status
=====================
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
=======================

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
=============================

The POST payload for the simplest job submission request looks like this:

::

    {
     "name": "myJob"
     "appId": "myApp"
     "appVersion": "1.0"
    }

In this example, all input and output directories are either specified in the *myApp* definition or are assigned their default values.  Currently, the execution system on which an application runs must be specified in either the application definition or job request.  Our example assumes that *myApp* assigns the execution system.  Future versions of the Jobs service will support dynamic execution system selection.

An archive system can also be specified in the application or job request; the default is to be the same as the execution system.

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

An execution system may define a *Data Transfer Node* (DTN).  A DTN is a high throughput node used to stage job inputs and to archive job outputs.  The goal is to improve transfer performance.  The execution system mounts the DTN's file system at the *dtnMountPoint* so that executing jobs have access to its data, but Tapis will connect to the DTN rather than the execution system during transfers. 

The directories assigned in application definitions and/or in a job submission requests: 

::

   execSystemExecDir
   execSystemInputDir
   execSystemOutputDir
   archiveSystemDir

Directory Assignments
^^^^^^^^^^^^^^^^^^^^^

The rootDir and jobWorkingDir are always assigned on system creation, so they are always available for use as macros when assigning directories in applications or job submission requests.  

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

ParameterSet
------------

ExecSystemConstraints
---------------------

Subscriptions
-------------


Job Execution
=============

Environment Variables
---------------------

The following standard environment variables are passed into each application container run by Tapis.

::

    _tapisAppId - Tapis app ID 
    _tapisAppVersion - Tapis app version
    _tapisArchiveOnAppError - true means archive even if the app returns a non-zero exit code
    _tapisArchiveSystemDir - the archive system directory on which app output is archived    
    _tapisArchiveSystemId - Tapis system used for archiving app output
    _tapisCoresPerNode - number of cores used per node by app
    _tapisDynamicExecSystem - true if dynamic system selection was used
    _tapisEffeciveUserId - the user ID under which the app runs
    _tapisExecSystemExecDir - the exec system directory where app artifacts are staged
    _tapisExecSystemId - the Tapis system where the app runs
    _tapisExecSystemInputDir - the exec system directory where input files are staged
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
    _tapisSysHost - the IP address or DNS name of the exec system 
    _tapisSysRootDir - the root directory on the exec system
    _tapisTenant - the tenant in which the job runs

Macro Substitution
------------------

Certain fields in the job request and


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





Querying Jobs
=============

Job Actions
===========



