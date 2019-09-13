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

1. Install [3scale toolbox](https://github.com/3scale/3scale_toolbox_packaging).

2. Configure/Add remote with 3scale URL and token by using 3scale toolbox command as seen below
	
	```sh
	
   3scale remote add instance_a https://$TOKEN@$TENANT.3scale.net/
		
	```
3. Create the Secret in openshift project.

	```sh
	
	oc project rh-dev
	
	oc create secret generic 3scale-toolbox --from-file=$HOME/.3scalerc.yaml
	```
4. Download [image](https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=72168) 3scaletoolbox and push it to your openshift registry.
 
    ```
    
    brew install skopeo
    yum install skopeo
    
    oc project rh-dev
    
    REGISTRY="$(oc get route docker-registry -n default -o 'jsonpath={.spec.host}')"  
    ```
    if your using openshfift 4+ version then use registry     
    
    ```
    REGISTRY="$(oc get route image-registry -n openshift-image-registry -o 'jsonpath={.spec.host}')" 
    ```
    
    ```
    
    oc create serviceaccount skopeo
    oc get secrets -o jsonpath='{range .items[?(@.metadata.annotations.kubernetes\.io/service-account\.name=="skopeo")]}{.metadata.annotations.openshift\.io/token-secret\.value}{end}' |tee skopeo-token
    TOKEN="$(cat skopeo-token)"
    
    skopeo inspect --tls-verify=false --creds="skopeo:$TOKEN" docker://$REGISTRY/openshift/nodejs
    oc adm policy add-role-to-user system:image-builder -n rh-dev system:serviceaccount:rh-dev:skopeo
    
    skopeo --insecure-policy copy --dest-tls-verify=false --dest-creds="skopeo:$TOKEN" docker-archive:$HOME/Downloads/docker-image-sha256_08eaec27972a5df6bc0e8c7577697ab83edf1d66adfe1fe00c2a320e8d7a881a.x86_64.tar.gz docker://$REGISTRY/rh-dev/toolbox:v0.12.4
    
    
    ```
    or you can use same image version from [quay.io](https://quay.io/repository/redhat/3scale-toolbox?tag=v0.12.3&tab=tags)
5. Read [3scale-toolbox Configuration](https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.6/html/operating_3scale/api-lifecyle-toolbox)

6. view [3scale-toolbox Jenkins File](https://raw.githubusercontent.com/rh-integration/IntegrationApp-Automation/master/cicd-3scale/3scaletoolbox/Jenkinsfile)

7. Create pipeline, update the pipeline parameters as per your environment .

```sh

oc new-app -f cicd-3scale/3scaletoolbox/pipeline-template.yaml  -p IMAGE_NAMESPACE=rh-dev -p DEV_PROJECT=rh-dev -p TEST_PROJECT=rh-test -p PROD_PROJECT=rh-prod  -p PRIVATE_BASE_URL=<API_URL> -p PUBLIC_PRODUCTION_WILDCARD_DOMAIN=<WILDCARD_DOMAIN> -p PUBLIC_STAGING_WILDCARD_DOMAIN=staging.<WILDCARD_DOMAIN> -p DEVELOPER_ACCOUNT_ID=developer 

```




