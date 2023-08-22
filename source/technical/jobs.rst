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

================     ======   =======================================   ===========
Name                 Method   UrlPath                                   Status
================     ======   =======================================   ===========
Submit               POST     /submit                                   Implemented
Resubmit             POST     /{JobUUID}/resubmit                       Implemented
\
List                 GET      /list                                     Implemented
Search               GET      /search                                   Implemented
Search               POST     /search                                   Implemented
\
Get                  GET      /{JobUUID}                                Implemented
Get Status           GET      /{JobUUID}/status                         Implemented
Get History          GET      /{JobUUID}/history                        Implemented
Get Output list      GET      /{JobUUID}/output/list/{outputPath}       Implemented
Download Output      GET      /{JobUUID}/output/download/{outputPath}   Implemented
Resubmit Request     GET      /{JobUUID}/resubmit_request               Implemented
\
Cancel               POST      /{JobUUID}/cancel                        Implemented
Hide                 POST      /{JobUUID}/hide                          Implemented
Unhide               POST      /{JobUUID}/unhide                        Implemented
SendEvent            POST      /{JobUUID}/sendEvent                     Implemented
\
Post Share           POST      /{JobUUID}/share                         Implemented
Get Share            GET       /{JobUUID}/share                         Implemented
Delete Share         DELETE    /{JobUUID}/share/{user}                  Implemented
\
Health Check         GET       /healthcheck                             Implemented
Ready                GET       /ready                                   Implemented
Hello                GET       /hello                                   Implemented
================     ======   =======================================   ===========


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

An archive system can also be specified in the application or job request; the default is for it to be the same as the execution system.

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
**jobType**
  A job's type can be either FORK or BATCH.
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
**fileInputArrays**
  Arrays of input files that need to be staged for the application.  *InheritMerge*.
**parameterSet**
  Runtime parameters organized by category.  *Inherit*.
**execSystemConstraints**
  Constraints applied against execution system capabilities to validate application/system compatibility. *InheritMerge*.
**subscriptions**
  Subscribe to the job's events.  *InheritMerge*.
**tags**
  An array of user-chosen strings that are associated with a job.  *InheritMerge*.
**notes**
  A JSON object containing any user-chosen data.  *Inherit*.
**isMpi**
  Indicates whether this job is an MPI job.  *Inherit*, default is false.
**mpiCmd**
  Specify the MPI launch command.  Conflicts with cmdPrefix if isMpi is set.  *Inherit*.
**cmdPrefix**
  String prepended to the application invocation command.  Conflicts with mpiCmd if isMpi is set.  *Inherit*.
**notes**
  Optional JSON object containing arbitrary user data, maximum length 65536 bytes.  *Inherit*.

The following subsections discuss the meaning and usage of each of the parameters available in a job request.  The schema_ and its referenced library_ comprise the actual JSON schema definition for job requests.

..  _schema: https://github.com/tapis-project/tapis-jobs/blob/dev/tapis-jobsapi/src/main/resources/edu/utexas/tacc/tapis/jobs/api/jsonschema/SubmitJobRequest.json

..  _library: https://github.com/tapis-project/tapis-shared-java/blob/dev/tapis-shared-lib/src/main/resources/edu/utexas/tacc/tapis/shared/jsonschema/defs/TapisDefinitions.json

Parameter Precedence
--------------------

The runtime environment of a Tapis job is determined by values in system definitions, the app definition and the job request, in low to high precedence order as listed.  Generally speaking, for values that can be assigned in multiple definitions, the values in job requests override those in app definitions, which override those in system definitions.  There are special cases, however, where the values from different definitions are merged.

See the jobs/apps/systems parameter matrix_ for a detailed description of how each parameter is handled.

.. _matrix: https://drive.google.com/file/d/1BrY6tHzOegwsgDMrhcKE7RHH7HRAA0Do/view?usp=sharing


Job Type
--------

An execution system can run jobs using a batch scheduler (e.g., Slurm or Condor) or a native runtime (e.g., Docker or Singularity) or both.  Users specify how to run a job using the *jobType* parameter, which is set to "BATCH" to use a batch scheduler or "FORK" to use a native runtime.  The jobType can also be specified in application definitions.  The final value assigned to the jobType of a job is calculated as follows:

::

    1. If the user specifies jobType in the job request, use it.
    2. Otherwise, if the app.jobType != null, use it.
    3. Otherwise, query the execution system and set jobType=BATCH if execSys.canRunBatch==true.
    4. Otherwise, set jobType=FORK.

Directories
-----------

The execution and archive system directories are calculated before the submission response is sent.  This calculation can include the use of macro definitions that get replaced by values at submission request time.  The `Macro Substitution`_ section discusses what macro definitions are available and how substitution works.  In this section, we document the default directory assignments which may include macro definitions.

.. _dir-definitions:


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
     execSystemExecDir:    ${JobWorkingDir}/jobs/${JobUUID}
     execSystemInputDir:   ${JobWorkingDir}/jobs/${JobUUID}
     execSystemOutputDir:  ${JobWorkingDir}/jobs/${JobUUID}/output
     archiveSystemDir:     /jobs/${JobUUID}/archive                 (if archiveSystemId is set)
   DTN defined:
     execSystemExecDir:    ${DtnMountPoint}/jobs/${JobUUID}
     execSystemInputDir:   ${DtnMountPoint}/jobs/${JobUUID}
     execSystemOutputDir:  ${DtnMountPoint}/jobs/${JobUUID}/output
     archiveSystemDir:     ${DtnMountPoint}/jobs/${JobUUID}/archive (if archiveSystemId is set)

FileInputs
----------

The *fileInputs* in Applications_ definitions are merged with those in job submission requests to produce the complete list of inputs to be staged for a job.  The following rules govern how job inputs are calculated.

 1. The effective inputs to a job are the combined inputs from the application and job request.
 2. Only named inputs are allowed in application definitions.
 3. Application defined inputs are either REQUIRED, OPTIONAL or FIXED.
 4. Applications can restrict the number and definitions of inputs (*strictFileInputs=true*).
 5. Anonymous (unnamed) inputs can be specified in the job request unless prohibited by the application definition (*strictFileInputs=true*).
 6. Job request inputs override values set in the application except for FIXED inputs.
 7. The *tapislocal* URL scheme specifies in-place inputs for which transfers are not performed.

The fileInputs array in job requests contains elements that conform to the following JSON schema.

::

   "JobFileInput": {
       "$comment": "Used to specify file inputs on Jobs submission requests",
       "type": "object",
           "properties": {
               "name": { "type": "string", "minLength": 1, "maxLength": 80 },
               "description": { "type": "string", "minLength": 1, "maxLength": 8096 },
               "autoMountLocal": { "type": "boolean"},
               "sourceUrl":  {"type": "string", "minLength": 1, "format": "uri"},
               "targetPath": {"type": "string", "minLength": 0},
               "notes": {"type": "string", "minLength": 0}
           },
       "additionalProperties": false
   }

JobFileInputs can be named or unnamed.  When the *name* field is assigned, Jobs will look for an input with the same name in the application definition (all application inputs are named).  When a match is found, values from the AppFileInput are merged into unassigned fields in the JobFileInput.

The *name* must start with an alphabetic character or an underscore (_) followed by zero or more alphanumberic or underscore characters.  If the name does not match one of the input names defined in the application, then the application must have *strictFileInputs=false*.  If the name matches an input name defined in the application, then the application's inputMode must be REQUIRED or OPTIONAL.  An error occurs if the inputMode is FIXED and there is a name match--job inputs cannot override FIXED application inputs.

The optional *notes* field can contain any valid user-specified JSON object. 

Except for in-place inputs discussed below, the *sourceUrl* is the location from which data are copied to the *targetPath*.  In Posix systems the sourceUrl can reference a file or a directory.  When a directory is specified, the complete directory subtree is copied.

Any URL protocol accepted by the Tapis Files_ service can be used in a *sourceUrl*.  The most common protocols used are tapis, http, and https.  The standard tapis URL format is *tapis://<tapis-system>/<path>*; please see the Files_ service for the complete list of supported protocols.

The *targetPath* is the location to which data are copied from the *sourceUrl*.  The target is rooted at the *execSystemInputDir* except, possibly, when HOST_EVAL() is used, in which case it is still relative to the execution system's rootDir.

A JobFileInput object is **complete** when its *sourceUrl* and *targetPath* are assigned; this provides the minimal information needed to effect a transfer.  If only the *sourceUrl* is set, Jobs will use the simple directory or file name from the URL to automatically assign the *targetPath*.  Specifying a *targetPath* as "*" results in the same automatic assignment.  Whether assigned by the user or Jobs, all job inputs that are not in-place and do not use the HOST_EVAL() function are copied into the *execSystemInputDir* subtree.

After application inputs are added to or merged with job request inputs, all complete JobFileInput objects are designated for staging.  Incomplete objects are ignored only if they were specified as OPTIONAL in the application definition.  Otherwise, an incomplete input object causes the job request to be rejected.


In-Place Inputs (tapislocal)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Job inputs already present on an execution system do not need to be transferred, yet users may still want to declare them for documentation purposes or to control how they are mounted into containers.  It's common, for example, for large data sets that cannot reasonably be copied to be mounted directly onto execution systems.  The Jobs and Applications services provide custom syntax that allows such input to be declared, but instructs the Jobs service to **not** copy that input.

Tapis introduces a new URL scheme, *tapislocal*, that is only recognized by the Applications and Jobs services.  Here are example URLs:

::

    tapislocal://exec.tapis/home/bud/mymri.dcm
    tapislocal://exec.tapis/corral/repl/shared

Like the *tapis* scheme and all common schemes (https, sftp, etc.), the first segment following the double slashes designates a host.  For *tapislocal*, the host is always the literal **exec.tapis**, which serves as a placeholder for a job's execution system.  The remainder of the URL is the path on the Tapis system.  All paths on Tapis systems, including those using the HOST_EVAL() function and the tapislocal URL, are rooted at the Tapis system's rootDir.

A *tapislocal* URL can only appear in the sourceUrl field of AppFileInput and JobFileInput parameters.

The *tapislocal* scheme indicates to Jobs that a filepath already exists on the execution system and, therefore, does not require data transfer during job execution.  If targetPath is "*", the Jobs service will assign the target path inside the container to be the last segment of the tapislocal URL path (/mymri.dcm and /shared in the examples above).

In container systems that require the explicit mounting of host filepaths, such as Docker, the Jobs service can mount the filepath into the container.  Both application definitions and job requests support the *autoMountLocal* boolean parameter.  This parameter is true by default, which causes Jobs to automatically mount the filepath into containers.  Setting autoMountLocal to false allows the user complete control over mounting using a *containerArgs* parameter.


.. _Files: https://tapis.readthedocs.io/en/latest/technical/files.html

.. _Systems: https://tapis.readthedocs.io/en/latest/technical/systems.html

.. _Applications: https://tapis.readthedocs.io/en/latest/technical/apps.html


FileInputArrays
---------------

The *fileInputArrays* parameter provides an alternative syntax for specifying inputs in Applications_ and job requests.  This syntax is convenient for specifying multiple inputs destined for the same target directory, an I/O pattern sometimes refered to as *scatter-gather*.  Generally, input arrays support the same semantics as FileInputs_ with some restrictions.

The fileInputArrays parameter in job requests contains elements that conform to the following JSON schema.

::

   "JobFileInputArray": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
            "name": { "type": "string", "minLength": 1, "maxLength": 80 },
            "description": { "type": "string", "minLength": 1, "maxLength": 8096},
            "sourceUrls": { "type": ["array", "null"],
                            "items": { "type": "string", "format": "uri", "minLength": 1 } },
            "targetDir": { "type": "string", "minLength": 1 },
            "notes": {"type": "string", "minLength": 0}
        }
   }

A fileInputArrays parameter is an array of JobFileInputArray objects, each of which contains an array of *sourceUrls* and a single *targetDir*.  One restriction is that *tapislocal* URLs cannot appear in *sourceUrls* fields.

An application's fileInputArrays are added to or merged with those in a job request following the same rules established for fileInputs in the previous section.  In particular, when names match, the *sourceUrls* defined in a job request override (i.e., completely replace) those defined in an application.  After merging, each JobFileInputArray must have a non-empty *sourceUrls* array.  See FileInputs_ and Applications_ for related information.

Each *sourceUrls* entry is a location from which data is copied to the *targetDir*.  In Posix systems each URL can reference a file or a directory.  In the latter case, the complete directory subtree is transferred.  All URLs recognized by the Tapis Files_ service can be used (*tapislocal* is not recognized by Files).

The *targetDir* is the directory into which all *sourceUrls* are copied.  The *targetDir* is always rooted at the *ExecSystemInputDir* and if *targetDir* is "*" or not specified, then it is assigned *ExecSystemInputDir*.  The simple name of each *sourceUrls* entry is the destination name used in *targetDir*.  Use different JobFileInputArrays with different targetDir's if name conflicts between *sourceUrls* entries exist.

The optional *notes* field can contain any valid user-specified JSON object.


ParameterSet
------------

The job *parameterSet* argument is comprised of these objects:

================    =====================   ===================================================
Name                JSON Schema Type        Description
================    =====================   ===================================================
appArgs             `JobArgSpec`_ array     Arguments passed to user's application
containerArgs       `JobArgSpec`_ array     Arguments passed to container runtime
schedulerOptions    `JobArgSpec`_ array     Arguments passed to HPC batch scheduler
envVariables        `KeyValuePair`_ array   Environment variables injected into application container
archiveFilter       object                  File archiving selector
logConfig           `LogConfig`_            User-specified stdout and stderr redirection
================    =====================   ===================================================

Each of these objects can be specifed in Tapis application definitions and/or in job submission requests.  In addition, the execution system can also specify environment variable settings.

appArgs
^^^^^^^

Specify one or more command line arguments for the user application using the *appArgs* parameter.  Arguments specified in the application definition are appended to those in the submission request.

containerArgs
^^^^^^^^^^^^^

Specify one or more command line arguments for the container runtime using the *containerArgs* parameter.  Arguments specified in the application definition are appended to those in the submission request.

schedulerOptions
^^^^^^^^^^^^^^^^

Specify HPC batch scheduler arguments for the container runtime using the *schedulerOptions* parameter.  Arguments specified in the application definition are appended to those in the submission request.  The arguments for each scheduler are passed using that scheduler's conventions.

Tapis defines a special scheduler option, **--tapis-profile**, to support local scheduler conventions.  Data centers sometimes customize their schedulers or restrict how those schedulers can be used.  The Systems_ service manages *SchedulerProfile* resources that are separate from any system definition, but can be referenced from system definitions.  The Jobs service uses directives contained in profiles to tailor application execution to local requirements.

As an example, below is the JSON input used to create the TACC scheduler profile.  The *moduleLoads* array contains one or more objects. Each object contains a *moduleLoadCommand*, which specifies the local command used to load each of the modules (in order) in its *modulesToLoad* list.  *hiddenOptions* identifies scheduler options that the local implementation prohibits.  In this case, "MEM" indicates that the *--mem* option should never be passed to Slurm.

::

    {
        "name": "TACC",
        "owner": "user1",
        "description": "Test profile for TACC Slurm",
        "moduleLoads": [
            {
                "moduleLoadCommand": "module load",
                "modulesToLoad": ["tacc-singularity"]
            }
        ],
        "hiddenOptions": ["MEM"]
    }

**Scheduler-Specific Processing**

Jobs will perform `macro-substitution`_ on Slurm scheduler options *--job-name* or *-J*.  This substitution allows Slurm job names to be dynamically generated before submitting them.

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

logConfig Spec
^^^^^^^^^^^^^^

A `LogConfig`_ can be supplied in the job submission request and/or in the application definition, with the former overriding the latter when both are supplied.  In supported runtimes (currently Singularity), the *logConfig* parameter can be used to redirect the application container's stdout and stderr to user-specified files.





.. _regex: https://docs.oracle.com/en/java/javase/15/docs/api/java.base/java/util/regex/Pattern.html

.. _glob: https://docs.oracle.com/javase/tutorial/essential/io/fileOps.html#glob

MPI and Related Support
-----------------------

On many systems, running Message Passing Interface (MPI) jobs is simply a matter of launching programs that have been configured or compiled with the proper MPI libraries.  Most of the work in employing MPI involves parallelizing program logic and specifying the correct libraries for the target execution system.  Once that's done, a command such as *mpirun* (or on TACC systems, *ibrun*) is passed the program's pathname and arguments to kick off parallel execution.

Tapis's *mpiCmd* parameter lets users set the MPI launch command in a system definition, application definition and/or job submission request (lowest to highest priority).  For example, if *mpiCmd=mpirun*, then the string "mpirun " will be prepended to the command normally used to execute the application.  Some MPI launchers have their own parameters, for instance, *mpiCmd=ibrun -n 4* requests 4 MPI tasks.

The *isMpi* parameter is specified in an application definition and/or job request to toggle MPI launching on or off.  This switch allows the same system to run both MPI and non-MPI jobs depending on the needs of particular jobs or applications.  The *isMpi* default is false, so this switch must be explicitly turned on to run an MPI job.  When turned on, *isMpi* requires *cmdMpi* be assigned in the system, application and/or job request.

The *cmdPrefix* parameter provides generalized support for launchers and is available in application definitions and job submission requests.  Like *mpiCmd*, a *cmdPrefix* value is simply prepended to a program's pathname and arguments.  Being more general, *cmdPrefix* could specify an MPI launcher, but it's not supported in system definitions and does not have a toggle to control usage.

*mpiCmd* and *cmdPrefix* are mutually exclusive; so if *isMpi* is true, then *cmdPrefix* must not be set.


ExecSystemConstraints
---------------------

Not implementated yet.

Subscriptions
-------------

Users can subscribe to job execution events.  Subscriptions specified in the application definition and those specified in the job request are merged to produce a job's initial subscription list.  New subscriptions can be added while a job is running, but not after the job has terminated.  A job's subscriptions can be listed and deleted.  Only job owners or tenant administrators can subscribe to a job, see the subscription_ APIs for details.

When creating a subscription the *ttlminutes* parameter can specify up to 4 weeks.  If the parameter is not specified or if it's set to 0, a default value of 1 week is used.

Subscribers are notified of job events by the Notifications_ service.  Currently, only email and webhook delivery methods are supported.  The event types to which users can subscribe are:

===========================    ===================================================
Event Type                     Description
===========================    ===================================================
JOB_NEW_STATUS                 When the job transitions to a new status
JOB_INPUT_TRANSACTION_ID       When an input file staging request is made
JOB_ARCHIVE_TRANSACTION_ID     When an archive file transfer request is made
JOB_SUBSCRIPTION               When a change to the job's subscriptions is made
JOB_SHARE_EVENT                When a job resource has been shared or unshared
JOB_ERROR_MESSAGE              When the job experienced an error
JOB_USER_EVENT                 When a user sends the job a custom event
ALL                            When any of the above occur
===========================    ===================================================

All event types other than JOB_USER_EVENT are generated by Tapis. See `Notification Messages`_ for a description of what Jobs returns for each of the Tapis-generated event.

A JOB_USER_EVENT contains a user-specified payload that can be sent to an active job using the job's UUID.  The payload must contain a JSON key named *eventData* and a string value of at least 1 character and no more than 16,384 characters.  The string can be unstructured or structured (such as a JSON object) as determined by the sender. The payload can optionally contain an *eventDetail* key with a string value of no more than 64 characters. This key is used to further categorize events and, if not provided, will default to "DEFAULT".  User events are always added to the job history and notifications are sent to subscribers interested in those events.

.. _subscription: https://tapis-project.github.io/live-docs/?service=Jobs#tag/subscriptions

.. _Notifications: https://tapis-project.github.io/live-docs/?service=Notifications

Shared Components
-----------------

JobArgSpec
^^^^^^^^^^

Simple argument strings can be specified in application definitions (AppArgSpec) and in job submission requests (JobArgSpec).  These argument strings are passed to specific components in the runtime system, such as the batch scheduler (schedulerOptions_), the container runtime (containerArgs_) or the user's application (appArgs_).

The following rules govern how job arguments are calculated.

 1. All argument in application definitions must be named.
 2. Application arguments are either REQUIRED, FIXED or one of two optional types.
 3. Anonymous (unnamed) argument can be specified in job requests.
 4. Job request argument override values set in the application except for FIXED arguments.
 5. The final argument ordering is the same as the order specified in the definitions, with application arguments preceding those from the job request.  Application arguments maintain their place even when overridden in the job request.
 6. The notes field can be any JSON object, i.e., JSON that begins with a brace ("{").

We define a **complete** AppArgSpec as one that has a non-empty name and arg value.  We define a **complete** JobArgSpec as one that has a non-empty arg value.  A JobArgSpec with the same name as an AppArgSpec inherits from the application and may override the AppArgSpec values.

This is the JSON schema used to define runtime arguments in `ParameterSet`_.

::

   "JobArgSpec": {
       "$comment": "Used to specify parameters on Jobs submission requests",
       "type": "object",
           "properties": {
               "name": { "type": "string", "minLength": 1, "maxLength": 80 },
               "description": { "type": "string", "minLength": 1, "maxLength": 8096 },
               "include": { "type": "boolean" },
               "arg":  {"type": "string", "minLength": 1},
               "notes": {"type": object}
           },
       "required": ["arg"],
       "additionalProperties": false
   }

As mentioned, the JobArgSpec is used in conjunction with the AppArgSpec defined in Applications_.  Arguments in application definitions are merged into job request arguments using the same name matching alorithm as in `FileInputs`_.

The *name* identifies the input argument.  If present, the name must start with an alphabetic character or an underscore (_) followed by zero or more alphanumeric or underscore characters.

The *description* is used to convey usage information to job requester.  If both application and request descriptions are provided, then the request description is appended as a separate paragraph to the application description.

The required *arg* value is an arbitrary string and is used as-is.  If this argument's name matches that of an application argument, this *arg* value overrides the application's value except when *inputMode=FIXED* in the application.

The *include* field applies only on named arguments that are also defined in the application definition with *inputMode* INCLUDE_ON_DEMAND or INCLUDE_BY_DEFAULT; this parameter is ignored on all other inputModes.  Argument inclusion is discussed in greater detail in following subsection.

Argument Processing
~~~~~~~~~~~~~~~~~~~

Applications_ use their AppArgSpecs to pass default values to job requests.  The AppArgSpec's *inputMode* determines how to handle arguments during job processing.  An *inputMode* field can have these values:

REQUIRED
   The argument must be provided for the job to run.  If an arg value is not specified in the application       definition, then it must be specified in the job request.  When provided in both, the job request arg value overrides the one in application.

FIXED
   The argument is completely defined in the application and not overridable in a job request.

INCLUDE_ON_DEMAND
   The argument, if complete, will only be included in the final argument list constructed by Jobs if it's explicitly referenced and included in the Job request.  This is the default value.

INCLUDE_BY_DEFAULT
    The argument, if complete, will automatically be included in the final argument list constructed by Jobs unless explicitly excluded in the Job request.

The truth table below defines how the AppArgSpec's *inputMode* and JobArgSpec's *include* settings interact to determine whether an argument is accepted or ignored during job processing.

+--------------------+-------------+-------------+
| AppArgSpec         | JobArgSpec  | Meaning     |
| *inputMode*        | *include*   |             |
+====================+=============+=============+
| INCLUDE_ON_DEMAND  | True        | include arg |
+--------------------+-------------+-------------+
| INCLUDE_ON_DEMAND  | False       | exclude arg |
+--------------------+-------------+-------------+
| INCLUDE_ON_DEMAND  | undefined   | include arg |
+--------------------+-------------+-------------+
| INCLUDE_BY_DEFAULT | True        | include arg |
+--------------------+-------------+-------------+
| INCLUDE_BY_DEFAULT | False       | exclude arg |
+--------------------+-------------+-------------+
| INCLUDE_BY_DEFAULT | undefined   | include arg |
+--------------------+-------------+-------------+

The JobArgSpec *include* value has no effect on REQUIRED or FIXED arguments.  In the cases where the value does apply, not specifying *include* in a named JobArgSpec that matches an AppArgSpec is effectively the same as setting *include=True*.  By setting *include=False*, a JobArgSpec can exclude any INCLUDE_ON_DEMAND or INCLUDE_BY_DEFAULT arguments.

KeyValuePair
^^^^^^^^^^^^

The JSON schema for defining key/value pairs of strings in various `ParameterSet`_ components is below.

::

   "KeyValuePair": {
       "$comment": "A simple key/value pair",
       "type": "object",
           "properties": {
               "key":   {"type": "string", "minLength": 1},
               "value": {"type": "string", "minLength": 0},
               "description": {"type": "string", "minLength": 1, "maxLength": 2048}
           },
        "required": ["key", "value"],
        "additionalProperties": false
   }

Both the *key* and *value* are required, though the *value* can be an empty string.  Descriptions are optional.

LogConfig
^^^^^^^^^

The JSON schema for used to redirect stdout and stderr to named file(s) in supported runtimes.  

::

   "logConfig": {
       "$comment": "Log file redirection and customization in supported runtimes",
       "type": "object",
       "required": [ "stdoutFilename", "stderrFilename" ],
       "additionalProperties": false,
           "properties": {
               "stdoutFilename": {"type": "string", "minLength": 1},
               "stderrFilename": {"type": "string", "minLength": 1}
           }
   }

Currently, only the Singularity (Apptainer) runtime is supported.  

When specified, both file name fields must be explicitly assigned, though they can be assigned to the same file.  If a *logConfig* object is not specified, or in runtimes where it's not supported, then both stdout and stderr are directed to the default **tapisjob.out** file in the job's output directory.  Output files, even when *logConfig* is used, are always relative to the ExecSystemOuputDir (see `Directory Definitions`_).

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

.. _macro-substitution:

Macro Substitution
------------------

Tapis defines macros or template variables that get replaced with actual values at well-defined points during job creation.  The act of replacing a macro with a value is often called macro substitution or macro expansion.  The complete list of Tapis macros can be found at JobTemplateVariables_.

There is a close relationship between these macro definitions and the Tapis environment variables just discussed:  Macros that have values assigned are passed as environment variables into application containers.  This makes macros used during job creation available to applications at runtime.

Most macro definitions are *ground* definitions because their values do not depend on any other macros.  On the other hand, *derived* macro definitions can include other macro definitions.  For example, in `Directory Assignments`_ the default input file directory is constructed with two macro definitions:

::

   execSystemInputDir = ${JobWorkingDir}/jobs/${JobUUID}

Macro values are referenced using the ${Macro-name} notation.  Since derived macro definitions reference other macros, there is the possibility of circular references.  Tapis detects these errors and aborts job creation.

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


.. _JobTemplateVariables: https://github.com/tapis-project/tapis-jobs/blob/dev/tapis-jobslib/src/main/java/edu/utexas/tacc/tapis/jobs/model/enumerations/JobTemplateVariables.java


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

Notification Messages
---------------------

Notifications are the messages sent to subscribers who have registered interest in certain job events.  See Subscriptions_ for an introduction to the different event types and a discussion of JOB_USER_EVENT content.  In this section, we specify the messages sent to subscribers for Jobs-generated events.

For events generated by the Jobs service, the *data* field in notification messages received by subscribers contains a JSON object that always include these fields:

- *jobName* - the user-specified job name
- *jobOwner* - the user who submitted the job
- *jobUuid* - the unique job ID
- *message* - a human readable message

Each of the Job event types also include additional fields as shown:

+--------------------------+-----------------------------------+
| Job Event Type           | Additional Fields                 |
+==========================+===================================+
|JOB_NEW_STATUS            | newJobStatus, oldJobStatus        |
+--------------------------+-----------------------------------+
|JOB_INPUT_TRANSACTION_ID  | transferStatus, transactionId     |
+--------------------------+-----------------------------------+
|JOB_ARCHIVE_TRANSACTION_ID| transferStatus, transactionId     |
+--------------------------+-----------------------------------+
|JOB_SUBSCRIPTION          | action, numSubscriptions          |
+--------------------------+-----------------------------------+
|JOB_SHARE_EVENT           | resourceType, shareType,          |
|                          | grantee, grantor                  |
+--------------------------+-----------------------------------+
|JOB_ERROR_MESSAGE         | jobStatus                         |
+--------------------------+-----------------------------------+

Additionally, when either of these conditions hold:

1. JOB_NEW_STATUS messages indicate a **terminal** *newJobStatus*, or
2. JOB_ERROR_MESSAGE messages have *eventDetail* = "FINAL_MESSAGE",

then the following additional fields are included in the notification:

- *blockedCount* - the number of times the job blocked (JSON number)
- *remoteJobId* - execution system job id (ex: pid, slurm id, docker hash, etc.)
- *remoteJobId2* - execution system auxilliary id associated with a job
- *remoteOutcome* - FINISHED, FAILED, FAILED_SKIP_ARCHIVE
- *remoteResultInfo* - application exit code
- *remoteQueue* - execution system scheduler queue
- *remoteSubmitted* - time job was submitted on remote system
- *remoteStarted* - time job started running on remote system
- *remoteEnded* - time job stopped running on remote system

Job terminal statuses are FINISHED, CANCELLED and FAILED.

..  _Subscriptions: #subscriptions


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
     execSystemExecDir:    ${JobWorkingDir}/jobs/${JobUUID}
     execSystemInputDir:   ${DtnMountPoint}/projects/NHERI/shared/${JobOwner}/jobs/${JobUUID}
     execSystemOutputDir:  ${DtnMountPoint}/projects/NHERI/shared/${JobOwner}/jobs/${JobUUID}/output

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

The Tapis v3 Jobs service currently supports Docker and Singularity containers run natively (i.e., not run using a batch scheduler like Slurm).  In general, Jobs launches an application's container on a remote system, monitors the container's execution, and captures the application's exit code after it terminates.  Jobs uses SSH to connect to the execution system to issue Docker, Singularity or native operating system commands.

To launch a job, the Jobs service creates a bash script, **tapisjob.sh**, with the runtime-specific commands needed to execute the container.  This script references **tapisjob.env**, a file Jobs creates to pass environment variables to application containers.  Both files are staged in the job's execSystemExecDir and, by default, are archived with job output on the archive system.  See `archiveFilter`_ to override this default behavior, especially if archives will be shared and the scripts pass sensitive information into containers.

Docker
------

To launch a Docker container, the Jobs service will SSH to the target host and issue a command using this template:

::

   docker run [docker options] image[:tag|@digest] [application args]

#. docker options:  (optional) user-specified arguments passed to docker
#. image:  (required) user-specified docker application image
#. application arguments:  (optional) user-specified command line arguments passed to the application

The docker run-command_ options *--cidfile*, *-d*, *-e*, *--env*, *--name*, *--rm*, and *--user* are reserved for use by Tapis.  Most other Docker options are available to the user.  The Jobs service implements these calling conventions:

#. The container name is set to the job UUID.
#. The container's user is set to the user ID used to establish the SSH session.
#. The container ID file is specified as *<JobUUID>.cid* in the execSystemExecDir, i.e., the directory from which the container is launched.
#. The container is removed after execution using the *-rm* option or by calling *docker rm*.

Logging
^^^^^^^

Logging should be considered up front when defining Tapis applications to run under Docker.  Since Jobs removes Docker containers after they execute, the container's log is lost under the default Docker logging_ configuration.  Typically, Docker pipes *stdout* and *stderr* to the container's log, which requires the application to take deliberate steps to preserve these outputs.

An application can maintain control over its log output by logging to a file outside of the container.  The application can do this by redirecting *stdout* and *stderr* or by explicitly writing to a file.  As discussed in `dir-definitions`_, the application always has read/write access to the host's *execSystemOutputDir*, which is mounted at /TapisOutput in the container (see next section).

On the other hand, applications can run on machines where the default Docker log driver is configured to write to files or services outside of containers.  In addition, Tapis passes any user-specified *log-driver* and *log-opts* options to *docker run*, so all customizations_ supported by Docker are possible.


Volume Mounts
^^^^^^^^^^^^^

In addition to the above conventions, bind_ mounts are used to mount the execution system's standard Tapis directories at the same locations in every application container.

::

   execSystemExecDir   on host is mounted at /TapisExec in the container.
   execSystemInputDir  on host is mounted at /TapisInput in the container.
   execSystemOutputDir on host is mounted at /TapisOutput in the container.

.. _bind: https://docs.docker.com/storage/bind-mounts/
.. _run-command: https://docs.docker.com/engine/reference/commandline/run/
.. _logging: https://docs.docker.com/config/containers/logging/
.. _customizations: https://docs.docker.com/config/containers/logging/configure/

Singularity
-----------

Tapis provides two distinct ways to launch a Singularity containers, using *singluarity instance start* or *singularity run*.

Singularity Start
^^^^^^^^^^^^^^^^^

Singularity's support for detached processes and services is implemented natively by its instance start_, stop_ and list_ commands.  To launch a container, the Jobs service will SSH to the target host and issue a command using this template:

::

   singularity instance start [singularity options] <image id> [application arguments] <job uuid>

where:

#. singularity options:  (optional) user-specified argument passed to singularity start
#. image id:  (required) user-specified singularity application image
#. application arguments:  (optional) user-specified command line arguments passed to the application
#. job uuid:  the job uuid used to name the instance (always set by Jobs)

The singularity options *--pidfile*, *--env* and *--name* are reserved for use by Tapis.  Users specify the environment variables to be injected into their application containers via the `envVariables`_ parameter.  Most other singularity options are available to users.

Jobs will then issue *singularity instance list* to obtain the container's process id (PID).  Jobs determines that the application has terminated when the PID is no longer in use by the operating system.

By convention, Jobs will look for a **tapisjob.exitcode** file in the Job's output directory after containers terminate.  If found, the file should contain only the integer code the application reported when it exited.  If not found, Jobs assumes the application exited normally with a zero exit code.

Finally, Jobs issues a *singularity instance stop <job uuid>* to clean up the singularity runtime environment and terminate all processes associated with the container.

.. _start: https://sylabs.io/guides/3.7/user-guide/cli/singularity_instance_start.html
.. _stop: https://sylabs.io/guides/3.7/user-guide/cli/singularity_instance_stop.html
.. _list: https://sylabs.io/guides/3.7/user-guide/cli/singularity_instance_list.html

Singularity Run
^^^^^^^^^^^^^^^

Jobs also supports a more do-it-yourself approach to running containers on remote system using singularity run_.  To launch a container, the Jobs service will SSH to the target host and issue a command using this template:

::

   nohup singularity run [singularity options.] <image id> [application arguments] > tapisjob.out 2>&1 &

where:

#. nohup_:  allows the background process to continue running even if the SSH session ends.
#. singularity options:  (optional) user-specified arguments passed to singularity run.
#. image id:  (required) user-specified singularity application image.
#. application arguments:  (optional) user-specified command line arguments passed to the application.
#. redirection:  stdout and stderr are redirected to **tapisjob.out** in the job's output directory.

The singularity *--env* option is reserved for use by Tapis.  Users specify the environment variables to be injected into their application containers via the `envVariables`_ parameter.  Most other singularity options are available to users.

Jobs will use the PID returned when issuing the background command to monitor the container's execution.  Jobs determines that the application has terminated when the PID is no longer in use by the operating system.

Jobs uses the same **TapisJob.exitcode** file convention introduced above to attain the application's exit code (if the file exists).

.. _run: https://sylabs.io/guides/3.7/user-guide/cli/singularity_run.html
.. _nohup: https://en.wikipedia.org/wiki/Nohup

Required Scripts
^^^^^^^^^^^^^^^^

The Singularity Start and Singularity Run approaches boath allow SSH sessions between Jobs and execution hosts to end without interrupting container execution.  Each approach, however, requires that the application image be appropriately constructed.  Specifically,

::

   Singularity start requires the startscript to be defined in the image.
   Singularity run requires the runscript to be defined in the image.

Required Termination Order
^^^^^^^^^^^^^^^^^^^^^^^^^^

Since Jobs monitors container execution by querying the operating system using the PID obtained at launch time, the initially launched program should be the last part of the application to terminate.  The program specified in the image script can spawn any number of processes (and threads), but it should not exit before those processes complete.

Optional Exit Code Convention
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Applications are not required to support the **TapisJob.exitcode** file convention as described above, but it is the only way in which Jobs can report the application specified exit status to the user.


------------------------------------------------------------

Querying Jobs
=============

Get Jobs list
---------------

With PySDK:

.. code-block:: text

        $ t.jobs.getJobList(limit=2, orderBy='lastUpdated(desc),name(asc)', computeTotal=True)


With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/list?limit=2&orderBy=lastUpdated(desc),name(asc)&computeTotal=true

The response will look something like the following:

::

    {
    "result": [
        {
            "uuid": "731b65f4-43e9-4a7a-b3a0-68644b53c1cb-007",
            "name": "SyRunSleepSecondsNoIPFiles-2",
            "owner": "testuser2",
            "appId": "SyRunSleepSecondsNoIPFiles-2",
            "created": "2021-07-21T19:56:02.163984Z",
            "status": "FINISHED",
            "remoteStarted": "2021-07-21T19:56:18.628448Z",
            "ended": "2021-07-21T19:56:52.637554Z",
            "tenant": "dev",
            "execSystemId": "tapisv3-exec2",
            "archiveSystemId": "tapisv3-exec2",
            "appVersion": "0.0.1",
            "lastUpdated": "2021-07-21T19:56:52.637554Z"
        },
        {
            "uuid": "79dfaba5-bfb4-4c6d-a198-643bda211dbf-007",
            "name": "SlurmSleepSeconds",
            "owner": "testuser2",
            "appId": "SlurmSleepSecondsVM",
            "created": "2021-07-21T19:16:02.019916Z",
            "status": "FINISHED",
            "remoteStarted": "2021-07-21T19:16:35.102868Z",
            "ended": "2021-07-21T19:16:57.909940Z",
            "tenant": "dev",
            "execSystemId": "tapisv3-exec2-slurm",
            "archiveSystemId": "tapisv3-exec2-slurm",
            "appVersion": "0.0.1",
            "lastUpdated": "2021-07-21T19:16:57.909940Z"
        }
    ],
    "status": "success",
    "message": "JOBS_LIST_RETRIVED Jobs list for the user testuser2 in the tenant dev retrived.",
    "version": "1.0.0-rc1",
    "metadata": {
        "recordCount": 2,
        "recordLimit": 2,
        "recordsSkipped": 0,
        "orderBy": "lastUpdated(desc),name(asc)",
        "startAfter": null,
        "totalCount": 1799
    }
    }


Get Job Details
-----------------

With PySDK:

.. code-block:: text

        $ t.jobs.getJob(jobUuid='ba34f946-8a18-44c4-9b25-19e21dfadf69-007')


With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007

The response will look something like the following:

::

     {
    "result": {
        "id": 1711,
        "name": "SyRunSleepSecondsNoIPFiles-2",
        "owner": "testuser2",
        "tenant": "dev",
        "description": "Sleep for a specified amount of time",
        "status": "FINISHED",
        "lastMessage": "Setting job status to FINISHED.",
        "created": "2021-07-12T23:56:01.790165Z",
        "ended": "2021-07-12T23:56:55.962694Z",
        "lastUpdated": "2021-07-12T23:56:55.962694Z",
        "uuid": "ba34f946-8a18-44c4-9b25-19e21dfadf69-007",
        "appId": "SyRunSleepSecondsNoIPFiles-2",
        "appVersion": "0.0.1",
        "archiveOnAppError": true,
        "dynamicExecSystem": false,
        "execSystemId": "tapisv3-exec2",
        "execSystemExecDir": "/workdir/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007",
        "execSystemInputDir": "/workdir/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007",
        "execSystemOutputDir": "/workdir/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/output",
        "execSystemLogicalQueue": null,
        "archiveSystemId": "tapisv3-exec",
        "archiveSystemDir": "/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive",
        "dtnSystemId": null,
        "dtnMountSourcePath": null,
        "dtnMountPoint": null,
        "nodeCount": 1,
        "coresPerNode": 1,
        "memoryMB": 100,
        "maxMinutes": 240,
        "fileInputs": "[]",
        "parameterSet": "{\"appArgs\": [], \"envVariables\": [{\"key\": \"_tapisAppId\", \"value\": \"SyRunSleepSecondsNoIPFiles-2\"}, {\"key\": \"_tapisAppVersion\", \"value\": \"0.0.1\"}, {\"key\": \"_tapisArchiveOnAppError\", \"value\": \"true\"}, {\"key\": \"_tapisArchiveSystemDir\", \"value\": \"/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive\"}, {\"key\": \"_tapisArchiveSystemId\", \"value\": \"tapisv3-exec\"}, {\"key\": \"_tapisCoresPerNode\", \"value\": \"1\"}, {\"key\": \"_tapisDynamicExecSystem\", \"value\": \"false\"}, {\"key\": \"_tapisEffeciveUserId\", \"value\": \"testuser2\"}, {\"key\": \"_tapisExecSystemExecDir\", \"value\": \"/workdir/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007\"}, {\"key\": \"_tapisExecSystemId\", \"value\": \"tapisv3-exec2\"}, {\"key\": \"_tapisExecSystemInputDir\", \"value\": \"/workdir/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007\"}, {\"key\": \"_tapisExecSystemOutputDir\", \"value\": \"/workdir/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/output\"}, {\"key\": \"_tapisJobCreateDate\", \"value\": \"2021-07-12Z\"}, {\"key\": \"_tapisJobCreateTime\", \"value\": \"23:56:01.790165454Z\"}, {\"key\": \"_tapisJobCreateTimestamp\", \"value\": \"2021-07-12T23:56:01.790165454Z\"}, {\"key\": \"_tapisJobName\", \"value\": \"SyRunSleepSecondsNoIPFiles-2\"}, {\"key\": \"_tapisJobOwner\", \"value\": \"testuser2\"}, {\"key\": \"_tapisJobUUID\", \"value\": \"ba34f946-8a18-44c4-9b25-19e21dfadf69-007\"}, {\"key\": \"_tapisJobWorkingDir\", \"value\": \"workdir\"}, {\"key\": \"_tapisMaxMinutes\", \"value\": \"240\"}, {\"key\": \"_tapisMemoryMB\", \"value\": \"100\"}, {\"key\": \"_tapisNodes\", \"value\": \"1\"}, {\"key\": \"_tapisSysHost\", \"value\": \"129.114.17.113\"}, {\"key\": \"_tapisSysRootDir\", \"value\": \"/home/testuser2\"}, {\"key\": \"_tapisTenant\", \"value\": \"dev\"}, {\"key\": \"JOBS_PARMS\", \"value\": \"15\"}, {\"key\": \"MAIN_CLASS\", \"value\": \"edu.utexas.tacc.testapps.tapis.SleepSecondsSy\"}], \"archiveFilter\": {\"excludes\": [], \"includes\": [\"Sleep*\", \"tapisjob.*\"], \"includeLaunchFiles\": true}, \"containerArgs\": [], \"schedulerOptions\": []}",
        "execSystemConstraints": null,
        "subscriptions": "[]",
        "blockedCount": 0,
        "remoteJobId": "1466046",
        "remoteJobId2": null,
        "remoteOutcome": "FINISHED",
        "remoteResultInfo": "0",
        "remoteQueue": null,
        "remoteSubmitted": null,
        "remoteStarted": "2021-07-12T23:56:20.900039Z",
        "remoteEnded": "2021-07-12T23:56:42.411522Z",
        "remoteSubmitRetries": 0,
        "remoteChecksSuccess": 3,
        "remoteChecksFailed": 0,
        "remoteLastStatusCheck": "2021-07-12T23:56:42.382661Z",
        "inputTransactionId": null,
        "inputCorrelationId": null,
        "archiveTransactionId": "66bc6c9a-210b-4ee6-9da3-252922928e7b",
        "archiveCorrelationId": "87f62e69-c180-4ad1-9aa7-ac5ada78e1b6",
        "tapisQueue": "tapis.jobq.submit.DefaultQueue",
        "visible": true,
        "createdby": "testuser2",
        "createdbyTenant": "dev",
        "tags": [
            "singularity",
            "sleep",
            "test"
        ],
        "_fileInputsSpec": null,
        "_parameterSetModel": null
    },
    "status": "success",
    "message": "JOBS_RETRIEVED Job ba34f946-8a18-44c4-9b25-19e21dfadf69-007 retrieved.",
    "version": "1.0.0-rc1",
  "metadata": null
  }

Get Job Status
----------------

With PySDK:

.. code-block:: text

        $ t.jobs.getJobStatus(jobUuid='ba34f946-8a18-44c4-9b25-19e21dfadf69-007')


With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/status

The response will look something like the following:

::

  {
    "result": {
      "status": "FINISHED"
      },
      "status": "success",
      "message": "JOBS_STATUS_RETRIEVED Status of the Job ba34f946-8a18-44c4-9b25-19e21dfadf69-007 retrieved.",
      "version": "1.0.0-rc1",
      "metadata": null
      }


Get Job History
----------------

With PySDK:

.. code-block:: text

        $ t.jobs.getJobHistory(jobUuid='ba34f946-8a18-44c4-9b25-19e21dfadf69-007')


With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/history

The response will look something like the following:

::

    {
    "result": [
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:02.365996Z",
            "jobStatus": "PENDING",
            "description": "The job has transitioned to a new status: PENDING.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:02.799166Z",
            "jobStatus": "PROCESSING_INPUTS",
            "description": "The job has transitioned to a new status: PROCESSING_INPUTS. The previous job status was PENDING.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:10.203007Z",
            "jobStatus": "STAGING_INPUTS",
            "description": "The job has transitioned to a new status: STAGING_INPUTS. The previous job status was PROCESSING_INPUTS.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:10.226013Z",
            "jobStatus": "STAGING_JOB",
            "description": "The job has transitioned to a new status: STAGING_JOB. The previous job status was STAGING_INPUTS.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:20.720637Z",
            "jobStatus": "SUBMITTING_JOB",
            "description": "The job has transitioned to a new status: SUBMITTING_JOB. The previous job status was STAGING_JOB.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:20.888569Z",
            "jobStatus": "QUEUED",
            "description": "The job has transitioned to a new status: QUEUED. The previous job status was SUBMITTING_JOB.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:20.902511Z",
            "jobStatus": "RUNNING",
            "description": "The job has transitioned to a new status: RUNNING. The previous job status was QUEUED.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:42.427492Z",
            "jobStatus": "ARCHIVING",
            "description": "The job has transitioned to a new status: ARCHIVING. The previous job status was RUNNING.",
            "transferTaskUuid": null,
            "transferSummary": {}
        },
        {
            "event": "JOB_NEW_STATUS",
            "created": "2021-07-12T23:56:55.966883Z",
            "jobStatus": "FINISHED",
            "description": "The job has transitioned to a new status: FINISHED. The previous job status was ARCHIVING.",
            "transferTaskUuid": null,
            "transferSummary": {}
        }
    ],
    "status": "success",
    "message": "JOBS_HISTORY_RETRIEVED Job ba34f946-8a18-44c4-9b25-19e21dfadf69-007 history retrieved for user testuser2 tenant dev",
    "version": "1.0.0-rc1",
    "metadata": {
        "recordCount": 9,
        "recordLimit": 100,
        "recordsSkipped": 0,
        "orderBy": null,
        "startAfter": null,
        "totalCount": -1
    }
    }

Get Job Output Listing
-----------------------

With PySDK:

.. code-block:: text

        $ t.jobs.getJobOutputList(jobUuid='ba34f946-8a18-44c4-9b25-19e21dfadf69-007', outputPath='/')


With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/output/list/

The response will look something like the following:

::

    {
    "result": [
        {
            "mimeType": null,
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "rw-rw-r--",
            "uri": "tapis://dev/tapisv3-exec/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/SleepSeconds.out",
            "lastModified": "2021-07-12T23:56:54Z",
            "name": "SleepSeconds.out",
            "path": "/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/SleepSeconds.out",
            "size": 3538
        },
        {
            "mimeType": null,
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "rw-rw-r--",
            "uri": "tapis://dev/tapisv3-exec/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.env",
            "lastModified": "2021-07-12T23:56:53Z",
            "name": "tapisjob.env",
            "path": "/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.env",
            "size": 1051
        },
        {
            "mimeType": null,
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "rw-rw-r--",
            "uri": "tapis://dev/tapisv3-exec/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.exitcode",
            "lastModified": "2021-07-12T23:56:54Z",
            "name": "tapisjob.exitcode",
            "path": "/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.exitcode",
            "size": 1
        },
        {
            "mimeType": null,
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "rw-rw-r--",
            "uri": "tapis://dev/tapisv3-exec/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.out",
            "lastModified": "2021-07-12T23:56:54Z",
            "name": "tapisjob.out",
            "path": "/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.out",
            "size": 3566
        },
        {
            "mimeType": "application/x-shar",
            "type": "file",
            "owner": "1003",
            "group": "1003",
            "nativePermissions": "rw-rw-r--",
            "uri": "tapis://dev/tapisv3-exec/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.sh",
            "lastModified": "2021-07-12T23:56:54Z",
            "name": "tapisjob.sh",
            "path": "/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/archive/tapisjob.sh",
            "size": 979
        }
    ],
    "status": "success",
    "message": "JOBS_OUTPUT_FILES_LIST_RETRIEVED Job ba34f946-8a18-44c4-9b25-19e21dfadf69-007 output files list retrieved for the user testuser2 in the tenant dev.",
    "version": "1.0.0-rc1",
    "metadata": {
        "recordCount": 5,
        "recordLimit": 100,
        "recordsSkipped": 0,
        "orderBy": null,
        "startAfter": null,
        "totalCount": 0
    }
    }

The Job output list API retrieves job's output files list for a previously submitted job by its UUID.
By default, the job must be in a terminal state (FINISHED or FAILED or CANCELLED) for the API to list the job's output files .
There is a query parameter allowIfRunning set to false by default.
If allowIfRunning=true, the API returns the job output files list even if the job is not in the terminal state.
Note that if a file is being written, still the file is listed.

Get Job Output Download
-------------------------

With PySDK:

.. code-block:: text

       $ t.jobs.getJobOutputDownload(jobUuid='ba34f946-8a18-44c4-9b25-19e21dfadf69-007', outputPath='/')


With CURL:

.. code-block:: text

      $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ba34f946-8a18-44c4-9b25-19e21dfadf69-007/output/download/ --output joboutput.zip

All the files in the the requested outputPath get downloaded in a zip file.

The Jobs output download API retrieves the job's output files for a previously submitted job by its UUID.
By default, the job must be in a terminal state (FINISHED or FAILED or CANCELLED) for the API to download the job's output files.
There is a query parameter allowIfRunning set to false by default.
If allowIfRunning=true, the API allows downloading the job output files even if the job is not in the terminal state.
Note that if a file is being written at the time of the request, the file is still downloaded with the current content.


Dedicated Search Endpoint
==========================
The jobs service provides dedicated search end-points to query jobs based on different conditions. The GET end-point allows to specify the query in the query parameters while the POST end-point allows complex queries in the request body using SQL-like syntax.


Search using GET on Dedicated Endpoint
---------------------------------------

With CURL:

.. code-block:: text

      $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/search?limit=2&status.eq=FINISHED&created.between=2021-07-01,2021-07-21&orderBy=lastUpdated(desc),name(asc)&computeTotal=True


The response will look something like the following:


::

    {
     "result": [
          {
              "uuid": "79234b2a-0995-4632-956e-b940d10607ba-007",
              "name": "SyRunSleepSecondsNoIPFiles-2",
              "owner": "testuser2",
              "appId": "SyRunSleepSecondsNoIPFiles-2",
              "created": "2021-07-20T23:56:02.616Z",
              "status": "FINISHED",
              "remoteStarted": "2021-07-20T23:56:20.368Z",
              "ended": "2021-07-20T23:56:54.409Z",
              "tenant": "dev",
              "execSystemId": "tapisv3-exec2",
              "archiveSystemId": "tapisv3-exec",
              "appVersion": "0.0.1",
              "lastUpdated": "2021-07-20T23:56:54.409Z"
          },
          {
              "uuid": "432f7018-070d-41c3-ba0e-a685f7f11e5c-007",
              "name": "SlurmSleepSeconds",
              "owner": "testuser2",
              "appId": "SlurmSleepSecondsVM",
              "created": "2021-07-20T23:16:01.629Z",
              "status": "FINISHED",
              "remoteStarted": "2021-07-20T23:16:24.781Z",
              "ended": "2021-07-20T23:16:58.745Z",
              "tenant": "dev",
              "execSystemId": "tapisv3-exec2-slurm",
              "archiveSystemId": "tapisv3-exec",
              "appVersion": "0.0.1",
              "lastUpdated": "2021-07-20T23:16:58.745Z"
          }
      ],
      "status": "success",
      "message": "JOBS_SEARCH_RESULT_LIST_RETRIEVED Jobs search list for the user testuser2 in the tenant dev retrieved.",
      "version": "1.0.0-rc1",
      "metadata": {
          "recordCount": 2,
          "recordLimit": 2,
          "recordsSkipped": 0,
          "orderBy": "lastUpdated(desc),name(asc)",
          "startAfter": null,
          "totalCount": 246
      }
      }


Search using POST on Dedicated Endpoint
---------------------------------------
A user can make complex queries to Jobs service by specifying SQL-like syntax in the request body to the end-point /v3/jobs/search.
An example request body in json format is shown below::

  {
    "search":
      [
        "(status = 'FINISHED' AND name = 'SleepSeconds') ",
        " OR (tags IN ('test'))"
      ]
  }


With cURL:

.. code-block:: text

       curl --location '$BASE_URL/v3/jobs/search?listType=ALL_JOBS&limit=2&computeTotal=True&select=name%2Ctags%2Cstatus%2CappId' \
       --header 'X-Tapis-Token: $jwt' \
       --header 'Content-Type: application/json' \
       --data '{
         "search":
         [
            "(status = '\''FINISHED'\'' AND name = '\''SleepSeconds'\'') ",
            " OR (tags IN ('\''test'\''))"
            ]
          }'

The response looks like this:


::

    {
    "result": [
        {
            "name": "SleepSecondsLoadTest",
            "status": "FINISHED",
            "appId": "SleepSeconds-Load",
            "tags": [
                "sleep",
                "test"
            ],
            "uuid": "e17edea6-33f8-441c-867c-d9d23509dd55-007"
        },
        {
            "name": "SleepSecondsLoadTest",
            "status": "FINISHED",
            "appId": "SleepSeconds-Load",
            "tags": [
                "sleep",
                "test"
            ],
            "uuid": "a3a539a9-c0e5-4a02-82c3-0dfbcada47f9-007"
        }
    ],
    "status": "success",
    "message": "JOBS_SEARCH_RESULT_LIST_RETRIEVED Jobs search list for the user testuser2 in the tenant dev retrieved. ",
    "version": "1.3.0",
    "commit": "ee1b3342",
    "build": "2023-03-01T15:42:55Z",
    "metadata": {
        "recordCount": 2,
        "recordLimit": 2,
        "recordsSkipped": 0,
        "orderBy": null,
        "startAfter": null,
        "totalCount": 27345
    }}




------------------------------------------------------------

Job Actions
===========

Job Cancel
-----------
A previously submitted job not in terminal state can be cancelled by its UUID.

With PySDK:

.. code-block:: text

        $ t.jobs.cancelJob(jobUuid='19b06299-4e7c-4b27-ae77-2258e9dc4734-007')


With CURL:

.. code-block:: text

        $ curl -X POST -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/19b06299-4e7c-4b27-ae77-2258e9dc4734-007/cancel

The response will look something like the following:

::

    {
    "result": {
        "message": "JOBS_JOB_CANCEL_ACCEPTED Request to cancel job 19b06299-4e7c-4b27-ae77-2258e9dc4734-007 has been accepted. "
    },
    "status": "success",
    "message": "JOBS_JOB_CANCEL_ACCEPTED_DETAILS Request to cancel job 19b06299-4e7c-4b27-ae77-2258e9dc4734-007 has been accepted. If the job is in a terminal state, the request will have no effect. If the job is transitioning between active and blocked states, another cancel request may need to be sent.",
    "version": "1.2.1",
    "metadata": null
   }

Hide Job
---------

With PySDK:

.. code-block:: text

        $ t.jobs.hideJob(jobUuid='19b06299-4e7c-4b27-ae77-2258e9dc4734-007')


With CURL:

.. code-block:: text

        $ curl -X POST -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/19b06299-4e7c-4b27-ae77-2258e9dc4734-007/hide

The response will look something like the following:

::

    {
    "result": {
        "message": "JOBS_JOB_CHANGED_VISIBILITY Job 19b06299-4e7c-4b27-ae77-2258e9dc4734-007 has been changed to hidden."
    },
    "status": "success",
    "message": "JOBS_JOB_CHANGED_VISIBILITY Job 19b06299-4e7c-4b27-ae77-2258e9dc4734-007 has been changed to hidden.",
    "version": "1.2.1",
    "metadata": null
   }

Unhide Job
-----------

With PySDK:

.. code-block:: text

           $ t.jobs.unhideJob(jobUuid='19b06299-4e7c-4b27-ae77-2258e9dc4734-007')


With CURL:

.. code-block:: text

           $ curl -X POST -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/19b06299-4e7c-4b27-ae77-2258e9dc4734-007/unhide

The response will look something like the following:

::

    {
    "result": {
        "message": "JOBS_JOB_CHANGED_VISIBILITY Job 19b06299-4e7c-4b27-ae77-2258e9dc4734-007 has been changed to unhidden."
    },
    "status": "success",
    "message": "JOBS_JOB_CHANGED_VISIBILITY Job 19b06299-4e7c-4b27-ae77-2258e9dc4734-007 has been changed to unhidden.",
    "version": "1.2.1",
    "metadata": null
    }



------------------------------------------------------------

Job Sharing
===========

Share a Job
------------
A previously submitted job can be shared with a user in the same tenant. Job resources that can shared are: JOB_HISTORY, JOB_RESUBMIT_REQUEST, JOB_OUTPUT. Currently only READ permission on the resources are allowed.


With PySDK:

.. code-block:: text

           $ t.jobs.shareJob(jobUuid='ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007',
                jobResource=["JOB_HISTORY","JOB_RESUBMIT_REQUEST","JOB_OUTPUT"],
                jobPermission='READ',
                grantee='testuser6')


With CURL:

.. code-block:: text

           $ curl -X POST -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007/share -d '{
            "jobResource": ["JOB_HISTORY", "JOB_RESUBMIT_REQUEST", "JOB_OUTPUT"], "jobPermission": "READ", "grantee": "testuser6"}'

The response will look something like the following:

::

    {
    "result": {
        "message": "JOBS_JOB_SHARED The job ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007 resource is shared by testuser2 to testuser6 in tenant dev"
    },
    "status": "success",
    "message": "JOBS_JOB_SHARED The job ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007 resource is shared by testuser2 to testuser6 in tenant dev",
    "version": "1.2.1",
    "metadata": null
   }

Get Job Share Information
--------------------------

With PySDK:

.. code-block:: text

           $ t.jobs.getJobShare(jobUuid='ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007')


With CURL:

.. code-block:: text

           $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007/share

The response will look something like the following:

::

    {
    "result": [
        {
            "tenant": "dev",
            "createdby": "testuser2",
            "jobUuid": "ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007",
            "grantee": "testuser5",
            "jobResource": "JOB_HISTORY",
            "jobPermission": "READ",
            "created": "2022-06-16T14:53:31.899199Z"
        },
        {
            "tenant": "dev",
            "createdby": "testuser2",
            "jobUuid": "ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007",
            "grantee": "testuser5",
            "jobResource": "JOB_OUTPUT",
            "jobPermission": "READ",
            "created": "2022-06-16T14:53:32.004831Z"
        },
        {
            "tenant": "dev",
            "createdby": "testuser2",
            "jobUuid": "ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007",
            "grantee": "testuser6",
            "jobResource": "JOB_HISTORY",
            "jobPermission": "READ",
            "created": "2022-06-16T17:17:50.981844Z"
        },
        {
            "tenant": "dev",
            "createdby": "testuser2",
            "jobUuid": "ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007",
            "grantee": "testuser6",
            "jobResource": "JOB_RESUBMIT_REQUEST",
            "jobPermission": "READ",
            "created": "2022-06-16T17:17:51.059726Z"
        },
        {
            "tenant": "dev",
            "createdby": "testuser2",
            "jobUuid": "ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007",
            "grantee": "testuser6",
            "jobResource": "JOB_OUTPUT",
            "jobPermission": "READ",
            "created": "2022-07-14T19:57:15.838019Z"
        }
    ],
    "status": "success",
    "message": "JOBS_JOB_SHARE_INFO_RETRIEVED Share information retrieved for the job ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007 for user testuser2 in tenant dev.",
    "version": "1.2.1",
    "metadata": {
        "recordCount": 5,
        "recordLimit": 100,
        "recordsSkipped": 0,
        "orderBy": null,
        "startAfter": null,
        "totalCount": 5
    }
    }

Unshare Job
-------------

With PySDK:

.. code-block:: text

           $ t.jobs.deleteJobShare(jobUuid='ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007', user='testuser6')


With CURL:

.. code-block:: text

           $ curl -X DELETE -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007/share/testuser6

The response will look something like this:

::

  {
  "result": {
      "message": "JOBS_JOB_UNSHARED The job ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007 resource is unshared by testuser2 to testuser6 in tenant dev"
  },
  "status": "success",
  "message": "JOBS_JOB_UNSHARED The job ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007 resource is unshared by testuser2 to testuser6 in tenant dev",
  "version": "1.2.1",
  "metadata": null
  }

List Shared Jobs
-----------------

The query parameter listType=SHARED_JOBS in the jobs list end-point allows to  list all shared jobs for a user, say testuser6, using testuser6's JWT. Note testuser6 is not the owner of the jobs listed. Default value for listType is MY_JOBS and to list all jobs including both shared and testuser6 owned job, listType=ALL_JOBS.

With PySDK:

.. code-block:: text

           $ t.jobs.getJobList(listType='SHARED_JOBS')


With CURL:

.. code-block:: text

           $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/jobs/list?listType=SHARED_JOBS

The response will look something like this:

::

  {
   "result": [
    {
        "uuid": "ccec730b-22ad-4088-a87e-bb8cfb2ab2e6-007",
        "name": "SleepSeconds",
        "owner": "testuser2",
        "appId": "SleepSeconds",
        "created": "2021-04-09T02:47:57.760Z",
        "status": "FINISHED",
        "remoteStarted": "2021-04-09T02:48:08.946Z",
        "ended": "2021-04-09T02:48:16.669Z",
        "tenant": "dev",
        "execSystemId": "tapisv3-exec2",
        "archiveSystemId": "tapisv3-exec",
        "appVersion": "0.0.1",
        "lastUpdated": "2021-04-09T02:48:16.669Z"
    }
    ],
    "status": "success",
    "message": "JOBS_LIST_RETRIVED Jobs list for the user testuser6 in the tenant dev retrived.",
    "version": "1.2.1",
    "metadata": {
    "recordCount": 1,
    "recordLimit": 100,
    "recordsSkipped": 0,
    "orderBy": null,
    "startAfter": null,
    "totalCount": -1
    }
    }

Job Search on Shared Job
-------------------------

Job search on a list of jobs can be performed using the query parameter listType=SHARED_JOBS in the search end-point.

In the following example, we use testuser5 JWT to do job search on list of jobs shared with testuser5.

With CURL:

.. code-block:: text

           $ curl -H "X-Tapis-Token:$jwt" '$BASE_URL/v3/jobs/search?listType=SHARED_JOBS&name.eq=SleepSeconds&created.between=2022-07-05,2022-07-06'

The response will look something like this:

::

    {
    "result": [
        {
            "uuid": "3b9cb514-4962-44e8-a851-55e933e558c0-007",
            "name": "SleepSeconds",
            "owner": "testuser2",
            "appId": "SleepSeconds",
            "created": "2022-07-05T21:34:11.355Z",
            "status": "FINISHED",
            "remoteStarted": "2022-07-05T21:34:48.776Z",
            "ended": "2022-07-05T21:35:31.808Z",
            "tenant": "dev",
            "execSystemId": "tapisv3-exec2",
            "archiveSystemId": "tapisv3-exec",
            "appVersion": "0.0.1",
            "lastUpdated": "2022-07-05T21:35:31.808Z"
        },
        {
            "uuid": "eacde4c4-1d93-4393-b220-63aea509b32c-007",
            "name": "SleepSeconds",
            "owner": "testuser2",
            "appId": "SleepSeconds",
            "created": "2022-07-05T21:43:05.371Z",
            "status": "FINISHED",
            "remoteStarted": "2022-07-05T21:43:44.899Z",
            "ended": "2022-07-05T21:44:27.509Z",
            "tenant": "dev",
            "execSystemId": "tapisv3-exec2",
            "archiveSystemId": "tapisv3-exec",
            "appVersion": "0.0.1",
            "lastUpdated": "2022-07-05T21:44:27.509Z"
        }
    ],
    "status": "success",
    "message": "JOBS_SEARCH_RESULT_LIST_RETRIEVED Jobs search list for the user testuser5 in the tenant dev retrieved.",
    "version": "1.2.1",
    "metadata": {
        "recordCount": 2,
        "recordLimit": 100,
        "recordsSkipped": 0,
        "orderBy": null,
        "startAfter": null,
        "totalCount": -1
    }
    }

Share Job Output
-----------------

As shown in the previous example of share a job, job output resource can be shared with a user, say testuser5, in the same tenant. This includes testuser5 can do job output listing and job output download with its own JWT even though its not the owner of the job.

Share Job History
------------------
As shown in the previous example of share a job, job history can be shared with a user, say testuser5, in the same tenant. This includes testuser5 can get job's history, status and job's detail information for jobs that are shared with it using its own JWT.
