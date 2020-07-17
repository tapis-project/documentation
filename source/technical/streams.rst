==============
Streams
==============


.. image:: ./tapis-v3-streams-api.png

Projects
---------
Projects are defined at a top level in the hierarchy of Streams resources. A user registers a project by providing metadata information such as the principal Investigator, project URL, funding resource, etc. A list of authorized users can be added to various project roles to have a controlled access over the project resources. When a project is first registered, a collection is created in the back-end MongoDB. User permissions to access this collection are then set up in the security kernel. Every request to access the project resource or documents within (i.e sites, instruments, variables) goes through a security kernel check and only the authorized user requests are allowed to be processed.

**Create Project**

With PySDK:

.. code-block:: plaintext

        $ t.streams.create_project(project_name='tapis_demo_project',description='test project', owner='testuser', pi='testuser', funding_resource='tapis', project_url='test.tacc.utexas.edu', project_id='tapis_demo_project',active=True)

With CURL:

.. code-block:: plaintext

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '{"project_name": "tapis_demo_project", "owner": "testuser","pi": "testuser","description": "test project","funding_resource": "tapis","project_url": "test.tacc.utexas.edu","active": "True"}' $BASE_URL/v3/streams/projects

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        active: True
        description: project for early demo
        funding_resource: tapis
        owner: testuser
        permissions:
        users: ['testuser']
        pi: testuser
        project_id: tapis_demo_project
        project_name: tapis_demo_project
        project_url: test.tacc.utexas.edu

|


**List Projects**

With PySDK:

.. code-block:: plaintext

        $ t.streams.list_projects()

With CURL:

.. code-block:: plaintext

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/streams/projects

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
         active: True
         description: project for early adopters demo
         funding_resource: tapis
         owner: testuser
         permissions:
         users: ['testuser']
         pi: ajamthe
         project_id: wq_demo_project12
         project_name: wq_demo_project12
         project_url: test.tacc.utexas.edu,

         active: True
         description: project for early demo
         funding_resource: tapis
         owner: testuser
         permissions:
         users: ['testuser']
         pi: testuser
         project_id: tapis_demo_project
         project_name: tapis_demo_project
         project_url: test.tacc.utexas.edu
        ]

|

**Get project Details**

With PySDK:

.. code-block:: plaintext

        $ t.streams.get_project(project_uuid='tapis_demo_project')


With CURL:

.. code-block:: plaintext

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/streams/projects/tapis_demo_project

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        active: True
        description: project for early demo
        funding_resource: tapis
        owner: testuser
        permissions:
        users: ['testuser']
        pi: testuser
        project_id: tapis_demo_project
        project_name: tapis_demo_project
        project_url: test.tacc.utexas.edu

|



**Update Project**

With PySDK:

.. code-block:: plaintext

        $ t.streams.update_project(project_uuid='tapis_demo_project', project_name='tapis_demo_project', pi='testuser', owner='testuser', project_url='tapis_demo_project.tacc.utexas.edu')

With CURL:

.. code-block:: plaintext

        $ curl -v -X PUT -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '{"project_name": "test_proj", "owner": "testuser","pi": "testuser","description": "test project for tapis","funding_resource": "tapis","project_url": "test.tacc.utexas.edu","active": "True"}' $BASE_URL/v3/streams/projects/test_proj


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

Sites
---------

Site is a geographical location that may hold one or more instruments. Sites are next in the streams hierarchy and they inherit permissions from the projects. Project owners can create sites by providing the geographical information such as latitude, longitude and elevation of the site or GeoJSON encoded spatial information. This spatial information is useful when searching sites or data based on location. In the back-end database a site is represented as a JSON document within the project collection. Site permissions are inherited from the project.

**Create Site**

|
.. code-block:: plaintext

        $ t.streams.create_site(project_uuid='tapis_demo_project',site_name='tapis_demo_site', site_id='tapis_demo_site', latitude=50, longitude = 10, elevation=2,description='test_site')

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

         chords_id: 27
         created_at: 2020-06-08 18:27:12.416134
         description: test_site
         elevation: 2
         latitude: 50
         location:
         coordinates: [10.0, 50.0]
         type: Point
         longitude: 10
         site_id: tapis_demo_site
         site_name: tapis_demo_site

|


**List Sites**

|
.. code-block:: plaintext

        $ t.streams.list_sites(project_uuid='tapis_demo_project')


|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
         chords_id: 28
         created_at: 2020-06-08 18:29:55.474870
         description: test_site
         elevation: 2
         latitude: 50
         location:
         coordinates: [10.0, 50.0]
         type: Point
         longitude: 10
         site_id: tapis_demo_site1
         site_name: tapis_demo_site1,

         chords_id: 27
         created_at: 2020-06-08 18:27:12.416134
         description: test_site
         elevation: 2
         latitude: 50
         location:
         coordinates: [10.0, 50.0]
         type: Point
         longitude: 10
         site_id: tapis_demo_site
         site_name: tapis_demo_site]

|

**Get site Details**

|
.. code-block:: plaintext

        $ t.streams.get_site(project_uuid='tapis_demo_project', site_id='tapis_demo_site1')


|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        chords_id: 28
        created_at: 2020-06-08 18:29:55.474870
        description: test_site
        elevation: 2
        latitude: 50
        location:
        coordinates: [10.0, 50.0]
        type: Point
        longitude: 10
        site_id: tapis_demo_site1
        site_name: tapis_demo_site1

|



**Update Site**

|
.. code-block:: plaintext

        $

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


|

Instruments
---------------

Instruments are physical entities that may have one or more embedded sensors to sense various parameters such as temperature, relative humidity, specific conductivity, etc. These sensors referred to as variables in Streams API generate measurements, which are stored in the influxDB along with a ISO8601 timestamp. Instruments are associated with specific sites and projects. Information about the instruments such as site and project ids, name and description of the instrument, etc. are stored in the mongoDB sites JSON document.

**Create Instrument**

|
.. code-block:: plaintext

        $ t.streams.create_instrument(project_uuid='tapis_demo_project',topic_category_id ='2',site_id='tapis_demo_site',  inst_name='tapis_demo_instrument',inst_description='demo instrument', inst_id='tapis_demo_instrument')

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

         chords_id: 25
         created_at: 2020-06-08 19:04:45.928533
         inst_description: demo instrument
         inst_id: tapis_demo_instrument
         inst_name: tapis_demo_instrument
         topic_category_id: 2
|


**List Instruments**

|
.. code-block:: plaintext

        $ t.streams.list_instruments(project_uuid='tapis_demo_project', site_id='tapis_demo_site')


|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
         chords_id: 25
         created_at: 2020-06-08 19:04:45.928533
         inst_description: demo instrument
         inst_id: tapis_demo_instrument
         inst_name: tapis_demo_instrument
         topic_category_id: 2]

|

**Get instrument Details**

|
.. code-block:: plaintext

        $ t.streams.list_instruments(project_uuid='tapis_demo_project', site_id='tapis_demo_site',inst_id='tapis_demo_instrument')


|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        [
         chords_id: 25
         created_at: 2020-06-08 19:04:45.928533
         inst_description: demo instrument
         inst_id: tapis_demo_instrument
         inst_name: tapis_demo_instrument
         topic_category_id: 2]

|



**Update Instrument**

|
.. code-block:: plaintext

        $

|

The response will look something like the following:

.. container:: foldable

     .. code-block:: json


|

