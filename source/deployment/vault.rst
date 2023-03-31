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

Introduction to Tapis Vault
===========================


Deploying Vault in Kubernetes
=============================

Deploying Vault Outside of Kubernetes
=====================================

The procedure below describes how to build a Vault VM, which we'll call tapis-vault.  This procedure can be used as a template for building Vault instances that run in Kubernetes or other environments.  Important security characteristics of this approach are:

- No Vault tokens are ever stored on disk.
- No unseal keys are ever stored on disk.

*The reason not to store these secrets on the Vault machine is because even if the root user is compromised, Vault secrets are inaccessible unless Vault is unsealed and the attacker has a valid token.*

We assume the installation usues the open source version of Hashicorp Vault, so we do not have access to Vault's enterprise features.  

The procedure can be split into two phases.  The first phase requires command line access to the Vault host as root.  The second phase can be performed remotely using the Vault REST APIs and a root token.  

PHASE I - Command Line Execution
--------------------------------

**Step 1 - Acquire TACC VM**

Acquire a TACC VM with a TLS certificate installed.  See the attached example-configureTLS.txt file for directions on how to prepare a chained certificate file at TACC.   

**Step 2 - Install Hashicorp Vault**

SSH into target VM as root.  Follow installation instructions using yum: 

https://learn.hashicorp.com/tutorials/vault/getting-started-install?in=vault/getting-started

**Step 3 - Change Private Key Access**

Now that Vault is installed, change the group of the private key to "vault" and allow group read.  Here's the command used on tapis-vault-prod:

chgrp vault /etc/pki/tls/private/tapis-vault-prod.tacc.utexas.edu.key.20210728
chmod 640 /etc/pki/tls/private/tapis-vault-prod.tacc.utexas.edu.key.20210728

It's also a good idea to create /etc/pki/tls/certs/README.VAULT with contents similar example-configureTLS.txt but customized for your VM.

**Step 4 - Configure Vault for RAFT Storage**

Save the original /etc/vault.d/vault.hcl.  Update /etc/vault.d/vault.hcl to use the RAFT backend.  The attached example-vault.hcl file provides template for your configuration.

**Step 5 - Start Vault**

systemctl enable vault.service 
systemctl start  vault.service
systemctl status vault.service

Test the installation (customize for your hostname):

export VAULT_ADDR=https://tapis-vault-prod.tacc.utexas.edu:8200
vault status

**Step 6 - Initialize Vault**
vault operator init

Five unseal keys and the root token will be written to the screen.  DO NOT SAVE THESE DATA ANYWHERE ON THE FILE SYSTEM.  Instead, copy the information off the screen and save them off the VM.  At TACC, we can use stache.      

**Step 7 - Unseal Vault**
The Vault requires 3 out of the 5 of the unseal keys to unseal.  Issue the operator unseal call 3 times, each time using a different key.

vault operator unseal 
vault status

**Step 8 - Export Root Token**
To avoid saving the root token to the command history file:  export HISTCONTROL=ignorespace 

  export VAULT_TOKEN=xxx

where the command has a leading space and xxx is the token output by the above operator init command.

**Step 9 - Enable Authn Methods and Secrets Engines**

vault secrets enable -version=2 -path=secret kv
vault auth enable approle
vault auth enable userpass

**Step 10 - Check Remote Access**

Before logging off, test remote access by running a status command that will be used in Phase II.  On the remote machine, export the root token.  

To avoid saving the root token to the command history file:  export HISTCONTROL=ignorespace

  export VAULT_TOKEN=xxx
curl -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/sys/health | jq 

**Step 11 - Logoff VM (optional)**

All further configuration will be performed from the remote machine.

PHASE II - Remote Commands
--------------------------

**Step 12 - Create SK Roles**

On the remote machine terminal, export the root token if that's already been done (see Step 10).  Clone the tapis-vault git repo into the current directory.

cd tapis-vault

curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" --data @roles/sk-role.json https://tapis-vault-prod.tacc.utexas.edu:8200/v1/auth/approle/role/sk

curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" --data @roles/sk-admin-role.json https://tapis-vault-prod.tacc.utexas.edu:8200/v1/auth/approle/role/sk-admin

**Step 13 - Test SK Roles (optional)**

curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/approle/role/sk/secret-id | jq
curl -X GET -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/approle/role/sk/role-id | jq

**Step 14 - Create Roles and Policies**

The tapis-vault/CreatePolicies.sh script encapsulates basic policy and role creation needed for Tapis to function.  See comments in the script for details, but basically the script requires:

The current directory to be tapis-vault.
The VAULT_TOKEN environment variable be set to a root token.
The DNS name of the new Vault VM be provided on the command line.
Requirements 1 and 2 where already set in the previous two steps, so an invocation of the script looks like this (but with your VM):

./CreatePolicies.sh tapis-vault-prod.tacc.utexas.edu

**Step 15 - View Roles (optional)**
Each of the roles referenced in CreatePolicies.sh should be returned.

curl -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/approle/role/sk | jq
curl -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/approle/role/sk-admin | jq

**Step 16 - View Policies (optional)**

Each of the policies listed in CreatePolicies.sh should be returned.

curl -s -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/sys/policy | jq
curl -s -H "X-Vault-Token: $VAULT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/sys/policy/tapis/sk-acl | jq

**Step 17 - Create tapisroot Token**

The tapisroot token is a root token that should be used instead of the original root token generated by Vault.  It tapisroot gets compromised it can easily be revoked and replaced.  

Create a file named tapisroot.json with the content:


    {
        "display_name": "tapisroot",
        "policies": [ "root" ],
        "ttl": 0 
    }
Run this command:

curl -X POST -s -H "X-Vault-Token: $VAULT_TOKEN" --data @tapisroot.json https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/token/create | jq

Save the returned "client_token" in a secure place, such as stache or wherever you saved the original root token and unseal keys.

**Step 18 - Test tapisroot Token (optional)**

To avoid saving the root token to the command history file:  export HISTCONTROL=ignorespace

  export TAPIS_ROOT_TOKEN=xxx
curl -X GET -H "X-Vault-Token: $TAPIS_ROOT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/approle/role/sk/role-id | jq
curl -s -X POST -H "X-Vault-Token: $TAPIS_ROOT_TOKEN" https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/approle/role/sk/secret-id | jq   

**Step 19 - Remove Secrets from History**

Remove any commands that leaked secrets into the history file.  Enter "history" to see the numbered history records.  To remove by line number:  

history -d <line number>
