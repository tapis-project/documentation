.. _preliminaries:

=======================================
Considerations and Prerequisites
=======================================

.. note::

    This guide is for users wanting to deploy Tapis software in their own datacenter. Researchers who 
    simply want to make use of the Tapis APIs do not need to deploy any Tapis components and can ignore
    this guide.  


If you are planning to deploy Tapis software at your own institution, there are a number of considerations 
and prerequisites that should be thought through before beginning. 
Administering a Tapis installation is a 
big commitment and will require substantial resources, including hardware and human capital, to be 
successful. 
Proper planning and design upfront will 
reduce the time required to get to a working Tapis installation that meets your institution's requirements.

.. warning::

  We strongly recommend consulting with the Tapis core team to plan your deployment and operations.

---------
Site Type
---------
Tapis supports geographically distributed deployments where different components are
running in different data centers and managed by different institutions. These
physically isolated installations of Tapis software are referred to as  *sites*.
There is a single *primary site* and zero or more *associate sites* within a Tapis
installation.

When deploying Tapis software to a new institution, one must decide whether to deploy a primary site or an
associate site. There are several aspects to consider:

* Primary sites must deploy all Tapis services, which increases the administrative burden and computational
  resource requirement significantly. 
* Associate sites can run a few, critical services on-premise while deferring to the primary site for
  all other services. Associate sites still maintain full administrative control over services running at their 
  site and full administrative control over tenants that they own. 
* Primary sites must manage all site and tenant configuration, including signing keys. 
* Primary sites are completely independent from any other Tapis software. Associate sites depend on
  a primary site to be functional -- if a primary site goes offline, the associate site will not function. 

The Texas Advanced Computing Center hosts a primary site for the "main" Tapis installation at the 
tapis.io domain. If you are interested in deploying an associate site as part of the main Tapis installation, 
please contact us. 


----------
Kubernetes
----------
The official Tapis installation scripts target Kubernetes for container orchestration. In the future, 
support for using Docker Compose instead of Kubernetes will be added. For now, a Kubernetes cluster is 
required to deploy Tapis using the official installation software. 

Successful deployment and operation of Tapis requires the operator(s) to have strong working knowledge
of Kubernetes concepts and abstractions, including Jobs, Deployments, PVCs, and Services, among others.
Introduction and administration of Kubernetes is beyond the scope of this document. 

----------------------------------
Environments and Capacity Planning
----------------------------------
Deploying Tapis requires dedicated capacity in your Kubernetes cluster. A minimum of two Tapis
installations for each site is required to allow updates to be applied in a pre-production environment 
before impacting production services.

The following are minimum requirements for each Tapis environment/installation:
  * 1+ control plane node. 2 cores/8GB Mem/32 GB disk for containers (/var/lib/containerd or /var/lib/docker or similar)
  * 2+ worker nodes. 4 cores/16 GB mem/64 GB disk for containers
  * Must have the ability to create PVC. Tapis will need to know the storage class name.
        * Both Ceph & NFS have been used successfully for this purpose 
  * Each Tapis installation must be deployed entirely within a single Kubernetes namespace and requires no special or elevated privileges on the cluster.
  * Outbound networking is required for several services
  * Inbound networking is only required for the external-facing IP which is then proxied to the rest of the Tapis services inside Kubernetes.
        * This "ingress" can be handled various ways; at TACC we use a manual haproxy server.
        * In traditional Kubernetes setups a combo of Load Balancer & Ingress services may also work
  * Based on Remote site firewall config, the Tapis Kube cluster may require special rules to be able to talk to "local" resources (clusters, storage, instruments, etc.) 
    
Note that for primary sites and associate sites that receive significant usage, the following compute 
requirements are strongly recommended:
  * 2+ worker nodes. 16 cores/64 GB mem/128 GB disk for containers


~~~~~~~~~~
Namespaces
~~~~~~~~~~
As mentioned above, each Tapis environment/installation must be deployed into its own, dedicated Kubernetes
namespace. Uniqueness assumptions made by the deployment architecture and scripts imply that attempting to
deploy multiple Tapis instances into the same Kubernetes namespace will result in failures. 

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Public IP Addresses, Domains and TLS Certificates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

All Tapis services respond to HTTP requests made to a configurable domain for the site. By default, each 
tenant is defined to a subdomain of the site domain. For example, the primary site at TACC has domain tapis.io, 
and each tenant is assigned the subdomain of the form <tenant_id>.tapis.io (e.g., designsafe.tapis.io for the 
DesignSafe project and cyverse.tapis.io for the CyVerse project). 

The official Tapis deployment tools will deploy and configure a reverse proxy to handle TLS negotiation 
and service request routing for all tenants owned by the site. The official Tapis proxy, or another reverse 
proxy with equivalent functionality, is strictly required for the Tapis services to function. 
In order for the Tapis proxy to be configured and deployed properly, the following must be available 
and provided:

  * A domain named owned by the institution to be used for the site, resolvable by DNS to a public IP address. 
  * A wildcard TLS certificate used for encryption for all top-level subdomains of the site domain. For
    example, if the site domain is ``mysite.org``, a wildcard certificate for ``*.mysite.org`` must
    be provided. In this case, tenants belonging to the site will use ``<tenant_id>.mysite.org`` as the 
    base URL for making HTTP requests to Tapis. 
  * A basic TCP reverse proxy listening on the public IP address assigned in DNS to all
    subdomains ``*.mysite.org``. For example, HAProxy or nginx can be used. 

A key point is that the Tapis proxy does **not** typically listen directly on the public IP address. This
is because a standard Kubernetes installation does not have a way of assigning public IP addresses to pods.  

.. note::

    One must typically deploy the external reverse proxy outside of Kubernetes. 


~~~~~~~~~~~~~~~~~~~~~~~~
Tenants & Authenticators
~~~~~~~~~~~~~~~~~~~~~~~~


--------
Deployer
--------
