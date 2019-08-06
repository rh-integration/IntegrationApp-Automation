## Add Apicurito as a service to your OpenShift project



### Procedure:

#### Add Apicurito as a service to your OpenShift project

1- Open the OpenShift console and select rh-dev project

2- Click Catalog. In the Catalog search field, type Apicurito and then select Red Hat Fuse Apicurito and select Next

3- In the Image Stream Namespace field, type openshift.

4- In the ROUTE_HOSTNAME field, give the wildcard domain name, for example apicurito-rh-dev.app.<>.redhat.com

5- Accept the default values for the rest of the settings in the Configuration step and click Create.

6- Click the link for the Aplicurito route 
                                            


 ![alt text](../images/apicurito_instance_create_04.png "Create the API (service)")

and Apicurito opens in a new web browser window or tab:

![alt text](../images/apicurito_instance_create_05.png "Create the API (service)")