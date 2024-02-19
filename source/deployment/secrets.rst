..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _secrets:

##############################
Managing Secrets with SkAdmin
##############################

.. raw:: html

    <style> .red {color:#FF4136; font-weight:bold; font-size:20px} </style>

.. role:: red


----

.. note::

    This guide is for users wanting to deploy Tapis software in their own datacenter. Researchers who 
    simply want to make use of the Tapis APIs do not need to deploy any Tapis components and can ignore
    this guide.  


Introduction to Tapis Secrets
=============================

Tapis stores all secrets that it uses or manages in `Hashicorp Vault <vault.html>`_.  These secrets include:

- Service passwords
- Database credentials
- Signing key pairs
- Credentials for user systems
- Arbitrary passwords and other secrets

The only Tapis runtime component that can access the Vault is the `Security Kernal (SK) <../technical/security.html>`_.  There is, however, sometimes a need to read, write or delete secrets outside of SK, such as when installing or updating Tapis, rotating keys, or when manual action can quickly solve a problem.  The `SkAdmin <https://github.com/tapis-project/tapis-security/tree/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands>`_ utility program provides such capabilities.  


The SkAdmin Utility
===================

The SkAdmin command line program manages secrets when Tapis is running or when it's offline or only partially running, such as during start up.  

SkAdmin does the following:

- Creates or updates secrets in SK.
- Creates or updates secrets directly in Vault without going through SK.
- Merges or replaces Kubernetes secrets with one or more values from SK.
- Merges or replaces Kubernetes secrets with one or more values directly from Vault.
- Generates passwords and key pairs on demand.
- Provides summary and detail information about work performed on a run.

Secret creation is independent of all Tapis services when going directly to Vault.  When used in this mode, the only dependencies are Vault and, possibly, Kubernetes.  This allows SkAdmin to bootstrap all secrets needed by Tapis before any services run.  Whether secrets are created by going through SK or by going directly to Vault, the same secret path naming conventions are used.

Packaging
---------

`SkAdmin <https://github.com/tapis-project/tapis-security/tree/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands/SkAdmin.java>`_ is written in Java and resides in the *securitylib* repository.  `SkAdminParameters <https://github.com/tapis-project/tapis-security/blob/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands/SkAdminParameters.java>`_ defines the supported command line parameters.

To run SkAdmin directly as a Java program, use the shaded JAR file, *shaded-securitylib.jar*.  For example, to see the help message, one would issue the following command from a terminal in which Java 17+ is configured and the JAR file is present::

 java -cp shaded-securitylib.jar edu.utexas.tacc.tapis.security.commands.SkAdmin -help

The most common way to run SkAdmin is using a docker container.  Here's how to display the help message using docker::

 docker run --rm --env SKADMIN_PARMS=-help tapis/securityadmin

The value assigned to the container's SKADMIN_PARMS environment variable is passed to SkAdmin on the command line.  See this `DockerFile <https://github.com/tapis-project/tapis-security/blob/dev/deployment/tapis-securityadmin/Dockerfile>`_ if you're interested in how this is done.  Here is the SkAdmin help information::

 SkAdmin for creating and deploying secrets to Kubernetes.

 SkAdmin [options...]

 -b (-baseurl) <base sk or vault url> : SK: http(s)://host/v3, Vault: http(s)://host:32342)
 -c (-create)                         : create secrets that don't already exist (default: false)
 -dm (-deployMerge)                   : deploy secrets to kubernetes, merge with existing (default: false)
 -dr (-deployReplace)                 : deploy secrets to kubernetes, replace any existing (default: false)
 -help (--help)                       : display help information (default: true)
 -i (-input) <file path>              : the json input file or folder
 -j (-jwtenv) VAL                     : JWT environment variable name
 -kn (-kubeNS) VAL                    : kubernetes namespace to be accessed
 -kssl                                : validate SSL connection to kubernetes (default: false)
 -kt (-kubeToken) VAL                 : kubernetes access token environment variable name
 -ku (-kubeUrl) VAL                   : kubernetes API server URL
 -o (-output) VAL                     : 'text' (default), 'json' or 'yaml' (default: text)
 -passwordlen N                       : number of random bytes in generated passwords (default: 16)
 -u (-update)                         : create new secrets and update existing ones (default: false)
 -vr (-vaultRole) VAL                 : vault role-id
 -vs (-vaultSecret) VAL               : vault secret-id


 Use either the -c or -u option to change secrets in Vault. Use the -dm 
 or -dr option to deploy secrets to Kubernetes.

 Access to Vault secrets is always required. Use either the -j option 
 to access the secrets using the Security Kernel or the {-vr, -vs} options 
 to accress the secrets by going directly to Vault. Set the baseurl to 
 match the access method.  Set the {-kn, -kt, -ku} options when deploying 
 secrets to Kubernetes.

We'll use the containerized version of SkAdmin for the rest of this discussion.

Launching SkAdmin
------------------

To manage secrets, SkAdmin requires both of these parameters:

- -i (-input) - JSON file or directory containing one more JSON files that conform to the `SkAdminInput.json <https://github.com/tapis-project/tapis-security/blob/dev/tapis-securitylib/src/main/resources/edu/utexas/tacc/tapis/security/jsonschema/SkAdminInput.json>`_ schema.
- -b (-baseurl) - the SK or Vault server url. 

And at least one of these *action* parameters:

- -c (-create) - create secrets only if they don't already exist in Vault.
- -u (-update) - write secrets to Vault even if they already exist. 
- -dm (-deployMerge) - write the specified key/value pairs to Kubernetes secrets, merging with unspecified key/value pairs that may exist in any secret. 
- -dr (-deplyReplace) - write the specified key/value pairs to Kubernetes secrets, completely replacing any secrets that may exist.

The *-c* and *-u* parameters are mutually exclusive, as are the *-dm* and *-dr* parameters.  The *-c* option will never overwrite a secret that already exists in Vault, so it is non-destructive.  If the secret doesn't exist, it will be created per the input file specification.  On the other hand, while the *-u* option also creates secrets if they don't already exist in Vault, it will overwrite existing secrets according to the input file specification.  The *-u* option can be destructive. 

The *-dm* option deploys secrets from Vault to Kubernetes secrets in an additive manner.  A Kubernetes secret can contain any number of key/value pairs.  The *-dm* option preserves existing key/value pairs and adds any new ones that exist in Vault; it therefore is non-destructive.  The *-dr* option, on the other hand, will replace all key/value pairs in a Kubernetes secret with the key/value pairs in Vault that are associated with the secret.  The *-dr* option can be destructive. 


Vault Parameters
^^^^^^^^^^^^^^^^^

Both of the following parameters are required when accessing Vault directly.  Note that these parameters are mutually exclusive with the SK Parameters.

- -vr (-vaultRole) - the Vault role-id used to be acquire an authorized Vault token.
- -vs (-vaultSecret) - the Vault secret-id used to be acquire an authorized Vault token.

The role-id is the one assigned to the Security Kernel.  The secret-id is a short-lived secret, usually with a 10 minute TTL, that can be thought of as a temporary password associated with the role-id.  Details on how to obtain these values is beyond the scope of this discussion, but tapis-deployer's `renew-sk-secret-script <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/skadmin/templates/kube/renew-sk-secret/renew-sk-secret-script>`_ provides an example implementation.

SK Parameters
^^^^^^^^^^^^^^

If transactions are going to occur using SK rather than going directly to Vault, the following parameter is required.  Note that this parameter is mutually exclusive with all Vault Parameters.

- -j (-jwtenv) - the environment variable name whose value is a JWT authorized to access SK.

The JWT is usually a Security Kernel service JWT.

Kubernetes Parameters
^^^^^^^^^^^^^^^^^^^^^

Kubernetes parameters are only required if a deployment to Kubernetes secrets has been specified (*-dm* or *-dr*).  All the following parameters are required to access Kubernetes.

- -kt (-kubeToken) - the environment variable name whose value contains an authorized Kubernetes token.
- -ku (-kubeUrl) - the URL to the Kubernetes API server.
- -kn (-kubeNS) - the Kubernetes namespace to access.

SkAdmin uses these values to call the Kubernetes secrets API.

General Parameters
^^^^^^^^^^^^^^^^^^^

These parameters are optional and have default values.

- -o (-output) - output format can be one of text, json, or yaml.  The default is text.
- -passwordlen - the length of generated passwords.  The default is 16.
- -help (–help) - show the SkAdmin help message (no value necessary).

SkAdmin Inputs
^^^^^^^^^^^^^^

SkAdmin takes JSON input that conforms to the `SkAdminInput.json <https://github.com/tapis-project/tapis-security/blob/dev/tapis-securitylib/src/main/resources/edu/utexas/tacc/tapis/security/jsonschema/SkAdminInput.json>`_ schema.  The required *-i* parameter can name a single JSON file or a directory that contains any number of JSON files.  When a directory is specified, all JSON files that are immediate children of the directory are loaded and merged into a single set of secrets to be processed.

SkAdmin supports the following Security Kernel secret types:

- dbcredential - database credentials used by services
- servicepwd - the password used by services to obtain their JWTs
- jwtsigning - the asymmetric key pair used to sign and validate Tapis JWTs
- jwtpublic - the public part of a jwtsigning key pair
- user - arbitrary secret information associcated with a user

A short discussion on secret types can be found in the Security Kernel `secrets section <../technical/security.html#secrets>`_.  The input files used to generate Tapis's initial set of secrets are in the `initialLoad <https://github.com/tapis-project/tapis-deployer/tree/main/playbooks/roles/skadmin/templates/kube/initialLoad>`_ directory of `tapis-deployer <https://github.com/tapis-project/tapis-deployer>`_. 

The values of passwords and keys fields can be specified using the distinguished value "<generate-secret>".  SkAdmin will generate random passwords or asymmetric key pairs as required.  The value of key fields can also be specified as "file:pathToPEMFile" where *pathToPEMFile* is a path, usually an absolute path, to a PEM file containing a public or private key.  Alternatively, key values can be provided inline in the input json files, in which case they are required to be in PEM format.

When SkAdmin is directed to generate a new key pair, both the public and private parts are saved in SK, but only the private part is deployed to Kubernetes using JwtSigning input.  To deploy the public key to Kubernetes, use separate JwtPublic input stanzas for each public key. 

JwtPublic stanza can also be used independently of whether a key pair resides in SK.  If the optional publicKey value is provided in the JwtPublic input stanza, then that value will be used without consulting SK.  In addition, if that value starts with the "file:" string, the publicKey will be assigned the contents of the specified file.

Execution
----------

SkAdmin execution consists of the following steps:

1. **Validate parameters** - Validate that a complete, non-conflicting set of parameters have be specified.  The API used to perform all I/O on the secrets database will be either the SK or Vault interface. 
2. **Load secret specifications** - The file or directory referenced by the *-input* parameter is loaded.  In the directory case, the JSON files in the directory are loaded in alphabetic order.  Each of the five secret types listed in the previous section are aggregated if there is more than one file.
3. **Validate secret specifications** - All five types of secrets are validated.  If a value of *<generate-secret>* is encountered, then a password or key pair is generated depending on context.  Any invalid input causes the program to abort.
4. **Create or update secrets** - If the *-create* parameter is set, then write the secrets to the Vault database only if they don't already exist there.  If the *-update* parameter is set, always write the secrets to the Vault database.
5. **Deploy secrets** - If the *-deployMerge* parameter is specified, then any new secret keys that do not already exist in Kubernetes secrets will be deployed.  If the *-deployReplace* parameter is specified, then all input secrets will be deployed to Kubernetes overwriting any existing secrets with the same name.
6. **Report results** - SkAdmin writes a report with both summary and detail information to stdout in the format specified by the *-output* parameter.      


Result Reporting
^^^^^^^^^^^^^^^^^

An accounting of what actions were performed is printed to stdout when the program completes.  Summary information include counts of secrets processed.  Detailed information includes an outcome message for each secret action that includes success, failure and skipped outcomes.  The default result format is text, but json and yaml can also be specified.

Creating Secrets with SkAdmin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

SkAdmin is an integral part of Tapis deployment processing:  It initializes Vault with Tapis roles and permissions, it creates secrets and, in Kubernetes environments, it deploys secrets to Kubernetes for subsequent injection into containers.  

In an automated Kubernetes environment, SkAdmin would run in a pod, which complicates how values get passed to SkAdmin.  Consult the top-level deployer `burnup <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/baseburnup/templates/kube/burnup>`_ script to see when SkAdmin gets called during Tapis deployment and `skadmin/burnup <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/skadmin/templates/kube/burnup>`_ to see how parameters are passed into the SkAdmin pod.  

For this discussion, however, we'll show how to create secrets by running an SkAdmin docker container directly.  In the first scenario, we'll go to your deployment's *skadmin/initialLoad* directory, which contains the deployment's initial secret specifications.  Here's how we invoke SkAdmin to only create the secrets that do not already exist in Vault::
 
 cd $TAPIS_DIR/tapis-kube/skadmin/initialLoad
 docker run -e SKADMIN_PARMS="-c -i /initialLoad -vr <VAULT_ROLEID> -vs <VAULT_SECRETID> -b http://vault:8200" --mount type=bind,source=`pwd`,target=/initialLoad --rm tapis/securityadmin

Going from left to right, we see that all the SkAdmin command line parameters are assigned to the SKADMIN_PARMS environment variable.  In this case, SkAdmin is being asked to create secrets only if they don't already exist.  It will read the JSON files in the */initialLoad* directory inside the container.  

SkAdmin will communicate directly with Vault using values represented by <VAULT_ROLEID> and <VAULT_SECRETID> and the given Vault network location.  Details on how to obtain these values is beyond the scope of this discussion, but tapis-deployer's `renew-sk-secret-script <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/skadmin/templates/kube/renew-sk-secret/renew-sk-secret-script>`_ provides an example implementation.

We bind mount the host's current directory into the */initialLoad* directory in the container.  Any host directory that contains SkAdmin JSON input files could serve as the source directory; any target directory in the container that's referenced by the *-i* parameter could serve as the destination.  We use the *--rm* flag to instruct docker to remove the container (and any secrets it contains) after execution.    

Creating and Deploying Secrets with SkAdmin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If we add Kubernetes parameters to the command line shown in the previous section, we'll be able to both create secrets and deploy them to Kubernetes.  The changes begin at the *-dm* parameter::

 cd $TAPIS_DIR/tapis-kube/skadmin/initialLoad
 docker run -e SKADMIN_PARMS="-c -i /initialLoad -vr <VAULT_ROLEID> -vs <VAULT_SECRETID> -b http://vault:8200" --mount type=bind,source=`pwd`,target=/initialLoad --rm -dm -kt <KUBE_TOKEN> -kn <KUBE_NAMESPACE> -ku https://kubernetes.default.svc.cluster.local tapis/securityadmin 

The *-dm* parameter instructs SkAdmin to merge the input secrets into Kubernetes secrets.  The merge will not change any secret value already in Kubernetes.  The <KUBE_TOKEN> and <KUBE_NAMESPACE> values allow access to the Kubernetes cluster running at the URL specified by the *-ku* parameter. 


Updating Secrets with SkAdmin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

It's common to add a secret after Tapis has already been deployed, such as when a new service is added to a site.  The deployed SkAdmin directory contains an `updateSecrets <https://github.com/tapis-project/tapis-deployer/tree/main/playbooks/roles/skadmin/templates/kube/updateSecrets>`_ subdirectory that makes it easy make incremental changes to secrets in Vault and Kubernetes.  The *updateSecrets/README* file contents explain how to do this::

 Adding New Secrets
 ==================

 This directory contains configuration and script files that allow new secrets to be imported into SK and Kubernetes.  The general approach follows that of the initial secrets loading process in the parent directory.  The main difference is that a staging directory contains one or more SkAdmin input files specified for a particular run.  

 Usage is as follows:

    1. Put one or more SkAdmin input json files into the ./updateFiles directory.
    2. ./burnup
    3. Remove your json files from the staging directory 
    
 Common use cases for this facility include creating secrets for new services, generating new secrets for an existing service after deleting that service's secrets in SK, and restoring secrets in Kubernetes that exist in SK.

 This facility assumes that SK was previously configured and initialized with secrets by running the burnup script in the parent directory.        

Replacing Secrets
~~~~~~~~~~~~~~~~~~

For safety, the process described in the above README calls SkAdmin with the create (*-c*) parameter just like in the two previous examples.  This means that the procedure is non-destructive to secrets in Vault and Kubernetes.  It also means the procedure cannot be used to replace existing secret values.

To replace an existing secret with a new one, follow these steps:

1. Use SK `listSecret <https://tapis-project.github.io/live-docs/?service=SK#tag/vault/operation/listSecretMeta>`_ and `readSecret <https://tapis-project.github.io/live-docs/?service=SK#tag/vault/operation/readSecret>`_ APIs to understand what secrets currently exist in SK.  Use *kubect get secret* calls to see what secrets are currently in Kubernetes and how SK maps them.  When new to this process, consider temporarily saving the secrets you plan to replace off to the side.
2. Run an SkAdmin container from the command line using the update (*-u*) and/or deployReplace (*-dr*) parameters and one input file at a time to limit potential loss.  SK saves up to 10 previous versions of a secret, so secrets are recoverable up to that limit.
3. Validate that everything went as expected and then delete any temporarily saved old secrets.

 



