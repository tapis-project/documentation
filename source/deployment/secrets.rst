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

Introduction to Tapis Secrets
=============================

Tapis stores all secrets that it uses or manages in `Hashicorp Vault <vault.html>`_.  These secrets include:

- Service passwords
- Database credentials
- Signing key pairs
- Credentials for user systems
- Arbitrary passwords and other secrets

The only Tapis runtime component that can access the Vault is the `Security Kernal (SK) <../technical/security.html>`_.  There is, however, a need to read, write or delete secrets outside of SK, such as when installing or updating Tapis, rotating keys, or when manual action quickly solves a problem.  The `SkAdmin <https://github.com/tapis-project/tapis-security/tree/dev/tapis-securitylib/src/main/java/edu/utexas/tacc/tapis/security/commands>`_ utility program provides such capabilities.  


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