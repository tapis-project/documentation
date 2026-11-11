.. _glossary:

########
Glossary
########

This Glossary is a quick reference for terms you'll see throughout the Tapis documentation. If you're working
through the `Getting Started <../getting-started/index.html>`_ guide and run into a term you don't recognize,
check here first.

Application (App)
    A program registered with Tapis, including the container image it runs and the inputs and arguments it accepts.

Authenticator
    The Tapis service that checks your TACC account credentials and gives you a token.

Base URL
    The web address for a tenant, such as ``https://tacc.tapis.io``. Every request you send to Tapis starts with it,
    so be sure to use the same base URL through every step.

Credential
    The login details, such as an AWS ``accessKey`` and ``accessSecret``, that Tapis stores so it can reach a system for you.

cURL
    A command line tool for transferring data via URLs. The command line examples in this documentation use it.

DEV and PROD Tenants
    DEV tenants are used for testing and are labeled with ``-dev``. PROD tenants are the main production environments.

Job
    One run of an application on a system.

JWT (JSON Web Token)
    The access token Tapis gives you when you log in. You'll include it in the ``X-Tapis-Token`` header of your
    requests so Tapis knows who you are.

S3 Bucket
    A storage container in Amazon AWS S3 where your files are kept.

System
    A storage or computing resource, such as an S3 bucket or a server, registered with Tapis so you can use it
    through the APIs.

Tapis
    An NSF-funded web-based API framework for securely managing computational workloads across infrastructure
    and institutions.

tapipy
    The Tapis Python SDK, used in the Python examples in this documentation.

Tenant
    An instance of Tapis. Each tenant, such as the *tacc* tenant, has its own base URL, users, tokens, systems,
    and apps.
