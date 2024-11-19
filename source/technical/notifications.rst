.. _notifications:

=============
Notifications
=============

The Notifications service supports the publish-subscribe model for delivering information to intereseted parties.
Currently only a Tapis service may directly create subscriptions and post events through this service. Users may
subscribe to job related events by creating subscriptions through the Jobs service. 
For more information on creating subscriptions through the Jobs service, please see `Job Subscriptions`_

.. _Job Subscriptions: https://tapis.readthedocs.io/en/latest/technical/jobs.html#subscriptions

.. warning::
  Currently subscriptions for notifications may only be managed through the Tapis Jobs service.


--------
Overview
--------
In Tapis, a notification *event* represents an occurrence that may be of interest to other parties. The
events are delivered asynchronously using a publish-subscribe model. Once an interested party has created a
*subscription*, matching *events* are delivered to the interested party as part of a *notification* object.
Deliveries are made via webhook or email. 

Currently only services may directly create subscriptions and publish events.

The model for a notification event is based on the CloudEvent specification version 1.0.
For more information about CloudEvents and the specification, please see https://cloudevents.io and
https://github.com/cloudevents/spec.


Please note that although currently the Notifications service is only accessed by users through the Jobs
service, this document discusses the general design and details of the service in order to provide
information for future planned development.

-----------
Event Model
-----------
An event contains the attributes listed below. The attributes *source*, *type* and *timestamp* are required.
Note that some attributes are maintained by Tapis, they are present when the event is part of a delivered
notification. The attributes maintained by Tapis may be present when publishing an event, but they will
be ignored.

Event attributes:

*source*
  Context in which the event happened. For example, for a job related event originating from Tapis at the
  primary TACC site, the source would be ``https://tapis.io/jobs``.
*type*
  Type of event. Used for routing notifications. A series of 3 fields separated by the dot character.
  The first field is the service name, the second field is the category and the third field is the detail.
  For example, when a job transitions to the FINISHED state, the type is ``jobs.JOB_NEW_STATUS.FINISHED``.
*subject*
  Subject of event in context of service. Examples: job Id, system Id, file path, role name, etc.
*timestamp*
  When the event happened.
*data*
  Optional. Additional information associated with the event. For example, data specific to the service associated
  with the event.
*seriesId*
  Optional. Id to be used for grouping events from the same tenant, source and subject. In a series,
  event order is preserved when sending out notifications. For example, the Jobs service (the source) sends out
  events with the job UUID as the subject and sets the seriesId to the job UUID. That way, a subscription can be
  created to follow (in order) all events of various types related to the job.
*deleteSubscriptionsMatchingSubject*
  Boolean indicating that all subscriptions whose *subjectFilter* matches the *subject* of the event should
  be deleted once all notifications are delivered.
*tenant*
  Tapis tenant associated with the event.
*uuid*
  Tapis generated unique identifier for the event.
*user*
  Tapis user associated with the event.
*received*
  Tapis generated timestamp for when the event was received by the Notifications service.
*seriesSeqCount*
  Tapis generated counter for seriesId. Can be used by notification receivers to track expected order.
  Notifications for events will be sent in order but may not be received in order.

Note that events are not persisted by the front end api service process. When events are received they are sent
to a message broker for asynchronous processing. The back end process will persist events temporarily in order
to support recovery.

Event Type
~~~~~~~~~~

An event type represents a channel through which users and services receive events. Services and users create
subscriptions with an event type filter in order to select the events delivered to them. The identifier for each
event type must have three parts in the format **<service>.<category>.<detail>**.
For example *jobs.JOB_NEW_STATUS.PENDING*, *apps.APP.UPDATE* or *files.OBJECT.DELETE*.

------------
Subscription
------------
A service can create a subscription for an event type in order to allow users and services to receive events.
Two delivery methods are supported, WEBHOOK and EMAIL.

At a high level, a subscription contains the following information:

*name*
  Optional short descriptive name. *owner+name* must be unique. Composed of alphanumeric characters and the following
  special characters: ``-._~``. If not provided, the service will create one.
*owner*
  A specific user set at create time. Default is *${apiUserId}*.
*description*
  An optional more verbose description.
*typeFilter*
  Filter to use when matching events. Matches against event type. Has three parts for matching
  *<service>.<category>.<detail>*. Each field may be a specific type or the wildcard character ``*``.
*subjectFilter*
  Filter to use when matching events. Matches against event subject. This may be a specific subject such as a job Id
  or the wildcard character, ``*``.
*deliveryTargets*
  List of targets to be used when delivering an event. Each target includes delivery method (EMAIL or WEBHOOK) and
  delivery address.
*ttlMinutes*
  Time to live in minutes. Specified when subscription created. Default is one week from creation.
  A TTL of 0 or less indicates no expiration. May be updated through an API call. Attribute *expiry* is recomputed when
  this attribute is updated.
*expiry*
  Time at which the subscription expires. Maintained by the service. Computed at create time and recomputed when attribute
  *ttlMinutes* is updated.

The attributes *typeFilter*, *subjectFilter* and *deliveryTargets* are required.

Subscription Name
~~~~~~~~~~~~~~~~~

For each owner the name must be unique and can be composed of alphanumeric characters and the following special
characters: ``-._~``. If the attribute *name* is not provided, then the service will generate one using the template::

 <jwtUser>~<owner>~<oboTenant>~<subjectFilter>~<random4>

For example::

 jobs~testuser1~dev~jobs.JOB_NEW_STATUS.ALL~m4Kx

Note that when constructing the name:

* *subjectFilter* will be truncated to 40 characters
* If *subjectFilter* is the wildcard character ``*``, it is replaced with the string ``ALL`` when constructing the name.
* The last 4 characters are generated at random from the set of alphanumeric characters including upper case, lower case and digits.


Delivery Target
~~~~~~~~~~~~~~~

Each subscription will contain a list of delivery targets for use in delivering events.
The list must contain at least one item. WEBHOOK and EMAIL deliveries are supported.

A delivery target contains the following information:

* *deliveryMethod* - The type of delivery method: WEBHOOK, EMAIL
* *deliveryAddress* - URL for WEBHOOK or email address for EMAIL


------------------
Notification Model
------------------
A notification is an object encapsulating the information sent to a delivery target. It contains the following:

* *uuid* - Unique identifier for the notification.
* *event* - All information contained in the event. See above under the section `Event Model`_.
* *eventUuid* - Unique identifier for the event.
* *tenant* - tenant associated with the notification.
* *subscriptionName* - Name of subscription associated with the notification.
* *deliveryTarget* - the delivery target
* *created* Timestamp for when the notification was created.

Example of a notification sent to a webhook::

 {
   "uuid": "30d70395-d5e9-43a4-ae90-2306b6bb00d6",
   "tenant": "admin",
   "subscriptionName": "4d0abbce-5cec-4d6e-8065-cdc5b2777389",
   "eventUuid": "50cfb971-c4b3-4d33-89c3-2b0f56f16e19",
   "event": {
     "source": "notifications",
     "type": "notifications.test.begin",
     "subject": "4d0abbce-5cec-4d6e-8065-cdc5b2777389",
     "data": null,
     "seriesId": "4d0abbce-5cec-4d6e-8065-cdc5b2777389",
     "timestamp": "2023-09-15T14:47:50.287792699Z",
     "deleteSubscriptionsMatchingSubject": false,
     "tenant": "admin",
     "user": "notifications",
     "received": "2023-09-15T14:47:51.000",
     "uuid": "50cfb971-c4b3-4d33-89c3-2b0f56f16e19",
     "seriesSeqCount": 4
   },
   "deliveryTarget": {
     "deliveryMethod": "WEBHOOK",
     "deliveryAddress": "https://admin.develop.tapis.io/v3/notifications/test/callback/4d0abbce-5cec-4d6e-8065-cdc5b2777389/"
   },
   "created": "2023-09-15T14:47:50.315188203Z"
 }

Example of a notification sent to an email address::

 {
   "uuid": "befe2475-58ad-4a5c-bcf2-593f04e49a20",
   "tenant": "dev",
   "subscriptionName": "jobs~testuser2~dev~ef9004c3-09d5-41d5-acd3-be7c9fd3daf6-007~cxh2",
   "eventUuid": "1d16202d-2248-4690-bcc9-a0134a4089cd",
   "event": {
     "source": "https://tapis.io/jobs",
     "type": "jobs.JOB_NEW_STATUS.FINISHED",
     "subject": "ef9004c3-09d5-41d5-acd3-be7c9fd3daf6-007",
     "data": "{\"newJobStatus\":\"FINISHED\",\"oldJobStatus\":\"ARCHIVING\",\"blockedCount\":0,\"remoteJobId\":\"35299a7d78f1591e395fdcec9dc6b1f3606be9f56f38453129b6ccc383ed9759\",\"remoteJobId2\":null,\"remoteOutcome\":\"FINISHED\",\"remoteResultInfo\":\"0\",\"remoteQueue\":null,\"remoteSubmitted\":\"2023-09-15T15:11:18.354731067Z\",\"remoteStarted\":null,\"remoteEnded\":null,\"jobName\":\"Tapis V3 smoketest job\",\"jobUuid\":\"ef9004c3-09d5-41d5-acd3-be7c9fd3daf6-007\",\"jobOwner\":\"testuser2\",\"message\":\"The job has transitioned to a new status: FINISHED. The previous job status was ARCHIVING.\"}",
     "seriesId": "ef9004c3-09d5-41d5-acd3-be7c9fd3daf6-007",
     "timestamp": "2023-09-15T15:11:23.947827477Z",
     "deleteSubscriptionsMatchingSubject": true,
     "tenant": "dev",
     "user": "jobs",
     "received": "2023-09-15T14:47:51.000",
     "uuid": "1d16202d-2248-4690-bcc9-a0134a4089cd",
     "seriesSeqCount": -1
   },
   "deliveryTarget": {
     "deliveryMethod": "EMAIL",
     "deliveryAddress": "me@example.com"
   },
   "created": "2023-09-15T15:11:23.965413696Z"
 }


---------------------
Notification Delivery
---------------------

Background
~~~~~~~~~~

When events are published to the Notifications front end api service, they are initially placed on a message
broker queue to be picked up asynchronously by a back end worker process known as the dispatch service.
Currently RabbitMQ is used as the message broker. 

The dispatch service reads events from the queue and assigns them to workers known as *delivery bucket managers*.
Delivery bucket managers are threads that receive their assigned events from in-memory queues.
The dispatch service assigns events to a bucket manager by taking a hash of the event *tenant*, *source*,
*subject* and *seriesId*. The hash allows for distributing work among the bucket managers while ensuring that
for a given *seriesId* the same bucket manager will process that series of events. This is how the service
ensures that notifications for events in a series are sent out in order.

When a bucket manager worker receives an event to process, it first finds all matching subscriptions by
querying a database. As discussed above, the matching is based on the *typeFilter* and *subjectFilter*
defined in a subscription.

For each delivery target in each matching subscription, the worker creates a Notification object and persists it
to a database. By persisting to a database we are able to support recovery and retries. The worker then begins
the process of delivering the notifications.


Configuring for EMAIL Delivery
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Supporting delivery by EMAIL involves configuring the Tapis Notifications service to use an SMTP relay.
This must be done by the Tapis systems administrator. Parameters for the relay are set as environment variables
to be picked up by the dispatcher service when it is started during a deployment.
For more information on deployer configuration please see `Notifications_Email_Config`_.

.. _Notifications_Email_Config: https://tapis.readthedocs.io/en/latest/deployment/deployer.html#configuring-support-for-email-notifications


Please note that deployer currently only supports template variables for TAPIS_MAIL_PROVIDER, TAPIS_SMTP_HOST and TAPIS_SMTP_PORT.
Other environment variables must be set manually in the deployment. 

The environment variables used to configure email delivery are:

*TAPIS_MAIL_PROVIDER*
  Optional. Supported values: SMTP, LOG, NONE. Default is LOG.
  This should typically be set to SMTP. Setting to LOG results in the dispatcher generating a log message showing
  the email information. Setting to NONE results in delivery being a NO-OP.
*TAPIS_SMTP_HOST*
  Required if provider is SMTP. Host to use as relay when sending email via SMTP.
*TAPIS_SMTP_PORT*
  Optional. Port used when sending email using SMTP. Default is 25.
*TAPIS_SMTP_FROM_NAME*
  Optional. Name for the email `From:` field. Default value is *Tapis Notifications Service*.
*TAPIS_SMTP_FROM_ADDRESS*
  Optional. Address for the email `From:` field. Default value is *no-reply@nowhere.com*.
*TAPIS_SMTP_AUTH*
  Optional. Boolean indicating if SMTP server requires a username and password. Default is *false*.
*TAPIS_SMTP_USER*
  Required if TAPIS_SMTP_AUTH is *true*.
*TAPIS_SMTP_PASSWORD*
  Required if TAPIS_SMTP_AUTH is *true*.

EMAIL Delivery
~~~~~~~~~~~~~~
When the notification delivery method is of type EMAIL, the dispatch worker will send an email using SMTP.

The ``To:`` field for the email will be the notification delivery address.

The ``From:`` field for the email will depend on the configuration parameters, as discussed above in the
section `Configuring for EMAIL Delivery`_. By default this will be::

  Tapis Notifications Service <no-reply@nowhere.com>

The ``Subject:`` of the email will have the following format::

  Tapis v3 notification. Event type: <event_type> subject: <subject>

If the event has no *subject* then the email subject will not have the subject portion.

An example email subject for the case where the event contains a *subject* attribute::

  Tapis v3 notification. Event type: jobs.JOB_NEW_STATUS.FINISHED subject: 1451b0ef-c057-4177-acd5-51a4901acb07-007

The body of the email will contain the notification data as json. An example may be found above under the section
`Notification Model`_. 

WEBHOOK Delivery
~~~~~~~~~~~~~~~~
When the notification delivery method is of type WEBHOOK, the dispatch worker will deliver the notification using an
HTTP POST request. The media type for the request will be *application/json* and the following header will be
added: ``User-Agent: Tapis/v3``.

The request body will be a json structure with the notification information.
An example may be found above under the section `Notification Model`_. 

------
Tables
------

Subscription Attributes
~~~~~~~~~~~~~~~~~~~~~~~

+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| Attribute       | Type           | Example            | Notes                                                                   |
+=================+================+====================+=========================================================================+
| tenant          | String         | designsafe         | - Name of the tenant associated with the subscription.                  |
|                 |                |                    | - *tenant* + *owner* + *name* must be unique.                           |
|                 |                |                    | - Determined by the service at creation time.                           |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| name            | String         | my-email-ntf-1     | - Optional short descriptive name.                                      |
|                 |                |                    | - *tenant* + *owner* + *name* must be unique.                           |
|                 |                |                    | - Allowed characters: Alphanumeric [0-9a-zA-Z] and ``-._~``.            |
|                 |                |                    | - If not provided the service will create one.                          |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| owner           | String         | jdoe               | - username of *owner*.                                                  |
|                 |                |                    | - Variable references: *${apiUserId}*. Resolved at create time.         |
|                 |                |                    | - By default this is the resolved value for *${apiUserId}*.             |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| description     | String         | My email           | - Optional more verbose description. Maximum length of 2048 characters. |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| enabled         | boolean        | FALSE              | - Indicates if subscription is active.                                  |
|                 |                |                    | - May be updated using the enable/disable endpoints.                    |
|                 |                |                    | - By default this is *true*.                                            |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| typeFilter      | String         | apps.APP.DELETE    | - Filter to use when matching events.                                   |
|                 |                |                    | - Matches against event type.                                           |
|                 |                |                    | - Has three dot separated parts: *<service>.<category>.<detail>*.       |
|                 |                |                    | - Each part may be a specific type or the wildcard character \*.        |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| subjectFilter   | String         | <job-id>           | - Filter to use when matching events.                                   |
|                 |                |                    | - Matches against event subject.                                        |
|                 |                |                    | - Can be specific for an exact match or the wildcard character \*.      |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| deliveryTargets | Object[]       |                    | - List of delivery targets to be used when delivering a matching event. |
|                 |                |                    | - Must have at least one.                                               |
|                 |                |                    | - Each target includes delivery method and delivery address.            |
|                 |                |                    | - Delivery methods supported: WEBHOOK, EMAIL                            |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| ttlMinutes      | int            | 60                 | - Time to live in minutes. Can be updated.                              |
|                 |                |                    | - Service will compute expiry based on this attribute.                  |
|                 |                |                    | - Default is one week from creation.                                    |
|                 |                |                    | - Value of 0 indicates no expiration.                                   |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| expiry          | Timestamp      |2020-06-26T15:10:43Z| - Time at which the subscription expires and will be deleted.           |
|                 |                |                    | - Maintained by the service.                                            |
|                 |                |                    | - Computed at create time.                                              |
|                 |                |                    | - Recomputed when attribute *ttlMinutes* is updated.                    |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| uuid            | UUID           |                    | - Auto-generated by service.                                            |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| created         | Timestamp      |2020-06-19T15:10:43Z| - When the subscription was created. Maintained by service.             |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+
| updated         | Timestamp      |2020-06-20T23:21:22Z| - When the subscription was last updated. Maintained by service.        |
+-----------------+----------------+--------------------+-------------------------------------------------------------------------+

Event Attributes
~~~~~~~~~~~~~~~~

+----------------+--------+--------------------------+-----------------------------------------------------------+
| Attribute      | Type   | Example                  | Notes                                                     |
+================+========+==========================+===========================================================+
| source         | String | https://tapis.io/jobs    | - Context in which event happened.                        |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| type           | String |jobs.JOB_NEW_STATUS.QUEUED| - Type of event. Used for routing notifications.          |
|                |        |                          | - Pattern is `<service>.<category>.<detail>`              |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| subject        | String |  <job-id>                | - Subject of event in the context of the service.         |
|                |        |                          | - Examples: job Id, app Id, file path, role name, etc.    |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| timestamp      | String | 2020-06-19T15:10:43Z     | - When the event happened.                                |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| data           | String |                          | - Optional.  Other data associated with the event.        |
|                |        |                          | - For example, service specific information.              |
+----------------+--------+--------------------------+-----------------------------------------------------------+
|delete          |boolean |                          | - Delete subscriptions where subjectFilter matches subject|
|Subscriptions   |        |                          |                                                           |
|MatchingSubject |        |                          |                                                           |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| endSeries      |boolean |                          | - Delete tracking data for the series.                    |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| seriesId       | String |  <job-id>                | - Optional. Group events based on tenant,source,subject.  |
|                |        |                          | - Preserves event order during notification delivery.     |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| tenant         | String |   tacc                   | - Tapis tenant associated with the event.                 |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| uuid           | String |                          | - Tapis generated unique identifier.                      |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| user           | String |                          | - Tapis user associated with the event.                   |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| received       | String | 2020-06-19T15:10:43Z     | - When the event was received by Tapis.                   |
+----------------+--------+--------------------------+-----------------------------------------------------------+
| seriesSeqCount | String |                          | - Tapis generated counter for seriesId.                   |
+----------------+--------+--------------------------+-----------------------------------------------------------+

Notification Attributes
~~~~~~~~~~~~~~~~~~~~~~~

+----------------+--------+----------------------------------------------------------------+
| Attribute      | Type   | Notes                                                          |
+================+========+================================================================+
| uuid           | String | Unique identifier for the notification.                        |
+----------------+--------+----------------------------------------------------------------+
| tenant         | String | Tenant associated with the notification.                       |
+----------------+--------+----------------------------------------------------------------+
|subscriptionName| String | Name of subscription associated with the notification.         |
+----------------+--------+----------------------------------------------------------------+
| eventUuid      | String | Unique identifier for the event contained in the notification. |
+----------------+--------+----------------------------------------------------------------+
| event          | Object | Event that triggered the notification.                         |
+----------------+--------+----------------------------------------------------------------+
| deliveryTarget | Object | The delivery target for the notification.                      |
+----------------+--------+----------------------------------------------------------------+
| created        | String | When the notification was created.                             |
+----------------+--------+----------------------------------------------------------------+

Delivery Target Attributes
~~~~~~~~~~~~~~~~~~~~~~~~~~

+----------------+--------+----------------------------------------------------------------+
| Attribute      | Type   | Notes                                                          |
+================+========+================================================================+
| deliveryMethod | enum   | WEBHOOK or EMAIL                                               |
+----------------+--------+----------------------------------------------------------------+
| deliveryAddress| String | URL for WEBHOOK or email address for EMAIL                     |
+----------------+--------+----------------------------------------------------------------+
