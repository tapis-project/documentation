..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _vault: 

###########
Tapis Vault
###########

.. raw:: html

    <style> .red {color:#FF4136; font-weight:bold; font-size:20px} </style>

.. role:: red


----

.. note::

    This guide is for users wanting to deploy Tapis software in their own datacenter. Researchers who 
    simply want to make use of the Tapis APIs do not need to deploy any Tapis components and can ignore
    this guide.  


Introduction to Tapis Vault
===========================

Tapis stores all its secrets in an instance of `Hashicorp Vault <https://www.hashicorp.com/products/vault>`_.  It is critical that access to Vault is tightly controlled and its secret content safeguarded.  The only Tapis component that interactes directly with Vault is the `Security Kernel <../technical/security.html>`_ and its associated utility programs.

When planning a Tapis installation, one should consider the tradeoff between automation and robust secret management.  In highly automated environments like Kubernetes, services are automatically restarted when they fail or need to be moved between nodes.  This level of automation requires writing at least one secret on some software accessible disk.  On the other hand, Vault initialization is geared toward having a human in the loop to execute its unseal protocol and to protect high value tokens.  

Tapis supports two levels of Vault automation.  When running in a Kubernetes cluster, Vault's unseal keys and a long-lived token are written to disk on the control plane.  Kubernetes accesses these secrets when it initializes a new Vault instance or it needs to restart Vault.  These secrets are protected by the operating system's account and access control mechanisms; if those mechanisms are compromised, the Vault's contents are vulnerable. 

Tapis also supports deploying Vault outside a Kubernetes cluster while the rest of Tapis runs in the cluster.  In this configuration, a data center can deploy Vault to meet its local security policies and standards, including limiting administrative access to Vault, running Vault in a physically secure location, employing a hardware security module, etc.

In the following two sections we discuss how the community version of Vault can be run inside Kubernetes and run on a VM outside of Kubernetes.  In both cases, Vault needs to be installed, certains capabilities need to be enabled, Tapis-specific policies and roles need to be created, and administrative processes need to be put in place.  Other configurations, such as running enterprise Vault or sharing Vault with other applications, are not covered, but information from this discussion can be adapted to other configurations.   

Deploying Vault in Kubernetes
=============================

Using `Tapis Deployer <./deployer.html>`_, Tapis's `top-level burnup script <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/baseburnup/templates/kube/burnup>`_ configures and initializes Vault early in the deployment process.  The `Vault burnup script <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/vault/templates/kube/burnup>`_ executes from the Kubernetes control plane and performs these tasks:

- Configures Vault's network and site location 
- Configures Vault storage
- Creates and initializes Vault (new installations only)

   - Creates *vault* file containing unseal keys and root token
- Creates *vault-token* file containing root token from *vault* file (if necessary)
- Pushes unseal keys and root token to Kubernetes secrets
- Starts the Vault pod and unseals it (if necessary)

The deployer scripts detect the *vault* file to determine whether Vault has been installed.  This file along with the *vault-token* file are placed in user's home directory by default, but this can be changed.

At this point, a Vault docker image is running in a Kubernetes pod and deployment scripts have written the unseal keys and the root token to files.  These secrets are also written to Kubernetes secrets to make them available to pods and jobs.  Kubernetes has all the secret information needed to restart Vault whenever it detects a failure or needs to move the pod.  This automation comes at the cost of having sensitive Vault secrets on disk in the Kubernetes control plane. 

The next phase initializes the Vault with Tapis roles, policies and secrets using the SkAdmin utility program.  SkAdmin secrets management capabilities is discussed in depth in its own `topic <secrets.html>`_, but here we'll focus on its role during Vault initialization.  

SkAdmin connects to Vault with administrative permissions so that is can set up Tapis's `standard policies <https://github.com/tapis-project/tapis-deployer/tree/main/playbooks/roles/skadmin/templates/kube/tapis-vault/policies/sk>`_ and its `administrative policies <https://github.com/tapis-project/tapis-deployer/tree/main/playbooks/roles/skadmin/templates/kube/tapis-vault/policies/sk-admin>`_.  
SkAdmin also sets up Tapis's `standard roles <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/skadmin/templates/kube/tapis-vault/roles/sk-role.json>`_ and its `administrative roles <https://github.com/tapis-project/tapis-deployer/blob/main/playbooks/roles/skadmin/templates/kube/tapis-vault/roles/sk-admin-role.json>`_.

Once SkAdmin completes setting up Tapis's roles and policies, Vault is ready to accept Tapis service and user secrets.  See the `secrets discussion <secrets.html>`_ for details.


Deploying Vault Outside of Kubernetes
=====================================

The procedure below describes how to build a Vault VM on Linux, which we'll call "**tapis-vault**".  This procedure can also be used as a template for building Vault instances in other environments and follows the same general outline as dicussed above for Kubernetes environments.  

Important security characteristics of the VM installation approach are:

- No Vault tokens are ever stored on the VM's disk.
- No unseal keys are ever stored on VM's disk.

*The reason not to store these secrets on the Vault machine is because even if the root user is compromised, Vault secrets are inaccessible unless Vault is unsealed and the attacker has a valid token.*  

That said, automation inside Kubernetes will typically require a scoped token to start the Security Kernel and that token will most likely be saved in the control plane.

We assume the installation uses the open source version of Hashicorp Vault, so we do not have access to Vault's enterprise features.  Tapis has been tested with Vault v1.8.3 and we assume a version compatible with that is being used.

The procedure can be split into two phases.  The first phase requires command line access to the Vault host as root.  The second phase can be performed remotely using the Vault REST APIs and a root token.  

PHASE I - Command Line Execution
--------------------------------

**Step 1 - Acquire A VM**

Acquire a VM with a TLS certificate installed.  We'll use the fictitious domain "**mydomain.com**" for illustrative purposes.

**Step 2 - Install Hashicorp Vault**

SSH into target VM as root.  Follow installation instructions for your package manager to natively install Vault: 

https://learn.hashicorp.com/tutorials/vault/getting-started-install?in=vault/getting-started

https://developer.hashicorp.com/vault/docs/install

**Step 3 - Change Private Key Access**

Now that Vault is installed, change the group of the private key to "vault" and allow group read.  Here are example commands:

| *chgrp vault /etc/pki/tls/private/tapis-vault-key.20230403*
| *chmod 640 /etc/pki/tls/private/tapis-vault-key.20230403*

It's also a good idea to create /etc/pki/tls/certs/README.VAULT explaining the steps you took to customize your VM.

**Step 4 - Configure Vault for RAFT Storage**

Save the original /etc/vault.d/vault.hcl.  Update /etc/vault.d/vault.hcl to use the RAFT backend.  Here are contents of an example vault.hcl file that can provide a template for your configuration::

    # Full configuration options can be found at https://www.vaultproject.io/docs/configuration

    ui = true

    disable_mlock = true

    cluster_addr  = "https://tapis-vault.mydomain.com:8201"
    api_addr      = "https://tapis-vault.mydomain.com:8200"

    storage "raft" {
        path = "/opt/vault/data"
        node_id = "node_1"
    }

    # HTTPS listener
    listener "tcp" {
        address       = "0.0.0.0:8200"
        tls_cert_file = "/etc/pki/tls/certs/certchain.pem"
        tls_key_file  = "/etc/pki/tls/private/tapis-vault-key.20230403"
        tls_client_ca_file = "/etc/pki/tls/certs/certchain.pem"
    }

Vault information about using the RAFT protocol can be found `here <https://developer.hashicorp.com/vault/docs/internals/integrated-storage>`_.

**Step 5 - Start Vault**

| *systemctl enable vault.service*
| *systemctl start  vault.service*
| *systemctl status vault.service*

Test the installation (customize for your hostname):

| *export VAULT_ADDR=https://tapis-vault.mydomain.com:8200*
| *vault status*

**Step 6 - Initialize Vault**

*vault operator init*

Five *unseal keys* and the *root token* will be written to the screen.  DO NOT SAVE THESE DATA PERMANENTLY ON THE FILE SYSTEM.  Instead, copy the information off the screen and save them securely off the VM.

**Step 7 - Unseal Vault**
The Vault requires 3 out of the 5 of the unseal keys to unseal.  Issue the operator unseal call 3 times, each time using a different key.

| *vault operator unseal*
| *vault status*

**Step 8 - Export Root Token**
To avoid saving the root token to the command history file:  

| *export HISTCONTROL=ignorespace* 
|   *export VAULT_TOKEN=xxx*

where the command has a leading space and xxx is the token output by the above operator init command.

**Step 9 - Enable Authn Methods and Secrets Engines**

| *vault secrets enable -version=2 -path=secret kv*
| *vault auth enable approle*
| *vault auth enable userpass*

**Step 10 - Check Remote Access**

Before logging off, test remote access by running a status command that will be used in Phase II.  On the remote machine, export the root token.  

To avoid saving the root token to the command history file:  

| *export HISTCONTROL=ignorespace*
|   *export VAULT_TOKEN=xxx*
| *curl -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/sys/health | jq* 

**Step 11 - Logoff VM (optional)**

All further configuration will be performed from the remote machine.

PHASE II - Remote Commands
--------------------------

**Step 12 - Create SK Roles**

On the remote machine terminal, export the root VAULT_TOKEN as shown in Step 10.  Clone the `tapis-vault-vm <https://github.com/tapis-project/tapis-vault-vm>`_ git repo into the current directory.

| *git clone https://github.com/tapis-project/tapis-vault-vm.git*
| *cd tapis-vault-vm*

| *curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" \-\-data @roles/sk-role.json https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk*

| *curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" \-\-data @roles/sk-admin-role.json https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk-admin*

**Step 13 - Test SK Roles (optional)**

| *curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk/secret-id | jq*

| *curl -X GET -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk/role-id | jq*

**Step 14 - Create Roles and Policies**

The tapis-vault/CreatePolicies.sh script encapsulates basic policy and role creation needed for Tapis to function.  See comments in the script for details, but basically the script requires:

- The current directory to be tapis-vault.
- The VAULT_TOKEN environment variable be set to a root token.
- The DNS name of the new Vault VM be provided on the command line.
- Requirements 1 and 2 where already set in the previous two steps, so an invocation of the script looks like this (but with your VM):

| *./CreatePolicies.sh tapis-vault.mydomain.com*

**Step 15 - View Roles (optional)**
Each of the roles referenced in CreatePolicies.sh should be returned.

| *curl -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk | jq*

| *curl -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk-admin | jq*

**Step 16 - View Policies (optional)**

Each of the policies listed in CreatePolicies.sh should be returned.

| *curl -s -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/sys/policy | jq*

| *curl -s -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/sys/policy/tapis/sk-acl | jq*

**Step 17 - Create tapisroot Token**

The tapisroot token is a root token that should be used instead of the original root token generated by Vault.  It tapisroot gets compromised it can easily be revoked and replaced.  

Create a file named tapisroot.json with the content::


    {
        "display_name": "tapisroot",
        "policies": [ "root" ],
        "ttl": 0 
    }

Run this command:

| *curl -X POST -s -H "X-Vault-Token: $VAULT_TOKEN" \-\-data @tapisroot.json https://tapis-vault.mydomain.com:8200/v1/auth/token/create | jq*

Save the returned "client_token" in a secure place, such as stache or wherever you saved the original root token and unseal keys.

**Step 18 - Test tapisroot Token (optional)**

To avoid saving the root token to the command history file:  

| *export HISTCONTROL=ignorespace*
|   *export TAPIS_ROOT_TOKEN=xxx*

| *curl -X GET -H "X-Vault-Token: $TAPIS_ROOT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk/role-id | jq*

| *curl -s -X POST -H "X-Vault-Token: $TAPIS_ROOT_TOKEN" https://tapis-vault.mydomain.com:8200/v1/auth/approle/role/sk/secret-id | jq*   

**Step 19 - Remove Secrets from History**

Remove any commands that leaked secrets into the history file.  Enter "history" to see the numbered history records.  To remove by line number:  

| *history -d <line number>*


Vault Backup
=====================================

Tapis configures Vault to run with the `raft <https://developer.hashicorp.com/vault/docs/internals/integrated-storage>`_ storage type by default, which allows Vault to operate normally while its database is backed up.  Vault provides these two administrative `commands <https://developer.hashicorp.com/vault/docs/commands/operator/raft>`_ to save and restore backups:

- *vault operator raft snapshot save <outfile>*
- *vault operator raft snapshot restore <infile>*

Tapis fills the gap in Vault's community edition support by automating periodic backups in Vault VM environments.  The `tapis-vaultbackup <https://github.com/tapis-project/tapis-vaultbackup>`_ repository contains a backup utility program's source code and documentation.  The program can be started in a secure manner to periodically takes snapshots of the Vault database (once a day by default).  The program runs as a daemon until it's shutdown.  Typically, a separate cron job is set up to copy the backup files from the VM to one or more remote data stores as local policy dictates. 

The program is written in Java and packaged as a self-contained executable.  The executable is then packaged into an rpm for use on operating systems that support that package manager.  There are no plans to support other package managers or container runtimes, but everything needed for such support is available in the repository.         


Vault Export
=====================================

The SkExport utility program provides a quick way to extract many Tapis secrets from Vault.  The output is written to stdout as either JSON data or key/value pairs.  One use of this program is to acquire Tapis service secrets and then to inject them into docker containers as environment variables.  SkExport `source code <https://github.com/tapis-project/tapis-security/tree/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands/aux/export>`_ is part of the Security Kernel library and is available as a docker `image <https://hub.docker.com/repository/docker/tapis/securityexport/general>`_.

SkExport parameters::

 SkExport [options...]
  -format (--format) [JSON | ENV] : JSON writes raw Vault data, ENV writes key=value (default: ENV)
  -help (--help)                  : display help information (default: false)
  -nosan (--nosanitize)           : don''t replace unsupported characters with underscore when -format=ENV (default is to sanitize)
  -noskip (--noskipusersecrets)   : don''t skip user secrets (default is to skip)
  -quote (--quoteenv)             : enclose secret values in single quotes when -format=ENV (default: false)
  -v (--verbose)                  : output statistics in addition to secrets (default no statistics)
  -vtok (--vaulttoken) VAL        : Vault token with proper authorization
  -vurl (--vaulturl) VAL          : Vault URL including port, ex: http(s)://host:32342

Running SkExport
----------------

The easiest way to execute SkExport is to run its docker image.  The *-vtok* and *-vurl* parameters are required.  Here's an example of how to export the tapis service secrets (user and system secrets are skipped) in environment variable format with the values single quoted::

    export SKEXPORT_PARMS='-quote -vtok xxxx -vurl https://tapis-vault.mydomain.com:8200'
    docker run --env SKEXPORT_PARMS tapis/securityexport

This example outputs JSON data::

    export SKEXPORT_PARMS='-format=JSON -vtok xxxx -vurl https://tapis-vault.mydomain.com:8200'
    docker run --env SKEXPORT_PARMS tapis/securityexport

Since a token with at least as much authorization as the Security Kernel's token must be used to extract secrets from Vault, and since secrets are being output in the clear, it's important to take proper security precautions when using SkExport.  These precautions include not leaving tokens or secrets in files and deleting sensitive information from the command line history file. 



Revoke / Regenerating Vault Root Tokens
=======================================

Revoking and regenerating Vault Root Tokens is standard practice for Vault. 

Thanks to these sources for providing details for the procedures.

- `Identifying Active Hashicorp Vault Root Tokens <https://www.greenreedtech.com/identifying-active-hashicorp-vault-root-tokens/>`_
- `Generate Root Token <https://developer.hashicorp.com/vault/tutorials/operations/generate-root>`_

Examples of UUIDs, tokens, passwords are randomized below.


**Step 1 - Make a Backup**

Ensure you have a good backup of your Vault before proceeding.

**Step 2 - Generate New Root Token**

Generate a one-time-password::

    # vault operator generate-root -init
    A One-Time-Password has been generated for you and is shown in the OTP field.
    You will need this value to decode the resulting root token, so keep it safe.
    Nonce         8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Started       true
    Progress      0/3
    Complete      false
    OTP           199273364d410af3c520c9460d
    OTP Length    26

Use the OTP & unseal keys to generate an Encoded Token. You must enter 3 different unseal keys::

    vault operator generate-root
    
    # vault operator generate-root
    Operation nonce: 8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Unseal Key (will be hidden): 
    Nonce       8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Started     true
    Progress    1/3
    Complete    false
    
    # vault operator generate-root
    Operation nonce: 8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Unseal Key (will be hidden): 
    Nonce       8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Started     true
    Progress    2/3
    Complete    false
    
    # vault operator generate-root
    Operation nonce: 8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Unseal Key (will be hidden): 
    Nonce            8af5de52-0da3-4896-ab9f-6f0f291f31dc
    Started          true
    Progress         3/3
    Complete         true
    Encoded Token    cd7dc17b468d1c4d0754446b7fe6008aXy1


Decode the encoded token using the OTP::

    # vault operator generate-root -decode=cd7dc17b468d1c4d0754446b7fe6008aXy1 -otp=199273364d410af3c520c9460d
    s.4f31f8b4380afdf78a0c4f2b

Note the New Root Token (*s.4f31f8b4380afdf78a0c4f2b*).


**Step 3 - Find and Revoke the Old Root Token**

In the vault container, list Accessors. There may be several.::

    # vault list auth/token/accessors
    Keys
    ----
    31e7d2f9d581f43758635169
    0a8511c58fdfffa7edea60e9
    aa1faa246e2e4346bc6364d3
    8fea0ebb035d3ffdcc8a5e36

You can use this to look the information for each accessor.::

    # vault list -format json auth/token/accessors | jq -r .[] | xargs -I '{}' vault token lookup -format json -accessor '{}' | jq -r 'select(.data.policies | any(. == "root"))'

For each accessor look for their creation time to identify the one you want to revoke::

    # vault token lookup -format json -accessor 0a8511c58fdfffa7edea60e9 | grep creation
        "creation_time": 1607701202,
        "creation_ttl": 0,

    # vault token lookup -format json -accessor aa1faa246e2e4346bc6364d3 | grep creation
        "creation_time": 1684427946,

    $ date -d @1607701202
    Fri Dec 11 09:40:02 CST 2021

    $ date -d @1684427946
    Thu May 18 11:39:06 CDT 2023


We see that token *0a8511c58fdfffa7edea60e9* is the 2-year-old one so that's the one to revoke.

Revoke the old token::

    # vault token revoke -accessor 0a8511c58fdfffa7edea60e9
    Success! Revoked token (if it existed)

Confirm the old one no longer works::

    # vault list -format json auth/token/accessors
    Error listing auth/token/accessors: Error making API request.

    URL: GET http://127.0.0.1:8200/v1/auth/token/accessors?list=true
    Code: 403. Errors:
    * permission denied

Verify the new one works::

    # export VAULT_TOKEN=s.4f31f8b4380afdf78a0c4f2b
    # vault list -format json auth/token/accessors
    [
      "aa1faa246e2e4346bc6364d3",
      "31e7d2f9d581f43758635169",
      "8fea0ebb035d3ffdcc8a5e36"
    ]

Note the old one is missing.



**Step 4 - Setup Tapis to Use the new Root Token**

- Use burndown script to stop vault.
- Move the old {tapisdatadir}/vault/vault-token out of the way (e.g. `mv vault-token vault-token-20230627-backup`)
- Update vault-token file with new root token.
- Delete vault secrets so they will be recreated.
  - kubectl delete secret vault-keys
  - kubectl delete secret vault-token
- Use burnup script to start vault.
- Restart Security Api. (Go to {tapisdir}/security/api and use the burndown & burnup scripts.)
- Confirm that the sk and vault secrets are just recently recreated::

    # kubectl get secret | grep vault
    tapis-sk-vault-secrets              Opaque                                2      15s
    vault-keys                          Opaque                                3      2m19s
    vault-token                         Opaque                                1      2m20s


