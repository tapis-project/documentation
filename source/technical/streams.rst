==============
Streams
==============


.. image:: images/tapis-v3-streams-api.png


Projects
---------
Projects are defined at a top level in the hierarchy of Streams resources. A user registers a project by providing metadata information such as the principal Investigator, project URL, funding resource, etc. A list of authorized users can be added to various project roles to have a controlled access over the project resources. When a project is first registered, a collection is created in the back-end MongoDB. User permissions to access this collection are then set up in the security kernel. Every request to access the project resource or documents within (i.e sites, instruments, variables) goes through a security kernel check and only the authorized user requests are allowed to be processed.

**Create Project**
^^^^^^^^^^^^^^^^^^^^^

With PySDK:

.. code-block:: text

        $ t.streams.create_project(project_name='tapis_demo_project_testuser6',description='test project', owner='testuser6', pi='testuser6', funding_resource='tapis', project_url='test.tacc.utexas.edu', project_id='tapis_demo_project_testuser6',active=True)

With CURL:

.. code-block:: text

        $ curl -v -X POST -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '{"project_name": "tapis_demo_project_testuser6",
                                                                "project_id":"tapis_demo_project_testuser6",
                                                                "owner": "testuser6",
                                                                "pi": "testuser6",
                                                                "description": "test project",
                                                                "funding_resource": "tapis",
                                                                "project_url": "test.tacc.utexas.edu",
                                                                "active": "True"}' $BASE_URL/v3/streams/projects

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        active: True
        description: test project
        funding_resource: tapis
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project_testuser6
        project_name: tapis_demo_project_testuser6
        project_url: test.tacc.utexas.edu

|


**List Projects**
^^^^^^^^^^^^^^^^^^^^^
With PySDK:

.. code-block:: text

        $ t.streams.list_projects()

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/streams/projects

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

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
         description: test project
         funding_resource: tapis
         owner: testuser6
         permissions:
         users: ['testuser6']
         pi: testuser6
         project_id: tapis_demo_project_testuser6
         project_name: tapis_demo_project_testuser6
         project_url: test.tacc.utexas.edu,
        ]

|

**Get Project Details**
^^^^^^^^^^^^^^^^^^^^^^^^^^
With PySDK:

.. code-block:: text

        $ t.streams.get_project(project_id='tapis_demo_project_testuser6')


With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt" $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        active: True
        description: project for early demo
        funding_resource: tapis
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project_testuser6
        project_name: tapis_demo_project_testuser6
        project_url: test.tacc.utexas.edu

|


**Update Project**
^^^^^^^^^^^^^^^^^^^^^
With PySDK:

.. code-block:: text

        $ t.streams.update_project(project_id='tapis_demo_project_testuser6', project_name='tapis_demo_project_testuser6', pi='testuser6', owner='testuser6', description= 'changed description',project_url='tapis_demo_project.tacc.utexas.edu')

With CURL:

.. code-block:: text

        $ curl -v -X PUT -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '{"project_name": "tapis_demo_project_testuser6",
                                                                "project_id":"tapis_demo_project_testuser6",
                                                                "owner": "testuser6",
                                                                "pi": "testuser6",
                                                                "description": "changed description",
                                                                "funding_resource": "tapis",
                                                                "project_url": "tapis_demo_project.tacc.utexas.edu",
                                                                "active": "True"}' $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        active: True
        description: changed description
        funding_resource: tapis
        last_updated: 2020-07-20 17:34:58.848079
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project_testuser6
        project_name: tapis_demo_project_testuser6
        project_url: tapis_demo_project.tacc.utexas.edu


**Delete Project**
^^^^^^^^^^^^^^^^^^^^^
With PySDK:

.. code-block:: text

        $ t.streams.delete_project(project_id='tapis_demo_project_testuser6')

With CURL:

.. code-block:: text

        $ curl -X DELETE -H "X-tapis-token:$jwt" $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        active: True
        description: project for early adopters demo
        funding_resource: tapis
        last_updated: 2020-12-04 15:06:41.460343
        owner: testuser6
        permissions:
        users: ['testuser6']
        pi: testuser6
        project_id: tapis_demo_project_testuser6
        project_name: tapis_demo_project_testuser6
        project_url: test.tacc.utexas.edu
        tapis_deleted: True



|

Sites
---------

Site is a geographical location that may hold one or more instruments. Sites are next in the streams hierarchy and they inherit permissions from the projects. Project owners can create sites by providing the geographical information such as latitude, longitude and elevation of the site or GeoJSON encoded spatial information. This spatial information is useful when searching sites or data based on location. In the back-end database a site is represented as a JSON document within the project collection. Site permissions are inherited from the project.

**Create Site**
^^^^^^^^^^^^^^^^^^^^^
With PySDK:

.. code-block:: text

        $ t.streams.create_site(project_id='tapis_demo_project_testuser6',request_body[{"site_name":"tapis_demo_site", "site_id":"tapis_demo_site", "latitude":50,"longitude":10, "elevation":2,"description":"test_site"}])

With CURL:

.. code-block:: text

       $  curl -X POST -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt" --data '[{"site_name":"tapis_demo_site","latitude":50,"longitude":10,"elevation":2,"site_id":"tapis_demo_site", "description":"test_site"}]' $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

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
^^^^^^^^^^^^^^^^^^^^^
With PySDK:

.. code-block:: text

        $ t.streams.list_sites(project_id='tapis_demo_project_testuser6')

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        [
         chords_id: 13
         created_at: 2020-07-20 19:00:55.220397
         description: demo site
         elevation: 1
         latitude: 1.0
         location:
         coordinates: [2.0, 1.0]
         type: Point
         longitude: 2
         site_id: demo_site
         site_name: demo_site,

         chords_id: 12
         created_at: 2020-07-20 18:15:25.404740
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

**Get Site Details**
^^^^^^^^^^^^^^^^^^^^^
With PySDK:


.. code-block:: text

        $ t.streams.get_site(project_id='tapis_demo_project_testuser6', site_id='tapis_demo_site1')


With CURL:

.. code-block:: text

       $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site

The response will look something like the following:

.. container:: foldable

     $ t.streams.get_site(project_id='tapis_demo_project_testuser6', site_id='tapis_demo_site')

     .. code-block:: text

        chords_id: 12
        created_at: 2020-07-20 18:15:25.404740
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



**Update Site**
^^^^^^^^^^^^^^^^^^^^^

With CURL:

.. code-block:: text

        $ curl -X PUT -H "Content-Type:application/json"  -H "X-Tapis-Token:$jwt" -d '{"project_id": "tapis_demo_project_testuser6","site_name":"tapis_demo_site","latitude":10, "longitude":80, "elevation":2, "description":"test site changed"}' $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site


With PySDK

.. code-block:: text

        $ t.streams.update_site(project_id='tapis_demo_project_testuser6',site_name='tapis_demo_site', site_id='tapis_demo_site', latitude=10, longitude = 80, elevation=2,description='test_site changed')


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        chords_id: 4
        created_at: 2020-08-10 19:36:48.649316
        description: test_site changed
        elevation: 2
        last_updated: 2020-08-10 19:37:20.115021
        latitude: 10
        location:
        coordinates: [80.0, 10.0]
        type: Point
        longitude: 80
        site_id: tapis_demo_site
        site_name: tapis_demo_site


**Delete Site**
^^^^^^^^^^^^^^^^^^^^^^^^

With CURL:

.. code-block:: text

        $ curl -X DELETE -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site


With PySDK

.. code-block:: text

        $ t.streams.delete_site(project_id='tapis_demo_project_testuser6', site_id='tapis_demo_site')


|

Instruments
---------------

Instruments are physical entities that may have one or more embedded sensors to sense various parameters such as temperature, relative humidity, specific conductivity, etc. These sensors referred to as variables in Streams API generate measurements, which are stored in the influxDB along with a ISO8601 timestamp. Instruments are associated with specific sites and projects. Information about the instruments such as site and project ids, name and description of the instrument, etc. are stored in the mongoDB sites JSON document.

**Create Instrument**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.create_instrument(project_id='tapis_demo_project_testuser6',site_id='tapis_demo_site',request_body=[{"topic_category_id":"2",  "inst_name":"tapis_demo_instrument","inst_description":"demo instrument", "inst_id":"tapis_demo_instrument"}])

With CURL:

.. code-block:: text

        $ curl -v -X POST -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt" --data '[{"topic_category_id":"2",","inst_name":"tapis_demo_instrument","inst_description":"demo instrument", "inst_id":"tapis_demo_instrument"}]'  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site/instruments



The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        chords_id: 10
        created_at: 2020-07-20 20:09:11.990814
        inst_description: demo instrument
        inst_id: tapis_demo_instrument
        inst_name: tapis_demo_instrument
        topic_category_id: 2

|


**List Instruments**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.list_instruments(project_id='tapis_demo_project_testuser6', site_id='tapis_demo_site')

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site/instruments


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        [
         chords_id: 10
         created_at: 2020-07-20 20:09:11.990814
         inst_description: demo instrument
         inst_id: tapis_demo_instrument
         inst_name: tapis_demo_instrument
         topic_category_id: 2,

         chords_id: 11
         created_at: 2020-07-20 20:14:20.512383
         inst_description: demo instrument
         inst_id: tapis_demo_instrument
         inst_name: tapis_demo_instrument1
         project_id: tapis_demo_project_testuser6
         site_id: tapis_demo_site
         topic_category_id: 2,

         chords_id: 12
         created_at: 2020-07-20 20:20:45.171473
         inst_description: demo instrument
         inst_id: demo_instrument
         inst_name: demo_instrument
         topic_category_id: 2,

         chords_id: 13
         created_at: 2020-07-20 20:21:52.842495
         inst_description: demo instrument
         inst_id: demo_instrument_aj
         inst_name: demo_instrument_aj
         topic_category_id: 2]



|

**Get instrument Details**
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.list_instruments(project_id='tapis_demo_project_testuser6', site_id='tapis_demo_site',inst_id='demo_instrument')

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site/instruments/demo_instrument

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        chords_id: 12
        created_at: 2020-07-20 20:20:45.171473
        inst_description: demo instrument
        inst_id: demo_instrument
        inst_name: demo_instrument
        topic_category_id: 2

|



**Update Instrument**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.update_instrument(inst_id= 'Ohio_River_Robert_C_Byrd_Locks', project_id='wq_demo_tapis_streams_proj2020-08-26T08:41:11.813391', site_id='wq_demo_site', inst_name='test', inst_description='test')

With CURL:

.. code-block:: text

        $ curl -X PUT -H "X-Tapis-token:$jwt" -H "Content-Type:application/json" --data '{"inst_id": "Ohio_River_Robert_C_Byrd_Locks",
        "site_id": "wq_demo_site", "inst_name": "UpdatedNAME","inst_description": "updated descript"}'
        $BASE_URL/v3/streams/projects/wq_demo_tapis_streams_proj2020-08-26T08:41:11.813391/sites/wq_demo_site/instruments/Ohio_River_Robert_C_Byrd_Locks'


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        chords_id: 6
        inst_description: test
        inst_id: Ohio_River_Robert_C_Byrd_Locks
        inst_name: test
        site_chords_id: 7
        updated_at: 2020-08-26 18:40:07.534077
        variables: [
        chords_id: 21
        shortname: temp
        updated_at: 2020-08-26 16:15:49.835211
        var_id: temp
        var_name: temperature,
        chords_id: 22
        shortname: bat
        updated_at: 2020-08-26 16:15:50.349601
        var_id: batv
        var_name: battery,
        chords_id: 23
        shortname: spc
        updated_at: 2020-08-26 16:15:50.749192
        var_id: spc
        var_name: specific_conductivity,
        chords_id: 24
        shortname: turb
        updated_at: 2020-08-26 16:15:51.158687
        var_id: turb
        var_name: turbidity,
        chords_id: 25
        shortname: ph
        updated_at: 2020-08-26 16:15:51.588573
        var_id: ph
        var_name: ph_level]

**Delete Instrument**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.delete_instrument(inst_id= 'tapis_demo_instrument', project_id='tapis_demo_project_testuser6_3', site_id='tapis_demo_site')

With CURL:

.. code-block:: text

        $ curl -X DELETE -H "X-Tapis-token:$jwt" $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6_3/sites/tapis_demo_site/instruments/tapis_demo_instrument

|

Variables
------------

**Create Variables**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.create_variable(project_id='tapis_demo_project_testuser6', inst_id='demo_instrument', site_id='tapis_demo_site', request_body=[{"topic_category_id":"2", "var_name":"battery", "shortname":"bat", "var_id":"batv"}])

With CURL:

.. code-block:: text

        $ curl -v -X POST -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt" --data '{"project_id":"tapis_demo_project_testuser6", "topic_category_id":"2","site_id":"tapis_demo_site", "inst_id":"demo_instrument", "var_name":"battery", "shortname":"bat", "var_id":"batv"}'  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site/instruments/demo_instrument/variables


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        chords_id: 39
        shortname: bat
        updated_at: 2020-07-20 21:51:38.712035
        var_id: batv
        var_name: battery

|


**List Variables**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.list_variables(project_id='tapis_demo_project_testuser6',site_id='tapis_demo_site', inst_id='demo_instrument')

With CURL:

.. code-block:: text

        $ curl -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6/sites/tapis_demo_site/instruments/demo_instrument/variables

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        [
         chords_id: 38
         shortname: bat
         updated_at: 2020-07-20 21:50:46.382558
         var_id: batv
         var_name: battery,

         chords_id: 39
         shortname: bat
         updated_at: 2020-07-20 21:51:38.712035
         var_id: batv
         var_name: battery,

         chords_id: 40
         inst_id: demo_instrument_1
         project_id: tapis_demo_project_testuser6
         shortname: bat
         site_id: tapis_demo_site
         topic_category_id: 2
         updated_at: 2020-07-20 21:56:45.555381
         var_id: batv
         var_name: battery]

|

**Get Variable Details**
^^^^^^^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.get_variable(project_id='tapis_demo_project_testuser6_1', site_id='tapis_site_final', inst_id='tapis_inst_final', var_id='batv')

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6_1/sites/tapis_site_final/instruments/tapis_inst_final/variables/batv

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        [
        chords_id: 21
        shortname: bat
        updated_at: 2020-08-18 20:46:11.673033
        var_id: batv
        var_name: battery]


|

**Update Variable**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.update_variable(var_name='"updated_temp', var_id='temp', shortname='temp_updated', project_id='wq_demo_tapis_streams_proj2020-08-25T16:21:30.113392', site_id='wq_demo_site',inst_id='Ohio_River_Robert_C_Byrd_Locks')

With CURL:

.. code-block:: text

        $ curl -X PUT -H "X-Tapis-token:$jwt" -H "Content-type:application/json"  --data '{ "var_name": "updated_temp","var_id": "temp","shortname":"temp_updated"}' $BASE_URL/v3/streams/projects/wq_demo_tapis_streams_proj2020-08-25T16:21:30.113392/sites/wq_demo_site/instruments/Ohio_River_Robert_C_Byrd_Locks/variables/temp


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        chords_id: 16
        inst_chords_id: 5
        shortname: temp_updated
        site_chords_id: 6
        updated_at: 2020-08-27 14:36:04.271154
        var_id: temp
        var_name: "updated_temp


**Delete Variable**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.delete_variable( var_id='139', project_id='tapis_demo_instrument', site_id='tapis_demo_site',inst_id='tapis_demo_instrument')

With CURL:

.. code-block:: text

        $ curl -v -X DELETE  -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/projects/tapis_demo_project_testuser6_3/sites/tapis_demo_site/instruments/tapis_demo_instrument/variables/batv


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        inst_chords_id: 24
        updated_at: 2020-12-03 02:52:27.437378
        var_id: 139

|


Measurements
--------------

**Create Measurements**
^^^^^^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.create_measurement(inst_id='demo_instrument',vars=[{"batv":10, "temp":90, "datetime":"2020-07-20T22:19:25Z"}])

With CURL:

.. code-block:: text

        $ curl -v -X POST -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt" --data '{"inst_id":"demo_instrument", "vars":[{"datetime":"2020-07-20T23:19:25Z", "batv":10, "temp":90}]}'  $BASE_URL/v3/streams/measurements


The response will look something like the following:

.. container:: foldable

     .. code-block:: json

       {
        "message": "Measurements Saved",
        "result": {
          "batv": {
            "2020-07-20T23:19:25Z": 10
          },
          "temp": {
            "2020-07-20T23:19:25Z": 90
          }
       },
       "status": "success",
       "version": "dev"
      }


|

**List Measurements**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.list_measurements(inst_id='demo_instrument',start_date='2020-05-08T00:00:00Z',end_date='2020-07-21T22:19:25Z', format='csv',project_id='tapis_demo_project_testuser6',site_id='tapis_demo_site')

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/measurements/demo_instrument

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        b'time,batv\n2020-07-20T22:19:25Z,10.0\n2020-07-20T23:19:25Z,10.0\n'


|


Channels
------------

**Channel Alert Types**
^^^^^^^^^^^^^^^^^^^^^^^

.. tabs::
        .. tab:: Threshold Check

                +-------------------+-----------------------+----------------------------------------+---------------------------------------------------------------+
                | Attribute         | Type                  | Example                                | Note                                                          |
                +===================+=======================+========================================+===============================================================+
                | key               | String                | "my_instrument_id.my_variable_id"      | should be in the format of <instrument_id>.<varaible_id>      |
                +-------------------+-----------------------+----------------------------------------+---------------------------------------------------------------+
                | operator          | String                | ">", "<"                               | (default is "<")                                              |
                +-------------------+-----------------------+----------------------------------------+---------------------------------------------------------------+
                | val               | Integer               |  3                                     |                                                               |
                +-------------------+-----------------------+----------------------------------------+---------------------------------------------------------------+

                Refer to https://docs.influxdata.com/influxdb/v2.0/api/#operation/CreateCheck for more infomation of each attribute parameter
        
        .. tab:: Deadman Check

                .. _InfluxDB: https://docs.influxdata.com/flux/v0.x/data-types/basic/duration/
                
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+
                | Attribute         | Type                  | Example                                         |                                                                                                    |
                +===================+=======================+=================================================+====================================================================================================+
                | key               | String                | "my_instrument_id.my_variable_id"               | should be in the format of <instrument_id>.<varaible_id>                                           |
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+
                | time_since        | String                | "3s"                                            | \*refer to InfluxDB_ for more info on valid duration type                                          |
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+
                | stale_time        | String                | "1m"                                            | \*(Optional) If value is not provided, stale_time will be calculated to produce a max of 20 action |
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+
                | report_zero       | Boolean               | True, False                                     | \*(Optional) If only zero values reported since time, trigger an alert                             |
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+
                | every             | String                | "1m"                                            | \*(Optional) If value is not provided, default will be "10s"                                       |
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+
                | offset            | String                | "1m"                                            | \*(Optional) If value is not provided, default will be "0s"                                        |
                +-------------------+-----------------------+-------------------------------------------------+----------------------------------------------------------------------------------------------------+

                Refer to https://docs.influxdata.com/influxdb/v2.0/api/#operation/CreateCheck for more infomation of each attribute parameter

**Channel Actions**
^^^^^^^^^^^^^^^^^^^^^
The type of actions that a channel should be performed can be defined under the action parameter within a triggers_with_actions object.

.. tabs::
        .. tab:: Actor

                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | Attribute         | Type                  | Example                                                               |
                +===================+=======================+=======================================================================+
                | method            | String                | "ACTOR"                                                               |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | actor_id          | String                | "my_actor"                                                            |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | message           | String                | "X instrument have exceeded the threshold of Y"                       |
                +-------------------+-----------------------+-----------------------------------------------------------------------+

        .. tab:: Job

                .. _Jobs: https://tapis.readthedocs.io/en/latest/technical/jobs.html

                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | Attribute         | Type                  | Example                                                               |
                +===================+=======================+=======================================================================+
                | method            | String                | "JOB"                                                                 |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | job_param         | Object                | see Jobs_ section for more information                                |
                +-------------------+-----------------------+-----------------------------------------------------------------------+

        .. tab:: Slack

                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | Attribute         | Type                  | Example                                                               |
                +===================+=======================+=======================================================================+
                | method            | String                | "SLACK"                                                               |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | webhook_url       | String                | "https://hooks.slack.com/services/XXXX"                               |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | message           | String                | "X instrument have exceeded the threshold of Y"                       |
                +-------------------+-----------------------+-----------------------------------------------------------------------+

        .. tab:: Discord

                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | Attribute         | Type                  | Example                                                               |
                +===================+=======================+=======================================================================+
                | method            | String                | "DISCORD"                                                             |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | webhook_url       | String                | "https://discord.com/api/webhooks/XXXX"                               |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | message           | String                | "X instrument have exceeded the threshold of Y"                       |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
        
        .. tab:: HTTP Webhook

                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | Attribute         | Type                  | Example                                                               |
                +===================+=======================+=======================================================================+
                | method            | String                | "WEBHOOK"                                                             |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | webhook_url       | String                | "https://api.services.com/webhooks/XXXX"                              |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | data_field        | String                | "content", "text", "message" (field name for webhook message)         |
                +-------------------+-----------------------+-----------------------------------------------------------------------+
                | message           | String                | "X instrument have exceeded the threshold of Y"                       |
                +-------------------+-----------------------+-----------------------------------------------------------------------+

**Create Channels**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.create_channels(channel_id="demo.tapis.channel",
                                    channel_name='demo.tapis.channel', 
                                    template_id="demo_channel_template",
                                    triggers_with_actions=[{
                                        "inst_ids":["demo_instrument"],
                                        "condition":{
                                                "key":"demo_instrument.batv",
                                                "operator":">", 
                                                "val":20 },
                                        "action":{
                                                "method":"ACTOR",
                                                "actor_id" :"XXXX",
                                                "message":"Instrument: demo_instrument exceeded threshold", "abaco_base_url":"https://api.tacc.utexas.edu","nonces":"XXXX-YYYY-ZZZZ" 
                                }}])

With CURL:

.. code-block:: text

        $ curl -v -X POST -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt" --data '{"channel_id":"demo.tapis.channel","channel_name":"demo.tapis.channel_1","template_id":"demo_channel_template","triggers_with_actions":[{"inst_ids":["demo_instrument"],"condition":{"key":"demo_instrument.batv","operator":">", "val":"20"}, "action":{"method":"ACTOR","actor_id" :"XXXX","message":"Instrument: demo_instrument batv exceeded threshold", "abaco_base_url":"https://api.tacc.utexas.edu","nonces":"XXXX-YYYY-ZZZZ"}}]}'  $BASE_URL/v3/streams/channels


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        channel_id: demo.tapis.channel
        channel_name: demo.tapis.channel
        create_time: 2020-07-21 03:02:51.755215
        last_updated: 2020-07-21 03:02:51.755227
        permissions:
        users: ['testuser6']
        status: ACTIVE
        template_id: demo_channel_template
        triggers_with_actions: [
        action:
        abaco_base_url: https://api.tacc.utexas.edu
        actor_id: XXXX
        message: Instrument: demo_instrument exceeded threshold
        method: ACTOR
        nonces: XXXX-YYYY-ZZZZ
        condition:
        key: demo_instrument.batv
        operator: >
        val: 20
        inst_ids: ['demo_instrument']]

**List Channels**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.list_channels()

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/channels

The response will look something like the following:

.. container:: foldable

  .. code-block:: json

    {
      "message": "Channels found",
      "result": [],
      "status": "success",
      "version": "dev"
    }

|

**Get Channel Details**
^^^^^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.get_channel(channel_id='demo.tapis.channel')

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/channels/demo.tapis.channel

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        channel_id: demo.tapis.channel
        channel_name: demo.tapis.channel
        create_time: 2020-07-21 03:02:51.755215
        last_updated: 2020-07-21 03:02:51.755227
        permissions:
        users: ['testuser6']
        status: ACTIVE
        template_id: demo_channel_template
        triggers_with_actions: [
        action:
        abaco_base_url: https://api.tacc.utexas.edu
        actor_id: XXXX
        message: Instrument: demo_instrument exceeded threshold
        method: ACTOR
        nonces: XXXX-YYYY-ZZZZ
        condition:
            key: demo_instrument.batv
            operator: >
            val: 20
            inst_ids: ['demo_instrument']]

|

**Update Channels**:
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

       $ t.streams.update_channel(channel_id="test1", channel_name='demo.wq.channel', template_id="demo_channel_template",triggers_with_actions=[{"inst_ids":[
       "Ohio_River_Robert_C_Byrd_Locks"],"condition":{"key":"Ohio_River_Robert_C_Byrd_Locks.temp","operator":">", "val":30},
       "action":{"method":"ACTOR","actor_id" :"XXXX","message":"Instrument: Ohio_River_Robert_C_Byrd_Locks  exceeded threshold",
       "abaco_base_url":"https://api.tacc.utexas.edu","nonces":"XXXX-YYYY-ZZZZ" }}])

With CURL:

.. code-block:: text

        $ curl -X PUT -H "X-Tapis-Token:$jwt" -H "Content-Type:application/json" $BASE_URL/v3/streams/channels/test1 -d '{"channel_id": "test1","channel_name":"demo.wq.channel","template_id": "demo_channel_template",
        "triggers_with_actions": [{"inst_ids": ["Ohio_River_Robert_C_Byrd_Locks" ],
        "condition": {"key": "Ohio_River_Robert_C_Byrd_Locks.temp","operator": ">","val": "40" } }]}'

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        channel_id: test1
        channel_name: demo.wq.channel
        create_time: 2020-08-18 20:51:41.350377
        last_updated: 2020-08-18 21:57:42.174860
        permissions:
        users: ['testuser2']
        status: ACTIVE
        template_id: demo_channel_template
        triggers_with_actions: [
        action:
        abaco_base_url: https://api.tacc.utexas.edu
        actor_id: XXXX
        message: Instrument: Ohio_River_Robert_C_Byrd_Locks  exceeded threshold
        method: ACTOR
        nonces: XXXX-YYYY-ZZZZ
        condition:
        key: Ohio_River_Robert_C_Byrd_Locks.temp
        operator: >
        val: 30
        inst_ids: ['Ohio_River_Robert_C_Byrd_Locks']]

|

**Update Channels Status**
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.update_status(channel_id='demo.tapis.channel', status='INACTIVE')

With CURL:

.. code-block:: text

        $ curl -X POST -H "Content-Type:application/json" -H "X-Tapis-Token:$jwt" -d '{"status":"INACTIVE"}' $BASE_URL/v3/streams/channels/demo.tapis.channel

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        channel_id: demo.tapis.channel
        channel_name: demo.tapis.channel
        create_time: 2020-07-21 03:02:51.755215
        last_updated: 2020-07-22 18:09:19.940080
        permissions:
        users: ['testuser6']
        status: INACTIVE
        template_id: demo_channel_template
        triggers_with_actions: [
        action:
        abaco_base_url: https://api.tacc.utexas.edu
        actor_id: XXXX
        message: Instrument: demo_instrument exceeded threshold
        method: ACTOR
        nonces: XXXX-YYYY-ZZZZ
        condition:
        key: demo_instrument.batv
        operator: >
        val: 90
        inst_ids: ['demo_instrument']]

|

Templates
-----------
**Create Template**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.create_template(template_id='test_template_for_tutorial', type='stream',
                script=' var crit lambda \n var channel_id string\n stream\n    |from()\n        .measurement(\'tsdata\')\n        '
                       ' .groupBy(\'var\')\n   |alert()\n       '
                       ' .id(channel_id +  \' {{ .Name }}/{{ .Group }}/{{.TaskName}}/{{index .Tags \"var\" }}\')\n         .crit(crit)\n    .noRecoveries()\n      '
                       '  .message(\'{{.ID}} is {{ .Level}} at time: {{.Time}} as value: {{ index .Fields \"value\" }} exceeded the threshold\')\n       '
                       ' .details(\'\')\n         .post()\n         .endpoint(\'api-alert\')\n     .captureResponse()\n    |httpOut(\'msg\')', _tapis_debug=True)





The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        create_time: 2020-07-22 15:30:58.244391
        last_updated: 2020-07-22 15:30:58.244407
        permissions:
        users: ['testuser6']
        script:  var crit lambda
         var channel_id string
         stream
            |from()
                .measurement('tsdata')
                 .groupBy('var')
           |alert()
                .id(channel_id +  ' {{ .Name }}/{{ .Group }}/{{.TaskName}}/{{index .Tags "var" }}')
                 .crit(crit)
            .noRecoveries()
                .message('{{.ID}} is {{ .Level}} at time: {{.Time}} as value: {{ index .Fields "value" }} exceeded the threshold')
                .details('')
                 .post()
                 .endpoint('api-alert')
             .captureResponse()
            |httpOut('msg')
        template_id: test_template_for_tutorial
        type: stream

|

**List Templates**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        $ t.streams.list_templates()

With CURL:

.. code-block:: text

        $ curl -H "X-Tapis-Token:$jwt"  $BASE_URL/v3/streams/templates

The response will look something like the following:

.. container:: foldable

     .. code-block:: json

        {
         "message": "Templates found",
         "result": [],
         "status": "success",
         "version": "dev"
       }



|

**Get Template Details**
^^^^^^^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.get_template(template_id='test_template_for_tutorial')

With CURL:

.. code-block:: text

        $ curl  -H "X-Tapis-Token:$jwt" $BASE_URL/v3/streams/templates/test_template_for_tutorial


The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        create_time: 2020-07-22 15:30:58.244391
        last_updated: 2020-07-22 15:30:58.244407
        permissions:
        users: ['testuser6']
        script:  var crit lambda
         var channel_id string
         stream
            |from()
                .measurement('tsdata')
                 .groupBy('var')
           |alert()
                .id(channel_id +  ' {{ .Name }}/{{ .Group }}/{{.TaskName}}/{{index .Tags "var" }}')
                 .crit(crit)
            .noRecoveries()
                .message('{{.ID}} is {{ .Level}} at time: {{.Time}} as value: {{ index .Fields "value" }} exceeded the threshold')
                .details('')
                 .post()
                 .endpoint('api-alert')
             .captureResponse()
            |httpOut('msg')
        template_id: test_template_for_tutorial
        type: stream


|

**Update Template**
^^^^^^^^^^^^^^^^^^^^^
With PySDK

.. code-block:: text

        t.streams.update_template(template_id='test_template_for_tutorial', type='stream',
                script=' var period=5s\n var every=0s\n var crit lambda \n var channel_id string\n stream\n    |from()\n        .measurement(\'tsdata\')\n        '
                       ' .groupBy(\'var\')\n   |alert()\n       '
                       ' .id(channel_id +  \' {{ .Name }}/{{ .Group }}/{{.TaskName}}/{{index .Tags \"var\" }}\')\n         .crit(crit)\n    .noRecoveries()\n      '
                       '  .message(\'{{.ID}} is {{ .Level}} at time: {{.Time}} as value: {{ index .Fields \"value\" }} exceeded the threshold\')\n       '
                       ' .details(\'\')\n         .post()\n         .endpoint(\'api-alert\')\n     .captureResponse()\n    |httpOut(\'msg\')', _tapis_debug=True)



The response will look something like the following:

.. container:: foldable

     .. code-block:: text

        create_time: 2020-08-19 19:48:59.177935
        last_updated: 2020-08-19 19:50:00.102827
        permissions:
        users: ['testuser2']
        script:  var period=5s
         var every=0s
         var crit lambda
         var channel_id string
         stream
            |from()
                .measurement('tsdata')
                 .groupBy('var')
           |alert()
                .id(channel_id +  ' {{ .Name }}/{{ .Group }}/{{.TaskName}}/{{index .Tags "var" }}')
                 .crit(crit)
            .noRecoveries()
                .message('{{.ID}} is {{ .Level}} at time: {{.Time}} as value: {{ index .Fields "value" }} exceeded the threshold')
                .details('')
                 .post()
                 .endpoint('api-alert')
             .captureResponse()
            |httpOut('msg')
        template_id: test_template_update
        type: stream

|

Alerts
-----------

**List Alerts**
^^^^^^^^^^^^^^^^^^^^^

With PySDK

.. code-block:: text

        $ t.streams.list_alerts(channel_id='demo_wq_channel2020-06-19T17_34_46.425419')


With CURL:

.. code-block:: text

        $ curl  -H "X-Tapis-Token:$jwt" $BASE_URL/v3/streams/channels/demo_wq_channel2020-06-19T17_34_46.425419/alerts

The response will look something like the following:

.. container:: foldable

     .. code-block:: text

            alerts: [
                actor_id: XXXX
                alert_id: 70fa63b4-c6b1-45a4-91a8-f4e9803ec898
                channel_id: demo_wq_channel2020-06-19T17_34_46.425419
                channel_name: demo.wq.channel
                create_time: 2020-06-19 20:51:44.390887
                execution_id: 7mBGaJbD4q0M1
                message: demo_wq_channel2020-06-19T17_34_46.425419 tsdata/var=11/demo_wq_channel2020-06-19T17_34_46.425419/11 is CRITICAL at time: 2020-06-19 20:51:43.229988 +0000 UTC as value: 150 exceeded the threshold,
                actor_id: XXXX
                alert_id: c16ab843-8417-4af0-a06c-ce1e4e7e4816
                channel_id: demo_wq_channel2020-06-19T17_34_46.425419
                channel_name: demo.wq.channel
                create_time: 2020-06-19 20:51:21.138143
                execution_id: ByOkp5W8Jxkqj
                message: demo_wq_channel2020-06-19T17_34_46.425419 tsdata/var=11/demo_wq_channel2020-06-19T17_34_46.425419/11 is CRITICAL at time: 2020-06-19 20:51:20.114319 +0000 UTC as value: 150 exceeded the threshold,
                actor_id: XXXX
                alert_id: 4c4b7e70-a034-419b-be8c-2c337803e5d4
                channel_id: demo_wq_channel2020-06-19T17_34_46.425419
                channel_name: demo.wq.channel
                create_time: 2020-06-19 20:51:10.454269
                execution_id: jboJWNqRKAA6V
                message: demo_wq_channel2020-06-19T17_34_46.425419 tsdata/var=11/demo_wq_channel2020-06-19T17_34_46.425419/11 is CRITICAL at time: 2020-06-19 20:51:09.862752 +0000 UTC as value: 150 exceeded the threshold]
                num_of_alerts: 3
            ]

|


Roles
-----------
Streams service uses **roles**  to manage permissions on the streams resources. CRUD operations on Streams resources such as Sites, Instruments and  Variables can be performed by authorized users having a specific role on the Project. Similarly CRUD operations on Channels and Templates can be done by authorized users having specific roles. Streams service supports three types of roles: *admin*, *manager* and *user*.

**Admin** has elevated privileges. An *admin* can create, update, or delete any of the Streams resources.

**Manager** can perform all read and write operations on Streams resources, with an exception of deleting them.

**User** can only perform read operations on the resources and are not authorized to write or delete the resources.

Table 1 below summarizes the authorized actions with respect to user roles.

+---------------------+-------------------------------------+
| Role                |   Request permitted                 |
+=====================+================+====================+
| admin               |  GET, PUT, POST, DELETE             |
|                     |                                     |
+---------------------+-------------------------------------+
| manager             |  GET, PUT, POST                     |
|                     |                                     |
+---------------------+-------------------------------------+
| user                |  GET                                |
|                     |                                     |
+---------------------+-------------------------------------+

When a user creates project, channel or template, an admin role of the form: **streams_projects_$project-oid_admin**, **streams_channels_$channel-oid_admin** or **streams_templates_$template-oid_admin**, respectively is created in the Security Kernel and is assigned to the requesting (JWT) user. Oid is the unique object id generated by the backend MongoDB for each of the Project, Channel or Template.

Admins can further grant roles such as **admin**, **manager** or **user** for other users listed on the project. To perform CRUD operations on Projects, Sites, Instruments and Variables, users must have appropriate role on the Project.
To perform CRUD operation on either Channels and Templates, users must have role associated with each of the resources.


**List Roles**
^^^^^^^^^^^^^^^^^^^^^
To get the list of user roles on a project, channel or template, the requesting(JWT) user must provide following three parameters:

 1) **resource_type** : project/channel/template

 2) **resource_id**: project_id/channel_id/template_id

 3) **user**: username for whom roles are to be checked

In order to list the user roles on a resource (Project, Channel, Template) the requesting(JWT) user must have one of the three roles (admin, manager, user) on it.

With PySDK

.. code-block:: text

        $ t.streams.list_roles(resource_id=<resource_id>, user=<username>,resource_type='project')
        $ t.streams.list_roles(resource_id=<resource_id>, user=<username>,resource_type='channel')
        $ t.streams.list_roles(resource_id=<resource_id>, user=<username>,resource_type='template')


With CURL:

.. code-block:: text


        $ curl -H "X-Tapis-Token:$jwt" {BASE_URL}/v3/streams/roles?user={userid}&resource_type={project/channel/template}&resource_id={project_id/channel_id/template_id}



The response will look like the following with the Python Client:

.. container:: foldable

     .. code-block:: text

            result: ['admin']

|

There are three possible responses depending on if the requesting(JWT) user and user specified in query parameters are same or different.

Case I: When requesting(JWT) user and user specified in the query parameters are same and both have role on the project/channel/template
The result will include all the roles for the user in query parameters for the given resource_id

.. container:: foldable

     .. code-block:: json

            {
             "message": "Roles found",
             "result": [
                "admin"
            ],
            "status": "success",
            "version": "dev"
            }

Case II: When requesting(JWT) user and user specified in the query parameters are different and JWT user does not have any role on the project/channel/template

.. container:: foldable

     .. code-block:: json

        {
           "message": "User not authorized to access roles",
           "result": "",
           "status": "success",
           "version": "dev"
        }


Case III: When requesting(JWT) user and user specified in the query parameters are different. JWT user has role on the project and user in query parameter does not have role on the project/channel/template

.. container:: foldable

     .. code-block:: json

            {
               "message": "Roles not found",
               "result": "",
               "status": "success",
               "version": "dev"
            }


**Grant Roles**
^^^^^^^^^^^^^^^^^^^^^
Roles can be granted by Project/Channel/Template *admins* or *managers* so that users can perform CRUD operations on the Streams resources.

Table 2 below shows that *admin* can grant any of the three roles to other users. Same or lower level permissions can be granted by *admins* and *managers*. Self role granting is not permitted.

Managers can only grant *manager* and *user* to other users.

Users do **not** have privileges to grant roles.

- Roles of the requesting(JWT) user are first checked by querying SK.

- If the username provided in the request body is the same as the JWT user, then self role granting is not permitted.

- If the JWT user and user provided in the request body are different, then existing roles for the username provided in the request body are retrieved and if the user already has the role, JWT user user is asking for no action is taken.

- If the role does not exist then JWT user roles are retrieved and compared with the rolename provided in the request body. Role is granted only if the JWT user has **same** or **higher** roles than the role name specified in the request body (*admin* role has highest rank, followed by *manager* and then *user*). Otherwise an error message saying, *User not authorized to grant role* is given in the response.


+---------------------+------------------------+
| Role                | Grant                  |
+=====================+========================+
| admin               |  admin, manager, user  |
|                     |                        |
+---------------------+------------------------+
| manager             |  manager, user         |
|                     |                        |
+---------------------+------------------------+
| user                |  cannot grant roles    |
|                     |                        |
+---------------------+------------------------+

With PySDK

.. code-block:: text

        $ t.streams.grant_role(resource_id=<resource_id>, user=<user>,resource_type='project/channel/template',role_name='admin/manager/user')


With CURL:

.. code-block:: text

        $ curl -X POST -H "X-Tapis-Token:$jwt" {BASE_URL}/v3/streams/roles

        Request body: { "user":"user_id",
                       "resource_type":"project/channel/template",
                       "resource_id":"project_uuid/channel_id/template_id",
                       "role_name": "admin/manager/user"
                      }


The response will vary based on following cases:

Case I: If the username provided in the request body is the same as the JWT user, then self role granting is not permitted.

With PySDK

.. code-block:: text

        $ t.streams.grant_role(resource_id='test_proj', user='testuser2',resource_type='project',role_name='manager')


.. container:: foldable

     .. code-block:: json

        {
          "message": "Cannot grant role for self",
          "metadata": {},
          "result": "",
          "status": "error",
          "version": "dev"}

Case II: If the JWT user and username provided in the request body are different, then existing roles for the username provided in the request body are retrieved and if the user already has the role JWT user user is asking for, no action is taken.

With PySDK

.. code-block:: text

        $ t.streams.grant_role(resource_id='test_proj', user='testuser6',resource_type='project',role_name='manager')

.. container:: foldable

     .. code-block:: json

        {
            "message": "Role already exists",
            "metadata": {},
            "result": [
                "manager"
            ],
            "status": "success",
            "version": "dev"
        }

Case III: If the role does not exist then JWT user roles are retrieved and compared with the rolename provided in the request body. Role is granted only if the JWT user has **same** or **higher*** roles than the role name specified in the request body. Otherwise an error message saying, “User not authorized to grant role” is given in the response.

For example testuser4 has ***manager** role on the project and the request is to grant testuser5 **admin*** role, then the request will not be fulfilled.

.. code-block:: text

        $ t.streams.grant_role(resource_id='test_proj', user='testuser5',resource_type='project',role_name='admin')

.. container:: foldable

     .. code-block:: json

        {
           "message": "Role admin cannot be granted",
           "result": "",
           "status": "error",
           "version": "dev"
        }

If the requesting (JWT) user only has a **user*** role, then no role can be granted to other users, and the response will be following

.. container:: foldable

     .. code-block:: json

        {
           "message": "Role manager cannot be granted",
           "result": "",
           "status": "error",
           "version": "dev"
        }


Case IV: If the requesting (JWT) user has no role on the project/channel/template, then the user is not authorized to grant any roles

.. container:: foldable

     .. code-block:: json

            {
               "message": "User not authorized to grant role",
               "result": "",
               "status": "error",
               "version": "dev"
            }

**Revoke Roles**
^^^^^^^^^^^^^^^^^^^^^

Users in **admin** role are capable of revoking any of the three roles: **admin**, **manager** and **user** for other users. Self role revoking is not permitted.
Users in *manager* and *user* role are not capable of revoking roles.

+---------------------+------------------------+
| Role                | Revoke                 |
+=====================+========================+
| admin               |  admin, manager, user  |
|                     |                        |
+---------------------+------------------------+
| manager             |  Cannot revoke role    |
|                     |                        |
+---------------------+------------------------+
| user                |  Cannot revoke role    |
|                     |                        |
+---------------------+------------------------+


With PySDK

.. code-block:: text

        $ permitted_client.streams.revoke_role(resource_id='test_proj', user='testuser6',resource_type='project',role_name='manager')

With CURL:

.. code-block:: text

        $ curl -X POST -H "X-Tapis-Token:$jwt" {BASE_URL}/v3/streams/revokeRole

        Request body: { "user":"user_id",
                       "resource_type":"project/channel/template",
                       "resource_id":"project_uuid/channel_id/template_id",
                       "role_name": "admin/manager/user"
                      }



The response will be following:

.. container:: foldable

     .. code-block:: json

         {
          "message": "Role manager successfully deleted for user testuser6",
          "metadata": [],
          "result": "",
          "status": "success",
          "version": "dev"
        }

Responses will vary based on following cases:

Case I: If the requesting (JWT) user has a **manager** or **user** role

.. container:: foldable

     .. code-block:: json

        {
           "message": "User not authorized to revoke role",
           "result": "",
           "status": "error",
           "version": "dev"
        }

Case II: If the JWT user is trying to revoke self role

.. container:: foldable

     .. code-block:: json

            {
               "message": "Cannot delete role for self",
               "result": "",
               "status": "error",
               "version": "dev"
            }
