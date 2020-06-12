Sites
------
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

