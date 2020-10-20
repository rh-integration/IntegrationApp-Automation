# IntegrationApp Automation


## Demo Story

An integration application consisting of Multiple services working in combination (single front end with dispatch to two back-ends), one or more APIs that need to be managed via 3scale, and one or more messaging destinations/addresses used for event-driven inputs and outputs. Now want to automate deployment of this application across multiple environments, using pre-defined pipelines provided by the platform. The delivery pipelines must support environment-specific properties, testing, versioning, and the ability to rollback incomplete or failed deployments.

![alt text](images/outline.png "outline")




**Products and Projects**

    • OpenShift Container Platform
    • Red Hat 3scale API Management
    • Red Hat Fuse
    • Apicurio
    • MySQL Database
    • Red Hat AMQ
    • Node.js (RHOAR) Web Application
    • Jenkins for CICD


![alt text](images/image2.png "outline 2")



 Steps
 
     • Design an application using Apicurio, Fuse, AMQ, and 3Scale.
     • Design API with Apicurio, integrate API with Fuse/Camel.
     • Source to Image (S2I) build and deploy apps on openshift environment.
     . Building a pipeline to support automated CI/CD 
     • Publish API on 3scale environment using 3scaletoolbox jenkins pipeline.
     • Manage the API through 3scale API management and update the application plan to rate-limit the application.
     • Design a web application that makes its calls through the 3scale API gateway.

## Application Environment

This demo contains below applications.

   1. [Gateway application](https://github.com/rh-integration/IntegrationApp-Automation/tree/master/maingateway-service).
   2. [User Service application ](https://github.com/rh-integration/IntegrationApp-Automation/tree/master/fuse-user-service)
   3. [Alert Service Application ](https://github.com/rh-integration/IntegrationApp-Automation/tree/master/fuse-alert-service)
   4. [Node.js Web application](https://github.com/rh-integration/IntegrationApp-Automation/tree/master/nodejsalert-ui)
   5. [3scale Toolbox Jenkins Pipeline](https://github.com/rh-integration/IntegrationApp-Automation/tree/master/cicd-3scale).
     


## Automation of Applications in OpenShift
### Build and deploy with pipelines
***The application works under [OpenShift](https://www.okd.io/) or [Minishift](https://www.okd.io/minishift/)***

The following instructions assuming that you are using OpenShift. But the same could be applied to Minishift as well.

Download the source codes from git repository by either forking, or simply cloning it. 

```
git clone https://github.com/rh-integration/IntegrationApp-Automation.git 

```
Assume you have OpenShift cluster ready and running.

```
# login to the OpenShift
oc login <OpenShift cluster url> --token=<OpenShift user login token>

```

Setup `rh-dev`, `rh-test` and `rh-prod` OpenShift projects as the target environment (you may skip this step if you already have the environment ready, and you can also change projects name inside env.sh ).
    
```sh

./setup/setup.sh

```
If you run the above setup.sh, the pipelines are automatically imported. In case you want to further customize the pipelines, please follow the instructions below.

You can also customize the pipelines by changing their parameters.  Different templates have different parameters but they are all listed below:

```
NAME                                DESCRIPTION         GENERATOR           VALUE
GIT_REPO                                                                    https://github.com/rh-integration/IntegrationApp-Automation
GIT_BRANCH                                                                  master
DEV_PROJECT                                                                 
TEST_PROJECT                                                                
PROD_PROJECT                                                                
MYSQL_USER                                                                  dbuser
MYSQL_PWD                                                                   password
IMAGE_REGISTRY                                                              image-registry.openshift-image-registry.svc:5000
IMAGE_NAMESPACE                                                             
PRIVATE_BASE_URL                                                            http://maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com
PRODUCTION_PUBLIC_BASE_URL                                                  https://3scalefuse.app.middleware.ocp.cloud.lab.eng.bos.redhat.com
STAGING_PUBLIC_BASE_URL                                                     https://3scalefuse-staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com
PUBLIC_PRODUCTION_WILDCARD_DOMAIN                                           app.middleware.ocp.cloud.lab.eng.bos.redhat.com
PUBLIC_STAGING_WILDCARD_DOMAIN                                              staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com
API_BASE_SYSTEM_NAME                                                        3scalefuse
SECRET_NAME                                                                 3scale-toolbox
TARGET_INSTANCE                                                             instance_a
DEVELOPER_ACCOUNT_ID                                                        Developer
DISABLE_TLS_VALIDATION                                                      yes

* If you have customized MYSQL_USER or MYSQL_PWD, please edit the nodejsalert-ui/config.js accordingly.

```
##### To list the parameters of each template:
```sh

# list for fuse-user-service pipeline
oc process --parameters -f fuse-user-service/src/main/resources/pipeline-app-build.yml

# list for maingateway-service pipeline
oc process --parameters -f  maingateway-service/src/main/resources/pipeline-app-build.yml

# list for nodejsalert-ui pipeline
oc process --parameters -f  nodejsalert-ui/resources/pipeline-app-build.yml

# list for fuse-alert-service pipeline
oc process --parameters -f  fuse-alert-service/src/main/resources/pipeline-app-build.yml

# list for aggregated-pipeline
oc process --parameters -f  pipelinetemplates/pipeline-aggregated-build.yml

```

##### To replace the existing pipelines with your customized pipelines:

```sh

##### switch to rh-dev project
oc project rh-dev

```

#### Remove the existing pipeline that you want to customize.

```sh

oc delete bc fuse-user-service-pipeline
oc delete bc maingateway-service-pipeline
oc delete bc nodejsalert-ui-pipeline
oc delete bc fuse-alert-service-pipeline
oc delete bc aggregated-pipeline
oc delete bc publish-api-3scale

```

```sh

# import fuse-user-service pipeline
oc new-app -f fuse-user-service/src/main/resources/pipeline-app-build.yml -p IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000 -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod

# import maingateway-service pipeline
oc new-app -f maingateway-service/src/main/resources/pipeline-app-build.yml -p IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000 -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod

# import nodejsalert-ui pipeline
oc new-app -f nodejsalert-ui/resources/pipeline-app-build.yml -p IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000 -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod

# import fuse-alert-service pipeline
oc new-app -f fuse-alert-service/src/main/resources/pipeline-app-build.yml -p IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000 -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod

# import aggregated-pipeline
oc new-app -f pipelinetemplates/pipeline-aggregated-build.yml -p IMAGE_REGISTRY=image-registry.openshift-image-registry.svc:5000 -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod  -p PRIVATE_BASE_URL=http://maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p DEVELOPER_ACCOUNT_ID=developer

# import 3scale pipeline
oc new-app -f cicd-3scale/3scaletoolbox/pipeline-template.yaml  -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod  -p PRIVATE_BASE_URL=http://maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p DEVELOPER_ACCOUNT_ID=developer 


```
#### Set the  IMAGE_REGISTRY in pipeline 

if you're using openshift 4 plus environment, then set the image registry 

```image-registry.openshift-image-registry.svc:5000```else set defualt from docker registry```docker-registry.default.svc:5000``` 
 



####  3scale pipeline setup

Before running Pipelines, listed 3scale configuration required to set.


* Create the routes for your APIcast gateways in 3scale Project if required with below command

```sh
 oc new-app -f apicast-routes-template.yaml -p BASE_NAME=rh-test-3scalefuse  -p MAJOR_VERSION=1 -p WILDCARD_DOMAIN=<openshift_wildcard_domain> -n <3scale_namespace>
 oc new-app -f apicast-routes-template.yaml -p BASE_NAME=rh-prod-3scalefuse  -p MAJOR_VERSION=1 -p WILDCARD_DOMAIN=<openshift_wildcard_domain> -n <3scale_namespace>
 
* BASE_NAME = project environment name- base name mentioned in Jenkins pipeline
```

* set below listed parameters

```sh
PUBLIC_PRODUCTION_WILDCARD_DOMAIN                                         
PUBLIC_STAGING_WILDCARD_DOMAIN                                            
API_BASE_SYSTEM_NAME                                                      
SECRET_NAME                                                               
TARGET_INSTANCE                                                           
DEVELOPER_ACCOUNT_ID                                                        
DISABLE_TLS_VALIDATION  set "yes" to disable TLS validation.
```
* Read [3scale-toolbox Configuration]( https://github.com/rh-integration/3scale-toolbox-jenkins-samples ) and  [3scale-toolbox image setup](https://github.com/rh-integration/IntegrationApp-Automation/tree/master/cicd-3scale#setup)

####  Run pipelines 

After you have set the parameters and imported all of the pipeline templates, you should have them under `Builds`, `Pipelines` of the selected OpenShift project.

![Pipeline View](images/pipeline_import_view.png "Pipeline View")

Please start the pipeline from `fuse-user-service-pipeline`, `fuse-alert-service-pipeline`, `maingateway-service-pipeline` ,`nodejsalert-ui-pipeline` and then `publish-api-3scale` to publish API on 3scale.

With `aggregated-pipeline`, you can build the entire application including all of the above modules mentioned. If you choose this pipeline, by default, it will build the entire application, but you will also be asked to select which individual module you want to build.  You will need to make your selection in your Jenkins console.

Once the build is finished, in your OpenShift, go to `rh-test` or `rh-prod`, navigate to `Applications`, `Routes` and click on maingateway-service and nodejsalert-ui route to launch the application.
You should see the application and it is started with web front-end like this, add 3scale user key and 3scale gatway url and click sendAlert button: 

![Application View](images/application_launch_view.png "Application View")



### Deploy with BlueGreen Deployment Strategy

The following instructions show how to use Jenkins Pipeline to deploy `nodejsalert-ui` module with BlueGreen Deployment Strategy.

We will work with `nodejsalert-ui-pipeline`.  Please login to Jenkins console in your OpenShift. Then you should see the pipeline job `rh-dev/nodejsalert-ui-pipeline`.  Click on it and next click on the `Build with Parameters`.  In the parameters input page, input the `SERVICE_VERSION`, check the checkbox for `BLUEGREEN_DEPLOYMENT`, and validate other parameters (default should work if you followed all the instructions in this page). Click on Build button to start the build.

After the build is finished. You should be able to see `nodejsalert-ui-green` services in your `rh-test` as well as `rh-prod` OpenShift projects.  Now you can change your existing nodejsalert-ui route to point to this Green service so that you can verify your new deployment before completely rollout to production. 


```
#To change the route to use Green release
oc patch route/nodejsalert-ui -p  '{"spec":{"to":{"name":"nodejsalert-ui-green"}}}' -n rh-test

#To rollback the deployment (if necessary)
oc patch route/nodejsalert-ui -p  '{"spec":{"to":{"name":"nodejsalert-ui"}}}' -n rh-test

```


### Decrease Maven Build times (optional)

In order to further speed up the builds time and avoid depndenices to download everytime, please follow the instruction [here](https://blog.openshift.com/decrease-maven-build-times-openshift-pipelines-using-persistent-volume-claim)



###  Cleaning Up

To clean up all of your environment, you can run the script:

```sh
 ./setup/delete-setup.sh
 
 ```


