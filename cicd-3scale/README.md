# 3scale Publish API with 3scale Toolbox


##  Load the OpenAPI Specifications to Apicurio

Go to [studio.apicur.io](https://studio.apicur.io/), login and import the openapi specification of maingateway-service

* Go to [https://studio.apicur.io/apis/import](https://studio.apicur.io/apis/import)
* Choose `Import from File/Clipboard`
* Fill-in the URL field with the raw url of the gateway service (https://github.com/rh-integration/IntegrationApp-Automation/blob/master/maingateway-service/src/spec/openapi-spe.json)
* Click `Edit API
* Click source tab add API Key scheme to secure API

```json
   "securityDefinitions" : {
      "apikey" : {
        "type" : "apiKey",
        "description" : "Use a 3scale API Key",
        "name" : "api-key",
        "in" : "query"
      }
    },
    "security" : [ {
      "apikey" : [ ]
    } ]

```
* add base path, API PRIVATE_BASE_URL in host field and set scheme type as seen below

```json

    "host": "maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com",
     "basePath": "/cicd",
     "schemes": [
       "http"
     ]

```

* save API under [/cicd-3scale/3scaletoolbox](/cicd-3scale/3scaletoolbox) folder.


## Setup

1. Install [3scale toolbox](https://github.com/3scale/3scale_toolbox/blob/master/README.md#installation).

2. Configure 3scale URL and token with in 3scaletoolbox.
	
	```sh
	
		3scale remote add $NAME https://$TOKEN@$TENANT.3scale.net/
		
	```
3. Create the sceret in openshift project.

	```sh
	
	oc project rh-dev
	
	oc create secret generic 3scale-toolbox --from-file=$HOME/.3scalerc.yaml
	```

4. view [3scaletoolbox Jenkins File](https://raw.githubusercontent.com/rh-integration/IntegrationApp-Automation/master/cicd-3scale/3scaletoolbox/Jenkinsfile)

5. Create pipeline, update the pipeline parameters as per your environment .

```sh

oc new-app -f cicd-3scale/3scaletoolbox/pipeline-template.yaml  -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod  -p PRIVATE_BASE_URL=http://maingateway-service-rh-test.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.app.middleware.ocp.cloud.lab.eng.bos.redhat.com -p DEVELOPER_ACCOUNT_ID=developer 

```




