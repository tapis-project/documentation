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

The only Tapis runtime component that can access the Vault is the `Security Kernal (SK) <../technical/security.html>`_.  There is, however, a need to read, write or delete secrets outside of SK, such as when installing or updating Tapis, rotating keys, or when manual action can quickly solve a problem.  The `SkAdmin <https://github.com/tapis-project/tapis-security/tree/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands>`_ utility program provides such capabilities.  


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

Secret creation is independent of all Tapis services when going directly to Vault.  When used in this mode, the only dependencies are on Kubernetes and Vault.  This allows SkAdmin to bootstrap all secrets needed by Tapis before any services run.  Whether secrets are created by going through SK or by going directly to Vault, the same secret path naming conventions are used.

Packaging
---------

`SkAdmin <https://github.com/tapis-project/tapis-security/tree/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands/SkAdmin.java>`_ is written in Java and resides in the *securitylib* repository.  `SkAdminParameters <https://github.com/tapis-project/tapis-security/blob/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands/SkAdminParameters.java>`_ defines the supported command line parameters.

To run SkAdmin directly as a Java program, use the shaded JAR file, *shaded-securitylib.jar*.  For example, to see the help message, one would issue the following command from a terminal in which Java 17+ is configured and the JAR file is present::

 java -cp shaded-securitylib.jar edu.utexas.tacc.tapis.security.commands.SkAdmin -help

The most common way to run SkAdmin is using a docker container.  Here's how to display the help message using docker::

 docker run --rm --env SKADMIN_PARMS=-help tapis/securityadmin

The value assigned to the container's SKADMIN_PARMS environment variable is passed to SkAdmin on the command line.  See this `DockerFile <https://github.com/tapis-project/tapis-security/blob/dev/deployment/tapis-securityadmin/Dockerfile>`_ for details.  Here is the SkAdmin help information::

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

- -i (-input) - JSON file or direct containing one more JSON files that conform to the SkAdminInput.json schema.
- -b (-baseurl) - the SK or Vault server url. 

And at least one of these *action* parameters:

- -c (-create) - create secrets only if they don't already exist in Vault.
- -u (-update) - write secrets to Vault even if they already exist. 
- -dm (-deployMerge) - write the specified key/value pairs to Kubernetes secrets, merging with unspecified key/value pairs that may exist in any secret. 
- -dr (-deplyReplace) - write the specified key/value pairs to Kubernetes secrets, completely replacing any secrets that may exist.

The *-c* and *-u* parameters are mutually exclusive, as are the *-dm* and *-dr* parameters.  The *-c* option will never overwrite a secret that already exists in Vault, so it is non-destructive.  If the secret doesn't exist, it will be created per the input file specification.  On the other hand, while the *-u* option also creates secrets if they don't already exist in Vault, it will overwrite existing secrets according to the input file specification.  The *-u* option can be destructive. 

The *-dm* option deploys secrets from Vault to Kubernetes secrets in an additive manner.  A Kubernetes secret can contain any number of key/value pairs.  The *-dm* option preserves existing key/value pairs and adds any new ones that exist in Vault; it therefore is non-destructive.  On the other hand, the *-dr* option will replace all key/value pairs in a Kubernetes secret with the key/value pairs in Vault that are associated with the secret.  The *-dr* option can be destructive. 


Vault Parameters
^^^^^^^^^^^^^^^^^

Both of the following parameters are required when access Vault directly.  Note that these parameters are mutually exclusive with the SK Parameters.

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
- -passwordlen - the length of generated passwords.  The default is 32.
- -help (–help) - show the SkAdmin help message (no value necessary).

SkAdmin Inputs
^^^^^^^^^^^^^^

SkAdmin takes JSON input that conforms to the `SkAdminInput <https://github.com/tapis-project/tapis-security/blob/dev/tapis-securitylib/src/main/resources/edu/utexas/tacc/tapis/security/jsonschema/SkAdminInput.json>`_ schema.  The required *-i* parameter can name a single JSON file or a directory that contains any number of JSON files.  When a directory is specified, all json files that are immediate children of the directory are loaded and merged into a single set of secrets to be processed.

SkAdmin supports the following Security Kernel secret types:

- dbcredential - database credentials used by services
- servicepwd - the password used by services to obtain their JWTs
- jwtsigning - the asymmetric key pair used to sign and validate Tapis JWTs
- jwtpublic - the public part of a jwtsigning key pair
- user - arbitrary secret information associcated with a user

A short discussion on secret types can be found in the Security Kernel `secrets section <../technical/security.html#secrets>`_.  The input files used to generate Tapis's initial set of secrets are in the `initialLoad <https://github.com/tapis-project/tapis-deployer/tree/main/playbooks/roles/skadmin/templates/kube/initialLoad>`_ directory of `tapis-deployer <https://github.com/tapis-project/tapis-deployer>`_. 

The values of passwords and keys fields can be specified using the distinguished value "<generate-secret>".  SkAdmin will generate random passwords or asymmetric key pairs as required.  The value of key fields can also be specified as "file:pathToPEMFile" where the pathToPEMFile is a path, usually an absolute path, to a PEM file containing a public or private key.  When key values are provided inline in the input json files, the values are required to be in PEM format.

When SkAdmin is directed to generate a new key pair, both the public and private parts are saved in SK, but only the private part is deployed to Kubernetes using JwtSigning input.  To deploy the public key to Kubernetes, use separate JwtPublic input stanzas for each public key.  Results report a combined tally for JwtSigning and JwtPublic under the JWT Signing Keys heading. 

JwtPublic stanza can also be used independently of whether a key pair resides in SK.  If the optional publicKey value is provided in the JwtPublic input stanza, then that value will be used without consulting SK.  In addition, if that value starts with the "file:" string, the publicKey will be assigned the contents of the specified file.

Execution
----------

SkAdmin execution consists of the following steps:


Result Reporting
^^^^^^^^^^^^^^^^^

An accounting of what actions were performed is printed to stdout when the program completes.  Summary information include counts of secret processing.  Detailed information includes an outcome message for each secret action that includes success, failure and skipped outcomes.  The default result format is text, but json and yaml can also be specified.

Deploying Tapis with SkAdmin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Updating Secrets with SkAdmin
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


More Examples
^^^^^^^^^^^^^^ 



