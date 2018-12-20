# IntegrationApp Automation


## Demo Story

An integration application consisting of Multiple services working in combination (single front end with dispatch to two back-ends), one or more APIs that need to be managed via 3scale, and one or more messaging destinations/addresses used for event-driven inputs and outputs. Now want to automate deployment of this application across multiple environments, using pre-defined pipelines provided by the platform. The delivery pipelines must support environment-specific properties, testing, versioning, and the ability to rollback incomplete or failed deployments.

![alt text](images/outline.png "outline")




**Products and Projects**

    • OpenShift Container Platform
    • Red Hat 3scale API Management
    • Red Hat Fuse
    • MySQL Database
    • Red Hat AMQ
    • Node.js (RHOAR) Web Application
    • Jenkins for CICD


![alt text](images/image2.png "outline 2")



 Steps
 
     • Design an application using Fuse, AMQ, and 3Scale.
     • Source to Image (S2I) build and deploy apps on openshift environment.
     • Building a pipeline to support automated CI/CD
     • Expose a REST API using Camel, and export API doc to swagger.
     • Publish API on 3scale environment using CI/CD pipeline.
     • Manage the API through 3scale API management and update the application plan to rate-limit the application.
     • Design a web application that makes its calls through the 3scale API gateway.

## Application Environment

This demo contains below applications.

    • Gateway application https://github.com/redhatHameed/3ScaleFuseAMQ/tree/master/maingateway-service 
    • User Service application https://github.com/redhatHameed/3ScaleFuseAMQ/tree/master/fisuser-service
    • Alert Service Application https://github.com/redhatHameed/3ScaleFuseAMQ/tree/master/fisalert-service
    • Node.js Web application https://github.com/redhatHameed/3ScaleFuseAMQ/tree/master/nodejsalert-ui
    • 3scale (Openshift on-premises) environment

### Automation of Applications in OpenShift.

TODO: -The below deployment will be achieved using Jenkins Pipelines CICD approach.

     • Deploying application to DEV Environment.
     • Deploying application from DEV to UAT Environment.
     • Deploying application in Prod Environment.
     • Deploying application to Prod DR Environment.
     • Publishing API’s in 3scale : (By using Operator or ansible playbooks).



