**Creating a Group (createGroup)**

Create a file in your current working directory called ``group.json`` with the following json schema:

.. code-block:: json

  {
    "id": "<group_id>",
    "users": [
        {
          "username":"<user_id>",
          "is_admin": false
        }
    ]
  }

.. note:: You do not need to add your own Tapis id to the users list. The owner of the Group is added by default. 

Replace *<group_id>* with your desired group id and *<user_id>* in the user objects with
the ids of any other Tapis users that you want to have access to your workflows resources.

.. warning::
  
  Users with ``is_admin`` flag set to ``true`` can perform every action on all Workflow resources in a Group except for 
  deleting the Group itself (only the Group owner has those permissions)

Submit the definition.

.. tabs::

  .. code-tab:: bash

    curl -X POST -H "content-type: application/json" -H "X-Tapis-Token: $JWT" https://tacc.tapis.io/v3/workflows/groups -d @group.json

  .. code-tab:: python

    import json
    from tapipy.tapis import Tapis


    t = Tapis(base_url='https://tacc.tapis.io', username='<userid>', password='************')
    t.get_tokens()

    with open('group.json', 'r') as file:
      group = json.load(file)

    t.workflows.createGroup(**group)