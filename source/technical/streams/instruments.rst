Instruments
------------
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

