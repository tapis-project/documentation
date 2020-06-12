Projects
---------
Projects are defined at a top level in the hierarchy of Streams resources. A user registers a project by providing metadata information such as the principal Investigator, project URL, funding resource, etc. A list of authorized users can be added to various project roles to have a controlled access over the project resources. When a project is first registered, a collection is created in the back-end MongoDB. User permissions to access this collection are then set up in the security kernel. Every request to access the project resource or documents within (i.e sites, instruments, variables) goes through a security kernel check and only the authorized user requests are allowed to be processed.

**Create Project**

|
.. code-block:: plaintext

        $ t.streams.create_project(project_name='tapis_demo_project',description='project for early demo', owner='testuser6', pi='testuser6', funding_resource='tapis', project_url='test.tacc.utexas.edu', project_id='tapis_demo_project',active=True)

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        active: True
        description: project for early demo
        funding_resource: tapis
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project
        project_name: tapis_demo_project
        project_url: test.tacc.utexas.edu

|


**List Projects**

|
.. code-block:: plaintext

        $ t.streams.list_projects()

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
         active: True
         description: project for early adopters demo
         funding_resource: tapis
         owner: testuser6
         permissions:
         users: ['testuser6']
         pi: ajamthe
         project_id: wq_demo_project12
         project_name: wq_demo_project12
         project_url: test.tacc.utexas.edu,

         active: True
         description: project for early demo
         funding_resource: tapis
         owner: testuser6
         permissions:
         users: ['testuser6']
         pi: testuser6
         project_id: tapis_demo_project
         project_name: tapis_demo_project
         project_url: test.tacc.utexas.edu
        ]

|

**Get project Details**

|
.. code-block:: plaintext

        $ t.streams.get_project(project_uuid='tapis_demo_project')

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        active: True
        description: project for early demo
        funding_resource: tapis
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project
        project_name: tapis_demo_project
        project_url: test.tacc.utexas.edu

|



**Update Project**

|
.. code-block:: plaintext

        $ t.streams.update_project(project_uuid='tapis_demo_project', project_name='tapis_demo_project', pi='testuser6', owner='testuser6', project_url='tapis_demo_project.tacc.utexas.edu')


|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        active: True
        description: project for early demo
        funding_resource: tapis
        last_updated: 2020-06-08 18:18:41.642606
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project
        project_name: tapis_demo_project
        project_url: tapis_demo_project.tacc.utexas.edu

|

