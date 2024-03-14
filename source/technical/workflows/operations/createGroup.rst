Creating a Group (createGroup)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Create a file in your current working directory called ``group.json`` with the following json schema:

.. code-block:: json

  {
    "id": "<group_id>",
    "users": [
        {
          "username":"<user_id>",
          "is_admin": true
        }
    ]
  }

.. note:: You do not need to add your own Tapis id to the users list. The owner of the Group is added by default. 

Replace *<group_id>* with your desired group id and *<user_id>* in the user objects with
the tapis user ids of the other users that you want to grant access to this group's workflow resources.

Submit the definition.

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups -d @group.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    with open('group.json', 'r') as openfile:
      group = json.load(openfile)

    t.workflows.createGroup(**group)