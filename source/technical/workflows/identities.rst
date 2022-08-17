----------
Identities
----------

Identities are mappings between a *Tapis identity* and some *external* identity.
An example of an external identity would be a *Github* user or *Dockerhub* user.

Identities have two primary functions. The first is it serves as a reference to some set of
credentials that are required to access a restricted external resource, such as a Github
repository or Dockerhub image registry. The second is for authenticating the identity of
a user that triggerred a webhook notification from some external resource.

For example, if:
  * *Github* user **jsmith** pushes code to some repository,
  * and has an "on-push" webhook notification configured to make a request the Workflows API(to trigger a pipeline)

We need to know which Tapis user(if any) corresponds to that Github user **jsmith** so we can determine
if **jsmith** is permitted to trigger that pipeline.

.. include:: /technical/workflows/security-note.rst

Identities Attribues Table
~~~~~~~~~~~~~~~~~~~~~~~~~~

+-------------+--------+----------------------------------------------------------+------------------------------------------------------------------------------------------------------------+
| Attribute   | Type   | Example                                                  | Notes                                                                                                      |
+=============+========+==========================================================+============================================================================================================+
| type        | Enum   | github, dockerhub                                        | - For each type of identity, the `credentials` object of the identity will be different. Details to follow |
+-------------+--------+----------------------------------------------------------+------------------------------------------------------------------------------------------------------------+
| name        | String | my-github-identity                                       | - Must be unique to the Tapis user.                                                                        |
+-------------+--------+----------------------------------------------------------+------------------------------------------------------------------------------------------------------------+
| description | String | This is the identity to access my restricted github repo |                                                                                                            |
+-------------+--------+----------------------------------------------------------+------------------------------------------------------------------------------------------------------------+
| credentials | Object |                                                          | - Contains the secret values to access the restricted external resources                                   |
+-------------+--------+----------------------------------------------------------+------------------------------------------------------------------------------------------------------------+

**Identity Examples**

.. tabs::

  .. tab:: Github

    .. code-block:: json

      {
        "type": "github",
        "name": "my-github-identity",
        "description": "My github identity",
        "credentials": {
          "username": "<username>",
          "personal_access_token": "<token>"
        }
      }
  
  .. tab:: Dockerhub

    .. code-block:: json

      {
        "type": "dockerhub",
        "name": "my-dockerhub-identity",
        "description": "My dockerhub identity",
        "credentials": {
          "username": "<username>",
          "token": "<token>"
        }
      }
